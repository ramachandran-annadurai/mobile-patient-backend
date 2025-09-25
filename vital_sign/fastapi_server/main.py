from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from typing import List, Optional
from datetime import datetime, timedelta
import logging

from config import settings
from database import connect_to_mongo, close_mongo_connection, get_collection, get_alerts_collection, get_preferences_collection, db
from models import (
    VitalSign, VitalSignCreate, VitalSignUpdate,
    VitalSignAlert, VitalSignAlertCreate, VitalSignAlertUpdate,
    UserPreferences, VitalSignStats, HealthSummary,
    VitalSignType, AlertSeverity
)
from ai_service import ai_service

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="Vital Signs Monitor API",
    description="API for monitoring and analyzing patient vital signs",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    await connect_to_mongo()

@app.on_event("shutdown")
async def shutdown_event():
    await close_mongo_connection()

# Health check endpoint
@app.get("/health")
async def health_check():
    mode = "mongodb" if db.client is not None else "mock"
    return {"status": "healthy", "timestamp": datetime.now(), "mode": mode}

# Mock data storage for when MongoDB is not available
mock_vital_signs = [
    {
        "_id": "mock_1",
        "type": "heartRate",
        "value": 75.0,
        "secondary_value": None,
        "timestamp": datetime.now() - timedelta(hours=1),
        "notes": "Normal heart rate",
        "is_anomaly": False,
        "confidence": None,
        "created_at": datetime.now() - timedelta(hours=1)
    },
    {
        "_id": "mock_2", 
        "type": "bloodPressure",
        "value": 120.0,
        "secondary_value": 80.0,
        "timestamp": datetime.now() - timedelta(hours=2),
        "notes": "Normal blood pressure",
        "is_anomaly": False,
        "confidence": None,
        "created_at": datetime.now() - timedelta(hours=2)
    },
    {
        "_id": "mock_3",
        "type": "temperature", 
        "value": 36.5,
        "secondary_value": None,
        "timestamp": datetime.now() - timedelta(hours=3),
        "notes": "Normal body temperature",
        "is_anomaly": False,
        "confidence": None,
        "created_at": datetime.now() - timedelta(hours=3)
    }
]

mock_alerts = [
    {
        "_id": "alert_1",
        "type": "heartRate",
        "severity": "medium",
        "message": "Heart rate slightly elevated",
        "timestamp": datetime.now() - timedelta(minutes=30),
        "action_required": "Monitor closely",
        "is_resolved": False,
        "created_at": datetime.now() - timedelta(minutes=30)
    }
]

# Vital Signs CRUD operations
@app.post("/vital-signs", response_model=VitalSign)
async def create_vital_sign(vital_sign: VitalSignCreate):
    """Create a new vital sign record"""
    try:
        if db.client is not None:
            # Use MongoDB
            collection = get_collection()
            vital_sign_dict = vital_sign.dict()
            vital_sign_dict["created_at"] = datetime.now()
            vital_sign_dict["user_id"] = "default_user"  # Add user_id to avoid duplicate key error
            
            result = await collection.insert_one(vital_sign_dict)
            vital_sign_dict["_id"] = str(result.inserted_id)
            
            return VitalSign(**vital_sign_dict)
        else:
            # Use mock data
            vital_sign_dict = vital_sign.dict()
            vital_sign_dict["_id"] = f"mock_{len(mock_vital_signs) + 1}"
            vital_sign_dict["created_at"] = datetime.now()
            
            mock_vital_signs.append(vital_sign_dict)
            return VitalSign(**vital_sign_dict)
    except Exception as e:
        logger.error(f"Error creating vital sign: {e}")
        raise HTTPException(status_code=500, detail="Failed to create vital sign")

@app.get("/vital-signs", response_model=List[VitalSign])
async def get_vital_signs(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    vital_type: Optional[VitalSignType] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None
):
    """Get vital signs with optional filtering"""
    try:
        if db.client is not None:
            # Use MongoDB
            collection = get_collection()
            query = {}
            
            if vital_type:
                query["type"] = vital_type.value
            
            if start_date or end_date:
                query["timestamp"] = {}
                if start_date:
                    query["timestamp"]["$gte"] = start_date
                if end_date:
                    query["timestamp"]["$lte"] = end_date
            
            cursor = collection.find(query).sort("timestamp", -1).skip(skip).limit(limit)
            vital_signs = []
            
            async for doc in cursor:
                doc["_id"] = str(doc["_id"])
                # Only include documents that have the required vital sign fields
                if all(field in doc for field in ["type", "value", "timestamp"]):
                    try:
                        vital_signs.append(VitalSign(**doc))
                    except Exception as e:
                        logger.warning(f"Skipping invalid vital sign document: {e}")
                        continue
            
            return vital_signs
        else:
            # Use mock data
            filtered_signs = mock_vital_signs.copy()
            
            if vital_type:
                filtered_signs = [vs for vs in filtered_signs if vs.get("type") == vital_type.value]
            
            if start_date or end_date:
                filtered_signs = [vs for vs in filtered_signs 
                                if (not start_date or vs.get("timestamp", datetime.now()) >= start_date) and
                                   (not end_date or vs.get("timestamp", datetime.now()) <= end_date)]
            
            # Sort by timestamp descending
            filtered_signs.sort(key=lambda x: x.get("timestamp", datetime.now()), reverse=True)
            
            # Apply pagination
            result = filtered_signs[skip:skip + limit]
            return [VitalSign(**vs) for vs in result]
    except Exception as e:
        logger.error(f"Error getting vital signs: {e}")
        raise HTTPException(status_code=500, detail="Failed to get vital signs")

@app.get("/vital-signs/{vital_sign_id}", response_model=VitalSign)
async def get_vital_sign(vital_sign_id: str):
    """Get a specific vital sign by ID"""
    try:
        from bson import ObjectId
        collection = get_collection()
        
        doc = await collection.find_one({"_id": ObjectId(vital_sign_id)})
        if not doc:
            raise HTTPException(status_code=404, detail="Vital sign not found")
        
        doc["_id"] = str(doc["_id"])
        return VitalSign(**doc)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting vital sign: {e}")
        raise HTTPException(status_code=500, detail="Failed to get vital sign")

@app.put("/vital-signs/{vital_sign_id}", response_model=VitalSign)
async def update_vital_sign(vital_sign_id: str, vital_sign_update: VitalSignUpdate):
    """Update a vital sign record"""
    try:
        from bson import ObjectId
        collection = get_collection()
        
        update_data = {k: v for k, v in vital_sign_update.dict().items() if v is not None}
        if update_data:
            update_data["updated_at"] = datetime.now()
            
            result = await collection.update_one(
                {"_id": ObjectId(vital_sign_id)},
                {"$set": update_data}
            )
            
            if result.matched_count == 0:
                raise HTTPException(status_code=404, detail="Vital sign not found")
        
        # Return updated document
        doc = await collection.find_one({"_id": ObjectId(vital_sign_id)})
        doc["_id"] = str(doc["_id"])
        return VitalSign(**doc)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating vital sign: {e}")
        raise HTTPException(status_code=500, detail="Failed to update vital sign")

@app.delete("/vital-signs/{vital_sign_id}")
async def delete_vital_sign(vital_sign_id: str):
    """Delete a vital sign record"""
    try:
        from bson import ObjectId
        collection = get_collection()
        
        result = await collection.delete_one({"_id": ObjectId(vital_sign_id)})
        if result.deleted_count == 0:
            raise HTTPException(status_code=404, detail="Vital sign not found")
        
        return {"message": "Vital sign deleted successfully"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting vital sign: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete vital sign")

# Statistics endpoint
@app.get("/vital-signs/stats", response_model=List[VitalSignStats])
async def get_vital_signs_stats(
    days: int = Query(30, ge=1, le=365)
):
    """Get vital signs statistics for the last N days"""
    try:
        collection = get_collection()
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        pipeline = [
            {"$match": {"timestamp": {"$gte": start_date, "$lte": end_date}}},
            {"$group": {
                "_id": "$type",
                "count": {"$sum": 1},
                "average": {"$avg": "$value"},
                "min_value": {"$min": "$value"},
                "max_value": {"$max": "$value"},
                "latest_value": {"$last": "$value"},
                "latest_timestamp": {"$last": "$timestamp"}
            }}
        ]
        
        stats = []
        async for doc in collection.aggregate(pipeline):
            stats.append(VitalSignStats(
                type=VitalSignType(doc["_id"]),
                count=doc["count"],
                average=round(doc["average"], 2),
                min_value=doc["min_value"],
                max_value=doc["max_value"],
                latest_value=doc["latest_value"],
                latest_timestamp=doc["latest_timestamp"]
            ))
        
        return stats
    except Exception as e:
        logger.error(f"Error getting vital signs stats: {e}")
        raise HTTPException(status_code=500, detail="Failed to get vital signs statistics")

# AI Analysis endpoints
@app.get("/analysis/anomalies")
async def detect_anomalies(
    days: int = Query(7, ge=1, le=30)
):
    """Detect anomalies in recent vital signs"""
    try:
        collection = get_collection()
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        cursor = collection.find({"timestamp": {"$gte": start_date, "$lte": end_date}})
        vital_signs = []
        
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            vital_signs.append(VitalSign(**doc))
        
        anomalies = await ai_service.detect_anomalies(vital_signs)
        return {"anomalies": anomalies, "total_checked": len(vital_signs)}
    except Exception as e:
        logger.error(f"Error detecting anomalies: {e}")
        raise HTTPException(status_code=500, detail="Failed to detect anomalies")

@app.get("/analysis/trends")
async def analyze_trends(
    days: int = Query(7, ge=1, le=30)
):
    """Analyze trends in vital signs"""
    try:
        collection = get_collection()
        end_date = datetime.now()
        start_date = end_date - timedelta(days=days)
        
        cursor = collection.find({"timestamp": {"$gte": start_date, "$lte": end_date}})
        vital_signs = []
        
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            vital_signs.append(VitalSign(**doc))
        
        trends = await ai_service.analyze_trends(vital_signs)
        return {"trends": trends}
    except Exception as e:
        logger.error(f"Error analyzing trends: {e}")
        raise HTTPException(status_code=500, detail="Failed to analyze trends")

@app.get("/analysis/early-warning-score")
async def calculate_early_warning_score(
    hours: int = Query(24, ge=1, le=168)
):
    """Calculate Early Warning Score based on recent vital signs"""
    try:
        collection = get_collection()
        end_date = datetime.now()
        start_date = end_date - timedelta(hours=hours)
        
        cursor = collection.find({"timestamp": {"$gte": start_date, "$lte": end_date}})
        vital_signs = []
        
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            vital_signs.append(VitalSign(**doc))
        
        ews = await ai_service.calculate_early_warning_score(vital_signs)
        return ews
    except Exception as e:
        logger.error(f"Error calculating early warning score: {e}")
        raise HTTPException(status_code=500, detail="Failed to calculate early warning score")

# Health summary endpoint
@app.get("/health-summary", response_model=HealthSummary)
async def get_health_summary():
    """Get comprehensive health summary"""
    try:
        collection = get_collection()
        alerts_collection = get_alerts_collection()
        
        # Get recent vital signs (last 24 hours)
        end_date = datetime.now()
        start_date = end_date - timedelta(hours=24)
        
        cursor = collection.find({"timestamp": {"$gte": start_date, "$lte": end_date}})
        vital_signs = []
        
        async for doc in cursor:
            doc["_id"] = str(doc["_id"])
            vital_signs.append(VitalSign(**doc))
        
        # Get alert counts
        critical_alerts = await alerts_collection.count_documents({"severity": "critical", "is_resolved": False})
        warning_alerts = await alerts_collection.count_documents({"severity": {"$in": ["high", "medium"]}, "is_resolved": False})
        
        # Get recent anomalies
        anomalies = await ai_service.detect_anomalies(vital_signs)
        recent_anomalies = len([a for a in anomalies if a.is_anomaly])
        
        # Get trends
        trends = await ai_service.analyze_trends(vital_signs)
        
        # Get early warning score
        ews = await ai_service.calculate_early_warning_score(vital_signs)
        
        # Determine overall status
        if critical_alerts > 0 or ews.risk_level == "critical":
            overall_status = "critical"
        elif warning_alerts > 0 or ews.risk_level == "high":
            overall_status = "warning"
        elif recent_anomalies > 0 or ews.risk_level == "medium":
            overall_status = "caution"
        else:
            overall_status = "normal"
        
        return HealthSummary(
            overall_status=overall_status,
            critical_alerts=critical_alerts,
            warning_alerts=warning_alerts,
            recent_anomalies=recent_anomalies,
            early_warning_score=ews,
            trend_analysis=trends,
            last_updated=datetime.now()
        )
    except Exception as e:
        logger.error(f"Error getting health summary: {e}")
        raise HTTPException(status_code=500, detail="Failed to get health summary")

# Alerts CRUD operations
@app.post("/alerts", response_model=VitalSignAlert)
async def create_alert(alert: VitalSignAlertCreate):
    """Create a new alert"""
    try:
        collection = get_alerts_collection()
        alert_dict = alert.dict()
        alert_dict["created_at"] = datetime.now()
        
        result = await collection.insert_one(alert_dict)
        alert_dict["_id"] = str(result.inserted_id)
        
        return VitalSignAlert(**alert_dict)
    except Exception as e:
        logger.error(f"Error creating alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to create alert")

@app.get("/alerts", response_model=List[VitalSignAlert])
async def get_alerts(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    severity: Optional[AlertSeverity] = None,
    is_resolved: Optional[bool] = None
):
    """Get alerts with optional filtering"""
    try:
        if db.client is not None:
            # Use MongoDB
            collection = get_alerts_collection()
            query = {}
            
            if severity:
                query["severity"] = severity.value
            if is_resolved is not None:
                query["is_resolved"] = is_resolved
            
            cursor = collection.find(query).sort("timestamp", -1).skip(skip).limit(limit)
            alerts = []
            
            async for doc in cursor:
                doc["_id"] = str(doc["_id"])
                alerts.append(VitalSignAlert(**doc))
            
            return alerts
        else:
            # Use mock data
            filtered_alerts = mock_alerts.copy()
            
            if severity:
                filtered_alerts = [alert for alert in filtered_alerts if alert.get("severity") == severity.value]
            if is_resolved is not None:
                filtered_alerts = [alert for alert in filtered_alerts if alert.get("is_resolved") == is_resolved]
            
            # Sort by timestamp descending
            filtered_alerts.sort(key=lambda x: x.get("timestamp", datetime.now()), reverse=True)
            
            # Apply pagination
            result = filtered_alerts[skip:skip + limit]
            return [VitalSignAlert(**alert) for alert in result]
    except Exception as e:
        logger.error(f"Error getting alerts: {e}")
        raise HTTPException(status_code=500, detail="Failed to get alerts")

@app.put("/alerts/{alert_id}", response_model=VitalSignAlert)
async def update_alert(alert_id: str, alert_update: VitalSignAlertUpdate):
    """Update an alert"""
    try:
        from bson import ObjectId
        collection = get_alerts_collection()
        
        update_data = {k: v for k, v in alert_update.dict().items() if v is not None}
        if update_data:
            update_data["updated_at"] = datetime.now()
            
            result = await collection.update_one(
                {"_id": ObjectId(alert_id)},
                {"$set": update_data}
            )
            
            if result.matched_count == 0:
                raise HTTPException(status_code=404, detail="Alert not found")
        
        # Return updated document
        doc = await collection.find_one({"_id": ObjectId(alert_id)})
        doc["_id"] = str(doc["_id"])
        return VitalSignAlert(**doc)
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating alert: {e}")
        raise HTTPException(status_code=500, detail="Failed to update alert")

# Statistics endpoint
@app.get("/statistics")
async def get_statistics(
    startDate: Optional[datetime] = None,
    endDate: Optional[datetime] = None
):
    """Get vital signs statistics"""
    try:
        if db.client is not None:
            # Use MongoDB
            collection = get_collection()
            end_date = endDate or datetime.now()
            start_date = startDate or (end_date - timedelta(days=30))
            
            pipeline = [
                {"$match": {"timestamp": {"$gte": start_date, "$lte": end_date}}},
                {"$group": {
                    "_id": "$type",
                    "count": {"$sum": 1},
                    "average": {"$avg": "$value"},
                    "min_value": {"$min": "$value"},
                    "max_value": {"$max": "$value"},
                    "latest_value": {"$last": "$value"},
                    "latest_timestamp": {"$last": "$timestamp"}
                }}
            ]
            
            stats = []
            async for doc in collection.aggregate(pipeline):
                stats.append({
                    "type": doc["_id"],
                    "count": doc["count"],
                    "average": round(doc["average"], 2),
                    "min_value": doc["min_value"],
                    "max_value": doc["max_value"],
                    "latest_value": doc["latest_value"],
                    "latest_timestamp": doc["latest_timestamp"]
                })
            
            return {"statistics": stats}
        else:
            # Use mock data
            end_date = endDate or datetime.now()
            start_date = startDate or (end_date - timedelta(days=30))
            
            # Filter by date range
            recent_signs = [vs for vs in mock_vital_signs 
                           if start_date <= vs.get("timestamp", datetime.now()) <= end_date]
            
            # Group by type and calculate stats
            stats = {}
            for vs in recent_signs:
                vs_type = vs.get("type")
                if vs_type not in stats:
                    stats[vs_type] = {
                        "count": 0,
                        "values": [],
                        "latest_value": vs.get("value", 0),
                        "latest_timestamp": vs.get("timestamp", datetime.now())
                    }
                
                stats[vs_type]["count"] += 1
                stats[vs_type]["values"].append(vs.get("value", 0))
                if vs.get("timestamp", datetime.now()) > stats[vs_type]["latest_timestamp"]:
                    stats[vs_type]["latest_value"] = vs.get("value", 0)
                    stats[vs_type]["latest_timestamp"] = vs.get("timestamp", datetime.now())
            
            # Calculate averages, min, max
            result = []
            for vs_type, data in stats.items():
                values = data["values"]
                result.append({
                    "type": vs_type,
                    "count": data["count"],
                    "average": sum(values) / len(values) if values else 0,
                    "min_value": min(values) if values else 0,
                    "max_value": max(values) if values else 0,
                    "latest_value": data["latest_value"],
                    "latest_timestamp": data["latest_timestamp"]
                })
            
            return {"statistics": result}
    except Exception as e:
        logger.error(f"Error getting statistics: {e}")
        raise HTTPException(status_code=500, detail="Failed to get statistics")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
