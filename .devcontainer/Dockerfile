# ============================================
# AI Closet Scanner - Development Container
# ============================================
# This Dockerfile creates a development environment with all tools needed
# for working on the AI Closet Scanner backend API

FROM mcr.microsoft.com/devcontainers/python:3.11

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build essentials
    build-essential \
    gcc \
    g++ \
    make \
    # Network tools
    curl \
    wget \
    httpie \
    # Git
    git \
    # Image processing (for Pillow)
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    # Database clients (if needed later)
    postgresql-client \
    # Utilities
    vim \
    nano \
    tree \
    jq \
    htop \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install Python development tools globally
RUN pip install --upgrade pip setuptools wheel && \
    pip install \
    black \
    pylint \
    mypy \
    pytest \
    pytest-asyncio \
    pytest-cov \
    ipython \
    httpx

# Create workspace directory
WORKDIR /workspace

# Set up convenient aliases
RUN echo 'alias ll="ls -lah"' >> /home/vscode/.bashrc && \
    echo 'alias python=python3' >> /home/vscode/.bashrc && \
    echo 'alias pip=pip3' >> /home/vscode/.bashrc && \
    echo 'export PS1="\[\e[36m\]ai-closet-scanner\[\e[m\] \[\e[33m\]\w\[\e[m\] \$ "' >> /home/vscode/.bashrc

# Create helpful welcome message
RUN echo '#!/bin/bash' > /usr/local/bin/welcome && \
    echo 'cat << "EOF"' >> /usr/local/bin/welcome && \
    echo '╔═══════════════════════════════════════════════════════════════╗' >> /usr/local/bin/welcome && \
    echo '║          🚀 AI Closet Scanner Development Environment          ║' >> /usr/local/bin/welcome && \
    echo '╚═══════════════════════════════════════════════════════════════╝' >> /usr/local/bin/welcome && \
    echo '' >> /usr/local/bin/welcome && \
    echo '  Quick Start:' >> /usr/local/bin/welcome && \
    echo '    cd backend-api && ./start.sh        # Start backend server' >> /usr/local/bin/welcome && \
    echo '' >> /usr/local/bin/welcome && \
    echo '  Useful Commands:' >> /usr/local/bin/welcome && \
    echo '    make install    # Install dependencies' >> /usr/local/bin/welcome && \
    echo '    make test       # Run tests' >> /usr/local/bin/welcome && \
    echo '    make dev        # Start development server' >> /usr/local/bin/welcome && \
    echo '' >> /usr/local/bin/welcome && \
    echo '  URLs:' >> /usr/local/bin/welcome && \
    echo '    API: http://localhost:8000' >> /usr/local/bin/welcome && \
    echo '    Docs: http://localhost:8000/docs' >> /usr/local/bin/welcome && \
    echo '    Dashboard: http://localhost:8000/dashboard' >> /usr/local/bin/welcome && \
    echo '' >> /usr/local/bin/welcome && \
    echo 'EOF' >> /usr/local/bin/welcome && \
    chmod +x /usr/local/bin/welcome

# Add welcome message to bashrc
RUN echo 'welcome' >> /home/vscode/.bashrc

# Ensure proper permissions
RUN chown -R vscode:vscode /workspace /home/vscode

# Switch to vscode user
USER vscode

# Default command
CMD ["/bin/bash"]
