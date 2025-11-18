"""
Database Models

SQLAlchemy models for storing clothing items and user data.
"""

from sqlalchemy import Column, String, Float, DateTime, Integer, JSON, Boolean, Index
from sqlalchemy.sql import func
from app.database import Base
from datetime import datetime


class ClothingItem(Base):
    """
    Clothing Item Model

    Stores analyzed clothing items with metadata and image URLs.
    Optimized for fast queries with indexes on commonly searched fields.
    """
    __tablename__ = "clothing_items"

    # Primary key
    id = Column(String, primary_key=True, index=True)  # UUID from client

    # User association
    user_id = Column(String, index=True, nullable=False)

    # Image URLs (Tigris presigned URLs)
    original_image_url = Column(String, nullable=True)
    extracted_image_url = Column(String, nullable=True)  # Background removed

    # Claude Analysis Results (all indexed for fast queries)
    type = Column(String, nullable=False, index=True)  # shirt, pants, dress, etc.
    color = Column(String, nullable=False, index=True)
    pattern = Column(String, nullable=False, index=True)
    style = Column(String, nullable=False, index=True)
    confidence = Column(Float, nullable=False)

    # Arrays stored as JSON
    season = Column(JSON, nullable=False)  # ["spring", "summer", ...]
    pairs_well_with = Column(JSON, nullable=False)  # ["jeans", "heels", ...]
    occasion = Column(JSON, nullable=True)  # ["casual", "work", ...]

    # Optional metadata
    material = Column(String, nullable=True)
    care_instructions = Column(String, nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_worn_at = Column(DateTime(timezone=True), nullable=True)

    # Usage tracking
    worn_count = Column(Integer, default=0)
    favorite = Column(Boolean, default=False)

    # Composite indexes for common query patterns
    __table_args__ = (
        # Index for querying by user and type (e.g., "all my jeans")
        Index('idx_user_type', 'user_id', 'type'),
        # Index for querying by user, type, and color (e.g., "blue jeans")
        Index('idx_user_type_color', 'user_id', 'type', 'color'),
        # Index for querying by user and color (e.g., "all blue items")
        Index('idx_user_color', 'user_id', 'color'),
        # Index for querying favorites
        Index('idx_user_favorite', 'user_id', 'favorite'),
    )

    def to_dict(self):
        """Convert to dictionary for JSON response."""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "original_image_url": self.original_image_url,
            "extracted_image_url": self.extracted_image_url,
            "type": self.type,
            "color": self.color,
            "pattern": self.pattern,
            "style": self.style,
            "confidence": self.confidence,
            "season": self.season,
            "pairs_well_with": self.pairs_well_with,
            "occasion": self.occasion,
            "material": self.material,
            "care_instructions": self.care_instructions,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "last_worn_at": self.last_worn_at.isoformat() if self.last_worn_at else None,
            "worn_count": self.worn_count,
            "favorite": self.favorite
        }
