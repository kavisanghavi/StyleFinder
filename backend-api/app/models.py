"""
Database Models

SQLAlchemy models for storing clothing items and user data.
"""

from sqlalchemy import Column, String, Float, DateTime, Integer, JSON
from sqlalchemy.sql import func
from app.database import Base
from datetime import datetime


class ClothingItem(Base):
    """
    Clothing Item Model

    Stores analyzed clothing items with metadata and image URLs.
    """
    __tablename__ = "clothing_items"

    # Primary key
    id = Column(String, primary_key=True, index=True)  # UUID from client

    # User association
    user_id = Column(String, index=True, nullable=False)

    # Image URLs (Tigris presigned URLs)
    original_image_url = Column(String, nullable=True)
    extracted_image_url = Column(String, nullable=True)  # Background removed

    # Claude Analysis Results
    type = Column(String, nullable=False)  # shirt, pants, dress, etc.
    color = Column(String, nullable=False)
    pattern = Column(String, nullable=False)
    style = Column(String, nullable=False)
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
    favorite = Column(Integer, default=0)  # 0 = false, 1 = true (SQLite doesn't have boolean)

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
            "favorite": bool(self.favorite)
        }
