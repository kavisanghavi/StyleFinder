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

# Import services
from app.services.claude_service import claude_service
from app.services.elevenlabs_service import elevenlabs_service
from app.services.nanobanana_service import nanobanana_service
from app.services.tigris_service import tigris_service
from app.services.brex_service import brex_service
from app.services.weather_service import weather_service
from app.services.background_removal_service import background_removal_service
from app.services.rembg_service import rembg_service
from app.monitoring.galileo_observer import galileo_observer
from app.config import settings

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

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
            "galileo": {"enabled": galileo_observer.galileo_enabled},
            "rembg": {"enabled": rembg_service.enabled, "type": "local-ai"}
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
    description="Upload a clothing image to get detailed AI analysis including type, color, style, and pairing suggestions."
)
async def analyze_clothing(file: UploadFile = File(...)):
    """
    Analyze a clothing item using Claude's vision capabilities.

    This endpoint accepts an image file and returns comprehensive analysis
    including clothing type, color, pattern, style, seasonality, and what it pairs well with.

    Args:
        file: Image file (JPEG, PNG, etc.)

    Returns:
        ClothingAnalysisResponse: Detailed clothing analysis

    Raises:
        HTTPException: If analysis fails
    """
    try:
        logger.info(f"📸 Analyzing clothing image: {file.filename}")

        # Read image
        image_data = await file.read()

        # Encode for Claude
        image_base64 = base64.b64encode(image_data).decode('utf-8')
        content_type = file.content_type or "image/jpeg"

        # MVP-C.3: Auto-generate ALL metadata with multimodal LLM
        logger.info("🤖 Auto-generating metadata with Claude...")
        analysis = await claude_service.analyze_clothing(image_base64, content_type)

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

        return analysis

    except Exception as e:
        logger.error(f"❌ Clothing analysis error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ==================== Outfit Generation ====================

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


# ==================== Background Removal (Rembg) ====================

@app.post(
    "/remove-background",
    tags=["Image Processing"],
    summary="Remove background from clothing image (rembg)",
    description="Remove background from clothing photos using local AI (rembg package). Fast, free, and works offline!"
)
async def remove_background(
    file: UploadFile = File(...),
    format: str = Form("png"),
    alpha_matting: bool = Form(False),
    model: str = Form("u2net")
):
    """
    Remove background from clothing image using rembg package.

    This endpoint uses the rembg Python package with U²-Net model for high-quality
    background removal. Perfect for phone photos of clothes!

    **Benefits:**
    - 🚀 Fast (1-3 seconds)
    - 💰 FREE (no API costs)
    - 📴 Works offline
    - 👔 Great for clothing

    **Available Models:**
    - `u2net`: Default, best for general use (recommended for clothing)
    - `u2netp`: Faster, smaller model (less accurate)
    - `u2net_human_seg`: Optimized for people/fashion photography
    - `u2net_cloth_seg`: Optimized specifically for clothing segmentation

    Args:
        file: Image file (JPEG, PNG, etc.)
        format: Output format (png, jpg) - PNG recommended for transparency
        alpha_matting: Enable better edge detection (slower but higher quality)
        model: Model to use for background removal

    Returns:
        StreamingResponse: Image with background removed (transparent PNG or white background JPG)

    Raises:
        HTTPException: If background removal fails
    """
    try:
        logger.info(f"🎨 Removing background from: {file.filename}")

        # Read image
        image_data = await file.read()

        # Remove background based on model choice
        if model == "u2net":
            # Standard removal with optional alpha matting
            result_image = await rembg_service.remove_background(
                image_data=image_data,
                format=format,
                alpha_matting=alpha_matting
            )
        else:
            # Advanced removal with specific model
            result_image = await rembg_service.remove_background_advanced(
                image_data=image_data,
                model_name=model,
                post_process_mask=alpha_matting
            )

        # Return as streaming response
        image_io = io.BytesIO(result_image)
        media_type = f"image/{format}"

        return StreamingResponse(
            image_io,
            media_type=media_type,
            headers={
                "Content-Disposition": f"inline; filename=no_bg.{format}",
                "X-Processing-Method": "rembg-local",
                "X-Model-Used": model
            }
        )

    except Exception as e:
        logger.error(f"❌ Background removal error: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post(
    "/remove-background-batch",
    tags=["Image Processing"],
    summary="Batch remove backgrounds (rembg)",
    description="Remove backgrounds from multiple clothing images at once."
)
async def remove_background_batch(
    files: List[UploadFile] = File(...),
    format: str = Form("png")
):
    """
    Remove backgrounds from multiple images in batch.

    Args:
        files: List of image files
        format: Output format for all images

    Returns:
        JSONResponse: List of base64-encoded images with backgrounds removed

    Raises:
        HTTPException: If batch processing fails
    """
    try:
        logger.info(f"🎨 Batch removing backgrounds from {len(files)} images...")

        # Read all images
        images_data = []
        for file in files:
            image_data = await file.read()
            images_data.append(image_data)

        # Process batch
        result_images = await rembg_service.remove_backgrounds_batch(
            images=images_data,
            format=format
        )

        # Encode to base64 for JSON response
        encoded_results = []
        for img_bytes in result_images:
            encoded = base64.b64encode(img_bytes).decode('utf-8')
            encoded_results.append(encoded)

        return JSONResponse({
            "count": len(encoded_results),
            "format": format,
            "images": encoded_results,
            "processing_method": "rembg-local"
        })

    except Exception as e:
        logger.error(f"❌ Batch background removal error: {e}")
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
