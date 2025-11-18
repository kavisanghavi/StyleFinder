# 🚀 Daytona Integration Guide
## AI Closet Scanner - Complete Setup & Deployment

This guide covers everything you need to know about deploying and developing AI Closet Scanner using **Daytona**, the open-source Development Environment Manager.

---

## 📋 Table of Contents

1. [What is Daytona?](#what-is-daytona)
2. [Why Use Daytona?](#why-use-daytona)
3. [Prerequisites](#prerequisites)
4. [Quick Start](#quick-start)
5. [Local Development](#local-development)
6. [Cloud Deployment](#cloud-deployment)
7. [Configuration](#configuration)
8. [Daytona Commands](#daytona-commands)
9. [Environment Variables & Secrets](#environment-variables--secrets)
10. [Troubleshooting](#troubleshooting)
11. [Best Practices](#best-practices)

---

## 🎯 What is Daytona?

**Daytona** is an open-source Development Environment Manager (DEM) that provides:

- **Instant Setup** - One command to create fully configured development environments
- **Standardization** - Everyone on your team uses the exact same environment
- **Devcontainer Support** - Compatible with VS Code and other IDEs
- **Self-Hosted or Cloud** - Deploy locally or on cloud infrastructure
- **Zero DevOps** - No complex Kubernetes or Docker knowledge required
- **Secure** - Perfect for running AI-generated code safely

**Daytona API**: `https://app.daytona.io/api`

---

## ✨ Why Use Daytona?

### For This Project

| Traditional Setup | With Daytona |
|-------------------|--------------|
| 30-60 min setup time | **2 min** one-command setup |
| "Works on my machine" issues | **100% consistent** environments |
| Manual API key configuration | **Secure secrets** management |
| Complex deployment | **One-click** deployment |
| Manual dependency management | **Automatic** installation |

### Key Benefits

1. **Hackathon Ready** - Demo your project instantly without setup
2. **Team Collaboration** - Share workspaces with teammates
3. **Public URLs** - Get HTTPS URLs automatically for iOS app integration
4. **Auto-Restart** - Server crashes? Daytona restarts automatically
5. **Resource Management** - Automatic CPU/memory allocation
6. **Built-in Monitoring** - Health checks and metrics out of the box

---

## 📦 Prerequisites

### Required

- **Git** - Version control
- **GitHub Account** - For repository access
- **Daytona Account** - Sign up at [daytona.io](https://www.daytona.io/)

### Optional (for local development)

- **Docker** - For local devcontainer support
- **VS Code** - Recommended IDE with devcontainer extension

### API Keys

You'll need API keys from:

1. **Anthropic Claude**: https://console.anthropic.com/
2. **ElevenLabs**: https://elevenlabs.io/
3. **Google Gemini**: https://makersuite.google.com/app/apikey
4. **Tigris Storage**: https://console.tigris.dev/
5. **Galileo**: https://console.galileo.ai/

---

## 🚀 Quick Start

### Method 1: Daytona Web Dashboard (Easiest)

1. **Login to Daytona**
   ```
   Visit: https://app.daytona.io/
   Sign in with GitHub
   ```

2. **Create New Workspace**
   ```
   Click "New Workspace"
   Repository: https://github.com/your-username/StyleFinder
   Name: ai-closet-scanner
   ```

3. **Configure Secrets** (in Daytona dashboard)
   ```
   Settings → Secrets → Add Secret

   Add these secrets:
   - ANTHROPIC_API_KEY
   - ELEVENLABS_API_KEY
   - GEMINI_API_KEY
   - TIGRIS_ACCESS_KEY
   - TIGRIS_SECRET_KEY
   - GALILEO_API_KEY
   ```

4. **Start Workspace**
   ```
   Click "Start Workspace"
   Wait 2-3 minutes for initial build
   ```

5. **Get Your Public URL**
   ```
   Your backend will be available at:
   https://ai-closet-scanner-[random].daytona.app
   ```

6. **Update iOS App**
   ```swift
   // In ClosetAI/Services/APIClient.swift
   private let baseURL = "https://ai-closet-scanner-[random].daytona.app"
   ```

---

## 💻 Local Development

### Using Daytona CLI

1. **Install Daytona CLI**
   ```bash
   # macOS/Linux
   curl -sf https://download.daytona.io/daytona/install.sh | sh

   # Verify installation
   daytona version
   ```

2. **Login**
   ```bash
   daytona login
   # Follow prompts to authenticate
   ```

3. **Create Workspace**
   ```bash
   # From GitHub
   daytona create https://github.com/your-username/StyleFinder

   # Or from local directory
   cd /path/to/StyleFinder
   daytona create .
   ```

4. **Open in IDE**
   ```bash
   # Open in VS Code
   daytona code ai-closet-scanner

   # Or SSH into workspace
   daytona ssh ai-closet-scanner
   ```

5. **Start Backend**
   ```bash
   # Inside workspace
   cd backend-api
   ./start.sh
   ```

### Using VS Code Devcontainer (Without Daytona)

1. **Install Docker Desktop**
   ```bash
   # Download from: https://www.docker.com/products/docker-desktop
   ```

2. **Install VS Code Extensions**
   - Dev Containers (ms-vscode-remote.remote-containers)
   - Python (ms-python.python)

3. **Open in Container**
   ```
   1. Open StyleFinder folder in VS Code
   2. Press F1 → "Dev Containers: Reopen in Container"
   3. Wait for container to build (first time: 5-10 min)
   4. Terminal opens inside container automatically
   ```

4. **Start Backend**
   ```bash
   cd backend-api
   ./start.sh
   ```

---

## ☁️ Cloud Deployment

### Deploy to Daytona Cloud

1. **Prepare Repository**
   ```bash
   # Ensure all files are committed
   git add .
   git commit -m "Add Daytona configuration"
   git push origin main
   ```

2. **Create Cloud Workspace**
   ```bash
   daytona create --target cloud https://github.com/your-username/StyleFinder
   ```

3. **Configure Environment**
   ```bash
   # Set environment variables via CLI
   daytona env set ANTHROPIC_API_KEY=sk-ant-api03-xxx
   daytona env set ELEVENLABS_API_KEY=xxx
   daytona env set GEMINI_API_KEY=xxx
   # ... (set all required keys)
   ```

4. **Start Services**
   ```bash
   # Start backend
   daytona exec -- cd backend-api && ./start.sh

   # Or use Daytona command
   daytona run start
   ```

5. **Get Public URL**
   ```bash
   daytona url ai-closet-scanner

   # Output: https://ai-closet-scanner-abc123.daytona.app
   ```

6. **Monitor Status**
   ```bash
   # Check workspace status
   daytona list

   # View logs
   daytona logs ai-closet-scanner

   # Open dashboard
   open https://ai-closet-scanner-abc123.daytona.app/dashboard
   ```

---

## ⚙️ Configuration

### Daytona Config File

The main configuration is in `.daytona/config.yaml`:

```yaml
workspace:
  name: ai-closet-scanner
  description: "AI-powered wardrobe management"

daytona:
  api_url: "https://app.daytona.io/api"

ports:
  - port: 8000
    visibility: public

commands:
  start: |
    cd backend-api
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Devcontainer Config

Located in `.devcontainer/devcontainer.json`:

```json
{
  "name": "AI Closet Scanner",
  "dockerFile": "Dockerfile",
  "forwardPorts": [8000],
  "postCreateCommand": "bash .devcontainer/post-create.sh"
}
```

### Environment Variables

Set these in Daytona dashboard or via CLI:

**Required:**
```bash
ANTHROPIC_API_KEY=sk-ant-api03-xxx
ELEVENLABS_API_KEY=xxx
GEMINI_API_KEY=xxx
TIGRIS_ACCESS_KEY=tid_xxx
TIGRIS_SECRET_KEY=tsec_xxx
GALILEO_API_KEY=xxx
```

**Optional:**
```bash
BREX_API_KEY=xxx
WEATHER_API_KEY=xxx
CLOUDINARY_API_KEY=xxx
REMOVEBG_API_KEY=xxx
```

---

## 🔧 Daytona Commands

### Workspace Management

```bash
# List all workspaces
daytona list

# Create workspace
daytona create <repo-url>

# Start workspace
daytona start ai-closet-scanner

# Stop workspace
daytona stop ai-closet-scanner

# Delete workspace
daytona delete ai-closet-scanner

# Get workspace info
daytona info ai-closet-scanner
```

### Development Commands

```bash
# Open in VS Code
daytona code ai-closet-scanner

# SSH into workspace
daytona ssh ai-closet-scanner

# Execute command
daytona exec ai-closet-scanner -- <command>

# View logs
daytona logs ai-closet-scanner

# Follow logs
daytona logs -f ai-closet-scanner
```

### Custom Commands (from config.yaml)

```bash
# Run setup
daytona run setup

# Start backend
daytona run start

# Start in production mode
daytona run start:prod

# Run tests
daytona run test

# View workspace info
daytona run info

# Open dashboard
daytona run dashboard
```

### Environment & Secrets

```bash
# Set environment variable
daytona env set KEY=value

# List environment variables
daytona env list

# Remove environment variable
daytona env unset KEY

# Set secret (encrypted)
daytona secret set SECRET_KEY value

# List secrets
daytona secret list
```

### Networking

```bash
# Get public URL
daytona url ai-closet-scanner

# Port forward
daytona port-forward ai-closet-scanner 8000:8000

# List open ports
daytona ports ai-closet-scanner
```

---

## 🔐 Environment Variables & Secrets

### Setting Secrets via Dashboard

1. **Navigate to Workspace Settings**
   ```
   Daytona Dashboard → Workspaces → ai-closet-scanner → Settings
   ```

2. **Add Secrets**
   ```
   Secrets Tab → Add Secret

   Name: ANTHROPIC_API_KEY
   Value: sk-ant-api03-xxx
   [✓] Encrypt this secret
   ```

3. **Verify Secrets**
   ```bash
   daytona secret list
   ```

### Setting Secrets via CLI

```bash
# Add secret
daytona secret set ANTHROPIC_API_KEY sk-ant-api03-xxx

# Add multiple secrets
daytona secret set \
  ELEVENLABS_API_KEY=xxx \
  GEMINI_API_KEY=xxx \
  TIGRIS_ACCESS_KEY=tid_xxx

# Verify
daytona secret list
```

### Loading from .env File

```bash
# Copy .env.example to .env
cp backend-api/.env.example backend-api/.env

# Edit .env with your keys
nano backend-api/.env

# Upload to Daytona
daytona env load backend-api/.env
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. "Workspace failed to start"

**Solution:**
```bash
# Check logs
daytona logs ai-closet-scanner

# Rebuild workspace
daytona rebuild ai-closet-scanner

# If still fails, delete and recreate
daytona delete ai-closet-scanner
daytona create https://github.com/your-username/StyleFinder
```

#### 2. "Port 8000 already in use"

**Solution:**
```bash
# Kill existing process
daytona exec -- lsof -ti:8000 | xargs kill -9

# Or restart workspace
daytona restart ai-closet-scanner
```

#### 3. "Missing API keys"

**Solution:**
```bash
# Verify secrets are set
daytona secret list

# Set missing secrets
daytona secret set ANTHROPIC_API_KEY sk-ant-api03-xxx

# Restart workspace
daytona restart ai-closet-scanner
```

#### 4. "Cannot connect to backend from iOS app"

**Solution:**
```bash
# Get public URL
daytona url ai-closet-scanner

# Verify backend is running
curl $(daytona url ai-closet-scanner)/health

# Update iOS app with correct URL
# File: ClosetAI/Services/APIClient.swift
```

#### 5. "Dependencies not installing"

**Solution:**
```bash
# SSH into workspace
daytona ssh ai-closet-scanner

# Manually install
cd backend-api
pip install -r requirements.txt

# Or run setup command
daytona run setup
```

### Health Checks

```bash
# Check workspace status
daytona info ai-closet-scanner

# Check backend health
curl $(daytona url ai-closet-scanner)/health

# View metrics dashboard
open $(daytona url ai-closet-scanner)/dashboard

# Check Python version
daytona exec -- python3 --version

# Check installed packages
daytona exec -- pip list
```

### Getting Help

```bash
# Daytona help
daytona --help

# Command-specific help
daytona create --help

# View documentation
daytona docs

# Check version
daytona version
```

---

## 🎯 Best Practices

### Development Workflow

1. **Use Branches**
   ```bash
   git checkout -b feature/new-feature
   daytona create . --branch feature/new-feature
   ```

2. **Commit Often**
   ```bash
   # Changes persist in workspace
   git add .
   git commit -m "Add feature"
   git push
   ```

3. **Test Locally First**
   ```bash
   # Test in local devcontainer
   # Then deploy to Daytona cloud
   daytona create --target cloud .
   ```

### Security

1. **Never Commit Secrets**
   ```bash
   # Always use Daytona secrets management
   # Never add API keys to .env in git
   ```

2. **Use Environment-Specific Configs**
   ```bash
   # Development
   ENVIRONMENT=development

   # Production
   ENVIRONMENT=production
   ```

3. **Rotate Keys Regularly**
   ```bash
   # Update secrets periodically
   daytona secret set ANTHROPIC_API_KEY new-key-xxx
   ```

### Performance

1. **Use Prebuilds**
   ```yaml
   # In .daytona/config.yaml
   commands:
     prebuild: |
       pip install -r backend-api/requirements.txt
   ```

2. **Cache Dependencies**
   ```yaml
   volumes:
     - type: volume
       source: python-packages
       target: /usr/local/lib/python3.11/site-packages
   ```

3. **Optimize Resources**
   ```yaml
   resources:
     cpu: "2"      # Adjust based on load
     memory: "4Gi"  # Increase if needed
   ```

### Collaboration

1. **Share Workspaces**
   ```bash
   # Invite team member
   daytona share ai-closet-scanner --email team@example.com
   ```

2. **Use Git**
   ```bash
   # All team members work from same repo
   # Daytona handles environment consistency
   ```

3. **Document Changes**
   ```bash
   # Update this file with any config changes
   # Keep DAYTONA_SETUP.md current
   ```

---

## 📚 Additional Resources

### Documentation

- **Daytona Docs**: https://www.daytona.io/docs
- **Devcontainer Spec**: https://containers.dev/
- **FastAPI Docs**: https://fastapi.tiangolo.com/

### Support

- **Daytona GitHub**: https://github.com/daytonaio/daytona
- **Daytona Discord**: https://discord.gg/daytona
- **Project Issues**: https://github.com/your-username/StyleFinder/issues

### Example Commands

```bash
# Complete deployment from scratch
daytona create --target cloud https://github.com/your-username/StyleFinder
daytona secret set ANTHROPIC_API_KEY=xxx ELEVENLABS_API_KEY=xxx GEMINI_API_KEY=xxx
daytona run start
daytona url ai-closet-scanner

# Daily development
daytona start ai-closet-scanner
daytona code ai-closet-scanner
# Make changes, test, commit
daytona logs -f ai-closet-scanner

# Demo for hackathon
daytona url ai-closet-scanner
# Share URL with judges
open $(daytona url ai-closet-scanner)/dashboard
```

---

## 🎉 You're All Set!

Your AI Closet Scanner is now running on Daytona! Here's what you have:

- ✅ Fully configured development environment
- ✅ Public HTTPS URL for your backend API
- ✅ Automatic dependency management
- ✅ Secure secrets storage
- ✅ Built-in monitoring and health checks
- ✅ One-command deployment
- ✅ Team collaboration ready

**Next Steps:**

1. Update iOS app with your Daytona backend URL
2. Test all API endpoints
3. Check the metrics dashboard
4. Share with your team or judges

**Happy Hacking! 🚀**

---

*Last Updated: 2024*
*For issues or questions, open an issue on GitHub*
