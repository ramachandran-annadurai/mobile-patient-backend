from motor.motor_asyncio import AsyncIOMotorClient
from pymongo import MongoClient
from config import settings
import logging
from datetime import datetime, timedelta

logger = logging.getLogger(__name__)

class Database:
    client: AsyncIOMotorClient = None
    database = None

db = Database()

async def connect_to_mongo():
    """Create database connection"""
    try:
        db.client = AsyncIOMotorClient(
            settings.MONGO_URI, 
            serverSelectionTimeoutMS=30000, 
            connectTimeoutMS=30000, 
            socketTimeoutMS=30000,
            retryWrites=True,
            retryReads=True
        )
        db.database = db.client[settings.DB_NAME]
        
        # Test the connection
        await db.client.admin.command('ping')
        logger.info("Connected to MongoDB successfully")
        
        # Create indexes for better performance
        await create_indexes()
        
        # Setup sample data if needed
        await setup_sample_data()
        
    except Exception as e:
        logger.error(f"Failed to connect to MongoDB: {e}")
        logger.info("Starting in mock mode - MongoDB connection failed")
        # Don't raise the exception, let the app continue in mock mode
        db.client = None
        db.database = None

async def close_mongo_connection():
    """Close database connection"""
    if db.client is not None:
        db.client.close()
        logger.info("Disconnected from MongoDB")

async def create_indexes():
    """Create database indexes for better performance"""
    try:
        collection = db.database[settings.COLLECTION_NAME]
        
        # Create indexes
        await collection.create_index("type")
        await collection.create_index("timestamp")
        await collection.create_index([("type", 1), ("timestamp", -1)])
        await collection.create_index("is_anomaly")
        
        logger.info("Database indexes created successfully")
    except Exception as e:
        logger.error(f"Failed to create indexes: {e}")

def get_collection():
    """Get the vital signs collection"""
    return db.database[settings.COLLECTION_NAME]

def get_alerts_collection():
    """Get the alerts collection"""
    return db.database["alerts"]

def get_preferences_collection():
    """Get the user preferences collection"""
    return db.database["user_preferences"]

async def setup_sample_data():
    """Create sample vital signs data if collection is empty or has invalid data"""
    if db.database is None:
        return
        
    collection = get_collection()
    
    # Check if we have any valid vital signs
    valid_count = await collection.count_documents({
        "type": {"$exists": True},
        "value": {"$exists": True},
        "timestamp": {"$exists": True}
    })
    
    if valid_count == 0:
        logger.info("Creating sample vital signs data...")
        sample_data = [
            {
                "user_id": "default_user",
                "type": "heartRate",
                "value": 75.0,
                "secondary_value": None,
                "timestamp": datetime.now() - timedelta(hours=1),
                "notes": "Normal heart rate reading",
                "is_anomaly": False,
                "confidence": None,
                "created_at": datetime.now() - timedelta(hours=1)
            },
            {
                "user_id": "default_user",
                "type": "bloodPressure",
                "value": 120.0,
                "secondary_value": 80.0,
                "timestamp": datetime.now() - timedelta(hours=2),
                "notes": "Normal blood pressure reading",
                "is_anomaly": False,
                "confidence": None,
                "created_at": datetime.now() - timedelta(hours=2)
            },
            {
                "user_id": "default_user",
                "type": "temperature",
                "value": 36.5,
                "secondary_value": None,
                "timestamp": datetime.now() - timedelta(hours=3),
                "notes": "Normal body temperature",
                "is_anomaly": False,
                "confidence": None,
                "created_at": datetime.now() - timedelta(hours=3)
            },
            {
                "user_id": "default_user",
                "type": "spO2",
                "value": 98.0,
                "secondary_value": None,
                "timestamp": datetime.now() - timedelta(hours=4),
                "notes": "Normal oxygen saturation",
                "is_anomaly": False,
                "confidence": None,
                "created_at": datetime.now() - timedelta(hours=4)
            },
            {
                "user_id": "default_user",
                "type": "respiratoryRate",
                "value": 16.0,
                "secondary_value": None,
                "timestamp": datetime.now() - timedelta(hours=5),
                "notes": "Normal respiratory rate",
                "is_anomaly": False,
                "confidence": None,
                "created_at": datetime.now() - timedelta(hours=5)
            }
        ]
        
        await collection.insert_many(sample_data)
        logger.info(f"Created {len(sample_data)} sample vital signs records")
    
    # Clean up any invalid documents that don't have required fields
    invalid_count = await collection.count_documents({
        "$or": [
            {"type": {"$exists": False}},
            {"value": {"$exists": False}},
            {"timestamp": {"$exists": False}}
        ]
    })
    
    if invalid_count > 0:
        logger.info(f"Found {invalid_count} invalid documents, cleaning up...")
        await collection.delete_many({
            "$or": [
                {"type": {"$exists": False}},
                {"value": {"$exists": False}},
                {"timestamp": {"$exists": False}}
            ]
        })
        logger.info("Invalid documents cleaned up")
