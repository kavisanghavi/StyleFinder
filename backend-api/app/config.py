"""
Configuration module for AI Closet Scanner Backend API.

This module manages all environment variables and application settings
using Pydantic Settings for type safety and validation.
"""

from pydantic_settings import BaseSettings
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    """
    Application settings loaded from environment variables.

    All API keys and sensitive data should be stored in a .env file
    and never committed to version control.
    """

    # ==================== Anthropic (Claude) ====================
    ANTHROPIC_API_KEY: str
    CLAUDE_MODEL: str = "claude-sonnet-4-20250514"

    # ==================== ElevenLabs (Voice) ====================
    ELEVENLABS_API_KEY: str
    ELEVENLABS_VOICE_ID: str = "EXAVITQu4vr4xnSDxMaL"  # Bella voice
    ELEVENLABS_MODEL: str = "eleven_multilingual_v2"

    # ==================== Google Gemini (Nano Banana) ====================
    GEMINI_API_KEY: str
    GEMINI_MODEL: str = "gemini-2.0-flash-exp"

    # ==================== Tigris Storage ====================
    TIGRIS_ENDPOINT: str = "https://fly.storage.tigris.dev"
    TIGRIS_ACCESS_KEY: str
    TIGRIS_SECRET_KEY: str
    TIGRIS_BUCKET_NAME: str = "closet-scanner-backups"
    TIGRIS_REGION: str = "auto"

    # ==================== Brex (Optional) ====================
    BREX_API_KEY: Optional[str] = None

    # ==================== Galileo Observability ====================
    GALILEO_API_KEY: str
    GALILEO_PROJECT_NAME: str = "closet-scanner"

    # ==================== Application Settings ====================
    ENVIRONMENT: str = "development"
    BACKEND_URL: str = "http://localhost:8000"
    SECRET_KEY: str = "change-this-in-production"

    # API Configuration
    API_TITLE: str = "AI Closet Scanner API"
    API_DESCRIPTION: str = "Backend API for AI-powered wardrobe management"
    API_VERSION: str = "1.0.0"

    # CORS Settings
    CORS_ORIGINS: list = ["*"]  # In production, specify exact origins

    # Rate Limiting
    MAX_UPLOAD_SIZE: int = 10 * 1024 * 1024  # 10MB

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """
    Get cached settings instance.

    Using lru_cache ensures we only load the environment variables once
    and reuse the same Settings instance throughout the application.

    Returns:
        Settings: Application settings instance
    """
    return Settings()


# Global settings instance
settings = get_settings()
