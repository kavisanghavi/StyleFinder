# ⚡ Quick Start Guide

## Get Your AI Closet Scanner Running in 15 Minutes

---

## 🎯 Quick Setup Checklist

### ☑️ Prerequisites (5 min)

- [ ] Python 3.11+ installed (`python3 --version`)
- [ ] macOS with Xcode 15+ (for iOS)
- [ ] Daytona account created
- [ ] Got all API keys (see below)

### ☑️ Backend Setup (5 min)

```bash
# 1. Navigate to backend
cd backend-api

# 2. Create virtual environment
python3 -m venv venv
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Set up environment
cp .env.example .env
nano .env  # Add your API keys

# 5. Run the server
uvicorn app.main:app --reload
```

**Test it**: Open http://localhost:8000/docs

### ☑️ iOS Setup (3 min)

```bash
# 1. Open Xcode project
open ClosetAI.xcodeproj

# 2. Update backend URL in:
# ClosetAI/Services/APIClient.swift
# Change: "http://localhost:8000" to your URL

# 3. Build and Run
# Press Cmd + R
```

### ☑️ Deploy to Daytona (2 min)

```bash
# 1. Install Daytona
curl -sf https://download.daytona.io/daytona/install.sh | sh

# 2. Login
daytona login

# 3. Create workspace
daytona create --name closet-scanner-backend

# 4. Get your URL
daytona url closet-scanner-backend
```

---

## 🔑 Required API Keys

### Get These Keys (10 minutes total):

1. **Claude (Anthropic)** - https://console.anthropic.com/
   ```
   ANTHROPIC_API_KEY=sk-ant-api03-...
   ```

2. **ElevenLabs** - https://elevenlabs.io/
   ```
   ELEVENLABS_API_KEY=...
   ```

3. **Gemini** - https://makersuite.google.com/app/apikey
   ```
   GEMINI_API_KEY=...
   ```

4. **Tigris** - https://console.tigris.dev/
   ```
   TIGRIS_ACCESS_KEY=tid_...
   TIGRIS_SECRET_KEY=tsec_...
   ```

5. **Galileo** - https://console.galileo.ai/
   ```
   GALILEO_API_KEY=...
   ```

6. **Brex** (Optional) - https://developer.brex.com/
   ```
   BREX_API_KEY=...
   ```

---

## 🧪 Quick Test

### 1. Test Health Endpoint

```bash
curl http://localhost:8000/health
```

Should return:
```json
{
  "status": "healthy",
  "services": {
    "claude": {"enabled": true},
    ...
  }
}
```

### 2. Test Clothing Analysis

```bash
curl -X POST "http://localhost:8000/analyze-clothing" \
  -F "file=@/path/to/shirt.jpg"
```

### 3. View Dashboard

Open: http://localhost:8000/dashboard

---

## 🐛 Quick Troubleshooting

### Backend won't start?
```bash
# Check Python version
python3 --version  # Should be 3.11+

# Reinstall dependencies
pip install -r requirements.txt --force-reinstall

# Check .env file
cat .env  # Make sure API keys are set
```

### iOS build fails?
```bash
# Clean build
Cmd + Shift + K

# Rebuild
Cmd + B
```

### API returns errors?
```bash
# Check logs in terminal
# Verify API keys are correct
# Test individual services at /docs
```

---

## 📚 Next Steps

Once everything is running:

1. ✅ Read `README.md` for full details
2. ✅ Check `IMPLEMENTATION_SUMMARY.md` for what's built
3. ✅ Read `docs/SETUP_GUIDE.md` for detailed setup
4. ✅ Explore `docs/API.md` for API reference
5. ✅ Start building iOS UI!

---

## 🎉 You're All Set!

Your AI Closet Scanner is now running locally!

**Backend**: http://localhost:8000
**Docs**: http://localhost:8000/docs
**Dashboard**: http://localhost:8000/dashboard

**Happy Hacking!** 🚀
