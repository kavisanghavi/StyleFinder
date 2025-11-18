# 🚀 Bulk Image Processing with Daytona

Complete guide to bulk processing clothing images with StyleFinder on Daytona.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Setup Supabase Database](#setup-supabase-database)
4. [Deploy to Daytona](#deploy-to-daytona)
5. [API Endpoints](#api-endpoints)
6. [Usage Examples](#usage-examples)
7. [Monitoring & Troubleshooting](#monitoring--troubleshooting)

---

## 🎯 Overview

The bulk processing system allows you to:

- ✅ **Upload multiple images** (10, 50, 100+ images)
- ✅ **Process in parallel** (5 images at a time)
- ✅ **Track progress** in real-time via job status
- ✅ **Store results** in Supabase
- ✅ **Auto-scale** with Daytona sandboxes (future)

### How It Works

```
┌─────────────────────────────────────────────┐
│  1. POST /bulk-analyze                       │
│     • Upload N images                        │
│     • Get job_id immediately                 │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  2. Images uploaded to Tigris                │
│     • Fast cloud storage                     │
│     • Returns URLs                           │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  3. Background worker starts                 │
│     • Processes 5 images at a time           │
│     • Each image:                            │
│       - Download from Tigris                 │
│       - Remove background (Gemini)           │
│       - Analyze with Claude                  │
│       - Save to Supabase                     │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  4. Poll GET /bulk-status/{job_id}           │
│     • Get progress: 45/50 completed          │
│     • Check when status = "completed"        │
└──────────────┬──────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────────┐
│  5. GET /bulk-results/{job_id}               │
│     • Retrieve all analyzed items            │
│     • Use in your app!                       │
└─────────────────────────────────────────────┘
```

---

## 🏗️ Architecture

### Current Implementation (Phase 1)

```
Single Daytona Instance
├── FastAPI Server (main.py)
├── Background Worker (async tasks)
│   ├── Batch 1: [img1, img2, img3, img4, img5] → Process in parallel
│   ├── Batch 2: [img6, img7, img8, img9, img10] → Process in parallel
│   └── Batch N: [...]
└── Services
    ├── Claude (image analysis)
    ├── Gemini (background removal)
    ├── Tigris (image storage)
    └── Supabase (metadata storage)
```

**Performance:**
- Processes **5 images concurrently** per batch
- Each image takes ~5-10 seconds
- ~30-50 images/minute throughput

### Future Scaling (Phase 2 - Daytona SDK)

```
Daytona Controller
├── Spawn Sandbox 1 → Process images 1-10
├── Spawn Sandbox 2 → Process images 11-20
├── Spawn Sandbox 3 → Process images 21-30
└── Spawn Sandbox N → Process images N...
```

**When to scale:** When processing 100+ images regularly.

---

## 🗄️ Setup Supabase Database

### 1. Create Tables

Run the SQL schema in your Supabase SQL Editor:

```bash
# Copy the schema
cat backend-api/supabase_schema.sql
```

Go to [Supabase Dashboard](https://app.supabase.com) → Your Project → SQL Editor → New Query

Paste and run the schema. This creates:

- `clothing_items` - Analyzed clothing data
- `processing_jobs` - Bulk job tracking
- `job_images` - Individual image status

### 2. Get Credentials

From Supabase Dashboard → Settings → API:

```bash
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Test Connection

```bash
curl https://xxxxx.supabase.co/rest/v1/processing_jobs \
  -H "apikey: YOUR_KEY" \
  -H "Authorization: Bearer YOUR_KEY"
```

Should return: `[]` (empty array)

---

## ☁️ Deploy to Daytona

### Option 1: Daytona Web (Easiest)

1. **Go to:** https://app.daytona.io
2. **Create Workspace:**
   - Repository: `https://github.com/kavisanghavi/StyleFinder`
   - Branch: `claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN`
3. **Set Environment Variables:**
   ```bash
   ANTHROPIC_API_KEY=sk-ant-...
   GEMINI_API_KEY=...
   SUPABASE_URL=https://xxxxx.supabase.co
   SUPABASE_KEY=eyJhbGci...
   TIGRIS_ACCESS_KEY=tid_...
   TIGRIS_SECRET_KEY=tsec_...
   ```

4. **Open Workspace Terminal:**
   ```bash
   cd backend-api
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   uvicorn app.main:app --host 0.0.0.0 --port 8000
   ```

5. **Get Public URL:**
   - Daytona will show: `https://8000-xxxxx.daytona.app`
   - Test: `curl https://8000-xxxxx.daytona.app/health`

### Option 2: Daytona CLI

```bash
# Install Daytona CLI
curl -sf https://download.daytona.io/daytona/install.sh | sh

# Login
daytona login

# Create workspace
daytona create StyleFinder \
  --git-url https://github.com/kavisanghavi/StyleFinder

# SSH into workspace
daytona code StyleFinder

# Inside workspace
cd backend-api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Set environment variables
export ANTHROPIC_API_KEY=sk-ant-...
export SUPABASE_URL=https://xxxxx.supabase.co
export SUPABASE_KEY=eyJhbGci...
# ... (add all env vars)

# Start server
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Get public URL
daytona url StyleFinder 8000
```

---

## 📡 API Endpoints

### 1. Bulk Upload

**Endpoint:** `POST /bulk-analyze`

**Request:**
```bash
curl -X POST "https://YOUR-DAYTONA-URL/bulk-analyze" \
  -F "user_id=user-123" \
  -F "files=@shirt1.jpg" \
  -F "files=@shirt2.jpg" \
  -F "files=@pants1.jpg" \
  -F "remove_background=true"
```

**Response:**
```json
{
  "status": "processing",
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "total_images": 3,
  "status_url": "/bulk-status/550e8400-e29b-41d4-a716-446655440000",
  "message": "Processing 3 images. Check status at /bulk-status/..."
}
```

### 2. Check Status

**Endpoint:** `GET /bulk-status/{job_id}`

**Request:**
```bash
curl "https://YOUR-DAYTONA-URL/bulk-status/550e8400-e29b-41d4-a716-446655440000"
```

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing",
  "total_images": 50,
  "processed_images": 23,
  "failed_images": 1,
  "progress_percent": 46.0,
  "created_at": "2025-01-18T10:30:00Z",
  "completed_at": null
}
```

**Status Values:**
- `pending` - Job created, not started
- `processing` - Currently processing
- `completed` - All images processed
- `failed` - Job failed

### 3. Get Results

**Endpoint:** `GET /bulk-results/{job_id}`

**Request:**
```bash
curl "https://YOUR-DAYTONA-URL/bulk-results/550e8400-e29b-41d4-a716-446655440000"
```

**Response:**
```json
{
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "completed",
  "total_items": 50,
  "items": [
    {
      "image_url": "https://tigris.../original-123.jpg",
      "status": "completed",
      "item": {
        "id": "abc-123",
        "type": "shirt",
        "color": "blue",
        "pattern": "solid",
        "style": "casual",
        "confidence": 0.95,
        "season": ["spring", "summer"],
        "pairs_well_with": ["jeans", "chinos"],
        "original_image_url": "https://...",
        "extracted_image_url": "https://..."
      },
      "processed_at": "2025-01-18T10:35:22Z"
    },
    ...
  ]
}
```

---

## 💻 Usage Examples

### Example 1: Python Script

```python
#!/usr/bin/env python3
"""
Bulk upload clothing images to StyleFinder
"""

import requests
import time
from pathlib import Path

# Configuration
DAYTONA_URL = "https://8000-xxxxx.daytona.app"
USER_ID = "user-123"
IMAGE_DIR = Path("./closet_photos")

def upload_bulk_images(image_files):
    """Upload multiple images for bulk processing"""

    # Prepare files
    files = [
        ('files', (img.name, open(img, 'rb'), 'image/jpeg'))
        for img in image_files
    ]

    # Upload
    response = requests.post(
        f"{DAYTONA_URL}/bulk-analyze",
        files=files,
        data={
            'user_id': USER_ID,
            'remove_background': 'true'
        }
    )

    # Close files
    for _, (_, f, _) in files:
        f.close()

    return response.json()

def check_status(job_id):
    """Check processing status"""
    response = requests.get(f"{DAYTONA_URL}/bulk-status/{job_id}")
    return response.json()

def get_results(job_id):
    """Get processed results"""
    response = requests.get(f"{DAYTONA_URL}/bulk-results/{job_id}")
    return response.json()

def main():
    # Find all images
    images = list(IMAGE_DIR.glob("*.jpg")) + list(IMAGE_DIR.glob("*.png"))
    print(f"📸 Found {len(images)} images")

    # Upload
    print("⬆️  Uploading...")
    result = upload_bulk_images(images)
    job_id = result['job_id']
    print(f"✅ Job created: {job_id}")

    # Poll status
    while True:
        status = check_status(job_id)
        progress = status['progress_percent']
        processed = status['processed_images']
        total = status['total_images']

        print(f"📊 Progress: {processed}/{total} ({progress}%)")

        if status['status'] == 'completed':
            print("✅ Processing complete!")
            break
        elif status['status'] == 'failed':
            print("❌ Processing failed!")
            break

        time.sleep(5)  # Poll every 5 seconds

    # Get results
    results = get_results(job_id)
    print(f"\n🎉 Processed {results['total_items']} items:")

    for item_data in results['items']:
        if item_data['item']:
            item = item_data['item']
            print(f"  - {item['type']}: {item['color']} {item['pattern']}")

if __name__ == "__main__":
    main()
```

**Run it:**
```bash
python3 bulk_upload.py
```

### Example 2: cURL

```bash
#!/bin/bash
# bulk_upload.sh

DAYTONA_URL="https://8000-xxxxx.daytona.app"
USER_ID="user-123"

# Upload
echo "Uploading images..."
RESPONSE=$(curl -s -X POST "$DAYTONA_URL/bulk-analyze" \
  -F "user_id=$USER_ID" \
  -F "files=@./images/shirt1.jpg" \
  -F "files=@./images/shirt2.jpg" \
  -F "files=@./images/pants1.jpg")

JOB_ID=$(echo $RESPONSE | jq -r '.job_id')
echo "Job ID: $JOB_ID"

# Poll status
while true; do
  STATUS=$(curl -s "$DAYTONA_URL/bulk-status/$JOB_ID")
  PROGRESS=$(echo $STATUS | jq -r '.progress_percent')
  STATE=$(echo $STATUS | jq -r '.status')

  echo "Progress: $PROGRESS%"

  if [ "$STATE" = "completed" ]; then
    echo "✅ Done!"
    break
  fi

  sleep 5
done

# Get results
curl -s "$DAYTONA_URL/bulk-results/$JOB_ID" | jq .
```

### Example 3: JavaScript/Node.js

```javascript
// bulk_upload.js
const FormData = require('form-data');
const fs = require('fs');
const axios = require('axios');

const DAYTONA_URL = 'https://8000-xxxxx.daytona.app';
const USER_ID = 'user-123';

async function uploadBulk(imagePaths) {
  const form = new FormData();
  form.append('user_id', USER_ID);
  form.append('remove_background', 'true');

  imagePaths.forEach(path => {
    form.append('files', fs.createReadStream(path));
  });

  const response = await axios.post(`${DAYTONA_URL}/bulk-analyze`, form, {
    headers: form.getHeaders()
  });

  return response.data;
}

async function pollStatus(jobId) {
  while (true) {
    const response = await axios.get(`${DAYTONA_URL}/bulk-status/${jobId}`);
    const status = response.data;

    console.log(`Progress: ${status.processed_images}/${status.total_images} (${status.progress_percent}%)`);

    if (status.status === 'completed') {
      console.log('✅ Processing complete!');
      break;
    }

    await new Promise(resolve => setTimeout(resolve, 5000));
  }
}

async function getResults(jobId) {
  const response = await axios.get(`${DAYTONA_URL}/bulk-results/${jobId}`);
  return response.data;
}

async function main() {
  const images = ['./images/shirt1.jpg', './images/shirt2.jpg', './images/pants1.jpg'];

  // Upload
  console.log('Uploading...');
  const uploadResult = await uploadBulk(images);
  const jobId = uploadResult.job_id;
  console.log(`Job ID: ${jobId}`);

  // Poll
  await pollStatus(jobId);

  // Get results
  const results = await getResults(jobId);
  console.log(`Processed ${results.total_items} items`);
  console.log(JSON.stringify(results, null, 2));
}

main();
```

---

## 📊 Monitoring & Troubleshooting

### Check Logs (Daytona)

```bash
# SSH into workspace
daytona code StyleFinder

# View logs
cd backend-api
tail -f logs/app.log
```

### Check Supabase

```sql
-- View recent jobs
SELECT * FROM processing_jobs
ORDER BY created_at DESC
LIMIT 10;

-- View job progress
SELECT
  id,
  user_id,
  status,
  processed_images,
  total_images,
  ROUND((processed_images::float / total_images) * 100, 1) as progress_pct
FROM processing_jobs
WHERE status = 'processing';

-- View failed images
SELECT * FROM job_images
WHERE status = 'failed'
ORDER BY updated_at DESC;
```

### Performance Tuning

**Batch Size:**
- Current: 5 images per batch
- Increase in `main.py:1255`: `batch_size = 10`
- Trade-off: Higher concurrency = more memory

**Timeout Issues:**
- If Claude/Gemini timeout, increase timeout in services
- Add retry logic for failed images

### Common Issues

**1. Job stuck in "pending"**
- Check if background worker started
- Restart Daytona instance

**2. Images not uploading to Tigris**
- Verify `TIGRIS_ACCESS_KEY` and `TIGRIS_SECRET_KEY`
- Check Tigris bucket exists

**3. High failure rate**
- Check Claude API rate limits
- Verify Gemini API quota
- Review error messages in `job_images.error_message`

---

## 🎓 Next Steps

1. **Test with 10 images** first
2. **Scale to 50-100 images**
3. **Monitor Supabase costs** (storage + requests)
4. **Add Daytona SDK** when processing 100+ images regularly
5. **Implement webhooks** for job completion notifications

---

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/kavisanghavi/StyleFinder/issues)
- **Docs:** See `/docs` endpoint on your Daytona URL
- **Supabase:** [Supabase Docs](https://supabase.com/docs)
- **Daytona:** [Daytona Docs](https://www.daytona.io/docs)

---

**Built with ❤️  on Daytona**
