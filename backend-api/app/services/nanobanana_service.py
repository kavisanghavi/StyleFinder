"""
Nano Banana Service (Google Gemini)

This service handles virtual try-on image generation using Google's Gemini
image generation capabilities. It creates realistic visualizations of clothing
combinations and virtual try-ons.

Features:
- Virtual try-on generation
- Background removal from clothing images
- Outfit visualization
"""

import google.generativeai as genai
import base64
import logging
from typing import List, Optional
from io import BytesIO
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class NanoBananaService:
    """
    Service wrapper for Google Gemini (Nano Banana) image generation.

    This class provides virtual try-on and image manipulation capabilities
    using Google's Gemini multimodal AI.
    """

    def __init__(self):
        """Initialize the Gemini service with API configuration."""
        try:
            # Configure Gemini
            genai.configure(api_key=settings.GEMINI_API_KEY)

            # Initialize the model
            self.model = genai.GenerativeModel(settings.GEMINI_MODEL)

            logger.info(f"🍌 Nano Banana service initialized with model: {settings.GEMINI_MODEL}")
            self.enabled = True

        except Exception as e:
            logger.warning(f"⚠️  Failed to initialize Nano Banana: {e}")
            self.enabled = False

    @trace(name="nanobanana_virtual_tryon")
    async def generate_tryon(
        self,
        user_image: str,  # base64
        clothing_items: List[str],  # list of base64 images
        style_guidance: Optional[str] = None
    ) -> bytes:
        """
        Generate a virtual try-on image.

        This method creates a realistic visualization of the user wearing
        the specified clothing items.

        Args:
            user_image: Base64-encoded user photo
            clothing_items: List of base64-encoded clothing images
            style_guidance: Optional style guidance for the generation

        Returns:
            Generated image as bytes (PNG format)

        Raises:
            Exception: If service is not available or generation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"🎨 Generating virtual try-on with {len(clothing_items)} items...")

        try:
            # Decode base64 images
            user_img_data = base64.b64decode(user_image)
            clothing_imgs = [base64.b64decode(item) for item in clothing_items]

            # Build the prompt
            base_prompt = """Create a photorealistic image showing this person wearing the specified clothing items.

Requirements:
- Maintain the person's facial features, skin tone, and body proportions exactly
- Ensure clothing fits naturally with realistic draping and folds
- Match lighting conditions between the person and clothes
- Keep realistic shadows and highlights
- Make sure the outfit looks professionally styled
- Preserve the background or use a neutral background"""

            if style_guidance:
                base_prompt += f"\n\nStyle guidance: {style_guidance}"

            # Prepare content for Gemini
            content_parts = [base_prompt]

            # Add user image
            content_parts.append({
                "mime_type": "image/jpeg",
                "data": user_img_data
            })

            # Add clothing images
            for i, img_data in enumerate(clothing_imgs):
                content_parts.append({
                    "mime_type": "image/jpeg",
                    "data": img_data
                })

            # Generate the image
            logger.debug("Calling Gemini API for virtual try-on...")
            response = self.model.generate_content(content_parts)

            # Extract image from response
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        image_data = part.inline_data.data
                        logger.info(f"✅ Generated try-on image ({len(image_data)} bytes)")
                        return image_data

            # If no image was found in response
            raise Exception("No image generated in response")

        except Exception as e:
            logger.error(f"❌ Nano Banana virtual try-on error: {e}")
            raise

    @trace(name="nanobanana_remove_background")
    async def remove_background(
        self,
        image_base64: str,
        subject_description: str = "clothing item"
    ) -> bytes:
        """
        Remove background from a clothing image.

        This isolates the clothing item on a transparent or white background,
        making it easier to use in virtual try-ons.

        Args:
            image_base64: Base64-encoded image
            subject_description: Description of what to keep (default: "clothing item")

        Returns:
            Image with removed background as bytes

        Raises:
            Exception: If service is not available or operation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"✂️  Removing background from {subject_description}...")

        try:
            # Decode image
            img_data = base64.b64decode(image_base64)

            # Build prompt
            prompt = f"""Remove the background from this image, keeping only the {subject_description}.

Requirements:
- Keep the {subject_description} perfectly intact
- Remove all background elements
- Use a transparent background (or white if transparency not possible)
- Maintain all details and colors of the {subject_description}
- Ensure clean edges without artifacts
- Preserve the original quality and resolution"""

            # Generate
            response = self.model.generate_content([
                prompt,
                {"mime_type": "image/jpeg", "data": img_data}
            ])

            # Extract result
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        result_data = part.inline_data.data
                        logger.info(f"✅ Background removed ({len(result_data)} bytes)")
                        return result_data

            raise Exception("No image generated in response")

        except Exception as e:
            logger.error(f"❌ Background removal error: {e}")
            raise

    @trace(name="nanobanana_outfit_visualization")
    async def visualize_outfit_combination(
        self,
        clothing_items: List[str],  # base64 images
        layout: str = "flat-lay"
    ) -> bytes:
        """
        Create a visualization of clothing items arranged together.

        This is useful for showing how items look together without a model.

        Args:
            clothing_items: List of base64-encoded clothing images
            layout: Layout style ("flat-lay", "hanger", "folded")

        Returns:
            Visualization image as bytes

        Raises:
            Exception: If service is not available or generation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"📸 Creating outfit visualization ({layout}) with {len(clothing_items)} items...")

        try:
            # Decode images
            clothing_imgs = [base64.b64decode(item) for item in clothing_items]

            # Build prompt based on layout
            layout_prompts = {
                "flat-lay": "Arrange these clothing items in a beautiful flat-lay style on a clean white surface, as if photographed from above. Make it look like a professional fashion photography flat-lay.",
                "hanger": "Show these clothing items hanging together on hangers, as they would appear in a closet. Use a clean, minimal background.",
                "folded": "Show these clothing items neatly folded and stacked, as they would appear in a drawer or on a shelf. Use warm, natural lighting."
            }

            prompt = layout_prompts.get(layout, layout_prompts["flat-lay"])
            prompt += "\n\nMake the image high-quality, well-lit, and aesthetically pleasing."

            # Prepare content
            content_parts = [prompt]
            for img_data in clothing_imgs:
                content_parts.append({
                    "mime_type": "image/jpeg",
                    "data": img_data
                })

            # Generate
            response = self.model.generate_content(content_parts)

            # Extract result
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        result_data = part.inline_data.data
                        logger.info(f"✅ Outfit visualization created ({len(result_data)} bytes)")
                        return result_data

            raise Exception("No image generated in response")

        except Exception as e:
            logger.error(f"❌ Outfit visualization error: {e}")
            raise

    @trace(name="nanobanana_style_image")
    async def generate_style_inspiration(
        self,
        style_description: str,
        reference_images: Optional[List[str]] = None
    ) -> bytes:
        """
        Generate style inspiration images based on description.

        Args:
            style_description: Text description of desired style
            reference_images: Optional reference images (base64)

        Returns:
            Generated inspiration image as bytes

        Raises:
            Exception: If service is not available or generation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"✨ Generating style inspiration: {style_description[:50]}...")

        try:
            prompt = f"""Create a fashion inspiration image that captures this style:

{style_description}

Make it look like a professional fashion photography shot, well-styled and aesthetically pleasing."""

            content_parts = [prompt]

            # Add reference images if provided
            if reference_images:
                for ref_img in reference_images:
                    img_data = base64.b64decode(ref_img)
                    content_parts.append({
                        "mime_type": "image/jpeg",
                        "data": img_data
                    })

            # Generate
            response = self.model.generate_content(content_parts)

            # Extract result
            if response.candidates and response.candidates[0].content.parts:
                for part in response.candidates[0].content.parts:
                    if hasattr(part, 'inline_data') and part.inline_data:
                        result_data = part.inline_data.data
                        logger.info(f"✅ Style inspiration created ({len(result_data)} bytes)")
                        return result_data

            raise Exception("No image generated in response")

        except Exception as e:
            logger.error(f"❌ Style inspiration generation error: {e}")
            raise


# Global instance
nanobanana_service = NanoBananaService()
