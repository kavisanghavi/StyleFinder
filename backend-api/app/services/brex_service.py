"""
Brex Payment Service (Optional)

This service handles premium subscription payments through Brex.
This is optional for the hackathon MVP but demonstrates payment integration.

Features:
- Subscription management
- Payment processing
- Receipt generation
"""

import logging
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
from app.config import settings
from app.monitoring.galileo_observer import trace

logger = logging.getLogger(__name__)


class BrexService:
    """
    Service wrapper for Brex payment processing.

    This class handles premium subscription payments and billing.
    """

    def __init__(self):
        """Initialize the Brex service with API configuration."""
        if settings.BREX_API_KEY:
            # In a real implementation, initialize the Brex SDK here
            self.api_key = settings.BREX_API_KEY
            self.enabled = True
            logger.info("💳 Brex service initialized")
        else:
            self.enabled = False
            logger.info("💳 Brex service disabled (no API key)")

    @trace(name="brex_process_subscription")
    async def process_subscription(
        self,
        user_id: str,
        plan: str = "monthly",
        payment_method: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Process a premium subscription payment.

        Args:
            user_id: Unique user identifier
            plan: Subscription plan ("monthly" or "annual")
            payment_method: Payment method ID

        Returns:
            Dict containing payment confirmation details

        Raises:
            Exception: If service is not available or payment fails
        """
        if not self.enabled:
            # Return mock response for demo
            logger.warning("⚠️  Brex disabled - returning mock payment response")
            return self._mock_payment_response(user_id, plan)

        logger.info(f"💰 Processing {plan} subscription for user: {user_id}")

        # In a real implementation, this would:
        # 1. Call Brex API to process payment
        # 2. Handle payment confirmation
        # 3. Update subscription status
        # 4. Generate receipt

        # For now, return mock response
        return self._mock_payment_response(user_id, plan)

    def _mock_payment_response(
        self,
        user_id: str,
        plan: str
    ) -> Dict[str, Any]:
        """
        Generate a mock payment response for demo purposes.

        Args:
            user_id: User identifier
            plan: Subscription plan

        Returns:
            Mock payment confirmation
        """
        amounts = {
            "monthly": 9.99,
            "annual": 99.99
        }

        amount = amounts.get(plan, 9.99)

        return {
            "status": "success",
            "transaction_id": f"brex_mock_{datetime.utcnow().strftime('%Y%m%d%H%M%S')}",
            "user_id": user_id,
            "plan": plan,
            "amount": amount,
            "currency": "USD",
            "subscription_start": datetime.utcnow().isoformat(),
            "subscription_end": (
                datetime.utcnow() +
                (timedelta(days=30) if plan == "monthly" else timedelta(days=365))
            ).isoformat(),
            "payment_method": "mock",
            "receipt_url": f"https://receipts.example.com/mock_{user_id}",
            "message": "Mock payment processed successfully (demo mode)"
        }

    @trace(name="brex_cancel_subscription")
    async def cancel_subscription(
        self,
        user_id: str,
        subscription_id: str
    ) -> Dict[str, Any]:
        """
        Cancel a user's subscription.

        Args:
            user_id: User identifier
            subscription_id: Subscription ID to cancel

        Returns:
            Cancellation confirmation

        Raises:
            Exception: If service is not available or cancellation fails
        """
        logger.info(f"❌ Cancelling subscription {subscription_id} for user: {user_id}")

        return {
            "status": "cancelled",
            "subscription_id": subscription_id,
            "user_id": user_id,
            "cancelled_at": datetime.utcnow().isoformat(),
            "refund_amount": 0.00,
            "message": "Subscription cancelled successfully"
        }

    @trace(name="brex_get_subscription_status")
    async def get_subscription_status(
        self,
        user_id: str
    ) -> Dict[str, Any]:
        """
        Get current subscription status for a user.

        Args:
            user_id: User identifier

        Returns:
            Subscription status information
        """
        logger.info(f"📊 Checking subscription status for user: {user_id}")

        # Mock response
        return {
            "user_id": user_id,
            "has_active_subscription": False,
            "plan": None,
            "status": "free",
            "trial_available": True,
            "features": {
                "max_items": 50,
                "virtual_tryon": False,
                "voice_recommendations": False,
                "cloud_backup": False
            }
        }


# Global instance
brex_service = BrexService()
