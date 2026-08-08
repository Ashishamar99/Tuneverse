"""
Appwrite Function: convert-amazon
Extracts playlists from Amazon Music using session cookies.

Trigger: HTTP POST
Input: { "cookies": "...", "playlistFilter": ["id1", "id2"] (optional) }
Output: Creates/updates import_jobs and import_progress documents.

Uses the unofficial Jaffa/amazon-music Python library.
Amazon's official API is closed beta — cookie-based session is the
only viable path without partner approval.
"""

import json
import os
from datetime import datetime, timedelta, timezone

from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.id import ID
from appwrite.permission import Permission
from appwrite.role import Role

DATABASE_ID = os.environ.get("APPWRITE_DATABASE_ID", "tuneverse")
IMPORT_JOBS_COLLECTION = "import_jobs"
IMPORT_PROGRESS_COLLECTION = "import_progress"
JOB_TTL_DAYS = 7


def main(context):
    client = Client()
    client.set_endpoint(os.environ["APPWRITE_FUNCTION_API_ENDPOINT"])
    client.set_project(os.environ["APPWRITE_FUNCTION_PROJECT_ID"])
    client.set_key(context.req.headers.get("x-appwrite-key", ""))

    db = Databases(client)

    try:
        body = json.loads(context.req.body or "{}")
    except json.JSONDecodeError:
        return context.res.json({"error": "Invalid JSON body"}, 400)

    cookies = body.get("cookies")
    user_id = context.req.headers.get("x-appwrite-user-id")

    if not cookies:
        return context.res.json({"error": "Missing 'cookies' field"}, 400)

    if not user_id:
        return context.res.json({"error": "Authentication required"}, 401)

    playlist_filter = body.get("playlistFilter")

    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(days=JOB_TTL_DAYS)

    job_id = ID.unique()
    permissions = [
        Permission.read(Role.user(user_id)),
        Permission.update(Role.user(user_id)),
        Permission.delete(Role.user(user_id)),
    ]

    job_doc = db.create_document(
        database_id=DATABASE_ID,
        collection_id=IMPORT_JOBS_COLLECTION,
        document_id=job_id,
        data={
            "userId": user_id,
            "source": "amazon",
            "status": "processing",
            "playlists": json.dumps([]),
            "createdAt": now.isoformat(),
            "expiresAt": expires_at.isoformat(),
        },
        permissions=permissions,
    )

    progress_id = f"job_{job_id}"
    db.create_document(
        database_id=DATABASE_ID,
        collection_id=IMPORT_PROGRESS_COLLECTION,
        document_id=progress_id,
        data={
            "userId": user_id,
            "jobId": job_id,
            "currentPlaylist": "",
            "processedTracks": 0,
            "totalTracks": 0,
            "lastMatchedTrack": "",
            "updatedAt": now.isoformat(),
        },
        permissions=permissions,
    )

    try:
        playlists_data = _extract_playlists(
            cookies, playlist_filter, db, job_id, progress_id, user_id
        )

        db.update_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_JOBS_COLLECTION,
            document_id=job_id,
            data={
                "status": "completed",
                "playlists": json.dumps(playlists_data),
            },
        )

        return context.res.json({
            "jobId": job_id,
            "status": "completed",
            "playlistCount": len(playlists_data),
            "totalTracks": sum(len(p["tracks"]) for p in playlists_data),
        })

    except Exception as e:
        db.update_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_JOBS_COLLECTION,
            document_id=job_id,
            data={"status": "failed"},
        )
        return context.res.json({"error": str(e), "jobId": job_id}, 500)


def _extract_playlists(cookies, playlist_filter, db, job_id, progress_id, user_id):
    """Extract playlists from Amazon Music using session cookies."""
    from amazonmusic import AmazonMusic

    am = AmazonMusic(cookies=cookies)
    raw_playlists = am.get_playlists()

    if playlist_filter:
        raw_playlists = [p for p in raw_playlists if p.id in playlist_filter]

    results = []

    for pl in raw_playlists:
        tracks_raw = am.get_playlist_tracks(pl.id)
        total = len(tracks_raw)

        _update_progress(db, progress_id, {
            "currentPlaylist": pl.name,
            "processedTracks": 0,
            "totalTracks": total,
        })

        tracks = []
        for i, t in enumerate(tracks_raw):
            tracks.append({
                "originalTitle": t.title,
                "originalArtist": t.artist,
                "originalAlbum": getattr(t, "album", None),
                "originalDurationMs": getattr(t, "duration_ms", None),
                "matchedSourceId": None,
                "matchConfidence": "pending",
                "matchedTitle": None,
            })

            if (i + 1) % 5 == 0 or i == total - 1:
                _update_progress(db, progress_id, {
                    "processedTracks": i + 1,
                    "lastMatchedTrack": f"{t.title} — {t.artist}",
                })

        results.append({
            "name": pl.name,
            "totalTracks": total,
            "matched": 0,
            "notFound": 0,
            "tracks": tracks,
        })

    return results


def _update_progress(db, progress_id, data):
    """Update the import_progress document for realtime UI updates."""
    data["updatedAt"] = datetime.now(timezone.utc).isoformat()
    try:
        db.update_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_PROGRESS_COLLECTION,
            document_id=progress_id,
            data=data,
        )
    except Exception:
        pass
