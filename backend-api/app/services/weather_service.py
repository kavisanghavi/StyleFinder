"""
Weather Service

Fetches weather data to provide context-aware outfit recommendations.
Uses OpenWeatherMap API for accurate weather forecasting.
"""

import logging
import httpx
from typing import Optional
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class WeatherService:
    """
    Service for fetching weather data to enhance outfit recommendations.
    """

    def __init__(self):
        """Initialize weather service."""
        # You can use OpenWeatherMap or any weather API
        # For demo, we'll use a free tier API
        self.api_key = getattr(settings, 'WEATHER_API_KEY', None)
        self.base_url = "https://api.openweathermap.org/data/2.5"
        self.enabled = bool(self.api_key)

        if self.enabled:
            logger.info("🌤️  Weather service initialized")
        else:
            logger.warning("⚠️  Weather API key not found - using mock data")

    @trace(name="weather_fetch")
    async def get_current_weather(
        self,
        city: str = "San Francisco",
        units: str = "imperial"  # imperial = Fahrenheit, metric = Celsius
    ) -> dict:
        """
        Get current weather for a city.

        Args:
            city: City name
            units: imperial (F) or metric (C)

        Returns:
            Weather data dictionary
        """
        if not self.enabled:
            # Return mock data for demo
            return self._get_mock_weather(city)

        try:
            logger.info(f"🌍 Fetching weather for {city}...")

            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/weather",
                    params={
                        "q": city,
                        "appid": self.api_key,
                        "units": units
                    },
                    timeout=10.0
                )

                if response.status_code != 200:
                    logger.error(f"Weather API error: {response.status_code}")
                    return self._get_mock_weather(city)

                data = response.json()

                weather_data = {
                    "temperature": round(data["main"]["temp"]),
                    "feels_like": round(data["main"]["feels_like"]),
                    "condition": data["weather"][0]["main"],
                    "description": data["weather"][0]["description"],
                    "humidity": data["main"]["humidity"],
                    "wind_speed": round(data["wind"]["speed"]),
                    "city": data["name"],
                    "icon": data["weather"][0]["icon"]
                }

                logger.info(f"✅ Weather fetched: {weather_data['temperature']}°F, {weather_data['condition']}")
                return weather_data

        except Exception as e:
            logger.error(f"❌ Weather fetch error: {e}")
            return self._get_mock_weather(city)

    @trace(name="weather_forecast")
    async def get_forecast(
        self,
        city: str = "San Francisco",
        days: int = 3,
        units: str = "imperial"
    ) -> list:
        """
        Get weather forecast for next few days.

        Args:
            city: City name
            days: Number of days to forecast
            units: imperial or metric

        Returns:
            List of daily forecasts
        """
        if not self.enabled:
            return self._get_mock_forecast(city, days)

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/forecast",
                    params={
                        "q": city,
                        "appid": self.api_key,
                        "units": units,
                        "cnt": days * 8  # 8 forecasts per day (3-hour intervals)
                    },
                    timeout=10.0
                )

                if response.status_code != 200:
                    return self._get_mock_forecast(city, days)

                data = response.json()

                # Group by day and get average
                forecasts = []
                for i in range(days):
                    day_data = data["list"][i * 8] if i * 8 < len(data["list"]) else data["list"][-1]
                    forecasts.append({
                        "date": day_data["dt_txt"].split()[0],
                        "temperature": round(day_data["main"]["temp"]),
                        "condition": day_data["weather"][0]["main"],
                        "description": day_data["weather"][0]["description"]
                    })

                return forecasts

        except Exception as e:
            logger.error(f"Forecast error: {e}")
            return self._get_mock_forecast(city, days)

    def _get_mock_weather(self, city: str) -> dict:
        """Return mock weather data for demo."""
        return {
            "temperature": 72,
            "feels_like": 68,
            "condition": "Clear",
            "description": "clear sky",
            "humidity": 45,
            "wind_speed": 8,
            "city": city,
            "icon": "01d"
        }

    def _get_mock_forecast(self, city: str, days: int) -> list:
        """Return mock forecast data for demo."""
        mock_conditions = ["Clear", "Cloudy", "Rain"]
        return [
            {
                "date": f"2024-11-{18 + i}",
                "temperature": 70 + (i * 2),
                "condition": mock_conditions[i % len(mock_conditions)],
                "description": f"{mock_conditions[i % len(mock_conditions)].lower()} sky"
            }
            for i in range(days)
        ]

    def get_outfit_suggestion_context(self, weather_data: dict) -> str:
        """
        Generate context string for outfit suggestions based on weather.

        Args:
            weather_data: Weather data dictionary

        Returns:
            Context string for Claude
        """
        temp = weather_data["temperature"]
        condition = weather_data["condition"]

        # Temperature-based suggestions
        if temp < 40:
            temp_advice = "very cold weather - recommend warm layers, coat, scarf"
        elif temp < 60:
            temp_advice = "cool weather - recommend light jacket or sweater"
        elif temp < 75:
            temp_advice = "mild weather - comfortable temperature for most outfits"
        elif temp < 85:
            temp_advice = "warm weather - recommend light, breathable fabrics"
        else:
            temp_advice = "hot weather - recommend minimal, cooling clothing"

        # Condition-based suggestions
        if "rain" in condition.lower():
            condition_advice = "rainy - suggest waterproof jacket or umbrella"
        elif "snow" in condition.lower():
            condition_advice = "snowy - suggest warm, waterproof outerwear"
        elif "cloud" in condition.lower():
            condition_advice = "cloudy - versatile layering recommended"
        else:
            condition_advice = "clear - any outfit style works"

        return f"Weather: {temp}°F, {condition}. {temp_advice}. {condition_advice}."


# Global instance
weather_service = WeatherService()
