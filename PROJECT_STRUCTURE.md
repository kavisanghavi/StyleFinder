# 📂 Project Structure

## AI Closet Scanner - Complete File Organization

This document provides a complete overview of the project structure and what each file does.

---

## 🌳 Directory Tree

```
closet-scanner/
│
├── .git/                               # Git repository
├── .gitignore                          # Git ignore rules
├── .daytona/                           # Daytona configuration
│   └── config.yaml                     # Workspace configuration
│
├── README.md                           # Main project README
├── PROJECT_STRUCTURE.md                # This file
│
├── docs/                               # Documentation
│   ├── SETUP_GUIDE.md                  # Complete setup instructions
│   ├── API.md                          # API documentation
│   └── DEMO.md                         # Demo script (to be created)
│
├── backend-api/                        # 🐍 Python Backend (FastAPI)
│   ├── .env.example                    # Environment variables template
│   ├── .env                            # Actual environment variables (gitignored)
│   ├── requirements.txt                # Python dependencies
│   ├── Dockerfile                      # Docker configuration
│   │
│   └── app/                            # Main application code
│       ├── __init__.py                 # Package initialization
│       ├── main.py                     # 🚀 FastAPI application entry point
│       ├── config.py                   # Configuration management
│       │
│       ├── routers/                    # API route handlers
│       │   └── __init__.py
│       │
│       ├── services/                   # AI service integrations
│       │   ├── __init__.py
│       │   ├── claude_service.py       # 🤖 Claude (Anthropic) integration
│       │   ├── elevenlabs_service.py   # 🗣️  ElevenLabs TTS integration
│       │   ├── nanobanana_service.py   # 🍌 Nano Banana (Gemini) integration
│       │   ├── tigris_service.py       # ☁️  Tigris storage integration
│       │   └── brex_service.py         # 💳 Brex payment integration
│       │
│       ├── monitoring/                 # Observability
│       │   ├── __init__.py
│       │   └── galileo_observer.py     # 📊 Galileo LLM monitoring
│       │
│       └── static/                     # Static files
│           └── dashboard.html          # Live metrics dashboard
│
└── ClosetAI/                           # 📱 iOS App (Swift/SwiftUI)
    ├── ClosetAIApp.swift               # App entry point
    ├── ContentView.swift               # Main view
    │
    ├── Models/                         # Data models
    │   ├── ClothingItem.swift          # Clothing item model
    │   └── OutfitSuggestion.swift      # Outfit model
    │
    ├── Views/                          # SwiftUI views
    │   ├── CameraView.swift            # (to be created)
    │   ├── WardrobeGridView.swift      # (to be created)
    │   ├── OutfitGeneratorView.swift   # (to be created)
    │   └── VirtualTryOnView.swift      # (to be created)
    │
    ├── ViewModels/                     # View models
    │   └── (to be created)
    │
    ├── Services/                       # iOS services
    │   ├── APIClient.swift             # Backend API communication
    │   ├── EncryptionService.swift     # AES-256-GCM encryption
    │   └── CoreDataManager.swift       # (to be created)
    │
    ├── Security/                       # Security utilities
    │   └── KeychainManager.swift       # (to be created)
    │
    └── Assets.xcassets/                # App assets (images, colors)
```

---

## 📄 File Descriptions

### Root Level

| File | Purpose |
|------|---------|
| `README.md` | Main project documentation, features, setup overview |
| `PROJECT_STRUCTURE.md` | This file - complete project organization |
| `.gitignore` | Specifies files to ignore in Git (API keys, secrets, etc.) |

### Documentation (`docs/`)

| File | Purpose |
|------|---------|
| `SETUP_GUIDE.md` | Step-by-step installation and deployment guide |
| `API.md` | Complete API endpoint documentation with examples |
| `DEMO.md` | Presentation script and demo walkthrough (to be created) |

### Backend API (`backend-api/`)

#### Configuration Files

| File | Purpose |
|------|---------|
| `.env.example` | Template for environment variables |
| `.env` | Actual API keys and secrets (NEVER commit to git!) |
| `requirements.txt` | Python package dependencies |
| `Dockerfile` | Docker container configuration |

#### Core Application (`backend-api/app/`)

| File | Purpose | Key Functions |
|------|---------|---------------|
| `main.py` | FastAPI app, all API endpoints | - Health checks<br>- Clothing analysis<br>- Outfit generation<br>- Virtual try-on<br>- Voice recommendations<br>- Cloud backup |
| `config.py` | Settings and environment variables | - Load .env<br>- Type-safe settings<br>- Cached configuration |

#### Services (`backend-api/app/services/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `claude_service.py` | Claude API integration | - Vision-based clothing analysis<br>- Outfit generation<br>- Style advice |
| `elevenlabs_service.py` | ElevenLabs TTS | - Text-to-speech<br>- Natural voice recommendations<br>- Multi-language support |
| `nanobanana_service.py` | Gemini image generation | - Virtual try-on<br>- Background removal<br>- Outfit visualization |
| `tigris_service.py` | Tigris cloud storage | - Encrypted backup storage<br>- Audio file hosting<br>- Image storage |
| `brex_service.py` | Payment processing | - Subscription management<br>- Payment processing (optional) |

#### Monitoring (`backend-api/app/monitoring/`)

| File | Purpose | Key Features |
|------|---------|--------------|
| `galileo_observer.py` | LLM observability | - Request tracing<br>- Performance metrics<br>- Error tracking<br>- Dashboard data |

#### Static Files (`backend-api/app/static/`)

| File | Purpose |
|------|---------|
| `dashboard.html` | Real-time metrics dashboard with live updates |

### iOS App (`ClosetAI/`)

#### Core App Files

| File | Purpose |
|------|---------|
| `ClosetAIApp.swift` | SwiftUI app lifecycle and entry point |
| `ContentView.swift` | Main app view |

#### Models (`ClosetAI/Models/`)

| File | Purpose | Key Properties |
|------|---------|----------------|
| `ClothingItem.swift` | Represents a clothing item | - ID, image path<br>- Claude analysis results<br>- User metadata<br>- Encryption support |
| `OutfitSuggestion.swift` | Represents an outfit | - Selected items<br>- Reasoning & tips<br>- Voice audio URL<br>- Alternatives |

#### Services (`ClosetAI/Services/`)

| File | Purpose | Key Functions |
|------|---------|---------------|
| `APIClient.swift` | Backend communication | - `analyzeClothing()`<br>- `generateOutfit()`<br>- `virtualTryOn()`<br>- `backupWardrobe()` |
| `EncryptionService.swift` | AES-256-GCM encryption | - `encrypt(data:)`<br>- `decrypt(data:)`<br>- Keychain key storage<br>- Image encryption |

---

## 🔑 Key Technologies by File

### Backend Technologies

```
main.py                  → FastAPI, Uvicorn
claude_service.py        → Anthropic SDK
elevenlabs_service.py    → ElevenLabs SDK
nanobanana_service.py    → Google Generative AI SDK
tigris_service.py        → Boto3 (S3-compatible)
galileo_observer.py      → Galileo Observe SDK
```

### iOS Technologies

```
ClosetAIApp.swift        → SwiftUI, Swift
APIClient.swift          → URLSession, Codable
EncryptionService.swift  → CryptoKit, Keychain
ClothingItem.swift       → Foundation, Codable
```

---

## 🔒 Security-Sensitive Files

**NEVER commit these files:**

```
backend-api/.env                    # Contains API keys
backend-api/**/*.key                # Any key files
backend-api/**/*.pem                # Any certificates
ClosetAI/Config/Secrets.plist       # iOS secrets (if created)
```

**Always in `.gitignore`:**
- `.env`
- `*.key`
- `*_API_KEY*`
- `*_SECRET*`
- `*credentials*`

---

## 📦 Dependencies

### Python (`backend-api/requirements.txt`)

```
FastAPI           → Web framework
Anthropic         → Claude AI
ElevenLabs        → Voice AI
Google-GenAI      → Gemini AI
Boto3             → Tigris storage
Galileo-Observe   → LLM monitoring
Uvicorn           → ASGI server
```

### iOS (Built-in frameworks)

```
SwiftUI           → UI framework
CryptoKit         → Encryption
Foundation        → Core utilities
Combine           → Reactive programming
```

---

## 🎯 File Relationships

### Backend Request Flow

```
1. Client Request → main.py
2. main.py → claude_service.py (analyze clothing)
3. claude_service.py → Claude API
4. Response → galileo_observer.py (log metrics)
5. Response → Client
```

### iOS Data Flow

```
1. User captures image → Camera
2. Encrypt image → EncryptionService
3. Send to backend → APIClient
4. Receive analysis → ClothingItem model
5. Store locally → Core Data
6. Display in UI → SwiftUI Views
```

---

## 📝 File Size Guidelines

| File Type | Typical Size |
|-----------|--------------|
| Python services | 200-500 lines |
| Swift models | 100-200 lines |
| Swift views | 150-300 lines |
| Configuration | 50-100 lines |
| Documentation | 200-500 lines |

---

## 🚀 Next Steps

Files to create:

### Backend
- [ ] Unit tests (`backend-api/tests/`)
- [ ] Integration tests
- [ ] CI/CD configuration

### iOS
- [ ] Camera view
- [ ] Wardrobe grid view
- [ ] Outfit generator view
- [ ] Virtual try-on view
- [ ] Core Data manager
- [ ] Keychain manager
- [ ] Unit tests
- [ ] UI tests

### Documentation
- [ ] Demo script
- [ ] Presentation slides
- [ ] Video tutorial
- [ ] Contributing guidelines
- [ ] Changelog

---

## 📊 Code Statistics

**Backend:**
- Total Lines: ~3,000
- Python Files: 9
- Endpoints: 10+
- AI Integrations: 5

**iOS:**
- Total Lines: ~1,500
- Swift Files: 6+
- Views: 4+
- Models: 2+

**Documentation:**
- Markdown Files: 5+
- Total Lines: ~2,000

---

## 🔄 File Update Frequency

| File | Update Frequency |
|------|------------------|
| `main.py` | High - New endpoints |
| Services | Medium - Feature additions |
| Models | Low - Stable structure |
| Config | Low - Settings changes |
| Documentation | Medium - Keep updated |

---

**Last Updated**: 2024-11-18

**Maintained By**: AI Closet Scanner Team
