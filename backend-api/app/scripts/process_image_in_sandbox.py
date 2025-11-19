#!/usr/bin/env python3
"""
Standalone Image Processing Script for Daytona Sandbox
=======================================================

This script runs INSIDE a Daytona sandbox to process clothing images.
It handles:
1. Image orientation correction
2. Background removal with Gemini
3. Upload to Tigris storage
4. AI analysis with Claude
5. Returns structured JSON results

Usage:
    python process_image_in_sandbox.py <image_base64> <config_json>

Environment Variables Required:
    - ANTHROPIC_API_KEY
    - GOOGLE_API_KEY
    - TIGRIS_ENDPOINT
    - TIGRIS_ACCESS_KEY
    - TIGRIS_SECRET_KEY
    - TIGRIS_BUCKET_NAME
"""

import sys
import json
import base64
import io
import logging
import time
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

# Third-party imports
try:
    from PIL import Image, ImageOps
    import boto3
    from botocore.exceptions import ClientError
    import anthropic
    import google.generativeai as genai
except ImportError as e:
    print(json.dumps({"error": f"Missing dependency: {e}"}))
    sys.exit(1)

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


class ImageProcessingError(Exception):
    """Custom exception for image processing errors."""
    pass


class ImageProcessor:
    """Handles all image processing operations in the sandbox."""

    def __init__(self, config: Dict[str, Any]):
        """Initialize with configuration."""
        self.config = config
        self.user_id = config.get('user_id')
        self.remove_background = config.get('remove_background', True)

        # Initialize API clients
        self._init_claude()
        self._init_gemini()
        self._init_tigris()

    def _init_claude(self):
        """Initialize Claude client."""
        api_key = self.config.get('anthropic_api_key')
        if not api_key:
            raise ValueError("ANTHROPIC_API_KEY is required")

        self.claude_client = anthropic.Anthropic(api_key=api_key)
        self.claude_model = "claude-sonnet-4-20250514"
        logger.info("✅ Claude client initialized")

    def _init_gemini(self):
        """Initialize Gemini client."""
        api_key = self.config.get('google_api_key')
        if not api_key:
            raise ValueError("GOOGLE_API_KEY is required")

        genai.configure(api_key=api_key)
        self.gemini_client = genai.GenerativeModel('gemini-2.0-flash-exp')
        logger.info("✅ Gemini client initialized")

    def _init_tigris(self):
        """Initialize Tigris S3 client."""
        try:
            self.s3_client = boto3.client(
                's3',
                endpoint_url=self.config.get('tigris_endpoint'),
                aws_access_key_id=self.config.get('tigris_access_key'),
                aws_secret_access_key=self.config.get('tigris_secret_key'),
                region_name=self.config.get('tigris_region', 'auto')
            )
            self.bucket = self.config.get('tigris_bucket_name')

            # Verify bucket exists
            self.s3_client.head_bucket(Bucket=self.bucket)
            logger.info(f"✅ Tigris client initialized (bucket: {self.bucket})")
        except Exception as e:
            logger.warning(f"⚠️  Tigris not available: {e}")
            self.s3_client = None

    def correct_orientation(self, image_bytes: bytes) -> bytes:
        """
        Correct image orientation using EXIF data and ensure portrait mode.

        Args:
            image_bytes: Raw image bytes

        Returns:
            Corrected image bytes
        """
        logger.info("🔄 Correcting image orientation...")

        try:
            image = Image.open(io.BytesIO(image_bytes))
            original_size = image.size

            # Apply EXIF orientation correction
            corrected_image = ImageOps.exif_transpose(image)

            # Ensure portrait orientation
            if corrected_image.width > corrected_image.height:
                corrected_image = corrected_image.rotate(90, expand=True)
                logger.info(f"🔄 Rotated to portrait: {original_size} → {corrected_image.size}")
            else:
                logger.info(f"✅ Already portrait: {corrected_image.size}")

            # Save corrected image
            output = io.BytesIO()
            image_format = corrected_image.format or 'JPEG'
            corrected_image.save(output, format=image_format, quality=95)

            return output.getvalue()

        except Exception as e:
            logger.warning(f"⚠️  Orientation correction failed: {e}")
            return image_bytes

    def upload_to_tigris(
        self,
        image_bytes: bytes,
        filename: str,
        content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """
        Upload image to Tigris storage.

        Args:
            image_bytes: Image data
            filename: Destination filename
            content_type: MIME type

        Returns:
            Presigned URL or None if upload fails
        """
        if not self.s3_client:
            logger.warning("⚠️  Tigris not available, skipping upload")
            return None

        logger.info(f"☁️  Uploading to Tigris: {filename}")

        try:
            # Generate S3 key
            if self.user_id:
                key = f"images/{self.user_id}/{filename}"
            else:
                timestamp = datetime.utcnow().strftime("%Y%m%d-%H%M%S")
                key = f"images/shared/{timestamp}-{filename}"

            # Upload to Tigris
            self.s3_client.put_object(
                Bucket=self.bucket,
                Key=key,
                Body=image_bytes,
                ContentType=content_type,
                Metadata={'upload-time': datetime.utcnow().isoformat()}
            )

            # Generate presigned URL (7 days)
            url = self.s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': self.bucket, 'Key': key},
                ExpiresIn=604800  # 7 days
            )

            logger.info(f"✅ Uploaded ({len(image_bytes)} bytes)")
            return url

        except ClientError as e:
            logger.error(f"❌ Tigris upload failed: {e}")
            return None

    def remove_background(self, image_bytes: bytes) -> Optional[bytes]:
        """
        Remove background using Gemini image generation.

        Args:
            image_bytes: Original image bytes

        Returns:
            Extracted image bytes or None if failed
        """
        logger.info("✂️  Removing background with Gemini...")

        try:
            # Convert to PIL Image
            image = Image.open(io.BytesIO(image_bytes))

            # Build prompt for background removal
            prompt = """Extract and isolate ONLY the clothing item from this image.

⚠️ ABSOLUTE CRITICAL REQUIREMENT #1 - VERTICAL ORIENTATION:
You MUST make the clothing item PERFECTLY VERTICAL and UPRIGHT. This is NON-NEGOTIABLE.
- Imagine drawing a vertical line from top to bottom of the image
- The clothing's center line (from collar to hem) MUST align with this vertical line
- The collar/neckline MUST be at the TOP (12 o'clock position)
- The bottom hem MUST be at the BOTTOM (6 o'clock position)
- The shoulders MUST be horizontal (parallel to the top edge of the image)
- If the photo was taken at ANY angle, rotate the clothing to be PERFECTLY UPRIGHT

BACKGROUND:
- Use ONLY pure white background (#FFFFFF) or transparent
- DO NOT add frames, borders, shadows, or decorative elements

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

            # Generate with Gemini
            response = self.gemini_client.generate_content([prompt, image])

            # Extract generated image
            for part in response.parts:
                if part.inline_data is not None:
                    image_data = part.inline_data.data

                    # Convert to PNG
                    try:
                        pil_image = Image.open(io.BytesIO(image_data))
                        output_buffer = io.BytesIO()
                        pil_image.save(output_buffer, format='PNG')
                        result_data = output_buffer.getvalue()
                    except:
                        result_data = image_data

                    logger.info(f"✅ Background removed ({len(result_data)} bytes)")
                    return result_data

            raise ImageProcessingError("No image generated in Gemini response")

        except Exception as e:
            logger.error(f"❌ Background removal failed: {e}")
            return None

    def analyze_with_claude(
        self,
        image_base64: str,
        content_type: str = "image/jpeg"
    ) -> Dict[str, Any]:
        """
        Analyze clothing item using Claude Vision.

        Args:
            image_base64: Base64-encoded image
            content_type: MIME type

        Returns:
            Analysis results dictionary
        """
        logger.info("🔍 Analyzing with Claude Vision...")

        analysis_prompt = """Analyze this image and identify ALL clothing items visible.

IMPORTANT: If multiple items are visible, return an array with each item separately!

Your JSON response must have this exact structure:

If ONE item:
{
    "items": [
        {
            "type": "shirt/pants/dress/jacket/shoes/accessory/etc",
            "color": "primary color name",
            "pattern": "solid/striped/floral/checkered/polka-dot/geometric/etc",
            "style": "casual/formal/athletic/business-casual/elegant/bohemian/etc",
            "season": ["spring", "summer", "fall", "winter"],
            "pairs_well_with": ["list of clothing types that would match well"],
            "confidence": 0.95,
            "material": "cotton/polyester/silk/denim/leather/etc (if visible)",
            "occasion": ["work", "casual", "formal", "party", "sports", "etc"],
            "care_instructions": "general care recommendations"
        }
    ]
}

If MULTIPLE items (e.g., red shirt + green shirt):
{
    "items": [
        {
            "type": "shirt",
            "color": "red",
            "pattern": "solid",
            ...
        },
        {
            "type": "shirt",
            "color": "green",
            "pattern": "solid",
            ...
        }
    ]
}"""

        try:
            # Call Claude API
            message = self.claude_client.messages.create(
                model=self.claude_model,
                max_tokens=1500,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": content_type,
                                    "data": image_base64,
                                },
                            },
                            {
                                "type": "text",
                                "text": analysis_prompt
                            }
                        ],
                    }
                ],
            )

            # Parse JSON response
            response_text = message.content[0].text
            analysis = json.loads(response_text)

            if 'items' in analysis and analysis['items']:
                items = analysis['items']
                logger.info(f"✅ Analyzed {len(items)} item(s)")

                # Return first item with all_items attached
                result = items[0].copy()
                result['all_items'] = items
                result['item_count'] = len(items)
                return result
            else:
                raise ImageProcessingError("No items found in Claude response")

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse Claude response: {e}")
            raise ImageProcessingError(f"Invalid JSON from Claude: {e}")
        except Exception as e:
            logger.error(f"❌ Claude analysis failed: {e}")
            raise ImageProcessingError(f"Claude analysis error: {e}")

    def process(self, image_base64: str, filename: str = "image.jpg") -> Dict[str, Any]:
        """
        Run complete image processing pipeline.

        Args:
            image_base64: Base64-encoded input image
            filename: Original filename

        Returns:
            Complete processing results
        """
        start_time = time.time()
        results = {
            'success': False,
            'processing_time_seconds': 0,
            'original_image_url': None,
            'extracted_image_url': None,
            'background_was_removed': False,
            'analysis': None,
            'errors': []
        }

        try:
            # Decode input image
            image_bytes = base64.b64decode(image_base64)
            logger.info(f"📥 Processing image: {filename} ({len(image_bytes)} bytes)")

            # Step 1: Correct orientation
            corrected_bytes = self.correct_orientation(image_bytes)

            # Step 2: Upload original to Tigris
            timestamp = int(time.time())
            original_filename = f"original-{timestamp}-{filename}"
            original_url = self.upload_to_tigris(
                corrected_bytes,
                original_filename,
                "image/jpeg"
            )
            results['original_image_url'] = original_url

            # Step 3: Remove background (if enabled)
            extracted_bytes = None
            analysis_bytes = corrected_bytes

            if self.remove_background:
                extracted_bytes = self.remove_background(corrected_bytes)

                if extracted_bytes:
                    results['background_was_removed'] = True

                    # Ensure portrait orientation for extracted image
                    try:
                        extracted_img = Image.open(io.BytesIO(extracted_bytes))
                        if extracted_img.width > extracted_img.height:
                            logger.info(f"🔄 Rotating extracted image to portrait")
                            extracted_img = extracted_img.rotate(90, expand=True)
                            output = io.BytesIO()
                            extracted_img.save(output, format='PNG', quality=95)
                            extracted_bytes = output.getvalue()
                    except Exception as e:
                        logger.warning(f"⚠️  Could not rotate extracted image: {e}")

                    # Step 4: Upload extracted to Tigris
                    extracted_filename = f"extracted-{timestamp}-{Path(filename).stem}.png"
                    extracted_url = self.upload_to_tigris(
                        extracted_bytes,
                        extracted_filename,
                        "image/png"
                    )
                    results['extracted_image_url'] = extracted_url

                    # Use extracted image for analysis
                    analysis_bytes = extracted_bytes

            # Step 5: Analyze with Claude
            analysis_base64 = base64.b64encode(analysis_bytes).decode('utf-8')
            content_type = "image/png" if extracted_bytes else "image/jpeg"

            analysis = self.analyze_with_claude(analysis_base64, content_type)
            results['analysis'] = analysis

            # Success!
            results['success'] = True
            results['processing_time_seconds'] = round(time.time() - start_time, 2)

            logger.info(f"✅ Processing complete in {results['processing_time_seconds']}s")

        except Exception as e:
            error_msg = f"Processing failed: {str(e)}"
            logger.error(f"❌ {error_msg}")
            results['errors'].append(error_msg)
            results['processing_time_seconds'] = round(time.time() - start_time, 2)

        return results


def main():
    """Main entry point for sandbox execution."""

    if len(sys.argv) < 3:
        print(json.dumps({
            "error": "Usage: python process_image_in_sandbox.py <image_base64> <config_json>"
        }))
        sys.exit(1)

    try:
        # Parse arguments
        image_base64 = sys.argv[1]
        config_json = sys.argv[2]
        config = json.loads(config_json)

        # Initialize processor
        processor = ImageProcessor(config)

        # Process image
        filename = config.get('filename', 'image.jpg')
        results = processor.process(image_base64, filename)

        # Output results as JSON
        print(json.dumps(results, indent=2))

        # Exit with appropriate code
        sys.exit(0 if results['success'] else 1)

    except Exception as e:
        error_output = {
            "error": str(e),
            "success": False
        }
        print(json.dumps(error_output))
        sys.exit(1)


if __name__ == "__main__":
    main()
