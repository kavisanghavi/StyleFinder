# 📘 API Documentation

## AI Closet Scanner Backend API

Base URL: `https://your-backend-url.daytona.app`

---

## Table of Contents

- [Authentication](#authentication)
- [Endpoints](#endpoints)
  - [Health Check](#health-check)
  - [Clothing Analysis](#clothing-analysis)
  - [Outfit Generation](#outfit-generation)
  - [Virtual Try-On](#virtual-try-on)
  - [Voice Recommendations](#voice-recommendations)
  - [Cloud Backup](#cloud-backup)
  - [Metrics](#metrics)
- [Error Handling](#error-handling)
- [Rate Limits](#rate-limits)

---

## Authentication

Currently, the API does not require authentication for development/demo purposes.

For production deployment, add API key authentication:
```
Authorization: Bearer YOUR_API_KEY
```

---

## Endpoints

### Health Check

Check if the API is running and view service status.

#### `GET /`

**Response:**
```json
{
  "status": "healthy",
  "service": "AI Closet Scanner API",
  "version": "1.0.0",
  "hosted_on": "Daytona",
  "environment": "production",
  "services": {
    "claude": true,
    "elevenlabs": true,
    "nanobanana": true,
    "tigris": true,
    "galileo": true
  }
}
```

#### `GET /health`

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-11-18T12:00:00Z",
  "services": {
    "claude": {
      "enabled": true,
      "model": "claude-sonnet-4-20250514"
    },
    "elevenlabs": {"enabled": true},
    "nanobanana": {"enabled": true},
    "tigris": {"enabled": true},
    "galileo": {"enabled": true}
  }
}
```

---

### Clothing Analysis

Analyze a clothing item using Claude's vision capabilities.

#### `POST /analyze-clothing`

**Request:**
```http
POST /analyze-clothing HTTP/1.1
Content-Type: multipart/form-data

file: <image file>
```

**cURL Example:**
```bash
curl -X POST "https://your-backend-url/analyze-clothing" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/clothing.jpg"
```

**Response:**
```json
{
  "type": "shirt",
  "color": "blue",
  "pattern": "solid",
  "style": "casual",
  "season": ["spring", "summer", "fall"],
  "pairs_well_with": ["jeans", "chinos", "shorts"],
  "confidence": 0.95,
  "material": "cotton",
  "occasion": ["casual", "work"],
  "care_instructions": "Machine wash cold, tumble dry low"
}
```

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Clothing category (shirt, pants, dress, etc.) |
| `color` | string | Primary color |
| `pattern` | string | Pattern description (solid, striped, floral, etc.) |
| `style` | string | Style category (casual, formal, athletic, etc.) |
| `season` | array | Suitable seasons |
| `pairs_well_with` | array | Complementary clothing items |
| `confidence` | float | Analysis confidence (0.0-1.0) |
| `material` | string | Material type (optional) |
| `occasion` | array | Suitable occasions (optional) |
| `care_instructions` | string | Care recommendations (optional) |

---

### Outfit Generation

Generate outfit suggestions based on wardrobe, occasion, and context.

#### `POST /generate-outfit`

**Request:**
```json
{
  "wardrobe_items": [
    {
      "id": "uuid-1",
      "type": "shirt",
      "color": "white",
      "style": "formal",
      "pattern": "solid"
    },
    {
      "id": "uuid-2",
      "type": "pants",
      "color": "navy",
      "style": "formal",
      "pattern": "solid"
    }
  ],
  "occasion": "work meeting",
  "weather": {
    "temperature": 72,
    "condition": "sunny"
  },
  "color_preference": "professional"
}
```

**cURL Example:**
```bash
curl -X POST "https://your-backend-url/generate-outfit" \
  -H "Content-Type: application/json" \
  -d '{
    "wardrobe_items": [...],
    "occasion": "work meeting",
    "weather": {"temperature": 72, "condition": "sunny"}
  }'
```

**Response:**
```json
{
  "items": [
    {
      "type": "shirt",
      "id": "uuid-1",
      "reasoning": "White shirt provides a clean, professional base"
    },
    {
      "type": "pants",
      "id": "uuid-2",
      "reasoning": "Navy pants complement the shirt perfectly"
    }
  ],
  "reasoning": "This outfit combines professionalism with comfort for your work meeting",
  "style_tips": "Roll sleeves slightly for a more approachable look",
  "audio_url": "https://storage.tigris.dev/audio/recommendation.mp3",
  "color_harmony": "White and navy create a timeless, sophisticated combination",
  "alternatives": [
    {
      "type": "shirt",
      "id": "uuid-3",
      "reason": "Light blue shirt for a softer look"
    }
  ]
}
```

**Request Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `wardrobe_items` | array | Yes | List of available clothing items |
| `occasion` | string | Yes | The occasion/event |
| `weather` | object | No | Weather conditions |
| `preferences` | object | No | User style preferences |
| `color_preference` | string | No | Preferred color scheme |

**Response Fields:**

| Field | Type | Description |
|-------|------|-------------|
| `items` | array | Selected outfit items with reasoning |
| `reasoning` | string | Overall outfit explanation |
| `style_tips` | string | Additional styling advice |
| `audio_url` | string | ElevenLabs voice recommendation URL (optional) |
| `color_harmony` | string | Color coordination explanation |
| `alternatives` | array | Alternative item suggestions |

---

### Virtual Try-On

Generate a photorealistic visualization of clothing items on a person.

#### `POST /virtual-tryon`

**Request:**
```json
{
  "user_image_base64": "base64_encoded_image_data",
  "clothing_items_base64": [
    "base64_encoded_item_1",
    "base64_encoded_item_2"
  ],
  "style_guidance": "professional business attire"
}
```

**Response:**

Binary image data (PNG format)

**Response Headers:**
```
Content-Type: image/png
Content-Disposition: inline; filename=tryon.png
```

**cURL Example:**
```bash
curl -X POST "https://your-backend-url/virtual-tryon" \
  -H "Content-Type: application/json" \
  -d '{"user_image_base64":"...","clothing_items_base64":[...]}' \
  --output tryon.png
```

---

### Voice Recommendations

Convert text to natural-sounding voice using ElevenLabs.

#### `POST /voice-recommendation`

**Request:**
```json
{
  "text": "This outfit looks great! The blue shirt complements your eyes perfectly."
}
```

**Response:**

Binary audio data (MP3 format)

**Response Headers:**
```
Content-Type: audio/mpeg
Content-Disposition: inline; filename=recommendation.mp3
```

**cURL Example:**
```bash
curl -X POST "https://your-backend-url/voice-recommendation" \
  -H "Content-Type: application/json" \
  -d '{"text":"Your styling advice here"}' \
  --output recommendation.mp3
```

---

### Cloud Backup

Backup encrypted wardrobe data to Tigris storage.

#### `POST /backup-wardrobe`

**Request:**
```json
{
  "user_id": "user-uuid",
  "encrypted_data": "base64_encoded_encrypted_backup",
  "metadata": {
    "device": "iPhone 15",
    "version": "1.0.0"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "backup_url": "https://storage.tigris.dev/backups/user-uuid/wardrobe-2024-11-18.encrypted",
  "timestamp": "2024-11-18T12:00:00Z"
}
```

#### `GET /list-backups/{user_id}`

**Response:**
```json
{
  "user_id": "user-uuid",
  "backups": [
    {
      "key": "backups/user-uuid/wardrobe-2024-11-18.encrypted",
      "size": 1024000,
      "last_modified": "2024-11-18T12:00:00Z",
      "url": "https://storage.tigris.dev/..."
    }
  ]
}
```

---

### Metrics

Get system metrics for monitoring dashboard.

#### `GET /metrics`

**Response:**
```json
{
  "total_requests": 150,
  "claude_calls": 45,
  "elevenlabs_calls": 30,
  "nanobanana_calls": 15,
  "tigris_uploads": 10,
  "average_latency": 0.234,
  "total_tokens": 12500,
  "errors": 2,
  "last_request_time": "2024-11-18T12:00:00Z",
  "recent_calls": [
    {
      "name": "claude_analyze_clothing",
      "latency": 0.543,
      "success": true,
      "timestamp": "2024-11-18T11:59:45Z"
    }
  ]
}
```

#### `GET /dashboard`

Returns HTML dashboard for viewing metrics in real-time.

---

## Error Handling

All errors return consistent JSON format:

```json
{
  "detail": "Error message here"
}
```

### HTTP Status Codes

| Code | Meaning |
|------|---------|
| 200 | Success |
| 400 | Bad Request - Invalid input |
| 404 | Not Found - Endpoint doesn't exist |
| 500 | Internal Server Error - Something went wrong |
| 503 | Service Unavailable - AI service temporarily down |

### Example Error Response

```json
{
  "detail": "Failed to analyze clothing: Invalid image format"
}
```

---

## Rate Limits

Current rate limits (subject to change):

- **General API**: 100 requests/minute per IP
- **Clothing Analysis**: 20 requests/minute
- **Outfit Generation**: 30 requests/minute
- **Virtual Try-On**: 10 requests/minute (resource-intensive)

Rate limit headers included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1605564000
```

---

## Request Examples

### Python

```python
import requests

# Analyze clothing
with open('shirt.jpg', 'rb') as f:
    response = requests.post(
        'https://your-backend-url/analyze-clothing',
        files={'file': f}
    )
    analysis = response.json()
    print(analysis)

# Generate outfit
response = requests.post(
    'https://your-backend-url/generate-outfit',
    json={
        'wardrobe_items': [...],
        'occasion': 'date night',
        'weather': {'temperature': 68, 'condition': 'clear'}
    }
)
outfit = response.json()
print(outfit)
```

### JavaScript

```javascript
// Analyze clothing
const formData = new FormData();
formData.append('file', fileInput.files[0]);

const response = await fetch('https://your-backend-url/analyze-clothing', {
  method: 'POST',
  body: formData
});

const analysis = await response.json();
console.log(analysis);

// Generate outfit
const outfitResponse = await fetch('https://your-backend-url/generate-outfit', {
  method: 'POST',
  headers: {'Content-Type': 'application/json'},
  body: JSON.stringify({
    wardrobe_items: [...],
    occasion: 'work',
    weather: {temperature: 72, condition: 'sunny'}
  })
});

const outfit = await outfitResponse.json();
console.log(outfit);
```

### Swift (iOS)

```swift
// See APIClient.swift for complete implementation

let analysis = try await APIClient.shared.analyzeClothing(imageData: imageData)
print(analysis)

let outfit = try await APIClient.shared.generateOutfit(
    wardrobeItems: items,
    occasion: "party"
)
print(outfit)
```

---

## Interactive Documentation

For interactive API documentation with "Try it out" functionality:

**Swagger UI**: `https://your-backend-url/docs`

**ReDoc**: `https://your-backend-url/redoc`

---

## Support

For issues or questions:
- GitHub Issues: [your-repo/issues](https://github.com/your-repo/issues)
- Email: support@example.com

---

**Last Updated**: 2024-11-18
**API Version**: 1.0.0
