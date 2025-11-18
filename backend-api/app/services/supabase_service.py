"""
Supabase Storage Service

Uses Supabase REST API (HTTPS) instead of direct PostgreSQL connection.
More reliable and works through firewalls.
"""

import logging
from supabase import create_client, Client
from app.config import settings
import os

logger = logging.getLogger(__name__)


class SupabaseService:
    """Service for storing clothing items in Supabase via REST API"""

    def __init__(self):
        try:
            # Get credentials from environment
            supabase_url = os.getenv("SUPABASE_URL", "https://cnnobgvxdpevzxjfoprs.supabase.co")
            supabase_key = os.getenv("SUPABASE_KEY", "")

            if not supabase_key:
                logger.warning("⚠️  Supabase key not found, storage disabled")
                self.enabled = False
                return

            # Create Supabase client (uses HTTPS REST API)
            self.client: Client = create_client(supabase_url, supabase_key)
            self.table_name = "clothing_items"
            self.enabled = True

            logger.info(f"☁️  Supabase storage initialized (REST API)")

        except Exception as e:
            logger.error(f"❌ Failed to initialize Supabase: {e}")
            self.enabled = False

    def save_item(self, item_data: dict) -> bool:
        """
        Save a clothing item to Supabase.

        Args:
            item_data: Dict with item fields

        Returns:
            True if successful
        """
        if not self.enabled:
            return False

        try:
            # Insert or update (upsert)
            response = self.client.table(self.table_name).upsert(item_data).execute()

            logger.info(f"💾 Saved item to Supabase: {item_data.get('id')}")
            return True

        except Exception as e:
            logger.error(f"❌ Supabase save error: {e}")
            return False

    def get_user_items(self, user_id: str) -> list:
        """
        Get all items for a user.

        Args:
            user_id: User identifier

        Returns:
            List of clothing items
        """
        if not self.enabled:
            return []

        try:
            response = self.client.table(self.table_name)\
                .select("*")\
                .eq("user_id", user_id)\
                .order("created_at", desc=True)\
                .execute()

            items = response.data if response.data else []
            logger.info(f"📦 Fetched {len(items)} items from Supabase for user {user_id}")
            return items

        except Exception as e:
            logger.error(f"❌ Supabase fetch error: {e}")
            return []


# Global instance
supabase_service = SupabaseService()
