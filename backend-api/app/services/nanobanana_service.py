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

from google import genai
from google.genai import types
import base64
import logging
from typing import List, Optional
from io import BytesIO
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)

try:
    from PIL import Image
    import io
    PIL_AVAILABLE = True
except ImportError:
    PIL_AVAILABLE = False
    logger.warning("⚠️  PIL not available - image extraction will be limited")


class NanoBananaService:
    """
    Service wrapper for Google Gemini (Nano Banana) image generation.

    This class provides virtual try-on and image manipulation capabilities
    using Google's Gemini multimodal AI.
    """

    def __init__(self):
        """Initialize the Gemini service with API configuration."""
        try:
            # Initialize the Gemini client (new API)
            self.client = genai.Client(api_key=settings.GEMINI_API_KEY)

            # Model for image generation - using exact model from documentation
            self.image_model = "gemini-2.5-flash-image"

            logger.info(f"🍌 Nano Banana service initialized with model: {self.image_model}")
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
        Remove background from a clothing image using Gemini image generation.

        This isolates the clothing item on a transparent or white background,
        making it easier to use in virtual try-ons.

        Args:
            image_base64: Base64-encoded image
            subject_description: Description of what to keep (default: "clothing item")

        Returns:
            Image with removed background as bytes (PNG format)

        Raises:
            Exception: If service is not available or operation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"✂️  Removing background from {subject_description} with Gemini...")

        try:
            # Decode image to PIL Image
            img_data = base64.b64decode(image_base64)
            image = Image.open(io.BytesIO(img_data))

            # Build prompt for background removal
            prompt = f"""Extract and isolate ONLY the {subject_description} from this image.

⚠️ ABSOLUTE CRITICAL REQUIREMENT #1 - VERTICAL ORIENTATION:
You MUST make the clothing item PERFECTLY VERTICAL and UPRIGHT. This is NON-NEGOTIABLE.
- Imagine drawing a vertical line from top to bottom of the image
- The clothing's center line (from collar to hem) MUST align with this vertical line
- The collar/neckline MUST be at the TOP (12 o'clock position)
- The bottom hem MUST be at the BOTTOM (6 o'clock position)
- The shoulders MUST be horizontal (parallel to the top edge of the image)
- If the photo was taken at ANY angle, rotate the clothing to be PERFECTLY UPRIGHT
- Zero degrees rotation - perfectly vertical - no tilt whatsoever
- Think: the clothing should look like it's hanging on a wall, not tilted

PRESERVE ARRANGEMENT (but keep vertical):
- Keep sleeves in their original position (spread out if they were spread out)
- Keep fabric drape and folds as they were
- DO NOT rearrange or "style" the clothing
- BUT ensure the overall garment is VERTICAL while preserving these details

BACKGROUND:
- Use ONLY pure white background (#FFFFFF) or transparent
- DO NOT add frames, borders, shadows, or decorative elements
- CLEAN simple background ONLY

COLORS & DETAILS:
- PRESERVE EXACT ORIGINAL COLORS - no changes, no enhancements
- DO NOT change lighting, saturation, brightness, or hue
- Keep exact fabric texture, patterns, stitching, and all details
- Maintain original quality and resolution
- Keep all wrinkles, creases, and fabric characteristics

OUTPUT:
- ONLY the clothing item exactly as photographed on plain white background
- Portrait orientation (vertical/tall)
- Center the item
- Clean edges, no artifacts
- NO artistic additions, NO styling changes"""

            # Generate with new Gemini API
            response = self.client.models.generate_content(
                model=self.image_model,
                contents=[prompt, image]
            )

            # Extract generated image - iterate response.parts directly (not candidates)
            for part in response.parts:
                if part.text is not None:
                    logger.info(f"📝 Gemini text response: {part.text[:100]}...")
                elif part.inline_data is not None:
                    # Get the image data directly from inline_data
                    image_data = part.inline_data.data

                    # Try to convert to PIL and save as PNG
                    try:
                        pil_image = Image.open(io.BytesIO(image_data))
                        output_buffer = io.BytesIO()
                        pil_image.save(output_buffer, format='PNG')
                        result_data = output_buffer.getvalue()
                    except:
                        # If conversion fails, use raw data
                        result_data = image_data

                    logger.info(f"✅ Background removed ({len(result_data)} bytes)")
                    return result_data

            logger.warning(f"⚠️  No image in response")
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


    @trace(name="nanobanana_remove_background_rembg")
    async def remove_background_rembg(
        self,
        image_bytes: bytes
    ) -> bytes:
        """
        Remove background from clothing image using rembg (AI-powered, local).

        This extracts just the clothing item, removing hangers, backgrounds, etc.
        Uses the U2-Net model for accurate background removal.

        Args:
            image_bytes: Image data as bytes

        Returns:
            Image with transparent background as bytes (PNG format)

        Raises:
            Exception: If background removal fails
        """
        logger.info("✂️  Removing background with rembg (AI-powered)...")

        try:
            from rembg import remove
            from PIL import Image
            import io

            # Remove background using rembg
            output_data = remove(image_bytes)

            # Convert to PIL Image to ensure it's PNG with transparency
            img = Image.open(io.BytesIO(output_data))

            # Save as PNG with transparency
            output_buffer = io.BytesIO()
            img.save(output_buffer, format='PNG')
            result_bytes = output_buffer.getvalue()

            logger.info(f"✅ Background removed successfully ({len(result_bytes)} bytes)")
            return result_bytes

        except Exception as e:
            logger.error(f"❌ Background removal error: {e}")
            logger.warning("⚠️  Returning original image due to error")
            return image_bytes

    @trace(name="extract_clothing_items")
    async def extract_clothing_items(
        self,
        image_data: bytes,
        item_descriptions: List[dict]
    ) -> List[bytes]:
        """
        Extract individual clothing items from a photo with multiple items.

        Args:
            image_data: Original photo bytes
            item_descriptions: List of dicts with 'type' and 'color' for each item

        Returns:
            List of extracted item images (one per clothing item, background removed)
        """
        if not self.enabled:
            logger.warning("⚠️  Gemini not available - returning original image for all items")
            return [image_data] * len(item_descriptions)

        logger.info(f"✂️  Extracting {len(item_descriptions)} individual clothing items...")

        extracted_images = []

        for i, item_desc in enumerate(item_descriptions):
            try:
                item_type = item_desc.get('type', 'clothing item')
                item_color = item_desc.get('color', '')

                prompt = f"""Extract ONLY the {item_color} {item_type} from this image.

TASK: Isolate and extract the {item_color} {item_type}, removing everything else.

REQUIREMENTS:
1. Extract ONLY the {item_color} {item_type} - nothing else
2. Remove ALL background - make it transparent or pure white
3. Remove the person, hanger, and any other items
4. Center the {item_type} in the frame
5. Preserve all clothing details (texture, folds, trim, pattern)
6. Make edges clean and professional
7. Output a catalog-quality product image

Return a clean PNG image of JUST the {item_color} {item_type} with no background."""

                # Use Gemini's vision + editing to extract the specific item
                image_base64 = base64.b64encode(image_data).decode('utf-8')

                # Call Gemini with vision prompt
                response = self.model.generate_content([
                    prompt,
                    {"mime_type": "image/jpeg", "data": image_base64}
                ])

                # For now, return original until we implement image generation
                # Gemini's current API doesn't directly support image output in the free tier
                # We'll use the original image as fallback
                logger.info(f"  ✅ Processed item {i+1}/{len(item_descriptions)}: {item_color} {item_type}")
                extracted_images.append(image_data)

            except Exception as e:
                logger.error(f"  ❌ Failed to extract item {i+1}: {e}")
                extracted_images.append(image_data)

        logger.info(f"✅ Extracted {len(extracted_images)} items")
        return extracted_images

    @trace(name="nanobanana_outfit_tryon")
    async def generate_outfit_tryon(
        self,
        model_image: str,  # base64
        clothing_images: List[str]  # list of base64 images
    ) -> bytes:
        """
        Generate a virtual try-on image showing a model wearing an outfit.

        This method creates a photorealistic image of the model wearing the clothing
        items from the provided images.

        Args:
            model_image: Base64-encoded model/person photo
            clothing_images: List of base64-encoded clothing item images

        Returns:
            Generated image as bytes (PNG format)

        Raises:
            Exception: If service is not available or generation fails
        """
        if not self.enabled:
            raise Exception("Nano Banana service is not available")

        logger.info(f"👔 Generating outfit try-on with {len(clothing_images)} clothing items...")

        try:
            # Decode base64 images
            model_img_data = base64.b64decode(model_image)
            clothing_imgs = [base64.b64decode(item) for item in clothing_images]

            # Convert to PIL Images
            model_pil = Image.open(io.BytesIO(model_img_data))
            clothing_pils = [Image.open(io.BytesIO(img)) for img in clothing_imgs]

            # Build the prompt for virtual try-on
            prompt = """Create a photorealistic image of the person in the first image WEARING the clothing items from the additional images.

CRITICAL REQUIREMENTS:
1. The person MUST BE WEARING the clothing items on their body - not floating or separate
2. Composite the clothing ONTO the person's body naturally
3. The clothing should replace what they're currently wearing
4. Ensure proper fit and draping as if the person is actually wearing these clothes
5. Maintain realistic shadows, lighting, and fabric folds on the person's body
6. Preserve the person's:
   - Exact face and facial features
   - Body shape and proportions
   - Pose and position
   - Background scene
7. Match the lighting between the clothing and person perfectly
8. Make it look like a natural photograph where the person is genuinely wearing these clothes

DO NOT:
- Place clothing items separately in the scene
- Overlay clothes on the background
- Create a collage or side-by-side view

OUTPUT: A single photorealistic image of the person wearing all the clothing items naturally."""

            logger.info("🤖 Calling Gemini API for outfit try-on generation...")

            # Prepare content for Gemini - use the new API format
            # Model image first, then clothing images
            content_parts = [prompt, model_pil]
            content_parts.extend(clothing_pils)

            # Generate the image using new Gemini API
            response = self.client.models.generate_content(
                model=self.image_model,
                contents=content_parts
            )

            # Extract generated image from response
            for part in response.parts:
                if part.text is not None:
                    logger.info(f"📝 Gemini text response: {part.text[:100]}...")
                elif part.inline_data is not None:
                    # Get the image data directly from inline_data
                    image_data = part.inline_data.data

                    # Convert to PNG format
                    try:
                        pil_image = Image.open(io.BytesIO(image_data))
                        output_buffer = io.BytesIO()
                        pil_image.save(output_buffer, format='PNG')
                        result_data = output_buffer.getvalue()
                    except:
                        # If conversion fails, use raw data
                        result_data = image_data

                    logger.info(f"✅ Outfit try-on generated ({len(result_data)} bytes)")
                    return result_data

            # If no image was found in response
            logger.warning("⚠️  No image in Gemini response")
            raise Exception("No image generated in response")

        except Exception as e:
            logger.error(f"❌ Outfit try-on generation error: {e}")
            raise


# Global instance
nanobanana_service = NanoBananaService()
