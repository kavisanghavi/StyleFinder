"""
Tigris Storage Service

This service handles all cloud storage operations using Tigris,
an S3-compatible object storage service.

Features:
- Encrypted wardrobe backups
- Audio file storage (voice recommendations)
- Image storage (clothing photos, try-ons)
- Automatic URL generation
"""

import boto3
from botocore.exceptions import ClientError
from datetime import datetime, timedelta
import logging
from typing import Optional
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class TigrisService:
    """
    Service wrapper for Tigris S3-compatible storage.

    This class handles all cloud storage operations including backups,
    audio files, and images.
    """

    def __init__(self):
        """Initialize the Tigris S3 client with credentials from settings."""
        try:
            self.s3_client = boto3.client(
                's3',
                endpoint_url=settings.TIGRIS_ENDPOINT,
                aws_access_key_id=settings.TIGRIS_ACCESS_KEY,
                aws_secret_access_key=settings.TIGRIS_SECRET_KEY,
                region_name=settings.TIGRIS_REGION
            )
            self.bucket = settings.TIGRIS_BUCKET_NAME

            # Verify connection by checking bucket exists
            try:
                self.s3_client.head_bucket(Bucket=self.bucket)
                logger.info(f"☁️  Tigris service initialized with bucket: {self.bucket}")
                self.enabled = True
            except ClientError:
                # Bucket doesn't exist, try to create it
                logger.info(f"Creating Tigris bucket: {self.bucket}")
                self.s3_client.create_bucket(Bucket=self.bucket)
                logger.info(f"✅ Created Tigris bucket: {self.bucket}")
                self.enabled = True

        except Exception as e:
            logger.warning(f"⚠️  Failed to initialize Tigris: {e}")
            logger.warning("Cloud storage features will be disabled")
            self.enabled = False

    @trace(name="tigris_upload_backup")
    async def upload_backup(
        self,
        user_id: str,
        data: bytes,
        metadata: Optional[dict] = None
    ) -> str:
        """
        Upload encrypted wardrobe backup to Tigris.

        The data should already be encrypted by the client before upload.
        This ensures end-to-end encryption and privacy.

        Args:
            user_id: Unique user identifier
            data: Encrypted backup data (bytes)
            metadata: Optional metadata dict

        Returns:
            Public URL or presigned URL to the backup

        Raises:
            Exception: If storage is not available or upload fails
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"📦 Uploading backup for user: {user_id}")

        try:
            # Generate unique key with timestamp
            timestamp = datetime.utcnow().isoformat()
            key = f"backups/{user_id}/wardrobe-{timestamp}.encrypted"

            # Prepare metadata
            upload_metadata = {
                'user-id': user_id,
                'upload-time': timestamp,
                'content-type': 'application/octet-stream'
            }
            if metadata:
                upload_metadata.update({f'custom-{k}': str(v) for k, v in metadata.items()})

            # Upload to Tigris
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=data,
                ContentType='application/octet-stream',
                Metadata=upload_metadata
            )

            # Generate URL
            url = f"{settings.TIGRIS_ENDPOINT}/{self.bucket}/{key}"

            logger.info(f"✅ Backup uploaded successfully ({len(data)} bytes)")
            logger.info(f"URL: {url}")

            return url

        except ClientError as e:
            logger.error(f"❌ Tigris upload error: {e}")
            raise Exception(f"Failed to upload backup: {e}")

    @trace(name="tigris_upload_audio")
    async def upload_audio(
        self,
        audio_bytes: bytes,
        filename: str,
        user_id: Optional[str] = None
    ) -> str:
        """
        Upload audio file (voice recommendation) to Tigris.

        Args:
            audio_bytes: Audio data in bytes
            filename: Desired filename
            user_id: Optional user ID for organization

        Returns:
            Public URL to the audio file

        Raises:
            Exception: If storage is not available or upload fails
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"🎵 Uploading audio: {filename}")

        try:
            # Generate key
            if user_id:
                key = f"audio/{user_id}/{filename}"
            else:
                timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
                key = f"audio/shared/{timestamp}-{filename}"

            # Upload
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=audio_bytes,
                ContentType='audio/mpeg',
                Metadata={
                    'upload-time': datetime.utcnow().isoformat()
                }
            )

            # Generate URL
            url = f"{settings.TIGRIS_ENDPOINT}/{self.bucket}/{key}"

            logger.info(f"✅ Audio uploaded successfully ({len(audio_bytes)} bytes)")

            return url

        except ClientError as e:
            logger.error(f"❌ Tigris audio upload error: {e}")
            raise Exception(f"Failed to upload audio: {e}")

    @trace(name="tigris_upload_image")
    async def upload_image(
        self,
        image_bytes: bytes,
        filename: str,
        content_type: str = "image/jpeg",
        user_id: Optional[str] = None
    ) -> str:
        """
        Upload image file to Tigris.

        Args:
            image_bytes: Image data in bytes
            filename: Desired filename
            content_type: MIME type (image/jpeg, image/png, etc.)
            user_id: Optional user ID for organization

        Returns:
            Public URL to the image

        Raises:
            Exception: If storage is not available or upload fails
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"🖼️  Uploading image: {filename}")

        try:
            # Generate key
            if user_id:
                key = f"images/{user_id}/{filename}"
            else:
                timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
                key = f"images/shared/{timestamp}-{filename}"

            # Upload (no ACL needed with presigned URLs)
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=image_bytes,
                ContentType=content_type,
                Metadata={
                    'upload-time': datetime.utcnow().isoformat()
                }
            )

            # Generate presigned URL (valid for 7 days)
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket,
                    'Key': key
                },
                ExpiresIn=604800  # 7 days in seconds
            )

            logger.info(f"✅ Image uploaded successfully ({len(image_bytes)} bytes)")

            return url

        except ClientError as e:
            logger.error(f"❌ Tigris image upload error: {e}")
            raise Exception(f"Failed to upload image: {e}")

    @trace(name="tigris_download_backup")
    async def download_backup(
        self,
        user_id: str,
        backup_key: Optional[str] = None
    ) -> bytes:
        """
        Download a wardrobe backup from Tigris.

        Args:
            user_id: User identifier
            backup_key: Specific backup key, or None for latest

        Returns:
            Encrypted backup data as bytes

        Raises:
            Exception: If storage is not available or download fails
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"📥 Downloading backup for user: {user_id}")

        try:
            if backup_key:
                key = backup_key
            else:
                # Get latest backup
                prefix = f"backups/{user_id}/"
                response = self.s3_client.list_objects_v2(
                    Bucket=self.bucket,
                    Prefix=prefix
                )

                if 'Contents' not in response or len(response['Contents']) == 0:
                    raise Exception("No backups found for this user")

                # Sort by last modified and get most recent
                objects = sorted(
                    response['Contents'],
                    key=lambda x: x['LastModified'],
                    reverse=True
                )
                key = objects[0]['Key']

            # Download
            response = self.s3_client.get_object(
                Bucket=self.bucket,
                Key=key
            )

            data = response['Body'].read()

            logger.info(f"✅ Downloaded backup ({len(data)} bytes)")

            return data

        except ClientError as e:
            logger.error(f"❌ Tigris download error: {e}")
            raise Exception(f"Failed to download backup: {e}")

    @trace(name="tigris_list_backups")
    async def list_backups(
        self,
        user_id: str
    ) -> list:
        """
        List all backups for a user.

        Args:
            user_id: User identifier

        Returns:
            List of backup metadata dicts

        Raises:
            Exception: If storage is not available
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"📋 Listing backups for user: {user_id}")

        try:
            prefix = f"backups/{user_id}/"
            response = self.s3_client.list_objects_v2(
                Bucket=self.bucket,
                Prefix=prefix
            )

            if 'Contents' not in response:
                return []

            backups = [
                {
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'].isoformat(),
                    'url': f"{settings.TIGRIS_ENDPOINT}/{self.bucket}/{obj['Key']}"
                }
                for obj in response['Contents']
            ]

            logger.info(f"✅ Found {len(backups)} backups")

            return backups

        except ClientError as e:
            logger.error(f"❌ Tigris list error: {e}")
            raise Exception(f"Failed to list backups: {e}")

    @trace(name="tigris_delete_backup")
    async def delete_backup(
        self,
        backup_key: str
    ) -> bool:
        """
        Delete a specific backup.

        Args:
            backup_key: Full key of the backup to delete

        Returns:
            True if successful

        Raises:
            Exception: If storage is not available or deletion fails
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        logger.info(f"🗑️  Deleting backup: {backup_key}")

        try:
            self.s3_client.delete_object(
                Bucket=self.bucket,
                Key=backup_key
            )

            logger.info("✅ Backup deleted successfully")

            return True

        except ClientError as e:
            logger.error(f"❌ Tigris delete error: {e}")
            raise Exception(f"Failed to delete backup: {e}")

    def get_timestamp(self) -> str:
        """
        Get current UTC timestamp in ISO format.

        Returns:
            ISO-formatted timestamp string
        """
        return datetime.utcnow().isoformat()

    def generate_presigned_url(
        self,
        key: str,
        expiration: int = 3600
    ) -> str:
        """
        Generate a presigned URL for temporary access to a file.

        Args:
            key: Object key
            expiration: URL expiration time in seconds (default: 1 hour)

        Returns:
            Presigned URL string

        Raises:
            Exception: If storage is not available
        """
        if not self.enabled:
            raise Exception("Tigris storage is not available")

        try:
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': self.bucket,
                    'Key': key
                },
                ExpiresIn=expiration
            )

            return url

        except ClientError as e:
            logger.error(f"❌ Failed to generate presigned URL: {e}")
            raise Exception(f"Failed to generate presigned URL: {e}")


# Global instance
tigris_service = TigrisService()
