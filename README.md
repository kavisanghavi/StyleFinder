# 🚀 AI Closet Scanner

> **Your Personal Fashion AI Assistant**
>
> Scan your closet with AI • Get outfit recommendations • Virtual try-on • 100% Private & Encrypted

[![Built for Hackathon](https://img.shields.io/badge/Built%20for-Hackathon-blue)]()
[![Powered by Claude](https://img.shields.io/badge/Powered%20by-Claude-orange)]()
[![Hosted on Daytona](https://img.shields.io/badge/Hosted%20on-Daytona-green)]()

---

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [Backend Setup](#backend-setup)
- [iOS App Setup](#ios-app-setup)
- [Daytona Deployment](#daytona-deployment)
- [API Documentation](#api-documentation)
- [Privacy & Security](#privacy--security)
- [Demo](#demo)
- [License](#license)

---

## 🎯 Overview

**AI Closet Scanner** is a privacy-first wardrobe management app that uses cutting-edge AI to help you:

- 📸 **Scan & Analyze** clothing items with computer vision
- 👔 **Generate Outfits** based on occasion, weather, and style
- 🎨 **Virtual Try-On** to see how outfits look before wearing them
- 🗣️ **Voice Recommendations** with natural-sounding style advice
- ☁️ **Cloud Backup** with end-to-end encryption

### The Problem

"I have nothing to wear!" - Despite having a full closet, we often struggle to:
- Remember what we own
- Create cohesive outfits
- Match items appropriately
- Dress for the occasion

### Our Solution

AI-powered wardrobe management that:
- ✅ Automatically catalogs your closet
- ✅ Suggests outfits based on context
- ✅ Shows you how outfits look before getting dressed
- ✅ Keeps all your data private and encrypted

---

## ✨ Features

### Core Features

#### 1. AI Clothing Analysis (Claude)
- Upload photos of clothing items
- Get detailed analysis: type, color, pattern, style, seasonality
- Automatic pairing suggestions
- Material and care instructions

#### 2. Smart Outfit Generation (Claude)
- Context-aware outfit suggestions
- Weather integration
- Occasion-based recommendations
- Color harmony analysis
- Alternative suggestions

#### 3. Virtual Try-On (Nano Banana)
- See how outfits look on you before wearing them
- Photorealistic visualization
- Multiple item combinations
- Background removal for clean images

#### 4. Voice Recommendations (ElevenLabs)
- Natural-sounding voice guidance
- Personalized styling tips
- Multi-language support
- Downloadable audio recommendations

#### 5. Privacy-First Storage
- **Local encryption** (AES-256-GCM)
- Keys stored in iOS Keychain
- Optional cloud backup to Tigris
- No tracking, no data selling

#### 6. Cloud Development (Daytona)
- Instant development environment
- Zero DevOps setup
- Live deployment
- Collaborative workspace

---

## 🛠️ Technology Stack

### AI Services

| Service | Purpose | Integration |
|---------|---------|-------------|
| **🤖 Claude (Anthropic)** | Fashion analysis & outfit generation | Vision API + Text generation |
| **🗣️ ElevenLabs** | Voice recommendations | Text-to-speech |
| **🍌 Nano Banana (Gemini)** | Virtual try-on image generation | Gemini 2.0 Flash |
| **☁️ Tigris** | Encrypted cloud storage | S3-compatible storage |
| **💳 Brex** | Premium subscriptions | Payment processing |
| **📊 Galileo** | LLM observability | Request tracing |
| **🏃 Daytona** | Cloud development platform | Workspace hosting |

### Backend (Python)

- **FastAPI** - Modern async web framework
- **Anthropic SDK** - Claude API integration
- **ElevenLabs SDK** - TTS integration
- **Google Generative AI** - Gemini integration
- **Boto3** - S3/Tigris storage
- **Galileo Observe** - LLM monitoring

### Frontend (iOS)

- **Swift** - Native iOS development
- **SwiftUI** - Modern declarative UI
- **CryptoKit** - AES-256-GCM encryption
- **Core Data** - Local data persistence
- **Keychain** - Secure key storage

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  iOS APP (Swift/SwiftUI)                 │
│  • Camera capture                                        │
│  • Local encryption (AES-256-GCM)                       │
│  • Core Data storage                                     │
│  • Calls backend API                                     │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ HTTPS
                 ▼
┌─────────────────────────────────────────────────────────┐
│          BACKEND API (Python/FastAPI)                    │
│          🏃 HOSTED ON DAYTONA                            │
│                                                           │
│  ┌────────────────────────────────────────────────────┐ │
│  │  AI Service Integrations:                          │ │
│  │  • Claude API (Anthropic)                          │ │
│  │  • ElevenLabs API                                  │ │
│  │  • Nano Banana (Gemini API)                        │ │
│  │  • Tigris S3 Storage                               │ │
│  │  • Galileo LLM Tracing                             │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Why This Architecture?

**iOS App (Local):**
- Privacy-first: data encrypted locally
- Offline functionality
- Fast, responsive UI
- Native iOS experience

**Backend on Daytona:**
- Heavy AI processing in the cloud
- API aggregation (one backend, multiple AI services)
- Monitoring with Galileo
- Easy to demo and scale

---

## 🚀 Getting Started

### Prerequisites

- **Backend:**
  - Python 3.11+
  - Daytona account (for deployment)
  - API keys (see below)

- **iOS:**
  - macOS with Xcode 15+
  - iOS 17+ simulator or device
  - Apple Developer account (for device testing)

### Required API Keys

You'll need API keys from the following services:

1. **Anthropic Claude**: https://console.anthropic.com/
2. **ElevenLabs**: https://elevenlabs.io/
3. **Google Gemini**: https://makersuite.google.com/app/apikey
4. **Tigris**: https://console.tigris.dev/
5. **Galileo**: https://console.galileo.ai/

Optional:
6. **Brex**: https://developer.brex.com/

---

## 🔧 Backend Setup

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/closet-scanner.git
cd closet-scanner/backend-api
```

### 2. Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

### 4. Configure Environment Variables

```bash
cp .env.example .env
```

Edit `.env` and add your API keys:

```bash
# Anthropic (Claude)
ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# ElevenLabs
ELEVENLABS_API_KEY=your_elevenlabs_key

# Google Gemini
GEMINI_API_KEY=your_gemini_key

# Tigris
TIGRIS_ACCESS_KEY=tid_your_access_key
TIGRIS_SECRET_KEY=tsec_your_secret_key

# Galileo
GALILEO_API_KEY=your_galileo_key

# Application
BACKEND_URL=http://localhost:8000
```

### 5. Run Locally

```bash
cd backend-api
uvicorn app.main:app --reload
```

The API will be available at: http://localhost:8000

- **API Docs**: http://localhost:8000/docs
- **Health Check**: http://localhost:8000/health
- **Dashboard**: http://localhost:8000/dashboard

---

## 📱 iOS App Setup

### 1. Open Xcode Project

```bash
open ClosetAI.xcodeproj
```

### 2. Update Backend URL

Edit `ClosetAI/Services/APIClient.swift`:

```swift
// Change this to your Daytona backend URL
private let baseURL = "https://your-daytona-url.daytona.app"
```

### 3. Build and Run

- Select a simulator or device
- Press `Cmd + R` to build and run

---

## 🏃 Daytona Deployment

> **Daytona** provides instant, fully-configured development environments with one command.
>
> **API Endpoint**: `https://app.daytona.io/api`

### ⚡ Quick Start (2 Minutes)

#### Method 1: Daytona Web Dashboard (Recommended)

1. **Visit** [https://app.daytona.io/](https://app.daytona.io/) and sign in with GitHub
2. **Click** "New Workspace" → Enter repository URL
3. **Add Secrets** in Settings → Secrets (ANTHROPIC_API_KEY, ELEVENLABS_API_KEY, etc.)
4. **Click** "Start Workspace" and wait ~2 min
5. **Get Public URL** from dashboard and update iOS app `APIClient.swift`

#### Method 2: Daytona CLI

```bash
# Install Daytona CLI
curl -sf https://download.daytona.io/daytona/install.sh | sh

# Login
daytona login

# Create workspace from GitHub
daytona create https://github.com/your-username/StyleFinder

# Set secrets
daytona secret set ANTHROPIC_API_KEY=sk-ant-api03-xxx
daytona secret set ELEVENLABS_API_KEY=xxx
daytona secret set GEMINI_API_KEY=xxx

# Start backend
daytona run start

# Get public URL
daytona url ai-closet-scanner
# Returns: https://ai-closet-scanner-abc123.daytona.app
```

### 📖 Complete Guide

For detailed instructions, troubleshooting, and advanced configuration, see:
**[DAYTONA_SETUP.md](./DAYTONA_SETUP.md)** - Complete Daytona integration guide

### 🔑 Required Secrets

Configure these in Daytona dashboard or via CLI:

- `ANTHROPIC_API_KEY` - Claude API key
- `ELEVENLABS_API_KEY` - Voice synthesis
- `GEMINI_API_KEY` - Virtual try-on
- `TIGRIS_ACCESS_KEY` - Cloud storage
- `TIGRIS_SECRET_KEY` - Cloud storage
- `GALILEO_API_KEY` - LLM observability

### 🌐 Access Your Deployment

Once deployed, your backend will be available at:

- **API**: `https://your-workspace.daytona.app`
- **Docs**: `https://your-workspace.daytona.app/docs`
- **Dashboard**: `https://your-workspace.daytona.app/dashboard`
- **Health**: `https://your-workspace.daytona.app/health`

### 🔄 Update iOS App

Edit `ClosetAI/Services/APIClient.swift`:

```swift
// Update baseURL with your Daytona workspace URL
private let baseURL = "https://your-workspace.daytona.app"
```

### 🎯 What You Get

✅ Fully configured Python 3.11 environment
✅ All dependencies auto-installed
✅ Public HTTPS URL for backend
✅ Automatic SSL certificates
✅ Health checks & auto-restart
✅ Built-in monitoring dashboard
✅ Secure secrets management
✅ Zero DevOps configuration

---

## 📚 API Documentation

### Endpoints

#### Health Check
```
GET /
GET /health
```

#### Clothing Analysis
```
POST /analyze-clothing
Content-Type: multipart/form-data

Request:
- file: Image file (JPEG, PNG)

Response:
{
  "type": "shirt",
  "color": "blue",
  "pattern": "solid",
  "style": "casual",
  "season": ["spring", "summer"],
  "pairs_well_with": ["jeans", "chinos"],
  "confidence": 0.95
}
```

#### Outfit Generation
```
POST /generate-outfit
Content-Type: application/json

Request:
{
  "wardrobe_items": [...],
  "occasion": "work",
  "weather": {"temperature": 72, "condition": "sunny"}
}

Response:
{
  "items": [...],
  "reasoning": "...",
  "style_tips": "...",
  "audio_url": "https://..."
}
```

#### Virtual Try-On
```
POST /virtual-tryon
Content-Type: application/json

Request:
{
  "user_image_base64": "...",
  "clothing_items_base64": [...]
}

Response: PNG image
```

For complete API documentation, visit: http://your-backend-url/docs

---

## 🔒 Privacy & Security

### Local Encryption

All user data is encrypted using **AES-256-GCM**:
- Encryption keys stored securely in iOS Keychain
- Data encrypted before leaving the device
- Only user has access to decryption keys

### Cloud Backup (Optional)

If user enables cloud backup:
- Data is **already encrypted** before upload
- Stored in Tigris S3-compatible storage
- No one (including us) can decrypt without the key

### No Tracking

- No analytics
- No user profiling
- No data selling
- No third-party tracking

---

## 🎥 Demo

### Screenshots

[Add screenshots here]

### Video Demo

[Add video demo link here]

### Live Dashboard

Visit the live metrics dashboard: http://your-backend-url/dashboard

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details

---

## 🙏 Acknowledgments

Built with amazing technologies from:
- **Anthropic** (Claude AI)
- **ElevenLabs** (Voice AI)
- **Google** (Gemini AI)
- **Tigris** (Cloud Storage)
- **Galileo** (LLM Observability)
- **Daytona** (Cloud Development)
- **Brex** (Payments)

---

## 📧 Contact

Have questions? Found a bug? Want to contribute?

- **GitHub Issues**: [github.com/your-username/closet-scanner/issues](https://github.com/your-username/closet-scanner/issues)
- **Email**: your-email@example.com

---

**Made with ❤️ for the Hackathon**

*Empowering personal style with AI, while respecting privacy.*
