from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from datetime import datetime
from enum import Enum

class VitalSignType(str, Enum):
    heart_rate = "heartRate"
    blood_pressure = "bloodPressure"
    temperature = "temperature"
    sp_o2 = "spO2"
    respiratory_rate = "respiratoryRate"

class AlertSeverity(str, Enum):
    low = "low"
    medium = "medium"
    high = "high"
    critical = "critical"

class VitalSignBase(BaseModel):
    type: VitalSignType
    value: float
    secondary_value: Optional[float] = None
    timestamp: datetime
    notes: Optional[str] = None
    is_anomaly: bool = False
    confidence: Optional[float] = None

class VitalSignCreate(VitalSignBase):
    pass

class VitalSignUpdate(BaseModel):
    value: Optional[float] = None
    secondary_value: Optional[float] = None
    timestamp: Optional[datetime] = None
    notes: Optional[str] = None
    is_anomaly: Optional[bool] = None
    confidence: Optional[float] = None

class VitalSign(VitalSignBase):
    id: str = Field(alias="_id")
    
    class Config:
        populate_by_name = True

class VitalSignAlertBase(BaseModel):
    type: VitalSignType
    severity: AlertSeverity
    message: str
    timestamp: datetime
    action_required: Optional[str] = None
    is_resolved: bool = False

class VitalSignAlertCreate(VitalSignAlertBase):
    pass

class VitalSignAlertUpdate(BaseModel):
    is_resolved: Optional[bool] = None
    action_required: Optional[str] = None

class VitalSignAlert(VitalSignAlertBase):
    id: str = Field(alias="_id")
    
    class Config:
        populate_by_name = True

class UserPreferences(BaseModel):
    user_id: str
    alert_thresholds: Dict[str, float] = Field(default_factory=dict)
    notification_settings: Dict[str, bool] = Field(default_factory=dict)
    chart_preferences: Dict[str, Any] = Field(default_factory=dict)

class VitalSignStats(BaseModel):
    type: VitalSignType
    count: int
    average: float
    min_value: float
    max_value: float
    latest_value: float
    latest_timestamp: datetime

class TrendAnalysis(BaseModel):
    type: VitalSignType
    trend: str  # "increasing", "decreasing", "stable"
    change_percentage: float
    confidence: float
    period_days: int

class AnomalyDetection(BaseModel):
    type: VitalSignType
    is_anomaly: bool
    confidence: float
    reason: Optional[str] = None
    suggested_action: Optional[str] = None

class EarlyWarningScore(BaseModel):
    score: int
    risk_level: str
    factors: List[str]
    timestamp: datetime
    recommendations: List[str]

class HealthSummary(BaseModel):
    overall_status: str
    critical_alerts: int
    warning_alerts: int
    recent_anomalies: int
    early_warning_score: Optional[EarlyWarningScore] = None
    trend_analysis: List[TrendAnalysis]
    last_updated: datetime
