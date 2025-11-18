"""
Galileo Observability Integration

This module provides comprehensive monitoring and tracing for all AI service calls.
It tracks performance metrics, token usage, latency, and errors for demo purposes.

Key Features:
- LLM call tracing with Galileo
- Real-time metrics collection
- Performance monitoring
- Error tracking
"""

from functools import wraps
import time
from typing import Dict, Any, Callable
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class GalileoObserver:
    """
    Galileo observability integration for tracking LLM calls and metrics.

    This class provides decorators for tracing function calls and collecting
    metrics for the demo dashboard.
    """

    def __init__(self):
        """Initialize the Galileo observer with empty metrics."""
        self.metrics = {
            "total_requests": 0,
            "claude_calls": 0,
            "elevenlabs_calls": 0,
            "nanobanana_calls": 0,
            "tigris_uploads": 0,
            "average_latency": 0.0,
            "total_tokens": 0,
            "errors": 0,
            "last_request_time": None,
        }
        self.call_history = []

        # Try to import and initialize Galileo
        try:
            from galileo_observe import Observer
            from app.config import settings

            self.observer = Observer(
                api_key=settings.GALILEO_API_KEY,
                project_name=settings.GALILEO_PROJECT_NAME
            )
            self.galileo_enabled = True
            logger.info("✅ Galileo observability enabled")
        except ImportError:
            logger.warning("⚠️  Galileo library not available - running without observability")
            self.galileo_enabled = False
            self.observer = None
        except Exception as e:
            logger.warning(f"⚠️  Failed to initialize Galileo: {e}")
            self.galileo_enabled = False
            self.observer = None

    def trace(self, name: str):
        """
        Decorator to trace function calls with Galileo.

        Args:
            name: Name of the trace/operation

        Returns:
            Decorator function

        Example:
            @galileo_observer.trace("claude_analyze")
            async def analyze_clothing(image):
                # Your code here
                pass
        """
        def decorator(func: Callable):
            @wraps(func)
            async def async_wrapper(*args, **kwargs):
                start_time = time.time()

                # Start Galileo trace if enabled
                trace_context = None
                if self.galileo_enabled and self.observer:
                    try:
                        trace_context = self.observer.trace(name=name)
                        trace_context.__enter__()
                    except Exception as e:
                        logger.warning(f"Failed to start Galileo trace: {e}")

                try:
                    # Execute the actual function
                    result = await func(*args, **kwargs)

                    # Calculate metrics
                    latency = time.time() - start_time

                    # Log success to Galileo
                    if trace_context:
                        try:
                            trace_context.log_metrics({
                                "latency": latency,
                                "status": "success",
                                "timestamp": datetime.utcnow().isoformat()
                            })
                        except Exception as e:
                            logger.warning(f"Failed to log metrics to Galileo: {e}")

                    # Update internal metrics
                    self._update_metrics(name, latency, success=True)

                    return result

                except Exception as e:
                    # Calculate latency even on error
                    latency = time.time() - start_time

                    # Log error to Galileo
                    if trace_context:
                        try:
                            trace_context.log_metrics({
                                "status": "error",
                                "error": str(e),
                                "latency": latency,
                                "timestamp": datetime.utcnow().isoformat()
                            })
                        except Exception as log_error:
                            logger.warning(f"Failed to log error to Galileo: {log_error}")

                    # Update metrics with error
                    self._update_metrics(name, latency, success=False)

                    # Re-raise the original exception
                    raise

                finally:
                    # Clean up Galileo trace
                    if trace_context:
                        try:
                            trace_context.__exit__(None, None, None)
                        except Exception as e:
                            logger.warning(f"Failed to exit Galileo trace: {e}")

            @wraps(func)
            def sync_wrapper(*args, **kwargs):
                """Synchronous wrapper for non-async functions."""
                start_time = time.time()

                trace_context = None
                if self.galileo_enabled and self.observer:
                    try:
                        trace_context = self.observer.trace(name=name)
                        trace_context.__enter__()
                    except Exception as e:
                        logger.warning(f"Failed to start Galileo trace: {e}")

                try:
                    result = func(*args, **kwargs)
                    latency = time.time() - start_time

                    if trace_context:
                        try:
                            trace_context.log_metrics({
                                "latency": latency,
                                "status": "success",
                                "timestamp": datetime.utcnow().isoformat()
                            })
                        except Exception as e:
                            logger.warning(f"Failed to log metrics: {e}")

                    self._update_metrics(name, latency, success=True)
                    return result

                except Exception as e:
                    latency = time.time() - start_time

                    if trace_context:
                        try:
                            trace_context.log_metrics({
                                "status": "error",
                                "error": str(e),
                                "latency": latency
                            })
                        except Exception:
                            pass

                    self._update_metrics(name, latency, success=False)
                    raise

                finally:
                    if trace_context:
                        try:
                            trace_context.__exit__(None, None, None)
                        except Exception:
                            pass

            # Return appropriate wrapper based on function type
            import inspect
            if inspect.iscoroutinefunction(func):
                return async_wrapper
            else:
                return sync_wrapper

        return decorator

    def _update_metrics(self, name: str, latency: float, success: bool = True):
        """
        Update internal metrics for the demo dashboard.

        Args:
            name: Name of the operation
            latency: Time taken in seconds
            success: Whether the operation succeeded
        """
        self.metrics["total_requests"] += 1
        self.metrics["last_request_time"] = datetime.utcnow().isoformat()

        # Track service-specific calls
        if "claude" in name.lower():
            self.metrics["claude_calls"] += 1
        elif "elevenlabs" in name.lower() or "tts" in name.lower():
            self.metrics["elevenlabs_calls"] += 1
        elif "nanobanana" in name.lower() or "gemini" in name.lower():
            self.metrics["nanobanana_calls"] += 1
        elif "tigris" in name.lower() or "upload" in name.lower():
            self.metrics["tigris_uploads"] += 1

        # Track errors
        if not success:
            self.metrics["errors"] += 1

        # Update rolling average latency
        current_avg = self.metrics["average_latency"]
        total = self.metrics["total_requests"]
        self.metrics["average_latency"] = (current_avg * (total - 1) + latency) / total

        # Store in call history (keep last 100 calls)
        self.call_history.append({
            "name": name,
            "latency": latency,
            "success": success,
            "timestamp": datetime.utcnow().isoformat()
        })
        if len(self.call_history) > 100:
            self.call_history.pop(0)

        # Log the metrics
        status = "✅" if success else "❌"
        logger.info(
            f"{status} {name} completed in {latency*1000:.2f}ms "
            f"(Total requests: {total})"
        )

    def get_metrics(self) -> Dict[str, Any]:
        """
        Get current metrics for the demo dashboard.

        Returns:
            Dict containing all current metrics
        """
        return {
            **self.metrics,
            "recent_calls": self.call_history[-10:]  # Last 10 calls
        }

    def reset_metrics(self):
        """Reset all metrics (useful for demos)."""
        self.metrics = {
            "total_requests": 0,
            "claude_calls": 0,
            "elevenlabs_calls": 0,
            "nanobanana_calls": 0,
            "tigris_uploads": 0,
            "average_latency": 0.0,
            "total_tokens": 0,
            "errors": 0,
            "last_request_time": None,
        }
        self.call_history = []
        logger.info("📊 Metrics reset")


# Global instance
galileo_observer = GalileoObserver()


# Convenience decorator
def trace(name: str):
    """
    Convenience function for the trace decorator.

    Usage:
        from app.monitoring.galileo_observer import trace

        @trace("my_function")
        async def my_function():
            pass
    """
    return galileo_observer.trace(name)
