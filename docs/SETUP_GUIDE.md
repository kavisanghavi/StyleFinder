# 🚀 Quick Setup Guide

## AI Closet Scanner - Complete Installation Instructions

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] Python 3.11 or higher installed
- [ ] macOS with Xcode 15+ (for iOS development)
- [ ] Daytona account created
- [ ] All required API keys obtained (see below)

---

## 🔑 Step 1: Obtain API Keys

### Required Services

#### 1. Anthropic Claude
- Go to: https://console.anthropic.com/
- Sign up / Log in
- Navigate to "API Keys"
- Create new key
- Copy: `sk-ant-api03-...`

#### 2. ElevenLabs
- Go to: https://elevenlabs.io/
- Sign up / Log in
- Go to Profile → API Keys
- Generate new key
- Copy the key

#### 3. Google Gemini (Nano Banana)
- Go to: https://makersuite.google.com/app/apikey
- Sign in with Google account
- Create API key
- Copy the key

#### 4. Tigris Cloud Storage
- Go to: https://console.tigris.dev/
- Sign up for free account
- Create a new project
- Generate access credentials
- Copy both access key and secret key

#### 5. Galileo AI Observability
- Go to: https://console.galileo.ai/
- Create account
- Create a new project
- Get API key from project settings
- Copy the key

#### 6. Brex (Optional - for payments)
- Go to: https://developer.brex.com/
- Sign up
- Get API credentials
- Copy API key

---

## 🔧 Step 2: Backend Setup (Local Development)

### 1. Clone Repository

```bash
git clone https://github.com/your-username/closet-scanner.git
cd closet-scanner
```

### 2. Set Up Python Environment

```bash
cd backend-api

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate  # On macOS/Linux
# OR
venv\Scripts\activate  # On Windows
```

### 3. Install Dependencies

```bash
pip install --upgrade pip
pip install -r requirements.txt
```

### 4. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Open in your editor
nano .env  # or use your preferred editor
```

Add your API keys to `.env`:

```bash
# ==================== Anthropic (Claude) ====================
ANTHROPIC_API_KEY=sk-ant-api03-YOUR_KEY_HERE

# ==================== ElevenLabs (Voice) ====================
ELEVENLABS_API_KEY=YOUR_ELEVENLABS_KEY

# ==================== Google Gemini (Nano Banana) ====================
GEMINI_API_KEY=YOUR_GEMINI_KEY

# ==================== Tigris Storage ====================
TIGRIS_ENDPOINT=https://fly.storage.tigris.dev
TIGRIS_ACCESS_KEY=tid_YOUR_ACCESS_KEY
TIGRIS_SECRET_KEY=tsec_YOUR_SECRET_KEY
TIGRIS_BUCKET_NAME=closet-scanner-backups

# ==================== Galileo Observability ====================
GALILEO_API_KEY=YOUR_GALILEO_KEY
GALILEO_PROJECT_NAME=closet-scanner

# ==================== Brex (Optional) ====================
BREX_API_KEY=YOUR_BREX_KEY  # Optional

# ==================== Application Settings ====================
BACKEND_URL=http://localhost:8000
ENVIRONMENT=development
```

### 5. Test the Backend

```bash
# Start the server
uvicorn app.main:app --reload

# In another terminal, test the health endpoint
curl http://localhost:8000/health
```

You should see:
```json
{
  "status": "healthy",
  "services": {
    "claude": {"enabled": true, ...},
    "elevenlabs": {"enabled": true},
    ...
  }
}
```

### 6. Access API Documentation

Open in your browser:
- **Interactive Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc
- **Live Dashboard**: http://localhost:8000/dashboard

---

## 🏃 Step 3: Deploy to Daytona

### 1. Install Daytona CLI

```bash
curl -sf https://download.daytona.io/daytona/install.sh | sh
```

### 2. Login to Daytona

```bash
daytona login
```

Follow the prompts to authenticate.

### 3. Push Your Code to GitHub

```bash
git add .
git commit -m "Initial commit: AI Closet Scanner"
git remote add origin https://github.com/your-username/closet-scanner.git
git push -u origin main
```

### 4. Create Daytona Workspace

```bash
daytona create \
  --name closet-scanner-backend \
  --from-git https://github.com/your-username/closet-scanner
```

### 5. Configure Secrets in Daytona

Go to the Daytona dashboard: https://app.daytona.io/

1. Navigate to your workspace
2. Go to Settings → Environment Variables
3. Add all your API keys as **secret** variables:
   - `ANTHROPIC_API_KEY`
   - `ELEVENLABS_API_KEY`
   - `GEMINI_API_KEY`
   - `TIGRIS_ACCESS_KEY`
   - `TIGRIS_SECRET_KEY`
   - `GALILEO_API_KEY`
   - `BREX_API_KEY` (optional)

### 6. Start the Backend on Daytona

```bash
# Open Daytona workspace
daytona code closet-scanner-backend
```

Inside the Daytona terminal:

```bash
cd backend-api
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 7. Get Your Public URL

```bash
daytona url closet-scanner-backend
```

This returns something like:
```
https://closet-scanner-backend-abc123.daytona.app
```

**Save this URL!** You'll need it for the iOS app.

---

## 📱 Step 4: iOS App Setup

### 1. Open Xcode Project

```bash
cd ..  # Go back to project root
open ClosetAI.xcodeproj
```

### 2. Update Backend URL

1. In Xcode, navigate to:
   ```
   ClosetAI → Services → APIClient.swift
   ```

2. Find this line:
   ```swift
   private let baseURL = "http://localhost:8000"
   ```

3. Replace with your Daytona URL:
   ```swift
   private let baseURL = "https://closet-scanner-backend-abc123.daytona.app"
   ```

### 3. Configure Project Settings

1. Select the project in Xcode
2. Go to "Signing & Capabilities"
3. Select your Team
4. Choose a unique Bundle Identifier

### 4. Add Required Capabilities

1. In "Signing & Capabilities", click "+ Capability"
2. Add:
   - **Camera Usage**: (for taking photos)
   - **Photo Library**: (for selecting images)
   - **Keychain Sharing**: (for encryption keys)

### 5. Update Info.plist

Add privacy descriptions:

```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your clothing items</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need photo library access to select clothing images</string>
```

### 6. Build and Run

1. Select a simulator or device
2. Press `Cmd + R` to build and run
3. Wait for the build to complete

### 7. Test the App

1. Open the app on simulator/device
2. Try uploading a clothing image
3. Check that it communicates with the backend
4. Verify results appear correctly

---

## ✅ Step 5: Verify Everything Works

### Test Checklist

- [ ] Backend running locally on http://localhost:8000
- [ ] Backend deployed to Daytona
- [ ] API docs accessible at `/docs`
- [ ] Dashboard showing at `/dashboard`
- [ ] iOS app builds without errors
- [ ] iOS app can connect to backend
- [ ] Clothing analysis works
- [ ] Outfit generation works

### Test Clothing Analysis

```bash
# Test with curl
curl -X POST "http://localhost:8000/analyze-clothing" \
  -H "accept: application/json" \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/clothing/image.jpg"
```

### Check Dashboard

Open: http://localhost:8000/dashboard

You should see metrics updating in real-time.

---

## 🐛 Troubleshooting

### Backend Issues

#### "Module not found" errors
```bash
pip install -r requirements.txt --force-reinstall
```

#### "API key invalid" errors
- Double-check your `.env` file
- Ensure no extra spaces around `=`
- Verify keys are correct on provider websites

#### Port 8000 already in use
```bash
# Find process using port 8000
lsof -i :8000

# Kill it
kill -9 <PID>

# Or use a different port
uvicorn app.main:app --port 8001
```

### iOS Issues

#### Build fails with "Command PhaseScriptExecution failed"
- Clean build folder: `Cmd + Shift + K`
- Rebuild: `Cmd + B`

#### "Failed to connect to backend"
- Check that backend is running
- Verify URL in `APIClient.swift` is correct
- Check firewall settings
- Try using the full Daytona URL

#### Simulator issues
- Reset simulator: `Device → Erase All Content and Settings...`
- Restart Xcode
- Try a different simulator

### Daytona Issues

#### Workspace won't start
- Check Daytona status: `daytona status`
- Restart workspace: `daytona restart <workspace-name>`
- Check logs: `daytona logs <workspace-name>`

#### Environment variables not working
- Verify they're set as "secrets" not regular variables
- Restart the workspace after adding variables
- Check spelling (case-sensitive)

---

## 📚 Next Steps

Now that everything is set up:

1. **Read the full README**: `/README.md`
2. **Explore API docs**: http://your-backend/docs
3. **Check out the dashboard**: http://your-backend/dashboard
4. **Start developing features**
5. **Run tests**: (add your test commands here)

---

## 🆘 Getting Help

If you're stuck:

1. **Check the logs**:
   ```bash
   # Backend logs
   tail -f /path/to/backend/logs

   # Xcode console
   # (View → Debug Area → Show Debug Area)
   ```

2. **Search GitHub Issues**
3. **Contact the team**
4. **Check sponsor documentation**:
   - Claude: https://docs.anthropic.com/
   - ElevenLabs: https://elevenlabs.io/docs
   - Gemini: https://ai.google.dev/docs
   - Tigris: https://www.tigrisdata.com/docs/
   - Galileo: https://docs.galileo.ai/
   - Daytona: https://docs.daytona.io/

---

## 🎉 Success!

If you made it here, congratulations! Your AI Closet Scanner is up and running.

**Happy Hacking!** 🚀
