# 🚀 StyleFinder Bulk Processing - Quick Start

**Bulk image processing is now live!** Process 10, 50, or 100+ clothing images in parallel.

---

## ⚡ 3-Minute Quick Start

### 1. Setup Supabase (One-time)

```bash
# Go to: https://app.supabase.com
# Select your project
# SQL Editor → New Query → Paste and run:

# Copy this file's contents:
cat backend-api/supabase_schema.sql
```

### 2. Get Your Credentials

From Supabase Dashboard → Settings → API:

```bash
SUPABASE_URL=https://cnnobgvxdpevzxjfoprs.supabase.co
SUPABASE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 3. Deploy to Daytona

**Option A: Daytona Web UI** (Easiest)

1. Go to https://app.daytona.io
2. Create workspace from: `https://github.com/kavisanghavi/StyleFinder`
3. Branch: `claude/daytona-bulk-image-processing-01FccCMhmkhcERQ8h8aLmJNN`
4. Add environment variables (see below)
5. Open terminal and run:

```bash
cd backend-api
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Environment Variables:**
```
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=...
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_KEY=eyJhbGci...
TIGRIS_ACCESS_KEY=tid_...
TIGRIS_SECRET_KEY=tsec_...
```

6. Get public URL from Daytona: `https://8000-xxxxx.daytona.app`

### 4. Test It!

```bash
# Update URL in example script
cd examples
nano bulk_upload.sh
# Change: DAYTONA_URL="https://8000-YOUR-URL.daytona.app"

# Upload images
./bulk_upload.sh path/to/shirt1.jpg path/to/pants1.jpg
```

---

## 📚 Documentation

- **BULK_PROCESSING_GUIDE.md** - Complete guide
- **TEST_BULK_PROCESSING.md** - Testing & troubleshooting
- **examples/** - Python & shell examples

**Happy Processing! 🚀**
