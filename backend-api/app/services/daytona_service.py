"""
Daytona Sandbox Service
=======================

Orchestrates image processing in isolated Daytona sandboxes for scalability.

This service:
1. Creates on-demand sandboxes with required dependencies
2. Uploads image processing script
3. Executes processing in isolated environment
4. Retrieves results and cleans up resources
5. Supports parallel processing of multiple images

Author: StyleFinder Team
"""

import json
import logging
import time
from typing import Dict, Any, Optional
from pathlib import Path

try:
    from daytona import Daytona, DaytonaConfig, Image, CreateSandboxFromImageParams
except ImportError:
    Daytona = None
    logging.warning("⚠️  Daytona SDK not installed. Install with: pip install daytona")

from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class DaytonaService:
    """Service for running image processing in Daytona sandboxes."""

    def __init__(self):
        """Initialize Daytona service with configuration."""
        if Daytona is None:
            logger.warning("⚠️  Daytona SDK not available - sandbox processing disabled")
            self.enabled = False
            return

        try:
            # Initialize Daytona client
            config = DaytonaConfig(
                api_key=settings.DAYTONA_API_KEY,
                api_url=settings.DAYTONA_API_URL,
                target=settings.DAYTONA_TARGET
            )
            self.client = Daytona(config)
            self.enabled = True

            # Load processing script
            script_path = Path(__file__).parent.parent / "scripts" / "process_image_in_sandbox.py"
            if script_path.exists():
                with open(script_path, 'r') as f:
                    self.processing_script = f.read()
                logger.info("✅ Daytona service initialized")
            else:
                logger.error(f"❌ Processing script not found: {script_path}")
                self.enabled = False

        except Exception as e:
            logger.warning(f"⚠️  Failed to initialize Daytona: {e}")
            logger.warning("Image processing will fall back to local execution")
            self.enabled = False

    def _create_sandbox(self) -> Any:
        """
        Create a new sandbox with Python and required dependencies.

        Returns:
            Sandbox instance
        """
        logger.info("🏗️  Creating Daytona sandbox...")

        try:
            # Define image with dependencies
            image = Image.debian_slim("3.12").pip_install([
                "Pillow==10.4.0",
                "boto3==1.29.7",
                "anthropic==0.39.0",
                "google-generativeai==0.8.3"
            ])

            # Create sandbox from image
            sandbox = self.client.create(
                CreateSandboxFromImageParams(image=image)
            )

            logger.info(f"✅ Sandbox created: {sandbox.id}")
            return sandbox

        except Exception as e:
            logger.error(f"❌ Failed to create sandbox: {e}")
            raise

    def _prepare_config(
        self,
        user_id: Optional[str] = None,
        remove_background: bool = True
    ) -> Dict[str, Any]:
        """
        Prepare configuration for sandbox execution.

        Args:
            user_id: User identifier for organizing uploads
            remove_background: Whether to remove background

        Returns:
            Configuration dictionary
        """
        return {
            'user_id': user_id,
            'remove_background': remove_background,
            'filename': 'image.jpg',
            # API keys
            'anthropic_api_key': settings.ANTHROPIC_API_KEY,
            'google_api_key': settings.GOOGLE_API_KEY,
            # Tigris configuration
            'tigris_endpoint': settings.TIGRIS_ENDPOINT,
            'tigris_access_key': settings.TIGRIS_ACCESS_KEY,
            'tigris_secret_key': settings.TIGRIS_SECRET_KEY,
            'tigris_bucket_name': settings.TIGRIS_BUCKET_NAME,
            'tigris_region': settings.TIGRIS_REGION
        }

    @trace(name="daytona_process_image")
    async def process_image(
        self,
        image_base64: str,
        filename: str = "image.jpg",
        user_id: Optional[str] = None,
        remove_background: bool = True
    ) -> Dict[str, Any]:
        """
        Process image in a Daytona sandbox.

        Args:
            image_base64: Base64-encoded image data
            filename: Original filename
            user_id: User identifier
            remove_background: Whether to remove background

        Returns:
            Processing results dictionary

        Raises:
            Exception: If processing fails
        """
        if not self.enabled:
            raise Exception("Daytona service is not available")

        sandbox = None
        start_time = time.time()

        try:
            # Step 1: Create sandbox
            logger.info(f"🚀 Starting Daytona image processing for: {filename}")
            sandbox = self._create_sandbox()

            # Step 2: Upload processing script
            logger.info("📤 Uploading processing script...")
            sandbox.fs.upload_file(
                self.processing_script.encode('utf-8'),
                "process_image.py"
            )

            # Step 3: Prepare configuration
            config = self._prepare_config(user_id, remove_background)
            config['filename'] = filename
            config_json = json.dumps(config)

            # Step 4: Execute processing script
            logger.info("⚙️  Executing image processing in sandbox...")

            # Escape arguments for shell
            image_arg = image_base64.replace("'", "'\\''")
            config_arg = config_json.replace("'", "'\\''")

            command = f"python3 process_image.py '{image_arg}' '{config_arg}'"

            response = sandbox.process.code_run(command)

            # Step 5: Parse results
            if response.exit_code != 0:
                logger.error(f"❌ Processing failed with exit code {response.exit_code}")
                logger.error(f"Output: {response.result}")
                raise Exception(f"Sandbox processing failed: {response.result}")

            # Parse JSON output
            try:
                results = json.loads(response.result)
            except json.JSONDecodeError as e:
                logger.error(f"❌ Failed to parse results: {e}")
                logger.error(f"Raw output: {response.result}")
                raise Exception(f"Invalid JSON output from sandbox: {e}")

            # Add metadata
            total_time = time.time() - start_time
            results['total_time_seconds'] = round(total_time, 2)
            results['sandbox_id'] = sandbox.id

            logger.info(f"✅ Daytona processing complete in {total_time:.2f}s")

            return results

        except Exception as e:
            logger.error(f"❌ Daytona processing error: {e}")
            raise

        finally:
            # Step 6: Clean up sandbox
            if sandbox:
                try:
                    logger.info(f"🧹 Cleaning up sandbox: {sandbox.id}")
                    sandbox.delete()
                    logger.info("✅ Sandbox deleted")
                except Exception as e:
                    logger.warning(f"⚠️  Failed to delete sandbox: {e}")

    @trace(name="daytona_process_batch")
    async def process_batch(
        self,
        images: list[Dict[str, Any]],
        user_id: Optional[str] = None,
        remove_background: bool = True
    ) -> list[Dict[str, Any]]:
        """
        Process multiple images in parallel sandboxes.

        Args:
            images: List of image dictionaries with 'base64' and 'filename' keys
            user_id: User identifier
            remove_background: Whether to remove backgrounds

        Returns:
            List of processing results

        Note:
            This method processes images concurrently in separate sandboxes.
            Use with caution for large batches to avoid resource limits.
        """
        if not self.enabled:
            raise Exception("Daytona service is not available")

        logger.info(f"🚀 Starting batch processing of {len(images)} images")

        # For now, process sequentially
        # TODO: Implement true parallel processing with asyncio.gather()
        results = []

        for i, img_data in enumerate(images):
            try:
                logger.info(f"Processing image {i+1}/{len(images)}: {img_data.get('filename', 'unknown')}")

                result = await self.process_image(
                    image_base64=img_data['base64'],
                    filename=img_data.get('filename', f'image_{i}.jpg'),
                    user_id=user_id,
                    remove_background=remove_background
                )

                results.append(result)

            except Exception as e:
                logger.error(f"❌ Failed to process image {i+1}: {e}")
                results.append({
                    'success': False,
                    'error': str(e),
                    'filename': img_data.get('filename', f'image_{i}.jpg')
                })

        logger.info(f"✅ Batch processing complete: {len(results)} results")
        return results

    def create_snapshot(self, snapshot_name: str = "image-processor") -> str:
        """
        Create a reusable snapshot with pre-installed dependencies.

        This can significantly speed up sandbox creation by caching
        the Python environment with all dependencies.

        Args:
            snapshot_name: Name for the snapshot

        Returns:
            Snapshot ID

        Note:
            Snapshots are cached for 24 hours by Daytona.
        """
        if not self.enabled:
            raise Exception("Daytona service is not available")

        logger.info(f"📸 Creating snapshot: {snapshot_name}")

        try:
            # Define image with all dependencies
            image = Image.debian_slim("3.12").pip_install([
                "Pillow==10.4.0",
                "boto3==1.29.7",
                "anthropic==0.39.0",
                "google-generativeai==0.8.3"
            ])

            # Create snapshot
            from daytona import CreateSnapshotParams
            snapshot = self.client.snapshot.create(
                CreateSnapshotParams(name=snapshot_name, image=image)
            )

            logger.info(f"✅ Snapshot created: {snapshot.id}")
            return snapshot.id

        except Exception as e:
            logger.error(f"❌ Failed to create snapshot: {e}")
            raise


# Singleton instance
daytona_service = DaytonaService()
