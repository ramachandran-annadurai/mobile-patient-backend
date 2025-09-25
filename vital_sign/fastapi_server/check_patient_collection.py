#!/usr/bin/env python3
"""
Check what's stored in the patient collection
"""

import asyncio
from motor.motor_asyncio import AsyncIOMotorClient
from config import settings

async def check_patient_collection():
    print("🔍 Checking Patient Collection")
    print("=" * 50)
    print(f"MongoDB URI: {settings.MONGO_URI}")
    print(f"Database: {settings.DB_NAME}")
    print(f"Collection: {settings.COLLECTION_NAME}")
    
    try:
        # Connect to MongoDB
        client = AsyncIOMotorClient(settings.MONGO_URI)
        db = client[settings.DB_NAME]
        collection = db[settings.COLLECTION_NAME]
        
        # Count documents
        count = await collection.count_documents({})
        print(f"\n📊 Total documents in '{settings.COLLECTION_NAME}' collection: {count}")
        
        # Get recent documents
        recent_docs = await collection.find().sort("created_at", -1).limit(5).to_list(length=5)
        
        if recent_docs:
            print(f"\n📋 Recent documents:")
            for i, doc in enumerate(recent_docs, 1):
                print(f"\n{i}. Document ID: {doc.get('_id')}")
                print(f"   Type: {doc.get('type')}")
                print(f"   Value: {doc.get('value')}")
                print(f"   Timestamp: {doc.get('timestamp')}")
                print(f"   Created: {doc.get('created_at')}")
                print(f"   User ID: {doc.get('user_id')}")
        else:
            print("\n❌ No documents found in the collection")
            
        # Check if there are any documents with different collection names
        all_collections = await db.list_collection_names()
        print(f"\n📁 All collections in database: {all_collections}")
        
        # Check other potential collections
        for coll_name in ['patients', 'patients_v2', 'patient_v2', 'vital_signs']:
            if coll_name in all_collections:
                coll = db[coll_name]
                coll_count = await coll.count_documents({})
                print(f"   - {coll_name}: {coll_count} documents")
        
        client.close()
        
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(check_patient_collection())
