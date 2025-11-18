"""
Claude AI Service (Anthropic)

This service handles all interactions with Anthropic's Claude API for:
- Clothing item analysis using vision capabilities
- Outfit generation based on wardrobe and context
- Style recommendations

Claude is the brain of the outfit recommendation system.
"""

import anthropic
import json
import logging
from typing import List, Dict, Optional, Any
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class ClaudeService:
    """
    Service wrapper for Anthropic Claude API.

    This class provides methods for analyzing clothing items and generating
    outfit recommendations using Claude's vision and text capabilities.
    """

    def __init__(self):
        """Initialize the Claude client with API key from settings."""
        self.client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        self.model = settings.CLAUDE_MODEL
        logger.info(f"🤖 Claude service initialized with model: {self.model}")

    @trace(name="claude_analyze_clothing")
    async def analyze_clothing(
        self,
        image_base64: str,
        content_type: str = "image/jpeg"
    ) -> Dict[str, Any]:
        """
        Analyze a clothing item using Claude's vision capabilities.

        This method sends an image to Claude and receives a detailed analysis
        including type, color, pattern, style, seasonality, and pairing suggestions.

        Args:
            image_base64: Base64-encoded image data
            content_type: MIME type of the image (image/jpeg, image/png, etc.)

        Returns:
            Dict containing:
                - type: Clothing category (shirt, pants, dress, etc.)
                - color: Primary color
                - pattern: Pattern description (solid, striped, etc.)
                - style: Style category (casual, formal, etc.)
                - season: List of suitable seasons
                - pairs_well_with: List of complementary items
                - confidence: Analysis confidence score

        Raises:
            anthropic.APIError: If the API call fails
            json.JSONDecodeError: If Claude's response is not valid JSON
        """
        logger.info("🔍 Analyzing clothing item with Claude...")

        # Construct the analysis prompt
        analysis_prompt = """Analyze this image and identify ALL clothing items visible.

IMPORTANT: If multiple items are visible, return an array with each item separately!

Your JSON response must have this exact structure:

If ONE item:
{
    "items": [
        {
            "type": "shirt/pants/dress/jacket/shoes/accessory/etc",
            "color": "primary color name",
            "pattern": "solid/striped/floral/checkered/polka-dot/geometric/etc",
            "style": "casual/formal/athletic/business-casual/elegant/bohemian/etc",
            "season": ["spring", "summer", "fall", "winter"],
            "pairs_well_with": ["list of clothing types that would match well"],
            "confidence": 0.95,
            "material": "cotton/polyester/silk/denim/leather/etc (if visible)",
            "occasion": ["work", "casual", "formal", "party", "sports", "etc"],
            "care_instructions": "general care recommendations"
        }
    ]
}

If MULTIPLE items (e.g., red shirt + green shirt):
{
    "items": [
        {
            "type": "shirt",
            "color": "red",
            "pattern": "solid",
            ...
        },
        {
            "type": "shirt",
            "color": "green",
            "pattern": "solid",
            ...
        }
    ]
}

Be specific and detailed. Extract EVERY visible clothing item separately. Only respond with the JSON object."""

        try:
            # Make API call to Claude
            message = self.client.messages.create(
                model=self.model,
                max_tokens=1500,
                messages=[
                    {
                        "role": "user",
                        "content": [
                            {
                                "type": "image",
                                "source": {
                                    "type": "base64",
                                    "media_type": content_type,
                                    "data": image_base64,
                                },
                            },
                            {
                                "type": "text",
                                "text": analysis_prompt
                            }
                        ],
                    }
                ],
            )

            # Extract and parse the JSON response
            response_text = message.content[0].text
            logger.debug(f"Claude response: {response_text}")

            # Strip markdown code blocks if present
            if response_text.strip().startswith("```"):
                # Remove ```json and ``` markers
                response_text = response_text.strip()
                if response_text.startswith("```json"):
                    response_text = response_text[7:]  # Remove ```json
                elif response_text.startswith("```"):
                    response_text = response_text[3:]  # Remove ```
                if response_text.endswith("```"):
                    response_text = response_text[:-3]  # Remove trailing ```
                response_text = response_text.strip()

            # Parse JSON
            analysis = json.loads(response_text)

            # Handle both old single-item format and new multi-item format
            if 'items' in analysis:
                items = analysis['items']
                logger.info(f"✅ Successfully analyzed {len(items)} item(s)")
                # Return first item for backward compatibility, but include all in response
                if items:
                    result = items[0].copy()
                    result['all_items'] = items  # Include all items for batch processing
                    result['item_count'] = len(items)
                    return result
                else:
                    raise ValueError("No items found in image")
            else:
                # Old format - single item
                logger.info(f"✅ Successfully analyzed: {analysis.get('type')} ({analysis.get('color')})")
                return analysis

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse Claude response as JSON: {e}")
            logger.error(f"Raw response: {response_text}")
            raise ValueError(f"Claude returned invalid JSON: {e}")

        except anthropic.APIError as e:
            logger.error(f"❌ Claude API error: {e}")
            raise

    @trace(name="claude_generate_outfit")
    async def generate_outfit(
        self,
        wardrobe_items: List[Dict],
        occasion: str,
        weather: Optional[Dict] = None,
        preferences: Optional[Dict] = None,
        color_preference: Optional[str] = None,
        weather_context: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Generate outfit suggestions based on wardrobe and context.

        This method uses Claude to select items from the user's wardrobe
        that work well together for the given occasion and weather.

        Args:
            wardrobe_items: List of clothing items with their attributes
            occasion: The occasion/event (e.g., "work", "date night", "gym")
            weather: Optional weather data (temperature, condition)
            preferences: Optional user style preferences
            color_preference: Optional preferred color scheme

        Returns:
            Dict containing:
                - items: List of selected items with reasoning
                - reasoning: Overall outfit explanation
                - style_tips: Additional styling advice
                - alternatives: Alternative item suggestions

        Raises:
            anthropic.APIError: If the API call fails
            ValueError: If the response cannot be parsed
        """
        logger.info(f"👔 Generating outfit for occasion: {occasion}")

        # Build wardrobe description
        wardrobe_description = "\n".join([
            f"- Item {i+1}: {item.get('type', 'unknown')} - "
            f"{item.get('color', 'unknown')}, "
            f"{item.get('style', 'unknown')}, "
            f"Pattern: {item.get('pattern', 'solid')} "
            f"(ID: {item.get('id', f'item_{i}')})"
            for i, item in enumerate(wardrobe_items)
        ])

        # Build context
        weather_info = ""
        if weather_context:
            weather_info = f"\nWeather: {weather_context}"
        elif weather:
            temp = weather.get('temperature', 'N/A')
            condition = weather.get('condition', 'N/A')
            weather_info = f"\nWeather: {temp}°F, {condition}"

        preferences_context = ""
        if preferences:
            preferences_context = f"\nUser preferences: {json.dumps(preferences)}"

        color_context = ""
        if color_preference:
            color_context = f"\nPreferred color scheme: {color_preference}"

        # Construct the prompt
        outfit_prompt = f"""Based on the following wardrobe, create a complete outfit recommendation.

WARDROBE:
{wardrobe_description}

OCCASION: {occasion}
{weather_info}
{preferences_context}
{color_context}

Create an outfit that:
1. Is appropriate for the occasion
2. Matches the weather (if provided)
3. Has good color coordination
4. Follows current fashion principles
5. Reflects the user's style preferences

Respond with ONLY a JSON object:
{{
    "items": [
        {{
            "type": "item type from wardrobe",
            "id": "item_id from wardrobe",
            "reasoning": "why this specific item was chosen"
        }}
    ],
    "reasoning": "overall explanation of why these items work together",
    "style_tips": "additional advice on how to wear/style this outfit",
    "color_harmony": "explanation of the color coordination",
    "alternatives": [
        {{
            "type": "item type",
            "id": "alternative_item_id",
            "reason": "when to use this instead"
        }}
    ]
}}

Only respond with the JSON object."""

        try:
            # Make API call to Claude
            message = self.client.messages.create(
                model=self.model,
                max_tokens=2000,
                messages=[
                    {
                        "role": "user",
                        "content": outfit_prompt
                    }
                ],
            )

            # Parse response
            response_text = message.content[0].text
            logger.debug(f"Claude outfit response: {response_text}")

            outfit = json.loads(response_text)

            logger.info(f"✅ Generated outfit with {len(outfit.get('items', []))} items")

            return outfit

        except json.JSONDecodeError as e:
            logger.error(f"❌ Failed to parse outfit response as JSON: {e}")
            logger.error(f"Raw response: {response_text}")
            raise ValueError(f"Claude returned invalid JSON: {e}")

        except anthropic.APIError as e:
            logger.error(f"❌ Claude API error: {e}")
            raise

    @trace(name="claude_style_advice")
    async def get_style_advice(
        self,
        outfit_description: str,
        user_profile: Optional[Dict] = None
    ) -> str:
        """
        Get style advice for a specific outfit or wardrobe.

        Args:
            outfit_description: Description of the outfit or wardrobe question
            user_profile: Optional user profile information

        Returns:
            Style advice as a string
        """
        logger.info("💬 Getting style advice from Claude...")

        profile_context = ""
        if user_profile:
            profile_context = f"\nUser profile: {json.dumps(user_profile)}"

        prompt = f"""You are a professional fashion stylist. Provide helpful, practical style advice.

QUESTION/OUTFIT:
{outfit_description}
{profile_context}

Provide clear, actionable styling advice in 2-3 paragraphs. Be specific and helpful."""

        try:
            message = self.client.messages.create(
                model=self.model,
                max_tokens=1000,
                messages=[
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
            )

            advice = message.content[0].text
            logger.info("✅ Style advice generated")

            return advice

        except anthropic.APIError as e:
            logger.error(f"❌ Claude API error: {e}")
            raise


# Global instance
claude_service = ClaudeService()
