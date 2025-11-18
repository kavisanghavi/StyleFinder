"""
ElevenLabs Text-to-Speech Service

This service handles voice generation for outfit recommendations
and style advice using ElevenLabs' high-quality TTS API.

Features:
- Natural-sounding voice recommendations
- Multi-language support
- Streaming audio generation
"""

import logging
from typing import Optional
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class ElevenLabsService:
    """
    Service wrapper for ElevenLabs Text-to-Speech API.

    This class generates natural-sounding voice recommendations
    for outfit suggestions and styling advice.
    """

    def __init__(self):
        """Initialize the ElevenLabs service with API configuration."""
        try:
            from elevenlabs import generate, set_api_key, Voice, VoiceSettings

            # Set API key
            set_api_key(settings.ELEVENLABS_API_KEY)

            self.generate = generate
            self.Voice = Voice
            self.VoiceSettings = VoiceSettings
            self.voice_id = settings.ELEVENLABS_VOICE_ID
            self.model = settings.ELEVENLABS_MODEL

            logger.info(f"🗣️  ElevenLabs service initialized with voice: {self.voice_id}")
            self.enabled = True

        except ImportError:
            logger.warning("⚠️  ElevenLabs library not installed - TTS disabled")
            self.enabled = False
        except Exception as e:
            logger.warning(f"⚠️  Failed to initialize ElevenLabs: {e}")
            self.enabled = False

    @trace(name="elevenlabs_tts")
    async def text_to_speech(
        self,
        text: str,
        voice_id: Optional[str] = None,
        stability: float = 0.5,
        similarity_boost: float = 0.75,
        style: float = 0.0,
        use_speaker_boost: bool = True
    ) -> bytes:
        """
        Convert text to speech using ElevenLabs API.

        Args:
            text: The text to convert to speech
            voice_id: Optional voice ID (uses default if not provided)
            stability: Voice stability (0.0 to 1.0)
            similarity_boost: Clarity/similarity (0.0 to 1.0)
            style: Style exaggeration (0.0 to 1.0)
            use_speaker_boost: Whether to use speaker boost

        Returns:
            Audio data as bytes (MP3 format)

        Raises:
            Exception: If TTS is not enabled or API call fails
        """
        if not self.enabled:
            raise Exception("ElevenLabs service is not available")

        logger.info(f"🎤 Generating speech for text (length: {len(text)} chars)...")

        try:
            # Use provided voice_id or default
            selected_voice = voice_id or self.voice_id

            # Generate audio with custom settings
            audio = self.generate(
                text=text,
                voice=self.Voice(
                    voice_id=selected_voice,
                    settings=self.VoiceSettings(
                        stability=stability,
                        similarity_boost=similarity_boost,
                        style=style,
                        use_speaker_boost=use_speaker_boost
                    )
                ),
                model=self.model
            )

            # Convert generator to bytes if necessary
            if hasattr(audio, '__iter__') and not isinstance(audio, bytes):
                audio_bytes = b''.join(audio)
            else:
                audio_bytes = audio

            logger.info(f"✅ Generated {len(audio_bytes)} bytes of audio")

            return audio_bytes

        except Exception as e:
            logger.error(f"❌ ElevenLabs TTS error: {e}")
            raise

    @trace(name="elevenlabs_outfit_recommendation")
    async def create_outfit_recommendation_audio(
        self,
        outfit_description: str,
        style_tips: str,
        make_it_conversational: bool = True
    ) -> bytes:
        """
        Create a voice recommendation for an outfit.

        This method combines outfit description and style tips into
        a natural-sounding voice recommendation.

        Args:
            outfit_description: Description of the outfit
            style_tips: Styling advice
            make_it_conversational: Whether to add conversational elements

        Returns:
            Audio data as bytes
        """
        logger.info("👗 Creating outfit recommendation audio...")

        # Build the script
        if make_it_conversational:
            script = f"""Hey! I've got a great outfit idea for you.

{outfit_description}

Here's my styling tip: {style_tips}

You're going to look amazing!"""
        else:
            script = f"{outfit_description}\n\n{style_tips}"

        # Generate audio
        return await self.text_to_speech(
            text=script,
            stability=0.6,  # Slightly more stable for recommendations
            similarity_boost=0.8,  # Clear speech
            style=0.3  # Slight style for personality
        )

    @trace(name="elevenlabs_quick_tip")
    async def create_quick_tip_audio(
        self,
        tip_text: str
    ) -> bytes:
        """
        Create audio for a quick styling tip.

        Args:
            tip_text: The tip text

        Returns:
            Audio data as bytes
        """
        logger.info("💡 Creating quick tip audio...")

        script = f"Quick tip: {tip_text}"

        return await self.text_to_speech(
            text=script,
            stability=0.7,
            similarity_boost=0.75
        )

    def get_available_voices(self) -> list:
        """
        Get list of available voices (if API supports it).

        Returns:
            List of available voice IDs and names
        """
        # This is a placeholder - actual implementation would query the API
        return [
            {"id": "EXAVITQu4vr4xnSDxMaL", "name": "Bella"},
            {"id": "21m00Tcm4TlvDq8ikWAM", "name": "Rachel"},
            {"id": "AZnzlk1XvdvUeBnXmlld", "name": "Domi"},
        ]


# Global instance
elevenlabs_service = ElevenLabsService()
