# 🚀 Run Your Backend - Simple Instructions

## ✅ Your API Keys Are Already Set!

Your `.env` file has:
- ✅ Claude API Key configured
- ✅ Gemini API Key configured

---

## 📝 Run Backend (Copy & Paste):

Open a **new terminal** window and run:

```bash
cd /Users/aipc/Documents/organzieer/ClosetAI/backend-api

# Create virtual environment (if needed)
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install fastapi uvicorn anthropic google-generativeai python-dotenv httpx boto3 pydantic-settings

# Start server
export PYTHONPATH=/Users/aipc/Documents/organzieer/ClosetAI/backend-api
uvicorn app.main:app --reload --port 8000
```

---

## ✅ Success Indicators:

You should see:
```
INFO:     Uvicorn running on http://127.0.0.1:8000
INFO:     Application startup complete.
🤖 Claude service initialized
🍌 Nano Banana service initialized
🎨 Background removal initialized (Google Gemini)
```

---

## 🧪 Test It:

In another terminal:
```bash
curl http://localhost:8000/health
```

Should return:
```json
{
  "status": "healthy",
  "services": {
    "claude": {"enabled": true},
    "gemini": {"enabled": true},
    ...
  }
}
```

---

## 🎯 What Works Now:

With just **Claude + Gemini** keys:
- ✅ Upload clothing photo
- ✅ **Gemini removes background**
- ✅ **Claude generates metadata**
- ✅ Save to closet
- ✅ Generate outfits
- ✅ Virtual try-on

**You're ready to test the full app!** 🚀

---

## 📱 Then Run iOS App:

```bash
open ClosetAI.xcodeproj
# Press Cmd+R
```

**Happy testing!** 🎉
