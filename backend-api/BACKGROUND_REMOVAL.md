# Background Removal Feature

## Overview

This application now supports **TWO methods** for removing backgrounds from clothing images:

1. **LLM-based (Gemini)** - Original method using AI image generation
2. **rembg Package (NEW!)** - Fast, local, FREE background removal using U²-Net model

## Method Comparison

| Feature | rembg (Recommended) | Gemini (LLM) |
|---------|---------------------|--------------|
| **Cost** | 100% FREE | API costs per image |
| **Speed** | 1-3 seconds | 5-10 seconds |
| **Quality** | Excellent (specialized model) | Good (general AI) |
| **Reliability** | Very consistent | Prompt-dependent |
| **Offline** | ✅ Works offline | ❌ Requires internet |
| **Best for** | Phone photos of clothes | Complex editing tasks |

## NEW Endpoints

### 1. Single Image Background Removal

**POST** `/remove-background`

Remove background from a single clothing image.

**Parameters:**
- `file` (required): Image file (JPEG, PNG, etc.)
- `format` (optional): Output format - `png` (default, transparent) or `jpg` (white background)
- `alpha_matting` (optional): Enable better edge detection (slower but higher quality) - `true` or `false`
- `model` (optional): Model to use:
  - `u2net` (default) - Best for general clothing
  - `u2netp` - Faster, smaller model
  - `u2net_human_seg` - Optimized for fashion photography with people
  - `u2net_cloth_seg` - Optimized specifically for clothing

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/remove-background" \
  -F "file=@shirt.jpg" \
  -F "format=png" \
  -F "alpha_matting=false" \
  -F "model=u2net" \
  --output output.png
```

**Example Python:**
```python
import requests

url = "http://localhost:8000/remove-background"
files = {"file": open("shirt.jpg", "rb")}
data = {
    "format": "png",
    "alpha_matting": False,
    "model": "u2net"
}

response = requests.post(url, files=files, data=data)

with open("output.png", "wb") as f:
    f.write(response.content)
```

**Response:**
- Returns image file directly (PNG or JPG)
- Headers include:
  - `X-Processing-Method: rembg-local`
  - `X-Model-Used: u2net`

---

### 2. Batch Background Removal

**POST** `/remove-background-batch`

Remove backgrounds from multiple images at once.

**Parameters:**
- `files` (required): List of image files
- `format` (optional): Output format for all images

**Example cURL:**
```bash
curl -X POST "http://localhost:8000/remove-background-batch" \
  -F "files=@shirt1.jpg" \
  -F "files=@shirt2.jpg" \
  -F "files=@shirt3.jpg" \
  -F "format=png"
```

**Example Python:**
```python
import requests
import base64

url = "http://localhost:8000/remove-background-batch"
files = [
    ("files", open("shirt1.jpg", "rb")),
    ("files", open("shirt2.jpg", "rb")),
    ("files", open("shirt3.jpg", "rb"))
]
data = {"format": "png"}

response = requests.post(url, files=files, data=data)
result = response.json()

print(f"Processed {result['count']} images")

# Save each image
for i, img_base64 in enumerate(result['images']):
    img_bytes = base64.b64decode(img_base64)
    with open(f"output_{i}.png", "wb") as f:
        f.write(img_bytes)
```

**Response JSON:**
```json
{
  "count": 3,
  "format": "png",
  "images": [
    "base64_encoded_image_1...",
    "base64_encoded_image_2...",
    "base64_encoded_image_3..."
  ],
  "processing_method": "rembg-local"
}
```

---

## Model Selection Guide

### u2net (Default) - Best All-Around
- Use for: General clothing items, products, catalog photos
- Quality: Excellent
- Speed: ~1-3 seconds
- **Recommended for phone photos of clothes**

### u2netp - Fast Processing
- Use for: When speed is critical, batch processing
- Quality: Good (slightly less accurate edges)
- Speed: ~0.5-1 second
- Trade-off: Faster but may miss fine details

### u2net_human_seg - Fashion Photography
- Use for: Photos with people wearing clothes
- Quality: Excellent for human subjects
- Speed: ~2-4 seconds
- Best for: Outfit photos, model shots, selfies with clothing

### u2net_cloth_seg - Clothing Specific
- Use for: Pure clothing items (no person)
- Quality: Optimized for fabric textures and patterns
- Speed: ~2-3 seconds
- Best for: Wardrobe catalog, flat-lay photos, product shots

---

## Integration with Existing Features

The rembg service is automatically initialized when the backend starts. You can check its status:

**GET** `/health`

```json
{
  "status": "healthy",
  "services": {
    "rembg": {
      "enabled": true,
      "type": "local-ai"
    }
  }
}
```

---

## Technical Details

### How It Works

The rembg package uses:
- **U²-Net** deep learning model
- Pre-trained on ~10,000 salient object detection images
- Specialized for foreground/background segmentation
- Runs locally using ONNX Runtime (CPU or GPU)

### Performance

- **CPU**: 1-3 seconds per image
- **GPU** (if available): <1 second per image
- Memory usage: ~500MB for model loading
- Model is cached after first use

### Dependencies

The following packages are automatically installed:
- `rembg==2.0.50` - Main package
- `onnxruntime` - ML model runtime
- `opencv-python-headless` - Image processing
- `numpy`, `scipy` - Numerical operations
- `scikit-image` - Advanced image processing
- `pymatting` - Alpha matting for better edges

---

## When to Use Each Method

### Use rembg (NEW) when:
- ✅ Processing phone photos of clothes
- ✅ Need fast, consistent results
- ✅ Want to minimize API costs
- ✅ Building a wardrobe catalog
- ✅ Batch processing multiple items

### Use Gemini (Original) when:
- ✅ Need complex image editing beyond background removal
- ✅ Want AI-powered item extraction with analysis
- ✅ Processing images with multiple items to separate
- ✅ Need intelligent scene understanding

---

## Example Use Cases

### 1. Wardrobe App - Quick Catalog
```python
# User takes phone photo of clothing item
# Upload to /remove-background for instant cataloging
result = remove_background("phone_photo.jpg", model="u2net_cloth_seg")
# Save to wardrobe with transparent background
```

### 2. E-commerce - Product Photos
```python
# Batch process product photos
images = ["shirt1.jpg", "shirt2.jpg", "pants1.jpg"]
results = remove_background_batch(images, format="png")
# Use transparent PNGs for online store
```

### 3. Fashion Try-On App
```python
# Remove background from clothing
clothing_clean = remove_background("dress.jpg", alpha_matting=True)
# Use with virtual try-on endpoint
tryon_result = virtual_tryon(user_photo, clothing_clean)
```

### 4. Social Media - Outfit Posts
```python
# High-quality edge detection for Instagram posts
result = remove_background(
    "outfit_photo.jpg",
    model="u2net_human_seg",
    alpha_matting=True
)
# Perfect for styled social media content
```

---

## Troubleshooting

### Service Not Available
```json
{
  "services": {
    "rembg": {"enabled": false}
  }
}
```

**Solution:** Ensure rembg is installed:
```bash
pip install rembg==2.0.50
```

### Poor Edge Quality
Try enabling alpha matting:
```python
remove_background(file, alpha_matting=True)
```

### Slow Processing
- Use `u2netp` model for faster (but less accurate) results
- Consider GPU acceleration if available
- Process images in batch for efficiency

### Wrong Subject Detected
Try a different model:
- For clothing items: `u2net_cloth_seg`
- For people wearing clothes: `u2net_human_seg`
- For general items: `u2net` (default)

---

## Performance Tips

1. **Batch Processing**: Use `/remove-background-batch` for multiple images
2. **Model Selection**: Choose the most specific model for your use case
3. **Format Choice**: Use PNG for transparency, JPG for smaller file sizes
4. **Alpha Matting**: Only enable when you need perfect edges (it's slower)
5. **Image Size**: Resize very large images (>4000px) before processing for faster results

---

## Cost Comparison

### 1000 Images Processing

| Method | Cost | Time |
|--------|------|------|
| **rembg (Local)** | $0 | ~30 minutes |
| **remove.bg API** | ~$200 | ~15 minutes |
| **Gemini (LLM)** | ~$50-100 | ~2 hours |

**Winner:** rembg saves you money while maintaining excellent quality!

---

## API Documentation

Full interactive API documentation available at:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

Look for the "Image Processing" tag to find the new endpoints.
