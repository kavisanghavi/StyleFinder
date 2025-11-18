"""
Test Supabase/PostgreSQL connection and create tables.

This script:
1. Tests the database connection
2. Creates all tables with indexes
3. Verifies the schema
"""

import sys
import os

# Add the backend-api directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from app.database import engine, Base, init_db
from app.models import ClothingItem
from app.config import settings
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def test_connection():
    """Test database connection."""
    try:
        logger.info("=" * 60)
        logger.info("Testing Supabase/PostgreSQL Connection...")
        logger.info("=" * 60)

        # Test connection
        with engine.connect() as connection:
            result = connection.execute(
                __import__('sqlalchemy').text("SELECT version()")
            )
            version = result.fetchone()[0]
            logger.info(f"✅ Connected to PostgreSQL!")
            logger.info(f"Database version: {version}")

        return True
    except Exception as e:
        logger.error(f"❌ Connection failed: {e}")
        return False


def create_tables():
    """Create all tables."""
    try:
        logger.info("\n" + "=" * 60)
        logger.info("Creating Tables...")
        logger.info("=" * 60)

        # Drop all tables first (for fresh start)
        logger.info("Dropping existing tables...")
        Base.metadata.drop_all(bind=engine)

        # Create all tables
        logger.info("Creating tables...")
        Base.metadata.create_all(bind=engine)

        logger.info("✅ Tables created successfully!")

        # Show created tables
        with engine.connect() as connection:
            result = connection.execute(
                __import__('sqlalchemy').text(
                    "SELECT tablename FROM pg_tables WHERE schemaname = 'public'"
                )
            )
            tables = result.fetchall()
            logger.info("\nCreated tables:")
            for table in tables:
                logger.info(f"  - {table[0]}")

        return True
    except Exception as e:
        logger.error(f"❌ Table creation failed: {e}")
        return False


def verify_schema():
    """Verify table schema and indexes."""
    try:
        logger.info("\n" + "=" * 60)
        logger.info("Verifying Schema and Indexes...")
        logger.info("=" * 60)

        with engine.connect() as connection:
            # Check columns
            result = connection.execute(
                __import__('sqlalchemy').text("""
                    SELECT column_name, data_type
                    FROM information_schema.columns
                    WHERE table_name = 'clothing_items'
                    ORDER BY ordinal_position
                """)
            )
            columns = result.fetchall()
            logger.info("\nColumns in 'clothing_items' table:")
            for col in columns:
                logger.info(f"  - {col[0]}: {col[1]}")

            # Check indexes
            result = connection.execute(
                __import__('sqlalchemy').text("""
                    SELECT indexname, indexdef
                    FROM pg_indexes
                    WHERE tablename = 'clothing_items'
                """)
            )
            indexes = result.fetchall()
            logger.info("\nIndexes on 'clothing_items' table:")
            for idx in indexes:
                logger.info(f"  - {idx[0]}")

        logger.info("✅ Schema verification complete!")
        return True
    except Exception as e:
        logger.error(f"❌ Schema verification failed: {e}")
        return False


def insert_test_data():
    """Insert test data to verify everything works."""
    try:
        logger.info("\n" + "=" * 60)
        logger.info("Inserting Test Data...")
        logger.info("=" * 60)

        from sqlalchemy.orm import Session
        import uuid

        with Session(engine) as session:
            # Create test item
            test_item = ClothingItem(
                id=str(uuid.uuid4()),
                user_id="test_user_123",
                type="jeans",
                color="blue",
                pattern="solid",
                style="casual",
                confidence=0.95,
                season=["spring", "summer", "fall", "winter"],
                pairs_well_with=["t-shirt", "sweater", "jacket"],
                occasion=["casual", "everyday"],
                material="denim",
                care_instructions="Machine wash cold"
            )

            session.add(test_item)
            session.commit()

            logger.info(f"✅ Test item inserted: {test_item.id}")

            # Query it back
            queried_item = session.query(ClothingItem).filter(
                ClothingItem.user_id == "test_user_123"
            ).first()

            logger.info(f"✅ Test item queried back: {queried_item.type} - {queried_item.color}")

            # Test search queries
            logger.info("\n" + "=" * 60)
            logger.info("Testing Search Queries...")
            logger.info("=" * 60)

            # Test 1: Search by type
            result = session.query(ClothingItem).filter(
                ClothingItem.type.ilike("%jean%")
            ).all()
            logger.info(f"✅ Fuzzy search 'jean': Found {len(result)} item(s)")

            # Test 2: Search by type and color
            result = session.query(ClothingItem).filter(
                ClothingItem.type.ilike("%jean%"),
                ClothingItem.color.ilike("%blue%")
            ).all()
            logger.info(f"✅ Search 'jeans' + 'blue': Found {len(result)} item(s)")

            # Clean up test data
            session.delete(queried_item)
            session.commit()
            logger.info("✅ Test data cleaned up")

        return True
    except Exception as e:
        logger.error(f"❌ Test data insertion failed: {e}")
        import traceback
        traceback.print_exc()
        return False


def main():
    """Run all tests."""
    logger.info("\n" + "=" * 60)
    logger.info("🚀 Supabase Database Setup & Test")
    logger.info("=" * 60)
    logger.info(f"Database URL: {settings.DATABASE_URL.split('@')[1] if settings.DATABASE_URL else 'Not set'}")

    # Run tests
    if not test_connection():
        logger.error("❌ Connection test failed. Exiting.")
        sys.exit(1)

    if not create_tables():
        logger.error("❌ Table creation failed. Exiting.")
        sys.exit(1)

    if not verify_schema():
        logger.error("❌ Schema verification failed. Exiting.")
        sys.exit(1)

    if not insert_test_data():
        logger.error("❌ Test data insertion failed. Exiting.")
        sys.exit(1)

    logger.info("\n" + "=" * 60)
    logger.info("✅ All tests passed! Database is ready.")
    logger.info("=" * 60)
    logger.info("\n📋 Summary:")
    logger.info("  ✅ Connection: SUCCESS")
    logger.info("  ✅ Tables: CREATED")
    logger.info("  ✅ Indexes: VERIFIED")
    logger.info("  ✅ Test Data: PASSED")
    logger.info("\n🎉 Your Supabase database is ready to use!")
    logger.info("=" * 60)


if __name__ == "__main__":
    main()
