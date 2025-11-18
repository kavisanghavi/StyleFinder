# 🚀 Daytona SDK Integration Guide
## AI Closet Scanner - Programmatic Sandbox Deployment

This guide covers deploying AI Closet Scanner using the **Daytona SDK** for programmatic sandbox management.

---

## 📋 Table of Contents

1. [What is Daytona?](#what-is-daytona)
2. [Prerequisites](#prerequisites)
3. [Getting Your API Key](#getting-your-api-key)
4. [Quick Start](#quick-start)
5. [Environment Configuration](#environment-configuration)
6. [Deployment Methods](#deployment-methods)
7. [Managing Sandboxes](#managing-sandboxes)
8. [Troubleshooting](#troubleshooting)

---

## 🎯 What is Daytona?

**Daytona** is an SDK for creating and managing isolated development sandboxes programmatically.

**Key Features:**
- 🐍 **SDK-based** - Python, TypeScript, JavaScript SDKs
- 📦 **Sandboxes** - Isolated containerized environments
- 🔧 **Declarative Images** - Build custom environments on-the-fly
- 🌐 **Preview URLs** - Automatic HTTPS URLs for running services
- ⚡ **Fast** - Spin up environments in seconds
- 🔐 **Secure** - API key-based authentication

**Official Documentation**: https://www.daytona.io/docs/

---

## 📦 Prerequisites

### Required

1. **Python 3.11+** (already installed for this project)
2. **Daytona SDK**:
   ```bash
   pip install daytona
   ```
3. **Daytona API Key** (see next section)

### API Keys for AI Services

You'll also need:
- **Anthropic Claude**: https://console.anthropic.com/
- **ElevenLabs**: https://elevenlabs.io/
- **Google Gemini**: https://makersuite.google.com/app/apikey
- **Tigris Storage** (optional): https://console.tigris.dev/
- **Galileo** (optional): https://console.galileo.ai/

---

## 🔑 Getting Your API Key

1. **Navigate to Daytona Dashboard**
   ```
   Visit: https://app.daytona.io/dashboard/
   ```

2. **Go to API Keys**
   ```
   Click: https://app.daytona.io/dashboard/keys
   ```

3. **Create New Key**
   ```
   - Click "Create Key"
   - Select scopes (recommended: write:sandboxes, delete:sandboxes)
   - Copy the generated key immediately
   - Store it securely (it won't be shown again!)
   ```

4. **Available Scopes**:
   - `write:sandboxes` - Create sandboxes
   - `delete:sandboxes` - Delete sandboxes
   - `write:snapshots` - Create snapshots
   - `delete:snapshots` - Delete snapshots
   - `read:volumes` - Read volumes
   - `write:volumes` - Write volumes
   - `delete:volumes` - Delete volumes
   - `read:audit_logs` - View audit logs

---

## 🚀 Quick Start

### Step 1: Install Daytona SDK

```bash
cd backend-api
pip install daytona
```

### Step 2: Configure Environment

Create/update `backend-api/.env`:

```bash
# Daytona Configuration
DAYTONA_API_KEY=your-daytona-api-key-here
DAYTONA_API_URL=https://app.daytona.io/api  # Default, can be omitted
DAYTONA_TARGET=us  # Optional: deployment region

# AI Services (Required)
ANTHROPIC_API_KEY=sk-ant-api03-xxx
ELEVENLABS_API_KEY=xxx
GEMINI_API_KEY=xxx

# Storage & Monitoring (Optional)
TIGRIS_ACCESS_KEY=tid_xxx
TIGRIS_SECRET_KEY=tsec_xxx
GALILEO_API_KEY=xxx
```

### Step 3: Deploy to Daytona

```bash
cd backend-api
python daytona_deploy.py
```

This script will:
1. ✅ Check all requirements
2. 📦 Build a custom Python 3.11 image with dependencies
3. 🚀 Create a Daytona sandbox
4. 📁 Upload backend code
5. 🔧 Configure environment variables
6. 🌐 Start the FastAPI server
7. 📡 Provide your preview URL

### Step 4: Get Your URLs

After deployment completes, you'll see:

```
====================================== ================
  ✅ Deployment Successful!
============================================================

📡 Backend API:     https://preview-abc123.daytona.app
📚 API Docs:        https://preview-abc123.daytona.app/docs
📊 Dashboard:       https://preview-abc123.daytona.app/dashboard
🏥 Health Check:    https://preview-abc123.daytona.app/health

🔧 Sandbox ID:      abc123
============================================================
```

### Step 5: Update iOS App

Edit `ClosetAI/Services/APIClient.swift`:

```swift
// Update with your Daytona preview URL
private let baseURL = "https://preview-abc123.daytona.app"
```

---

## ⚙️ Environment Configuration

Daytona SDK configuration follows this precedence:

1. **Configuration in Code** (highest priority)
2. **Environment Variables**
3. **.env File**
4. **Default Values** (lowest priority)

### Method 1: .env File (Recommended)

Create `backend-api/.env`:

```bash
DAYTONA_API_KEY=your-key-here
DAYTONA_API_URL=https://app.daytona.io/api
DAYTONA_TARGET=us
```

### Method 2: Environment Variables

```bash
# macOS/Linux
export DAYTONA_API_KEY=your-key-here
export DAYTONA_API_URL=https://app.daytona.io/api
export DAYTONA_TARGET=us

# Windows PowerShell
$env:DAYTONA_API_KEY="your-key-here"
$env:DAYTONA_API_URL="https://app.daytona.io/api"
$env:DAYTONA_TARGET="us"
```

### Method 3: Configuration in Code

```python
from daytona import DaytonaConfig, Daytona

config = DaytonaConfig(
    api_key="your-key-here",
    api_url="https://app.daytona.io/api",
    target="us"
)

daytona = Daytona(config=config)
```

---

## 🛠️ Deployment Methods

### Automated Deployment (Recommended)

Use the provided deployment script:

```bash
cd backend-api
python daytona_deploy.py
```

**What it does:**
- Checks all requirements
- Builds custom image with all dependencies
- Creates sandbox
- Uploads code
- Configures environment
- Starts server
- Returns preview URL

### Manual Deployment (Advanced)

```python
from daytona import Daytona, Image, CreateSandboxFromImageParams
import os

# Initialize Daytona
daytona = Daytona()

# Build custom image
# Note: debian_slim base image includes necessary system packages
image = (
    Image.debian_slim("3.11")  # Debian with Python 3.11
    .pip_install([
        "fastapi==0.104.1",
        "uvicorn[standard]==0.24.0",
        "anthropic==0.7.1",
        # ... other dependencies
    ])
    .workdir("/workspace")
)

# Create sandbox
sandbox = daytona.create(
    CreateSandboxFromImageParams(image=image)
)

# Upload code
sandbox.fs.upload("backend-api/app", "/workspace/app")

# Start server
sandbox.process.start_and_wait(
    cmd="uvicorn app.main:app --host 0.0.0.0 --port 8000",
    background=True
)

# Get preview URL
preview_url = f"https://preview-{sandbox.id}.daytona.app"
print(f"API running at: {preview_url}")
```

---

## 📊 Managing Sandboxes

### List Your Sandboxes

```python
from daytona import Daytona

daytona = Daytona()
sandboxes = daytona.list_sandboxes()

for sandbox in sandboxes:
    print(f"ID: {sandbox.id}, Status: {sandbox.status}")
```

### Get Sandbox Details

```python
sandbox_id = "abc123"
sandbox = daytona.get_sandbox(sandbox_id)

print(f"ID: {sandbox.id}")
print(f"Status: {sandbox.status}")
print(f"URL: https://preview-{sandbox.id}.daytona.app")
```

### Delete Sandbox

Use the cleanup script:

```bash
# Delete specific sandbox
python daytona_cleanup.py abc123

# Delete last created sandbox (from .daytona_sandbox_id file)
python daytona_cleanup.py
```

Or programmatically:

```python
sandbox = daytona.get_sandbox("abc123")
sandbox.delete()
print("Sandbox deleted!")
```

### Execute Commands in Sandbox

```python
# Run a command
result = sandbox.process.code_run("pip list")
print(result.result)

# Check server logs
result = sandbox.process.code_run("tail /tmp/uvicorn.log")
print(result.result)
```

### File Operations

```python
# Upload file
sandbox.fs.upload("local/path/file.py", "/workspace/file.py")

# Download file
sandbox.fs.download("/workspace/logs.txt", "local/logs.txt")

# Read file content
content = sandbox.fs.read("/workspace/.env")
print(content)

# Write file
sandbox.fs.write("/workspace/config.json", '{"debug": true}')
```

---

## 🐛 Troubleshooting

### Issue: "DAYTONA_API_KEY not set"

**Solution:**
```bash
# Check if key is set
echo $DAYTONA_API_KEY

# Set it
export DAYTONA_API_KEY=your-key-here

# Or add to .env file
echo "DAYTONA_API_KEY=your-key-here" >> backend-api/.env
```

### Issue: "Module 'daytona' not found"

**Solution:**
```bash
pip install daytona

# Verify installation
python -c "import daytona; print(daytona.__version__)"
```

### Issue: "Invalid API key"

**Solution:**
1. Get a new key from https://app.daytona.io/dashboard/keys
2. Ensure you copied the entire key
3. Check for extra spaces or quotes
4. Verify the key has required scopes (write:sandboxes)

### Issue: "Sandbox creation failed"

**Solution:**
```bash
# Check your Daytona account status
# Ensure you have available sandbox quota
# Try with simpler image first:

from daytona import Daytona, Image
daytona = Daytona()
sandbox = daytona.create()  # Uses default image
```

### Issue: "Preview URL not accessible"

**Solution:**
1. Wait 30-60 seconds for service to start
2. Check if server is running:
   ```python
   result = sandbox.process.code_run("ps aux | grep uvicorn")
   print(result.result)
   ```
3. Check server logs:
   ```python
   result = sandbox.process.code_run("cat /tmp/uvicorn.log")
   print(result.result)
   ```

### Issue: "Missing dependencies in sandbox"

**Solution:**

Update `daytona_deploy.py` to include missing packages:

```python
# Add missing Python packages to the pip_install list
image = (
    Image.debian_slim("3.11")
    .pip_install([
        "your-missing-package",  # Add here
        "fastapi==0.104.1",
        "uvicorn[standard]==0.24.0",
        # ... other packages
    ])
    .workdir("/workspace")
)
```

---

## 🎯 Best Practices

### 1. **Use .env for Secrets**
```bash
# Never commit .env files
echo ".env" >> .gitignore

# Always use environment variables for secrets
DAYTONA_API_KEY=xxx  # Not in code!
```

### 2. **Clean Up Unused Sandboxes**
```python
# Delete sandbox when done
sandbox.delete()

# Or use the cleanup script
python daytona_cleanup.py
```

### 3. **Monitor Resource Usage**
```bash
# Check sandbox count
daytona = Daytona()
sandboxes = daytona.list_sandboxes()
print(f"Active sandboxes: {len(sandboxes)}")
```

### 4. **Handle Errors Gracefully**
```python
try:
    sandbox = create_sandbox()
    deploy_backend(sandbox)
except Exception as e:
    print(f"Deployment failed: {e}")
    sandbox.delete()  # Clean up on failure
```

### 5. **Use Snapshots for Common Environments**
```python
# Create snapshot of configured sandbox
snapshot = sandbox.create_snapshot()

# Create new sandbox from snapshot (faster)
new_sandbox = daytona.create_from_snapshot(snapshot.id)
```

---

## 📚 Additional Resources

### Documentation

- **Daytona Docs**: https://www.daytona.io/docs/
- **Daytona Dashboard**: https://app.daytona.io/dashboard/
- **API Keys**: https://app.daytona.io/dashboard/keys
- **Python SDK**: `pip show daytona`

### Example Scripts

All scripts are in `backend-api/`:

- **daytona_deploy.py** - Automated deployment
- **daytona_cleanup.py** - Cleanup sandboxes

### Support

- **Daytona GitHub**: https://github.com/daytonaio/daytona
- **Project Issues**: https://github.com/your-username/StyleFinder/issues

---

## ✅ Quick Reference

```bash
# Install SDK
pip install daytona

# Get API key
open https://app.daytona.io/dashboard/keys

# Configure environment
cp .env.example .env
# Edit .env and add DAYTONA_API_KEY

# Deploy
python daytona_deploy.py

# Cleanup
python daytona_cleanup.py
```

---

## 🎉 You're All Set!

Your AI Closet Scanner is now deployable via Daytona SDK! Here's what you have:

- ✅ Programmatic sandbox management
- ✅ Custom image with all dependencies
- ✅ Automatic preview URLs
- ✅ Environment configuration
- ✅ Deployment and cleanup scripts
- ✅ Complete documentation

**Next Steps:**

1. Get your Daytona API key
2. Configure `.env` file
3. Run `python daytona_deploy.py`
4. Update iOS app with preview URL
5. Test your API!

**Happy Deploying! 🚀**

---

*Last Updated: 2024*
*Based on Daytona SDK documentation: https://www.daytona.io/docs/llms-full.txt*
