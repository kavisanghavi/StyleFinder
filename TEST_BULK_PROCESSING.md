# 🧪 Testing Bulk Processing

Quick guide to test the bulk processing implementation.

## ✅ Pre-Flight Checklist

### 1. Setup Supabase Database

```bash
# 1. Go to https://app.supabase.com
# 2. Select your project (or create new one)
# 3. Go to SQL Editor
# 4. Run the schema:

cat backend-api/supabase_schema.sql
# Copy output and paste into Supabase SQL Editor, then run
```

**Verify tables were created:**

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('clothing_items', 'processing_jobs', 'job_images');
```

Should return 3 rows.

### 2. Get API Credentials

From Supabase Dashboard → Settings → API:

```bash
# Copy these values
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Setup Environment Variables

On Daytona:

```bash
# In Daytona workspace, create .env file
cd /home/user/StyleFinder/backend-api

cat > .env << 'EOF'
# Anthropic
ANTHROPIC_API_KEY=sk-ant-api03-your-key

# Supabase
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Gemini (for background removal)
GEMINI_API_KEY=your-gemini-key

# Tigris (cloud storage)
TIGRIS_ACCESS_KEY=tid_your_access_key
TIGRIS_SECRET_KEY=tsec_your_secret_key
TIGRIS_ENDPOINT=https://fly.storage.tigris.dev
TIGRIS_BUCKET=closet-scanner

# Optional
ELEVENLABS_API_KEY=your_key
GALILEO_API_KEY=your_key
EOF
```

### 4. Install Dependencies

```bash
cd /home/user/StyleFinder/backend-api

# Create virtual environment
python3 -m venv venv

# Activate
source venv/bin/activate

# Install
pip install -r requirements.txt
```

## 🚀 Start the Server

### On Daytona

```bash
cd /home/user/StyleFinder/backend-api
source venv/bin/activate

# Start server
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Server will start at: http://0.0.0.0:8000
# Daytona exposes it at: https://8000-xxxxx.daytona.app
```

### Verify Server is Running

```bash
# Health check
curl https://8000-xxxxx.daytona.app/health

# Should return:
{
  "status": "healthy",
  "timestamp": "2025-01-18T...",
  "services": {
    "claude": {"enabled": true, "model": "claude-sonnet-4"},
    "supabase": {"enabled": true},
    ...
  }
}
```

## 📸 Test Bulk Upload

### Test 1: Simple Upload (2 images)

```bash
# Update the Daytona URL in the script
cd /home/user/StyleFinder/examples

# Edit bulk_upload.sh
nano bulk_upload.sh
# Change: DAYTONA_URL="https://8000-xxxxx.daytona.app"

# Create test images (or use your own)
mkdir -p test_images

# Upload
./bulk_upload.sh test_images/shirt1.jpg test_images/shirt2.jpg
```

**Expected Output:**
```
🚀 StyleFinder Bulk Image Upload
================================================================================
   Server:     https://8000-xxxxx.daytona.app
   User ID:    test-user-123
   Images:     2 files
================================================================================

📦 Uploading images...
✅ Upload successful!
   Job ID: 550e8400-e29b-41d4-a716-446655440000
   Images: 2

📊 Monitoring progress...
   [█████████████████████████████░] 50.0% | 1/2 | 15s elapsed
   [██████████████████████████████] 100.0% | 2/2 | 28s elapsed

✅ Processing complete!
   Processed: 2 items
   Time: 28s

📋 Fetching results...
✨ Done!
```

### Test 2: Python Script (10 images)

```bash
cd /home/user/StyleFinder

# Edit script
nano examples/bulk_upload_example.py
# Change: DAYTONA_URL = "https://8000-xxxxx.daytona.app"

# Run
python3 examples/bulk_upload_example.py \
  --images test_images/*.jpg \
  --user-id my-user-123
```

### Test 3: Direct API Calls (curl)

```bash
# Set your Daytona URL
DAYTONA_URL="https://8000-xxxxx.daytona.app"

# 1. Upload images
RESPONSE=$(curl -X POST "$DAYTONA_URL/bulk-analyze" \
  -F "user_id=test-user-123" \
  -F "files=@./test_images/shirt1.jpg" \
  -F "files=@./test_images/shirt2.jpg" \
  -F "remove_background=true")

echo $RESPONSE | jq .

# Extract job ID
JOB_ID=$(echo $RESPONSE | jq -r '.job_id')
echo "Job ID: $JOB_ID"

# 2. Check status
curl "$DAYTONA_URL/bulk-status/$JOB_ID" | jq .

# 3. Get results (when completed)
curl "$DAYTONA_URL/bulk-results/$JOB_ID" | jq .
```

## 🔍 Verify in Supabase

### Check Job Status

```sql
-- View all jobs
SELECT
  id,
  user_id,
  status,
  processed_images,
  total_images,
  created_at
FROM processing_jobs
ORDER BY created_at DESC
LIMIT 5;
```

### Check Processed Images

```sql
-- View job images
SELECT
  ji.id,
  ji.status,
  ji.image_url,
  ci.type,
  ci.color,
  ci.style
FROM job_images ji
LEFT JOIN clothing_items ci ON ji.item_id = ci.id
WHERE ji.job_id = 'your-job-id-here'
ORDER BY ji.created_at;
```

### Check Analyzed Items

```sql
-- View all analyzed items for a user
SELECT
  id,
  type,
  color,
  pattern,
  style,
  confidence,
  created_at
FROM clothing_items
WHERE user_id = 'test-user-123'
ORDER BY created_at DESC;
```

## 📊 Performance Testing

### Test with 50 Images

```bash
# Create 50 test images (or use real ones)
cd /home/user/StyleFinder

# Upload
./examples/bulk_upload.sh test_images/*.jpg

# Monitor in Supabase:
# - Job progress updates every ~5 seconds
# - Processing ~5-10 images per minute (depends on API latency)
```

**Expected Timing:**
- 10 images: ~2-3 minutes
- 50 images: ~10-15 minutes
- 100 images: ~20-30 minutes

## 🐛 Troubleshooting

### Issue: "Job stuck in pending"

**Solution:**
```bash
# Check server logs
cd /home/user/StyleFinder/backend-api
tail -f logs/app.log

# Or check background worker is running
ps aux | grep uvicorn

# Restart server if needed
pkill uvicorn
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Issue: "Images not uploading to Tigris"

**Solution:**
```bash
# Verify Tigris credentials
echo $TIGRIS_ACCESS_KEY
echo $TIGRIS_SECRET_KEY

# Test Tigris connection
python3 -c "from app.services.tigris_service import tigris_service; print(tigris_service.enabled)"

# Should print: True
```

### Issue: "High failure rate"

**Check:**
1. Claude API rate limits (60 RPM)
2. Gemini API quota
3. Image quality (corrupted images fail)

**SQL to find failures:**
```sql
SELECT
  error_message,
  COUNT(*) as count
FROM job_images
WHERE status = 'failed'
GROUP BY error_message;
```

### Issue: "Supabase connection failed"

**Solution:**
```bash
# Test connection
curl https://YOUR_SUPABASE_URL/rest/v1/processing_jobs \
  -H "apikey: YOUR_SUPABASE_KEY" \
  -H "Authorization: Bearer YOUR_SUPABASE_KEY"

# Should return: [] (empty array)

# If error, check:
# 1. URL is correct (ends with .supabase.co)
# 2. Key is the "anon" key from Supabase dashboard
# 3. RLS policies disabled (or configured correctly)
```

## ✅ Success Criteria

All tests pass if:

1. ✅ Server starts without errors
2. ✅ `/health` endpoint returns `{"status": "healthy"}`
3. ✅ Bulk upload creates job in Supabase
4. ✅ Job status updates as images process
5. ✅ Results endpoint returns analyzed items
6. ✅ Images stored in Tigris
7. ✅ Metadata stored in Supabase

## 📈 Next Steps

After successful testing:

1. **Deploy to production Daytona instance**
2. **Set up monitoring** (Galileo dashboard)
3. **Optimize batch size** based on performance
4. **Add webhooks** for job completion notifications
5. **Implement retry logic** for failed images
6. **Scale with Daytona SDK** if needed (100+ images)

## 🎓 Advanced: Daytona SDK Integration

For processing 100+ images with horizontal scaling:

```python
# future: Use Daytona SDK to spawn multiple sandboxes
from daytona import Sandbox

async def process_with_daytona(job_id, image_batches):
    """Spawn multiple Daytona sandboxes for parallel processing"""

    sandboxes = []

    for i, batch in enumerate(image_batches):
        # Create sandbox
        sandbox = Sandbox.create({
            "image": "python:3.11-slim",
            "env": {
                "ANTHROPIC_API_KEY": settings.ANTHROPIC_API_KEY,
                "GEMINI_API_KEY": settings.GEMINI_API_KEY,
                "SUPABASE_URL": settings.SUPABASE_URL,
                "SUPABASE_KEY": settings.SUPABASE_KEY,
            }
        })

        # Install deps and run worker
        await sandbox.exec("pip install -r requirements.txt")
        await sandbox.exec(f"python worker.py {job_id} {i}")

        sandboxes.append(sandbox)

    # Wait for all to complete
    await asyncio.gather(*[s.wait() for s in sandboxes])

    # Cleanup
    for s in sandboxes:
        s.destroy()
```

---

**Happy Testing! 🚀**
