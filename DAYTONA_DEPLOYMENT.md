# 🚀 Deploy StyleFinder to Daytona (SDK Method)

Complete guide to deploying the bulk processing backend to Daytona using the Python SDK.

---

## 📋 Prerequisites

1. **Daytona Account** - Sign up at https://app.daytona.io
2. **Daytona API Key** - Get from Daytona dashboard
3. **Python 3.11+** installed locally
4. **API Credentials** for:
   - Anthropic (Claude)
   - Google Gemini
   - Supabase
   - Tigris

---

## 🔑 Step 1: Get Your Daytona API Key

```bash
# 1. Go to: https://app.daytona.io
# 2. Sign in or create account
# 3. Go to: Settings → API Keys
# 4. Click "Generate New API Key"
# 5. Copy the key (starts with "daytona_...")
```

**Example API Key:**
```
daytona_1234567890abcdef...
```

---

## 📦 Step 2: Install Daytona SDK

```bash
# Install the Daytona Python SDK
pip install daytona-sdk

# Verify installation
python3 -c "from daytona import Daytona; print('✅ Daytona SDK installed')"
```

---

## 🚀 Step 3: Deploy Using the Script

### Option A: Interactive Deployment (Recommended)

```bash
cd /path/to/StyleFinder

# Run deployment script
python3 deploy_to_daytona.py --api-key YOUR_DAYTONA_API_KEY

# Follow the prompts to enter your API credentials:
# - ANTHROPIC_API_KEY
# - GEMINI_API_KEY
# - SUPABASE_URL
# - SUPABASE_KEY
# - TIGRIS_ACCESS_KEY
# - TIGRIS_SECRET_KEY
```

**Example Run:**

```
================================================================================
🚀 StyleFinder Deployment to Daytona
================================================================================

📋 Please provide your API credentials:

Required credentials:
  ANTHROPIC_API_KEY (e.g., sk-ant-...): sk-ant-api03-xxxxx
  GEMINI_API_KEY (e.g., your-gemini-key): AIzaSy...xxxxx
  SUPABASE_URL (e.g., https://xxxxx.supabase.co): https://cnnobgvx...
  SUPABASE_KEY (e.g., eyJhbGci...): eyJhbGciOi...
  TIGRIS_ACCESS_KEY (e.g., tid_...): tid_xxxxx
  TIGRIS_SECRET_KEY (e.g., tsec_...): tsec_xxxxx

Optional credentials (press Enter to skip):
  ELEVENLABS_API_KEY (optional):

🔌 Connecting to Daytona...
✅ Connected to Daytona

📦 Creating Daytona sandbox...
✅ Sandbox created: abc123def456

🔧 Configuring environment variables...
✅ Environment variables configured

📥 Cloning repository: https://github.com/kavisanghavi/StyleFinder
✅ Repository cloned and checked out branch: claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN

📦 Installing dependencies...
✅ Dependencies installed

🚀 Starting FastAPI server...
⏳ Waiting for server to start...
✅ Server started successfully!

🔍 Verifying deployment at: https://8000-abc123def456.daytona.app
✅ Deployment verified!

📊 Service Status:
   ✅ Claude
   ✅ Supabase
   ✅ Gemini
   ✅ Tigris

================================================================================
🎉 Deployment Complete!
================================================================================

📍 Your StyleFinder API is live at:
   https://8000-abc123def456.daytona.app

📚 API Documentation:
   https://8000-abc123def456.daytona.app/docs

✨ Deployment complete! Your API is ready to process bulk images.
```

### Option B: Manual SDK Usage

If you prefer to write your own script:

```python
from daytona import Daytona, DaytonaConfig

# Initialize
config = DaytonaConfig(api_key="your-daytona-api-key")
daytona = Daytona(config)

# Create sandbox
sandbox = daytona.create()

print(f"Sandbox ID: {sandbox.id}")

# Clone repo
sandbox.process.code_run("""
cd /workspace
git clone https://github.com/kavisanghavi/StyleFinder .
git checkout claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN
""")

# Create .env file
env_content = """
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGci...
TIGRIS_ACCESS_KEY=tid_...
TIGRIS_SECRET_KEY=tsec_...
TIGRIS_ENDPOINT=https://fly.storage.tigris.dev
TIGRIS_BUCKET=closet-scanner
"""

sandbox.filesystem.write("/workspace/backend-api/.env", env_content)

# Install dependencies
sandbox.process.code_run("""
cd /workspace/backend-api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
""")

# Start server
sandbox.process.start_session("""
cd /workspace/backend-api
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
""")

# Get URL
public_url = f"https://8000-{sandbox.id}.daytona.app"
print(f"API URL: {public_url}")

# Keep sandbox alive
# (Don't delete sandbox if you want it to keep running)
```

---

## 🧪 Step 4: Test the Deployment

Once deployed, test the bulk processing:

```bash
# Set your Daytona URL
DAYTONA_URL="https://8000-YOUR-SANDBOX-ID.daytona.app"

# 1. Health check
curl "$DAYTONA_URL/health"

# 2. Test bulk upload
curl -X POST "$DAYTONA_URL/bulk-analyze" \
  -F "user_id=test-user-123" \
  -F "files=@path/to/shirt1.jpg" \
  -F "files=@path/to/pants1.jpg"

# Response:
{
  "status": "processing",
  "job_id": "550e8400-e29b-41d4-a716-446655440000",
  "total_images": 2,
  "status_url": "/bulk-status/550e8400-..."
}

# 3. Check status
curl "$DAYTONA_URL/bulk-status/550e8400-..."

# 4. Get results
curl "$DAYTONA_URL/bulk-results/550e8400-..."
```

---

## 🔧 Managing Your Sandbox

### View Running Sandboxes

```python
from daytona import Daytona, DaytonaConfig

config = DaytonaConfig(api_key="your-api-key")
daytona = Daytona(config)

# List all sandboxes
sandboxes = daytona.list()
for sandbox in sandboxes:
    print(f"ID: {sandbox.id}, Status: {sandbox.status}")
```

### Stop/Delete Sandbox

```python
# Get sandbox by ID
sandbox = daytona.get("your-sandbox-id")

# Delete sandbox
sandbox.delete()
print("Sandbox deleted")
```

### View Logs

```python
# Get sandbox
sandbox = daytona.get("your-sandbox-id")

# View logs
logs = sandbox.process.get_session_logs()
print(logs)
```

---

## 📊 Monitoring Your Deployment

### Check Server Status

```bash
# Health endpoint
curl https://8000-YOUR-ID.daytona.app/health

# Dashboard
open https://8000-YOUR-ID.daytona.app/dashboard
```

### View API Documentation

```bash
# Swagger UI
open https://8000-YOUR-ID.daytona.app/docs
```

### Monitor Supabase

```sql
-- In Supabase SQL Editor:

-- View recent jobs
SELECT * FROM processing_jobs
ORDER BY created_at DESC
LIMIT 10;

-- View processing status
SELECT
  id,
  status,
  processed_images,
  total_images,
  ROUND((processed_images::float / total_images) * 100, 1) as progress
FROM processing_jobs
WHERE status = 'processing';
```

---

## 🔄 Updating Your Deployment

To update your deployed code:

```python
from daytona import Daytona, DaytonaConfig

config = DaytonaConfig(api_key="your-api-key")
daytona = Daytona(config)
sandbox = daytona.get("your-sandbox-id")

# Pull latest code
sandbox.process.code_run("""
cd /workspace
git pull origin claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN
""")

# Restart server
sandbox.process.code_run("pkill uvicorn")
sandbox.process.start_session("""
cd /workspace/backend-api
source venv/bin/activate
uvicorn app.main:app --host 0.0.0.0 --port 8000
""")
```

---

## 🐛 Troubleshooting

### Issue: "Module 'daytona' not found"

```bash
pip install daytona-sdk
```

### Issue: "Invalid API key"

```bash
# Verify your API key
# 1. Go to https://app.daytona.io
# 2. Settings → API Keys
# 3. Generate a new key if needed
```

### Issue: "Server not starting"

```python
# Check logs
sandbox = daytona.get("your-sandbox-id")
logs = sandbox.process.get_session_logs()
print(logs)

# Common fixes:
# 1. Check environment variables
# 2. Verify dependencies installed
# 3. Check port 8000 is not in use
```

### Issue: "Can't access public URL"

```bash
# Wait a few minutes for DNS to propagate
sleep 60

# Try health check
curl https://8000-YOUR-ID.daytona.app/health

# If still failing, check Daytona dashboard
```

---

## 💡 Tips & Best Practices

### 1. Keep Sandbox Running

The deployment script keeps the sandbox alive. If you exit, the sandbox may be deleted.

```python
# To keep sandbox running permanently:
# Don't call sandbox.delete()

# Or use Daytona's persistent sandboxes feature
```

### 2. Environment Variables

Store sensitive credentials securely:

```python
# Use environment variables
import os

api_key = os.getenv('DAYTONA_API_KEY')
anthropic_key = os.getenv('ANTHROPIC_API_KEY')
```

### 3. Resource Management

Monitor your Daytona usage:

```python
# Check sandbox resource usage
sandbox = daytona.get("your-sandbox-id")
stats = sandbox.get_stats()
print(f"CPU: {stats.cpu_usage}%")
print(f"Memory: {stats.memory_usage}MB")
```

---

## 📚 Additional Resources

- **Daytona Documentation:** https://www.daytona.io/docs
- **Daytona Python SDK:** https://pypi.org/project/daytona-sdk/
- **StyleFinder Docs:**
  - QUICKSTART.md
  - BULK_PROCESSING_GUIDE.md
  - TEST_BULK_PROCESSING.md

---

## 🎓 Next Steps

1. ✅ Deploy to Daytona using this guide
2. ✅ Test with 10 images
3. ✅ Monitor in Supabase dashboard
4. ✅ Scale to 50-100 images
5. ✅ Integrate with your iOS app

---

**Happy Deploying! 🚀**
