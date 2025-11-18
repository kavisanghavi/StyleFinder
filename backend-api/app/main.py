"""
AI Closet Scanner - Backend API

Main FastAPI application that orchestrates all AI services for wardrobe management.

This backend integrates:
- Claude (Anthropic): Clothing analysis and outfit generation
- ElevenLabs: Voice recommendations
- Nano Banana (Gemini): Virtual try-on
- Tigris: Cloud storage
- Galileo: LLM observability

Hosted on Daytona for cloud development and deployment.
"""

from fastapi import FastAPI, UploadFile, File, HTTPException, Form, Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
import base64
import io
import logging
from pathlib import Path
from PIL import Image, ExifTags, ImageOps

# Import services
from app.services.claude_service import claude_service
from app.services.elevenlabs_service import elevenlabs_service
from app.services.nanobanana_service import nanobanana_service
from app.services.tigris_service import tigris_service
from app.services.brex_service import brex_service
from app.services.weather_service import weather_service
from app.services.background_removal_service import background_removal_service
from app.monitoring.galileo_observer import galileo_observer
from app.config import settings

# Import database
from app.database import init_db, get_db
from app.models import ClothingItem as ClothingItemModel
from sqlalchemy.orm import Session
from fastapi import Depends
import uuid

# Import Supabase (REST API - more reliable)
from app.services.supabase_service import supabase_service

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# ==================== In-Memory Storage for Testing ====================
# Simple dictionary to store analyzed items per user
# Format: {user_id: [list of analyzed items]}
CLOSET_CACHE: Dict[str, List[Dict[str, Any]]] = {}

# ==================== Initialize FastAPI App ====================

app = FastAPI(
    title=settings.API_TITLE,
    description=settings.API_DESCRIPTION,
    version=settings.API_VERSION,
    docs_url="/docs",
    redoc_url="/redoc"
)

# ==================== CORS Middleware ====================

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== Pydantic Models ====================

class ClothingAnalysisResponse(BaseModel):
    """Response model for clothing analysis."""
    type: str = Field(..., description="Clothing type (shirt, pants, etc.)")
    color: str = Field(..., description="Primary color")
    pattern: str = Field(..., description="Pattern type")
    style: str = Field(..., description="Style category")
    season: List[str] = Field(..., description="Suitable seasons")
    pairs_well_with: List[str] = Field(..., description="Complementary items")
    confidence: float = Field(..., description="Analysis confidence (0-1)")
    material: Optional[str] = Field(None, description="Material type")
    occasion: Optional[List[str]] = Field(None, description="Suitable occasions")
    care_instructions: Optional[str] = Field(None, description="Care recommendations")
    original_image_url: Optional[str] = Field(None, description="Tigris URL for original uploaded image")
    extracted_image_url: Optional[str] = Field(None, description="Tigris URL for background-removed/extracted image")
    background_was_removed: Optional[bool] = Field(False, description="Whether background removal was applied")


class OutfitRequest(BaseModel):
    """Request model for outfit generation."""
    wardrobe_items: List[Dict[str, Any]] = Field(..., description="List of wardrobe items")
    occasion: str = Field(..., description="Occasion or event")
    weather: Optional[Dict[str, Any]] = Field(None, description="Weather conditions")
    preferences: Optional[Dict[str, Any]] = Field(None, description="User preferences")
    color_preference: Optional[str] = Field(None, description="Preferred color scheme")


class OutfitResponse(BaseModel):
    """Response model for outfit generation."""
    items: List[Dict[str, Any]] = Field(..., description="Selected outfit items")
    reasoning: str = Field(..., description="Outfit explanation")
    style_tips: str = Field(..., description="Styling advice")
    audio_url: Optional[str] = Field(None, description="Voice recommendation URL")
    color_harmony: Optional[str] = Field(None, description="Color coordination explanation")
    alternatives: Optional[List[Dict[str, Any]]] = Field(None, description="Alternative items")


class VirtualTryOnRequest(BaseModel):
    """Request model for virtual try-on."""
    user_image_base64: str = Field(..., description="Base64-encoded user photo")
    clothing_items_base64: List[str] = Field(..., description="Base64-encoded clothing images")
    style_guidance: Optional[str] = Field(None, description="Style guidance")


class BackupRequest(BaseModel):
    """Request model for wardrobe backup."""
    user_id: str = Field(..., description="Unique user identifier")
    encrypted_data: str = Field(..., description="Base64-encoded encrypted backup")
    metadata: Optional[Dict[str, Any]] = Field(None, description="Optional metadata")


class BackupResponse(BaseModel):
    """Response model for backup operations."""
    status: str = Field(..., description="Operation status")
    backup_url: str = Field(..., description="Backup file URL")
    timestamp: str = Field(..., description="Backup timestamp")


# ==================== Health Check ====================

@app.get("/", tags=["Health"])
async def root():
    """
    Health check endpoint.

    Returns system status and service availability.
    """
    return {
        "status": "healthy",
        "service": "AI Closet Scanner API",
        "version": settings.API_VERSION,
        "hosted_on": "Daytona",
        "environment": settings.ENVIRONMENT,
        "services": {
            "claude": claude_service is not None,
            "elevenlabs": elevenlabs_service.enabled,
            "nanobanana": nanobanana_service.enabled,
            "tigris": tigris_service.enabled,
            "galileo": galileo_observer.galileo_enabled
        }
    }


@app.get("/health", tags=["Health"])
async def health_check():
    """Detailed health check with service status."""
    return {
        "status": "healthy",
        "timestamp": tigris_service.get_timestamp(),
        "services": {
            "claude": {"enabled": True, "model": settings.CLAUDE_MODEL},
            "elevenlabs": {"enabled": elevenlabs_service.enabled},
            "nanobanana": {"enabled": nanobanana_service.enabled},
            "tigris": {"enabled": tigris_service.enabled},
            "weather": {"enabled": weather_service.enabled},
            "galileo": {"enabled": galileo_observer.galileo_enabled}
        }
    }


# ==================== Weather ====================

@app.get("/weather/{city}", tags=["Weather"])
async def get_weather(city: str):
    """Get current weather for a city to help with outfit recommendations."""
    try:
        weather_data = await weather_service.get_current_weather(city)
        return weather_data
    except Exception as e:
        logger.error(f"Weather fetch error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/weather/{city}/forecast", tags=["Weather"])
async def get_forecast(city: str, days: int = 3):
    """Get weather forecast for outfit planning."""
    try:
        forecast = await weather_service.get_forecast(city, days)
        return {"city": city, "forecast": forecast}
    except Exception as e:
        logger.error(f"Forecast fetch error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Clothing Analysis ====================

@app.post(
    "/analyze-clothing",
    response_model=ClothingAnalysisResponse,
    tags=["Clothing Analysis"],
    summary="Analyze a clothing item",
    description="Upload a clothing image to get detailed AI analysis including type, color, style, and pairing suggestions. Images are encrypted and stored in Tigris cloud storage."
)
async def analyze_clothing(
    file: UploadFile = File(...),
    user_id: Optional[str] = Form(None),
    remove_background: Optional[bool] = Form(True),
    db: Session = Depends(get_db)
):
    """
    Analyze a clothing item using Claude's vision capabilities.

    This endpoint:
    1. Uploads original image to Tigris (cloud storage)
    2. Removes background to extract clean clothing image
    3. Uploads extracted image to Tigris
    4. Analyzes with Claude
    5. Returns metadata + Tigris URLs

    Args:
        file: Image file (JPEG, PNG, etc.)
        user_id: Optional user identifier for organizing images in Tigris
        remove_background: Whether to remove background and extract clothing (default: True)

    Returns:
        ClothingAnalysisResponse: Detailed clothing analysis with Tigris URLs

    Raises:
        HTTPException: If analysis fails
    """
    try:
        logger.info(f"📸 Analyzing clothing image: {file.filename}")

        # Read image
        image_data = await file.read()
        content_type = file.content_type or "image/jpeg"

        # Auto-rotate image to vertical/portrait orientation
        try:
            image = Image.open(io.BytesIO(image_data))
            original_size = image.size
            width, height = original_size

            # First, apply EXIF orientation correction
            corrected_image = ImageOps.exif_transpose(image)

            # Then, ensure image is portrait (vertical/top-down)
            # If width > height, rotate 90° counter-clockwise to make it portrait
            if corrected_image.width > corrected_image.height:
                corrected_image = corrected_image.rotate(90, expand=True)
                logger.info(f"🔄 Rotated image 90° to portrait: {original_size} → {corrected_image.size}")
            else:
                logger.info(f"✅ Image is already portrait orientation: {corrected_image.size}")

            # Save corrected image back to bytes
            output = io.BytesIO()
            image_format = corrected_image.format or 'JPEG'
            corrected_image.save(output, format=image_format, quality=95)
            image_data = output.getvalue()

        except Exception as e:
            logger.warning(f"⚠️  Could not auto-rotate image: {e}, using original")

        # Encode for processing
        image_base64 = base64.b64encode(image_data).decode('utf-8')

        # Save original image locally for testing
        try:
            import time
            timestamp = int(time.time())
            test_output_dir = Path("test_outputs")
            test_output_dir.mkdir(exist_ok=True)

            local_filename = f"original-{timestamp}-{file.filename}"
            local_path = test_output_dir / local_filename

            with open(local_path, "wb") as f:
                f.write(image_data)

            logger.info(f"💾 Saved original image locally: {local_path}")
        except Exception as e:
            logger.warning(f"⚠️  Failed to save original image locally: {e}")

        # === STEP 1: Upload original image to Tigris ===
        original_image_url = None
        if tigris_service.enabled and user_id:
            try:
                logger.info("☁️  Uploading original image to Tigris...")
                import time
                timestamp = int(time.time())
                original_filename = f"original-{timestamp}-{file.filename}"
                original_image_url = await tigris_service.upload_image(
                    image_bytes=image_data,
                    filename=original_filename,
                    content_type=content_type,
                    user_id=user_id
                )
                logger.info(f"✅ Original image uploaded: {original_image_url}")
            except Exception as e:
                logger.warning(f"⚠️  Failed to upload original to Tigris: {e}")

        # === STEP 2: Remove background and extract clothing ===
        extracted_image_url = None
        extracted_image_data = None
        background_was_removed = False
        analysis_image_base64 = image_base64  # Default to original

        if remove_background and nanobanana_service.enabled:
            try:
                logger.info("✂️  Removing background with Gemini API...")
                extracted_image_data = await nanobanana_service.remove_background(
                    image_base64=image_base64,
                    subject_description="clothing item"
                )

                # Check if background removal succeeded
                if extracted_image_data and len(extracted_image_data) > 0:
                    background_was_removed = True

                    # Force extracted image to portrait orientation (Gemini sometimes rotates it)
                    try:
                        extracted_img = Image.open(io.BytesIO(extracted_image_data))
                        if extracted_img.width > extracted_img.height:
                            logger.info(f"🔄 Extracted image is landscape, rotating to portrait: {extracted_img.size}")
                            extracted_img = extracted_img.rotate(90, expand=True)
                            output = io.BytesIO()
                            extracted_img.save(output, format='PNG', quality=95)
                            extracted_image_data = output.getvalue()
                            logger.info(f"✅ Extracted image rotated to portrait: {extracted_img.size}")
                    except Exception as e:
                        logger.warning(f"⚠️  Could not rotate extracted image: {e}")

                    analysis_image_base64 = base64.b64encode(extracted_image_data).decode('utf-8')

                    # Save extracted image locally for testing
                    try:
                        import time
                        timestamp = int(time.time())
                        test_output_dir = Path("test_outputs")
                        test_output_dir.mkdir(exist_ok=True)

                        local_filename = f"extracted-{timestamp}-{file.filename.rsplit('.', 1)[0]}.png"
                        local_path = test_output_dir / local_filename

                        with open(local_path, "wb") as f:
                            f.write(extracted_image_data)

                        logger.info(f"💾 Saved extracted image locally: {local_path}")
                    except Exception as e:
                        logger.warning(f"⚠️  Failed to save image locally: {e}")

                    # Upload extracted image to Tigris
                    if tigris_service.enabled and user_id:
                        try:
                            logger.info("☁️  Uploading extracted image to Tigris...")
                            import time
                            timestamp = int(time.time())
                            # Use PNG extension since background removal returns PNG
                            extracted_filename = f"extracted-{timestamp}-{file.filename.rsplit('.', 1)[0]}.png"
                            extracted_image_url = await tigris_service.upload_image(
                                image_bytes=extracted_image_data,
                                filename=extracted_filename,
                                content_type="image/png",
                                user_id=user_id
                            )
                            logger.info(f"✅ Extracted image uploaded: {extracted_image_url}")
                        except Exception as e:
                            logger.warning(f"⚠️  Failed to upload extracted image: {e}")
                else:
                    logger.info("ℹ️  Background removal skipped or failed, using original")

            except Exception as e:
                logger.warning(f"⚠️  Background removal failed: {e}, using original")

        # === STEP 3: Analyze with Claude ===
        logger.info("🤖 Auto-generating metadata with Claude...")
        # If background was removed, image is now PNG, not original type
        analysis_content_type = "image/png" if background_was_removed else content_type
        analysis = await claude_service.analyze_clothing(analysis_image_base64, analysis_content_type)

        # MVP-C.2: Extract individual clothing items with Gemini
        if analysis.get('item_count', 1) > 1 and analysis.get('all_items'):
            logger.info(f"✂️  Extracting {analysis['item_count']} individual items...")

            # Extract each clothing item separately with background removed
            extracted_images = await nanobanana_service.extract_clothing_items(
                image_data=image_data,
                item_descriptions=analysis['all_items']
            )

            # Add extracted images to each item as base64
            for i, item in enumerate(analysis['all_items']):
                if i < len(extracted_images):
                    item['extracted_image'] = base64.b64encode(extracted_images[i]).decode('utf-8')

            # Add to main result too
            if extracted_images:
                analysis['extracted_image'] = base64.b64encode(extracted_images[0]).decode('utf-8')

        logger.info(f"✅ Analysis complete: {analysis.get('item_count', 1)} item(s) processed!")

        # === STEP 4: Add Tigris URLs and extracted image to response ===
        analysis['original_image_url'] = original_image_url
        analysis['extracted_image_url'] = extracted_image_url
        analysis['background_was_removed'] = background_was_removed

        # Add extracted image as base64 for iOS app to save locally
        if background_was_removed and extracted_image_data:
            analysis['extracted_image'] = base64.b64encode(extracted_image_data).decode('utf-8')
            logger.info("📦 Added extracted image to response (base64)")

        # === STEP 5: Save to Supabase (REST API) ===
        if user_id:
            item_id = str(uuid.uuid4())  # Generate UUID for item

            # Prepare item data for Supabase
            item_data = {
                'id': item_id,
                'user_id': user_id,
                'original_image_url': original_image_url,
                'extracted_image_url': extracted_image_url,
                'type': analysis.get('type', ''),
                'color': analysis.get('color', ''),
                'pattern': analysis.get('pattern', ''),
                'style': analysis.get('style', ''),
                'confidence': analysis.get('confidence', 0.0),
                'season': analysis.get('season', []),
                'pairs_well_with': analysis.get('pairs_well_with', []),
                'occasion': analysis.get('occasion'),
                'material': analysis.get('material'),
                'care_instructions': analysis.get('care_instructions')
            }

            # Save to Supabase via REST API
            supabase_service.save_item(item_data)

            # Add item ID to response
            analysis['item_id'] = item_id

        return analysis

    except Exception as e:
        logger.error(f"❌ Clothing analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get(
    "/closet/{user_id}",
    tags=["Closet"],
    summary="Get user's closet items",
    description="Fetch all clothing items for a specific user from Supabase."
)
async def get_user_closet(user_id: str, db: Session = Depends(get_db)):
    """
    Get all clothing items for a user from Supabase database.

    Returns:
        List of clothing items with metadata and image URLs
    """
    try:
        items = db.query(ClothingItemModel).filter(
            ClothingItemModel.user_id == user_id
        ).order_by(
            ClothingItemModel.created_at.desc()
        ).all()

        return {
            "user_id": user_id,
            "item_count": len(items),
            "items": [item.to_dict() for item in items]
        }

    except Exception as e:
        logger.error(f"❌ Failed to fetch closet: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Outfit Generation ====================

@app.post(
    "/style-outfit-smart",
    tags=["Outfit Styler"],
    summary="Claude-powered smart outfit matching",
    description="Send your wardrobe items and get 3 AI-matched outfit variations."
)
async def style_outfit_smart(
    occasion: str = Body(...),
    wardrobe_items: List[Dict[str, Any]] = Body(...),
    weather: Optional[Dict[str, Any]] = Body(None)
):
    """
    Claude-powered outfit matching with actual item analysis.

    Claude sees all your items and picks the best combinations.

    Steps:
    1. Claude analyzes your entire wardrobe
    2. Creates 3 different outfit variations for the occasion
    3. Returns matched outfits with specific item IDs

    Args:
        occasion: Type of occasion
        wardrobe_items: Full list of user's clothing items
        weather: Optional weather info

    Returns:
        3 complete outfit variations with matched items
    """
    try:
        logger.info(f"🎨 Smart outfit matching for {occasion} with {len(wardrobe_items)} items")

        # Build wardrobe description for Claude
        items_description = "\n".join([
            f"- ID: {item['id']}\n  Type: {item['type']}\n  Color: {item['color']}\n  Style: {item['style']}\n  Pattern: {item['pattern']}\n  Occasions: {', '.join(item.get('occasion', []) or [])}"
            for item in wardrobe_items
        ])

        import anthropic
        import json
        import re

        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)

        smart_matching_prompt = f"""Create 3 different complete outfit variations for a {occasion} occasion from this wardrobe.

Weather: {weather.get('condition', 'mild') if weather else 'mild'}, {weather.get('temperature', 'comfortable') if weather else 'comfortable'}°

Each variation should have a different style/vibe but all appropriate for the occasion.

AVAILABLE WARDROBE:
{items_description}

IMPORTANT RULES:
1. Each outfit must have EXACTLY:
   - ONE top (shirt, blouse, sweater, etc.) OR one dress
   - ONE bottom (pants, skirt, jeans, etc.) - SKIP if dress
   - Optional: shoes, outerwear, accessories
2. NO duplicates - don't pick 2 tops or 2 bottoms
3. Be appropriate for {occasion}
4. Respect the occasion field of items (formal items for formal occasions)
5. Colors/patterns must work well together
6. Use ACTUAL item IDs from the wardrobe above

Return ONLY valid JSON:
{{
    "outfits": [
        {{
            "name": "Classic Look",
            "vibe": "Timeless and polished",
            "items": [
                {{"item_id": "actual-uuid-from-wardrobe", "role": "why this item works"}},
                ...
            ],
            "styling_tips": "How to wear and accessorize",
            "color_story": "Why these colors work together"
        }},
        ...  (2 more variations)
    ]
}}"""

        logger.info("🤖 Having Claude match items intelligently...")

        response = client.messages.create(
            model=settings.CLAUDE_MODEL,
            max_tokens=3000,
            messages=[{"role": "user", "content": smart_matching_prompt}]
        )

        # Extract JSON
        response_text = response.content[0].text
        logger.info(f"📝 Claude response (full): {response_text}")

        # Try to extract JSON
        try:
            json_match = re.search(r'```(?:json)?\s*(\{.*?\})\s*```', response_text, re.DOTALL)
            if json_match:
                response_text = json_match.group(1)
            elif not response_text.strip().startswith('{'):
                json_match = re.search(r'\{.*\}', response_text, re.DOTALL)
                if json_match:
                    response_text = json_match.group(0)

            outfit_data = json.loads(response_text)
            outfits = outfit_data.get('outfits', [])

            if not outfits:
                logger.warning("⚠️  No outfits in response, returning empty")
                return {
                    "success": False,
                    "message": "Claude couldn't create outfits from available items",
                    "outfits": []
                }

        except json.JSONDecodeError as e:
            logger.error(f"❌ JSON parse error: {e}")
            logger.error(f"Response text: {response_text}")
            raise HTTPException(status_code=500, detail=f"Failed to parse Claude response: {str(e)}")

        # Enrich with full item details
        enriched_outfits = []
        for outfit in outfits:
            matched_items = []
            for outfit_item in outfit.get('items', []):
                item_id = outfit_item['item_id']
                full_item = next((item for item in wardrobe_items if item.get('id') == item_id), None)

                if full_item:
                    item_copy = full_item.copy()
                    item_copy['role_in_outfit'] = outfit_item.get('role', '')
                    matched_items.append(item_copy)

            enriched_outfits.append({
                'name': outfit.get('name', 'Outfit'),
                'vibe': outfit.get('vibe', ''),
                'items': matched_items,
                'styling_tips': outfit.get('styling_tips', ''),
                'color_story': outfit.get('color_story', '')
            })

        logger.info(f"✨ Created {len(enriched_outfits)} smart-matched outfits")

        return {
            "success": True,
            "occasion": occasion,
            "weather": weather,
            "outfits": enriched_outfits
        }

    except Exception as e:
        logger.error(f"❌ Outfit styling error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post(
    "/generate-outfit",
    response_model=OutfitResponse,
    tags=["Outfit Generation"],
    summary="Generate outfit suggestions",
    description="Generate AI-powered outfit suggestions based on your wardrobe, occasion, and weather."
)
async def generate_outfit(request: OutfitRequest):
    """
    Generate outfit suggestions based on wardrobe and context.

    This endpoint uses Claude to select items from your wardrobe that work well
    together, and optionally generates a voice recommendation using ElevenLabs.

    Args:
        request: OutfitRequest with wardrobe items and context

    Returns:
        OutfitResponse: Outfit suggestion with items, reasoning, and tips

    Raises:
        HTTPException: If generation fails
    """
    try:
        logger.info(f"👔 Generating outfit for occasion: {request.occasion}")

        # Fetch weather if city is provided
        weather_context = None
        if request.weather:
            try:
                weather_data = await weather_service.get_current_weather(
                    request.weather.get("city", "San Francisco")
                )
                weather_context = weather_service.get_outfit_suggestion_context(weather_data)
                logger.info(f"🌤️  Weather context: {weather_context}")
            except Exception as e:
                logger.warning(f"Weather fetch failed, continuing without: {e}")

        # Generate outfit with Claude
        outfit = await claude_service.generate_outfit(
            wardrobe_items=request.wardrobe_items,
            occasion=request.occasion,
            weather=request.weather,
            preferences=request.preferences,
            color_preference=request.color_preference,
            weather_context=weather_context
        )

        # Generate voice recommendation with ElevenLabs (if enabled)
        audio_url = None
        if elevenlabs_service.enabled:
            try:
                # Combine reasoning and tips for audio
                audio_text = f"{outfit['reasoning']} {outfit.get('style_tips', '')}"

                # Generate audio
                audio_bytes = await elevenlabs_service.create_outfit_recommendation_audio(
                    outfit_description=outfit['reasoning'],
                    style_tips=outfit.get('style_tips', '')
                )

                # Upload to Tigris (if enabled)
                if tigris_service.enabled:
                    filename = f"recommendation_{request.occasion.replace(' ', '-')}.mp3"
                    audio_url = await tigris_service.upload_audio(audio_bytes, filename)
                    logger.info(f"🎵 Audio uploaded: {audio_url}")

            except Exception as e:
                logger.warning(f"⚠️  Audio generation failed (continuing without audio): {e}")

        outfit['audio_url'] = audio_url

        logger.info(f"✅ Outfit generated with {len(outfit['items'])} items")

        return outfit

    except Exception as e:
        logger.error(f"❌ Outfit generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Virtual Try-On ====================

@app.post(
    "/virtual-tryon",
    tags=["Virtual Try-On"],
    summary="Generate virtual try-on",
    description="Create a realistic visualization of you wearing selected clothing items."
)
async def virtual_tryon(request: VirtualTryOnRequest):
    """
    Generate a virtual try-on image using Nano Banana (Gemini).

    This endpoint creates a photorealistic image showing the user wearing
    the specified clothing items.

    Args:
        request: VirtualTryOnRequest with user image and clothing items

    Returns:
        StreamingResponse: Generated try-on image (PNG format)

    Raises:
        HTTPException: If generation fails
    """
    try:
        logger.info("🎨 Generating virtual try-on...")

        # Generate try-on image with Nano Banana
        result_image = await nanobanana_service.generate_tryon(
            user_image=request.user_image_base64,
            clothing_items=request.clothing_items_base64,
            style_guidance=request.style_guidance
        )

        # Return as streaming response
        image_io = io.BytesIO(result_image)

        return StreamingResponse(
            image_io,
            media_type="image/png",
            headers={"Content-Disposition": "inline; filename=tryon.png"}
        )

    except Exception as e:
        logger.error(f"❌ Virtual try-on error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post(
    "/virtual-tryon-outfit",
    tags=["Virtual Try-On"],
    summary="Try on outfit with Gemini",
    description="Upload a model image and multiple clothing images to see the model wearing the outfit using AI image generation."
)
async def virtual_tryon_outfit(
    model_image: UploadFile = File(..., description="Image of the person/model"),
    user_id: Optional[str] = Form(None, description="Optional user ID for organizing images"),
    clothing_image_1: Optional[UploadFile] = File(None, description="First clothing item"),
    clothing_image_2: Optional[UploadFile] = File(None, description="Second clothing item"),
    clothing_image_3: Optional[UploadFile] = File(None, description="Third clothing item"),
    clothing_image_4: Optional[UploadFile] = File(None, description="Fourth clothing item"),
    clothing_image_5: Optional[UploadFile] = File(None, description="Fifth clothing item"),
):
    """
    Generate a virtual try-on image showing a person wearing an outfit.

    This endpoint:
    1. Takes a model image and multiple clothing images (separate items)
    2. Uses Gemini to generate a photorealistic image of the model wearing all items
    3. Saves the generated image to Tigris
    4. Returns the Tigris URL and image metadata

    Args:
        model_image: Photo of the person/model
        clothing_image_1-5: Individual clothing item images
        user_id: Optional user identifier

    Returns:
        JSON with generated image URL and metadata

    Raises:
        HTTPException: If generation fails
    """
    try:
        logger.info("👔 Generating outfit virtual try-on with Gemini...")

        # Read model image
        model_data = await model_image.read()
        model_base64 = base64.b64encode(model_data).decode('utf-8')

        # Collect all clothing images
        clothing_files = [
            clothing_image_1, clothing_image_2, clothing_image_3,
            clothing_image_4, clothing_image_5
        ]

        # Read and encode clothing images
        clothing_base64_list = []
        for clothing_file in clothing_files:
            if clothing_file is not None:
                clothing_data = await clothing_file.read()
                clothing_base64 = base64.b64encode(clothing_data).decode('utf-8')
                clothing_base64_list.append(clothing_base64)

        if not clothing_base64_list:
            raise HTTPException(status_code=400, detail="At least one clothing image is required")

        logger.info(f"📸 Processing {len(clothing_base64_list)} clothing items...")

        # Generate try-on with Gemini
        logger.info("🤖 Calling Gemini for virtual try-on generation...")
        result_image = await nanobanana_service.generate_outfit_tryon(
            model_image=model_base64,
            clothing_images=clothing_base64_list
        )

        # Upload generated image to Tigris
        try_on_url = None
        if tigris_service.enabled and result_image:
            try:
                logger.info("☁️  Uploading virtual try-on to Tigris...")
                import time
                timestamp = int(time.time())
                filename = f"virtual-tryon-{timestamp}.png"
                try_on_url = await tigris_service.upload_image(
                    image_bytes=result_image,
                    filename=filename,
                    content_type="image/png",
                    user_id=user_id
                )
                logger.info(f"✅ Virtual try-on uploaded: {try_on_url}")
            except Exception as e:
                logger.warning(f"⚠️  Failed to upload to Tigris: {e}")

        # Encode result as base64 for response
        result_base64 = base64.b64encode(result_image).decode('utf-8')

        return {
            "success": True,
            "message": "Virtual try-on generated successfully",
            "try_on_image_url": try_on_url,
            "try_on_image_base64": result_base64,
            "timestamp": tigris_service.get_timestamp()
        }

    except Exception as e:
        logger.error(f"❌ Virtual try-on outfit error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Voice Recommendations ====================

@app.post(
    "/voice-recommendation",
    tags=["Voice"],
    summary="Generate voice recommendation",
    description="Convert text to natural-sounding voice using ElevenLabs."
)
async def voice_recommendation(text: str = Body(..., embed=True)):
    """
    Convert text to speech using ElevenLabs.

    Args:
        text: Text to convert to speech

    Returns:
        StreamingResponse: Audio file (MP3 format)

    Raises:
        HTTPException: If TTS fails
    """
    try:
        logger.info(f"🎤 Generating voice for text (length: {len(text)})")

        # Generate audio
        audio_bytes = await elevenlabs_service.text_to_speech(text)

        # Return as streaming response
        audio_io = io.BytesIO(audio_bytes)

        return StreamingResponse(
            audio_io,
            media_type="audio/mpeg",
            headers={"Content-Disposition": "inline; filename=recommendation.mp3"}
        )

    except Exception as e:
        logger.error(f"❌ Voice generation error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Cloud Backup ====================

@app.post(
    "/backup-wardrobe",
    response_model=BackupResponse,
    tags=["Backup"],
    summary="Backup wardrobe to cloud",
    description="Upload encrypted wardrobe backup to Tigris storage."
)
async def backup_wardrobe(request: BackupRequest):
    """
    Backup encrypted wardrobe data to Tigris.

    The data should already be encrypted by the client before upload.

    Args:
        request: BackupRequest with encrypted data

    Returns:
        BackupResponse: Backup confirmation with URL

    Raises:
        HTTPException: If backup fails
    """
    try:
        logger.info(f"💾 Backing up wardrobe for user: {request.user_id}")

        # Decode base64
        encrypted_bytes = base64.b64decode(request.encrypted_data)

        # Upload to Tigris
        backup_url = await tigris_service.upload_backup(
            user_id=request.user_id,
            data=encrypted_bytes,
            metadata=request.metadata
        )

        return {
            "status": "success",
            "backup_url": backup_url,
            "timestamp": tigris_service.get_timestamp()
        }

    except Exception as e:
        logger.error(f"❌ Backup error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get(
    "/list-backups/{user_id}",
    tags=["Backup"],
    summary="List user backups",
    description="Get all backups for a specific user."
)
async def list_backups(user_id: str):
    """
    List all backups for a user.

    Args:
        user_id: User identifier

    Returns:
        List of backup metadata

    Raises:
        HTTPException: If listing fails
    """
    try:
        backups = await tigris_service.list_backups(user_id)
        return {"user_id": user_id, "backups": backups}

    except Exception as e:
        logger.error(f"❌ List backups error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Premium Subscription ====================

@app.post(
    "/premium-subscription",
    tags=["Subscription"],
    summary="Process premium subscription",
    description="Process a premium subscription payment via Brex."
)
async def premium_subscription(
    user_id: str = Body(...),
    plan: str = Body(..., regex="^(monthly|annual)$")
):
    """
    Process premium subscription payment.

    Args:
        user_id: User identifier
        plan: Subscription plan ("monthly" or "annual")

    Returns:
        Payment confirmation

    Raises:
        HTTPException: If payment fails
    """
    try:
        logger.info(f"💳 Processing {plan} subscription for user: {user_id}")

        payment_result = await brex_service.process_subscription(
            user_id=user_id,
            plan=plan
        )

        return payment_result

    except Exception as e:
        logger.error(f"❌ Subscription error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Metrics & Monitoring ====================

@app.get(
    "/metrics",
    tags=["Monitoring"],
    summary="Get system metrics",
    description="Get Galileo observability metrics for monitoring dashboard."
)
async def get_metrics():
    """
    Get current system metrics.

    Returns metrics tracked by Galileo observer for the demo dashboard.

    Returns:
        Dict containing metrics
    """
    return galileo_observer.get_metrics()


# ==================== Demo Dashboard ====================

@app.get(
    "/dashboard",
    response_class=HTMLResponse,
    tags=["Demo"],
    summary="View demo dashboard",
    description="Live metrics dashboard showing API usage and performance."
)
async def demo_dashboard():
    """Serve the demo dashboard HTML page."""
    dashboard_path = Path(__file__).parent / "static" / "dashboard.html"

    if dashboard_path.exists():
        with open(dashboard_path, "r") as f:
            return HTMLResponse(content=f.read())
    else:
        # Return a simple inline dashboard if file doesn't exist
        return HTMLResponse(content="""
<!DOCTYPE html>
<html>
<head>
    <title>AI Closet Scanner - Live Metrics</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
               background: #0a0e27; color: white; padding: 40px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .metric-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                      gap: 20px; margin: 30px 0; }
        .metric-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                      padding: 30px; border-radius: 15px; }
        .metric-value { font-size: 48px; font-weight: bold; margin: 10px 0; }
        .metric-label { font-size: 14px; opacity: 0.9; text-transform: uppercase; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 AI Closet Scanner - Live Metrics</h1>
        <p>Powered by Daytona Cloud • Monitored by Galileo</p>
        <div class="metric-grid">
            <div class="metric-card">
                <div class="metric-label">Total Requests</div>
                <div class="metric-value" id="total-requests">0</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Claude Calls</div>
                <div class="metric-value" id="claude-calls">0</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">ElevenLabs TTS</div>
                <div class="metric-value" id="elevenlabs-calls">0</div>
            </div>
            <div class="metric-card">
                <div class="metric-label">Avg Latency (ms)</div>
                <div class="metric-value" id="avg-latency">0</div>
            </div>
        </div>
    </div>
    <script>
        setInterval(async () => {
            const response = await fetch('/metrics');
            const data = await response.json();
            document.getElementById('total-requests').textContent = data.total_requests;
            document.getElementById('claude-calls').textContent = data.claude_calls;
            document.getElementById('elevenlabs-calls').textContent = data.elevenlabs_calls;
            document.getElementById('avg-latency').textContent = Math.round(data.average_latency * 1000);
        }, 2000);
    </script>
</body>
</html>
        """)


# ==================== Startup Event ====================

@app.on_event("startup")
async def startup_event():
    """Log startup information."""
    # Skip SQLAlchemy init - using Supabase REST API instead
    # init_db()

    logger.info("=" * 60)
    logger.info("🚀 AI Closet Scanner API Starting...")
    logger.info("=" * 60)
    logger.info(f"Version: {settings.API_VERSION}")
    logger.info(f"Environment: {settings.ENVIRONMENT}")
    logger.info(f"Backend URL: {settings.BACKEND_URL}")
    logger.info("=" * 60)
    logger.info("📊 Service Status:")
    logger.info(f"  🤖 Claude: ✅ Enabled ({settings.CLAUDE_MODEL})")
    logger.info(f"  🗣️  ElevenLabs: {'✅ Enabled' if elevenlabs_service.enabled else '❌ Disabled'}")
    logger.info(f"  🍌 Nano Banana: {'✅ Enabled' if nanobanana_service.enabled else '❌ Disabled'}")
    logger.info(f"  ☁️  Tigris: {'✅ Enabled' if tigris_service.enabled else '❌ Disabled'}")
    logger.info(f"  💳 Brex: {'✅ Enabled' if brex_service.enabled else '❌ Disabled'}")
    logger.info(f"  📊 Galileo: {'✅ Enabled' if galileo_observer.galileo_enabled else '❌ Disabled'}")
    logger.info(f"  💾 Database: ✅ Enabled (SQLite)")
    logger.info("=" * 60)
    logger.info("✅ API Ready!")
    logger.info("=" * 60)


# ==================== Main Entry Point ====================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
