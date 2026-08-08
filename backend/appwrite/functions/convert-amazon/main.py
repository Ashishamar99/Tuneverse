"""
Appwrite Function: convert-amazon
Extracts tracks from an Amazon Music playlist using the amz library.

Trigger: HTTP POST
Input: {
  "playlistId": "...",
  "accessToken": "...",
  "apiUrl": "https://amz.dezalty.com" (optional, default proxy)
}
Output: Creates/updates import_jobs and import_progress documents.

The amz library (pip: amazon-music) connects to a proxy API that
fetches data from Amazon Music. Users provide their access_token
obtained from their Amazon Music web session.
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
DEFAULT_API_URL = "https://amz.dezalty.com"


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

    playlist_id = body.get("playlistId")
    access_token = body.get("accessToken", "")
    api_url = body.get("apiUrl", DEFAULT_API_URL)
    user_id = context.req.headers.get("x-appwrite-user-id")

    if not playlist_id:
        return context.res.json({"error": "Missing 'playlistId' field"}, 400)

    if not user_id:
        return context.res.json({"error": "Authentication required"}, 401)

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
        playlist_data = _extract_playlist(
            api_url, access_token, playlist_id, db, progress_id
        )

        db.update_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_JOBS_COLLECTION,
            document_id=job_id,
            data={
                "status": "completed",
                "playlists": json.dumps([playlist_data]),
            },
        )

        return context.res.json({
            "jobId": job_id,
            "status": "completed",
            "playlistName": playlist_data["name"],
            "totalTracks": playlist_data["totalTracks"],
            "tracks": playlist_data["tracks"],
        })

    except Exception as e:
        db.update_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_JOBS_COLLECTION,
            document_id=job_id,
            data={"status": "failed"},
        )
        return context.res.json({"error": str(e), "jobId": job_id}, 500)


def _extract_playlist(api_url, access_token, playlist_id, db, progress_id):
    """Extract a single playlist from Amazon Music using the amz library."""
    from amz.api import API

    api = API(api_url, access_token=access_token)
    result = api.get_playlist(playlist_id)

    playlist_name = getattr(result, "title", None) or getattr(result, "name", "Amazon Playlist")
    raw_tracks = getattr(result, "tracks", [])

    if hasattr(raw_tracks, "toDict"):
        raw_tracks = list(raw_tracks)

    total = len(raw_tracks)
    _update_progress(db, progress_id, {
        "currentPlaylist": str(playlist_name),
        "totalTracks": total,
    })

    tracks = []
    for i, t in enumerate(raw_tracks):
        track_title = getattr(t, "title", None) or getattr(t, "name", "Unknown")
        track_artist = getattr(t, "artist", None) or getattr(t, "artists", "Unknown")
        track_album = getattr(t, "album", None)

        if isinstance(track_artist, list):
            track_artist = ", ".join(str(a) for a in track_artist)

        tracks.append({
            "originalTitle": str(track_title),
            "originalArtist": str(track_artist),
            "originalAlbum": str(track_album) if track_album else None,
        })

        if (i + 1) % 5 == 0 or i == total - 1:
            _update_progress(db, progress_id, {
                "processedTracks": i + 1,
                "lastMatchedTrack": f"{track_title} — {track_artist}",
            })

    return {
        "name": str(playlist_name),
        "totalTracks": total,
        "tracks": tracks,
    }


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
