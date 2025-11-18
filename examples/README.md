# 📚 StyleFinder Examples

Example scripts for deploying and using the bulk image processing API.

---

## 📂 Files Overview

### Deployment Scripts

#### `daytona_deploy_minimal.py` ⭐ **Start Here**
The simplest way to deploy to Daytona using the Python SDK.

```bash
# 1. Edit the file and add your API keys
nano daytona_deploy_minimal.py

# 2. Run it
python3 daytona_deploy_minimal.py

# Done! Your API will be live in ~5 minutes
```

**What it does:**
- Creates Daytona sandbox
- Clones repository
- Installs dependencies
- Starts FastAPI server
- Returns public URL

---

### Bulk Upload Clients

#### `bulk_upload.sh`
Shell script for bulk uploading images.

```bash
# 1. Configure
nano bulk_upload.sh
# Set: DAYTONA_URL="https://8000-xxxxx.daytona.app"

# 2. Upload images
./bulk_upload.sh photo1.jpg photo2.jpg photo3.jpg

# Features:
# - Progress bar
# - Auto-polling
# - Pretty output
```

#### `bulk_upload_example.py`
Full-featured Python client for bulk processing.

```bash
# Upload with progress tracking
python3 bulk_upload_example.py \
  --images ./photos/*.jpg \
  --url https://8000-xxxxx.daytona.app \
  --user-id my-user-123

# Features:
# - Real-time progress
# - Error handling
# - JSON results export
```

---

## 🚀 Quick Start

### 1. Deploy to Daytona

**Easiest method:**

```bash
# Edit and run the minimal deployment script
cd examples
nano daytona_deploy_minimal.py  # Add your API keys
python3 daytona_deploy_minimal.py
```

You'll get output like:
```
🎉 Deployment Complete!
📍 Your API is live at:
   https://8000-abc123.daytona.app
```

### 2. Upload Images

**Shell script:**

```bash
# Configure URL
nano bulk_upload.sh
# Change: DAYTONA_URL="https://8000-abc123.daytona.app"

# Upload
./bulk_upload.sh shirt1.jpg shirt2.jpg pants1.jpg
```

**Python script:**

```bash
python3 bulk_upload_example.py \
  --images ./closet_photos/*.jpg \
  --url https://8000-abc123.daytona.app
```

### 3. Monitor Results

```bash
# Check job status (from bulk upload output)
curl "https://8000-abc123.daytona.app/bulk-status/JOB_ID"

# Get results when complete
curl "https://8000-abc123.daytona.app/bulk-results/JOB_ID"
```

---

## 📖 Detailed Guides

For more information, see:

- **../DAYTONA_DEPLOYMENT.md** - Full Daytona deployment guide
- **../BULK_PROCESSING_GUIDE.md** - Architecture and API reference
- **../TEST_BULK_PROCESSING.md** - Testing and troubleshooting
- **../QUICKSTART.md** - Quick start guide

---

## 🔧 Configuration

### API Keys Required

All scripts need these credentials:

```bash
# Daytona
DAYTONA_API_KEY=daytona_...          # From https://app.daytona.io

# AI Services
ANTHROPIC_API_KEY=sk-ant-...         # From https://console.anthropic.com
GEMINI_API_KEY=AIzaSy...             # From https://makersuite.google.com

# Storage
SUPABASE_URL=https://xxx.supabase.co # From https://app.supabase.com
SUPABASE_KEY=eyJhbGci...             # From Supabase dashboard
TIGRIS_ACCESS_KEY=tid_...            # From https://console.tigris.dev
TIGRIS_SECRET_KEY=tsec_...           # From Tigris dashboard
```

---

## 💡 Tips

### Deployment
- Use `daytona_deploy_minimal.py` for quickest deployment
- Keep the script running to maintain sandbox
- Use Daytona dashboard to manage sandboxes

### Bulk Upload
- Test with 2-3 images first
- Use shell script for simple uploads
- Use Python script for advanced features (progress, retry, etc.)

### Monitoring
- Poll status every 5 seconds
- Check Supabase dashboard for detailed tracking
- View logs in Daytona dashboard

---

## 🐛 Troubleshooting

### "Module 'daytona' not found"
```bash
pip install daytona-sdk
```

### "Invalid API key"
Check your Daytona API key at: https://app.daytona.io → Settings → API Keys

### "Connection timeout"
Wait 30-60 seconds for Daytona DNS to propagate after deployment

### "Job stuck in pending"
Check server logs in Daytona dashboard or restart the server

---

## 📚 Examples by Use Case

### Use Case: Deploy and Test

```bash
# 1. Deploy
python3 daytona_deploy_minimal.py

# 2. Test
./bulk_upload.sh test1.jpg test2.jpg
```

### Use Case: Production Upload

```bash
# Upload entire closet
python3 bulk_upload_example.py \
  --images ~/closet_photos/*.jpg \
  --url https://8000-xxxxx.daytona.app \
  --user-id user-12345
```

### Use Case: CI/CD Integration

```bash
# In your CI pipeline
python3 examples/bulk_upload_example.py \
  --images ./test_images/*.jpg \
  --url $DAYTONA_URL \
  --user-id ci-test-user
```

---

**Choose your script and start processing! 🚀**
