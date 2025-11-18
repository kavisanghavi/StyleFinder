# 🚀 QUICK START - Test Your App NOW!

## ✅ API Keys Already Configured!

Your `.env` file is ready with:
- ✅ **Claude API Key** - For metadata generation
- ✅ **Gemini API Key** - For background removal + virtual try-on

---

## 🏃 Start Backend (30 seconds):

```bash
cd backend-api

# Activate virtual environment
source venv/bin/activate

# Install dependencies (if not done)
pip install -r requirements.txt

# Start server
uvicorn app.main:app --reload
```

**Backend will run at**: `http://localhost:8000`

---

## 📱 Run iOS App:

```bash
# Open Xcode
open ClosetAI.xcodeproj

# Press Cmd+R to run
```

---

## 🧪 Test Complete Flow:

### 1. **Add Item to Closet** (MVP-C.1, C.2, C.3)
1. Open app → **Closet tab**
2. Tap **+ button** (top right)
3. Choose **"Take Photo"** or **"Choose Photo"**
4. Select a clothing image
5. Watch the magic:
   - ✨ Gemini removes background
   - 🤖 Claude generates ALL metadata
   - 💾 Auto-saves to Core Data
   - ☁️ Auto-backs up to cloud (encrypted)

### 2. **Edit Metadata** (MVP-C.4)
1. **Tap on any item** in the grid
2. Edit view opens
3. Change Type, Color, Style, etc. using dropdowns
4. Tap **Save**
5. Changes persist ✅

### 3. **Filter by Category** (MVP-C.5)
1. See filter pills at top of Closet
2. Tap **"Pants"** or **"Shirt"**
3. Grid filters instantly ✅

### 4. **Generate Outfit from YOUR Closet**
1. Go to **Style tab**
2. Shows: "Using X items from your closet"
3. Choose occasion (Work, Date Night, etc.)
4. Tap **"Generate Outfit"**
5. AI creates outfit from YOUR actual items! ✅

### 5. **Virtual Try-On**
1. Go to **Try-On tab**
2. Upload your photo
3. Select clothing item
4. Tap **"Try It On"**
5. See AI visualization ✅

---

## 🎯 What to Expect:

### First Upload:
```
📸 Analyzing clothing image...
🎨 Removing background with Gemini AI...
🤖 Auto-generating metadata with Claude...
✅ Analysis complete!
```

### You'll See:
- Clean image (background removed)
- All metadata auto-filled:
  - Type: "Shirt"
  - Color: "Blue"
  - Style: "Casual"
  - Fabric: "Cotton"
  - Occasion: "Work, Casual"
  - Season: "Spring, Summer, Fall"
  - Etc.

### Then:
- Tap to edit any field
- Filter by category
- Generate outfits from your closet
- Try-on visualization

---

## 🐛 Troubleshooting:

### Backend Won't Start?
```bash
# Check if dependencies installed
cd backend-api
source venv/bin/activate
pip list | grep -E "fastapi|anthropic|google"
```

### iOS App Can't Connect?
- Make sure backend is running at `http://localhost:8000`
- Check backend logs for errors
- Test: `curl http://localhost:8000/health`

### No Background Removal?
- Check backend logs: `🎨 Removing background with Gemini...`
- Gemini API key must be valid
- Will return original image if Gemini fails (graceful fallback)

---

## ✅ Success Indicators:

### Backend Running:
```
INFO:     Started server process
INFO:     Waiting for application startup.
🤖 Claude service initialized
🍌 Nano Banana (Gemini) service initialized
🎨 Background removal initialized (Google Gemini - Smart!)
INFO:     Application startup complete.
```

### iOS App Working:
- Can upload photos ✅
- Can see metadata generated ✅
- Can save to closet ✅
- Can filter items ✅
- Can edit metadata ✅
- Can generate outfits ✅

---

## 🎉 You're Ready!

**Everything is configured and ready to test!**

Just run:
1. Backend: `uvicorn app.main:app --reload`
2. iOS: Press Cmd+R in Xcode

**Start testing and WIN the hackathon!** 🏆
