"""
Rembg Background Removal Service

Uses the rembg Python package for fast, local, and FREE background removal.
This is ideal for phone photos of clothes - works offline and costs nothing!
"""

import logging
import io
from typing import Optional
from PIL import Image
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class RembgService:
    """
    Service for removing backgrounds using the rembg package.

    Uses U²-Net pre-trained model for high-quality background removal.
    Perfect for clothing photos from phones.
    """

    def __init__(self):
        """Initialize rembg service."""
        self.enabled = False
        try:
            from rembg import remove
            self.remove = remove
            self.enabled = True
            logger.info("✨ Rembg initialized - LOCAL background removal ready (FREE!)")
        except ImportError:
            logger.warning("⚠️  rembg not installed - run: pip install rembg")
        except Exception as e:
            logger.error(f"❌ Rembg initialization error: {e}")

    @trace(name="rembg_remove_background")
    async def remove_background(
        self,
        image_data: bytes,
        format: str = "png",
        alpha_matting: bool = False,
        alpha_matting_foreground_threshold: int = 240,
        alpha_matting_background_threshold: int = 10,
    ) -> bytes:
        """
        Remove background from clothing image using rembg.

        Args:
            image_data: Original image bytes
            format: Output format ('png' recommended for transparency)
            alpha_matting: Enable better edge detection (slower but higher quality)
            alpha_matting_foreground_threshold: Foreground detection threshold (0-255)
            alpha_matting_background_threshold: Background detection threshold (0-255)

        Returns:
            Image bytes with background removed (transparent PNG)

        Raises:
            Exception: If removal fails
        """
        if not self.enabled:
            logger.warning("⚠️  Rembg not available - returning original image")
            return image_data

        try:
            logger.info(f"🎨 Removing background with rembg ({len(image_data)} bytes)...")

            # Remove background using rembg
            # This uses the U²-Net model which is excellent for clothing
            output_data = self.remove(
                image_data,
                alpha_matting=alpha_matting,
                alpha_matting_foreground_threshold=alpha_matting_foreground_threshold,
                alpha_matting_background_threshold=alpha_matting_background_threshold,
            )

            # Convert to requested format if needed
            if format.lower() != 'png':
                # Convert to PIL Image for format conversion
                output_image = Image.open(io.BytesIO(output_data))

                # If converting to non-transparent format, add white background
                if format.lower() in ['jpg', 'jpeg']:
                    # Create white background
                    background = Image.new('RGB', output_image.size, (255, 255, 255))
                    # Paste the image with transparency onto white background
                    if output_image.mode == 'RGBA':
                        background.paste(output_image, mask=output_image.split()[3])
                    else:
                        background.paste(output_image)
                    output_image = background

                # Save to bytes
                output_buffer = io.BytesIO()
                output_image.save(output_buffer, format=format.upper())
                output_data = output_buffer.getvalue()

            logger.info(f"✅ Background removed! Output size: {len(output_data)} bytes")
            return output_data

        except Exception as e:
            logger.error(f"❌ Rembg background removal error: {e}")
            # Return original on error
            return image_data

    @trace(name="rembg_batch_removal")
    async def remove_backgrounds_batch(
        self,
        images: list[bytes],
        **kwargs
    ) -> list[bytes]:
        """
        Remove backgrounds from multiple images.

        Args:
            images: List of image bytes
            **kwargs: Additional arguments passed to remove_background()

        Returns:
            List of processed image bytes
        """
        logger.info(f"🎨 Processing {len(images)} images in batch with rembg...")

        results = []
        for i, image_data in enumerate(images):
            try:
                processed = await self.remove_background(image_data, **kwargs)
                results.append(processed)
                logger.info(f"  ✅ Image {i+1}/{len(images)} processed")
            except Exception as e:
                logger.error(f"  ❌ Image {i+1}/{len(images)} failed: {e}")
                # Use original on error
                results.append(image_data)

        logger.info(f"✅ Batch processing complete: {len(results)}/{len(images)} successful")
        return results

    async def remove_background_advanced(
        self,
        image_data: bytes,
        model_name: str = "u2net",
        post_process_mask: bool = False
    ) -> bytes:
        """
        Advanced background removal with model selection.

        Available models:
        - u2net: Default, best for general use (clothing, products)
        - u2netp: Faster, smaller model (less accurate)
        - u2net_human_seg: Optimized for people/fashion photography
        - u2net_cloth_seg: Optimized specifically for clothing segmentation

        Args:
            image_data: Original image bytes
            model_name: Model to use for segmentation
            post_process_mask: Apply morphological operations to clean mask

        Returns:
            Image bytes with background removed
        """
        if not self.enabled:
            logger.warning("⚠️  Rembg not available - returning original image")
            return image_data

        try:
            from rembg import remove, new_session

            logger.info(f"🎨 Removing background with model: {model_name}")

            # Create session with specific model
            session = new_session(model_name)

            # Remove background with custom session
            output_data = remove(
                image_data,
                session=session,
                post_process_mask=post_process_mask
            )

            logger.info(f"✅ Advanced removal complete ({model_name})")
            return output_data

        except Exception as e:
            logger.error(f"❌ Advanced removal error: {e}")
            # Fallback to basic removal
            return await self.remove_background(image_data)


# Global instance
rembg_service = RembgService()
