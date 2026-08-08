"""
Appwrite Function: backup-cleanup
Scheduled daily — deletes expired import_jobs and import_progress documents.

Trigger: CRON schedule (0 3 * * *)  — runs at 3 AM UTC daily
"""

import os
from datetime import datetime, timezone

from appwrite.client import Client
from appwrite.services.databases import Databases
from appwrite.query import Query

DATABASE_ID = os.environ.get("APPWRITE_DATABASE_ID", "tuneverse")
IMPORT_JOBS_COLLECTION = "import_jobs"
IMPORT_PROGRESS_COLLECTION = "import_progress"


def main(context):
    client = Client()
    client.set_endpoint(os.environ["APPWRITE_FUNCTION_API_ENDPOINT"])
    client.set_project(os.environ["APPWRITE_FUNCTION_PROJECT_ID"])
    client.set_key(os.environ["APPWRITE_API_KEY"])

    db = Databases(client)

    now = datetime.now(timezone.utc).isoformat()

    expired = db.list_documents(
        database_id=DATABASE_ID,
        collection_id=IMPORT_JOBS_COLLECTION,
        queries=[
            Query.less_than("expiresAt", now),
            Query.limit(100),
        ],
    )

    deleted_jobs = 0
    deleted_progress = 0

    for doc in expired["documents"]:
        job_id = doc["$id"]
        try:
            db.delete_document(
                database_id=DATABASE_ID,
                collection_id=IMPORT_PROGRESS_COLLECTION,
                document_id=f"job_{job_id}",
            )
            deleted_progress += 1
        except Exception:
            pass

        db.delete_document(
            database_id=DATABASE_ID,
            collection_id=IMPORT_JOBS_COLLECTION,
            document_id=job_id,
        )
        deleted_jobs += 1

    context.log(f"Cleaned up {deleted_jobs} expired jobs, {deleted_progress} progress docs")
    return context.res.json({
        "deletedJobs": deleted_jobs,
        "deletedProgress": deleted_progress,
    })
