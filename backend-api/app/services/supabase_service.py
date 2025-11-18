"""
Supabase Storage Service

Uses Supabase REST API (HTTPS) instead of direct PostgreSQL connection.
More reliable and works through firewalls.
"""

import logging
from supabase import create_client, Client
from app.config import settings
import os

logger = logging.getLogger(__name__)


class SupabaseService:
    """Service for storing clothing items in Supabase via REST API"""

    def __init__(self):
        try:
            # Get credentials from environment
            supabase_url = os.getenv("SUPABASE_URL", "https://cnnobgvxdpevzxjfoprs.supabase.co")
            supabase_key = os.getenv("SUPABASE_KEY", "")

            if not supabase_key:
                logger.warning("⚠️  Supabase key not found, storage disabled")
                self.enabled = False
                return

            # Create Supabase client (uses HTTPS REST API)
            self.client: Client = create_client(supabase_url, supabase_key)
            self.table_name = "clothing_items"
            self.enabled = True

            logger.info(f"☁️  Supabase storage initialized (REST API)")

        except Exception as e:
            logger.error(f"❌ Failed to initialize Supabase: {e}")
            self.enabled = False

    def save_item(self, item_data: dict) -> bool:
        """
        Save a clothing item to Supabase.

        Args:
            item_data: Dict with item fields

        Returns:
            True if successful
        """
        if not self.enabled:
            return False

        try:
            # Insert or update (upsert)
            response = self.client.table(self.table_name).upsert(item_data).execute()

            logger.info(f"💾 Saved item to Supabase: {item_data.get('id')}")
            return True

        except Exception as e:
            logger.error(f"❌ Supabase save error: {e}")
            return False

    def get_user_items(self, user_id: str) -> list:
        """
        Get all items for a user.

        Args:
            user_id: User identifier

        Returns:
            List of clothing items
        """
        if not self.enabled:
            return []

        try:
            response = self.client.table(self.table_name)\
                .select("*")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .execute()

            items = response.data if response.data else []
            logger.info(f"📦 Fetched {len(items)} items from Supabase for user {user_id}")
            return items

        except Exception as e:
            logger.error(f"❌ Supabase fetch error: {e}")
            return []

    # ==================== Bulk Processing Job Methods ====================

    def create_job(self, user_id: str, total_images: int) -> dict:
        """
        Create a new bulk processing job.

        Args:
            user_id: User identifier
            total_images: Total number of images to process

        Returns:
            Job data with job_id
        """
        if not self.enabled:
            return {}

        try:
            job_data = {
                'user_id': user_id,
                'status': 'pending',
                'total_images': total_images,
                'processed_images': 0,
                'failed_images': 0
            }

            response = self.client.table('processing_jobs').insert(job_data).execute()
            job = response.data[0] if response.data else {}

            logger.info(f"📋 Created job {job.get('id')} for {total_images} images")
            return job

        except Exception as e:
            logger.error(f"❌ Failed to create job: {e}")
            return {}

    def add_images_to_job(self, job_id: str, user_id: str, image_urls: list) -> bool:
        """
        Add images to a processing job.

        Args:
            job_id: Job identifier
            user_id: User identifier
            image_urls: List of Tigris image URLs

        Returns:
            True if successful
        """
        if not self.enabled:
            return False

        try:
            job_images = [
                {
                    'job_id': job_id,
                    'user_id': user_id,
                    'image_url': url,
                    'status': 'pending'
                }
                for url in image_urls
            ]

            response = self.client.table('job_images').insert(job_images).execute()

            logger.info(f"📸 Added {len(image_urls)} images to job {job_id}")
            return True

        except Exception as e:
            logger.error(f"❌ Failed to add images to job: {e}")
            return False

    def get_job_status(self, job_id: str) -> dict:
        """
        Get the status of a processing job.

        Args:
            job_id: Job identifier

        Returns:
            Job data with status
        """
        if not self.enabled:
            return {}

        try:
            response = self.client.table('processing_jobs')\
                .select("*")\
                .eq("id", job_id)\
                .execute()

            job = response.data[0] if response.data else {}
            return job

        except Exception as e:
            logger.error(f"❌ Failed to get job status: {e}")
            return {}

    def get_pending_job_images(self, job_id: str, limit: int = 10) -> list:
        """
        Get pending images from a job for processing.

        Args:
            job_id: Job identifier
            limit: Maximum number of images to fetch

        Returns:
            List of pending job images
        """
        if not self.enabled:
            return []

        try:
            response = self.client.table('job_images')\
                .select("*")\
                .eq("job_id", job_id)\
                .eq("status", "pending")\
                .limit(limit)\
                .execute()

            images = response.data if response.data else []
            return images

        except Exception as e:
            logger.error(f"❌ Failed to get pending images: {e}")
            return []

    def update_job_image_status(self, image_id: str, status: str, item_id: str = None, error_message: str = None) -> bool:
        """
        Update the status of a job image.

        Args:
            image_id: Job image identifier
            status: New status (processing, completed, failed)
            item_id: Optional clothing item ID if completed
            error_message: Optional error message if failed

        Returns:
            True if successful
        """
        if not self.enabled:
            return False

        try:
            update_data = {'status': status}

            if item_id:
                update_data['item_id'] = item_id
            if error_message:
                update_data['error_message'] = error_message
            if status == 'completed' or status == 'failed':
                import datetime
                update_data['processed_at'] = datetime.datetime.utcnow().isoformat()

            response = self.client.table('job_images')\
                .update(update_data)\
                .eq("id", image_id)\
                .execute()

            return True

        except Exception as e:
            logger.error(f"❌ Failed to update image status: {e}")
            return False

    def update_job_progress(self, job_id: str) -> bool:
        """
        Update job progress based on completed/failed images.

        Args:
            job_id: Job identifier

        Returns:
            True if successful
        """
        if not self.enabled:
            return False

        try:
            # Get counts
            completed_response = self.client.table('job_images')\
                .select("id", count='exact')\
                .eq("job_id", job_id)\
                .eq("status", "completed")\
                .execute()

            failed_response = self.client.table('job_images')\
                .select("id", count='exact')\
                .eq("job_id", job_id)\
                .eq("status", "failed")\
                .execute()

            processed_count = completed_response.count or 0
            failed_count = failed_response.count or 0

            # Get job total
            job = self.get_job_status(job_id)
            total = job.get('total_images', 0)

            # Determine job status
            if processed_count + failed_count >= total:
                job_status = 'completed'
                import datetime
                completed_at = datetime.datetime.utcnow().isoformat()
            else:
                job_status = 'processing'
                completed_at = None

            # Update job
            update_data = {
                'processed_images': processed_count,
                'failed_images': failed_count,
                'status': job_status
            }
            if completed_at:
                update_data['completed_at'] = completed_at

            self.client.table('processing_jobs')\
                .update(update_data)\
                .eq("id", job_id)\
                .execute()

            logger.info(f"📊 Job {job_id}: {processed_count}/{total} completed, {failed_count} failed")
            return True

        except Exception as e:
            logger.error(f"❌ Failed to update job progress: {e}")
            return False


# Global instance
supabase_service = SupabaseService()
