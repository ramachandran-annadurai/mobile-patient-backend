import numpy as np
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from models import VitalSign, VitalSignType, AnomalyDetection, TrendAnalysis, EarlyWarningScore
import logging

logger = logging.getLogger(__name__)

class AIAnalysisService:
    def __init__(self):
        self.anomaly_threshold = 2.0  # Standard deviations
        self.trend_window_days = 7
    
    async def detect_anomalies(self, vital_signs: List[VitalSign]) -> List[AnomalyDetection]:
        """Detect anomalies in vital signs using statistical methods"""
        anomalies = []
        
        # Group by type
        by_type = {}
        for vs in vital_signs:
            if vs.type not in by_type:
                by_type[vs.type] = []
            by_type[vs.type].append(vs)
        
        for vs_type, signs in by_type.items():
            if len(signs) < 3:  # Need at least 3 data points
                continue
                
            values = [vs.value for vs in signs]
            mean_val = np.mean(values)
            std_val = np.std(values)
            
            for vs in signs:
                z_score = abs((vs.value - mean_val) / std_val) if std_val > 0 else 0
                
                if z_score > self.anomaly_threshold:
                    anomaly = AnomalyDetection(
                        type=vs_type,
                        is_anomaly=True,
                        confidence=min(z_score / self.anomaly_threshold, 1.0),
                        reason=f"Value {vs.value} is {z_score:.2f} standard deviations from mean",
                        suggested_action=self._get_anomaly_action(vs_type, vs.value, mean_val)
                    )
                    anomalies.append(anomaly)
        
        return anomalies
    
    def _get_anomaly_action(self, vs_type: VitalSignType, value: float, mean: float) -> str:
        """Get suggested action for anomaly"""
        if vs_type == VitalSignType.heart_rate:
            if value > mean:
                return "Monitor closely, consider immediate medical attention if sustained"
            else:
                return "Check for bradycardia, monitor for symptoms"
        elif vs_type == VitalSignType.blood_pressure:
            if value > mean:
                return "Monitor for hypertension, consider medication review"
            else:
                return "Check for hypotension, monitor for dizziness"
        elif vs_type == VitalSignType.temperature:
            if value > mean:
                return "Monitor for fever, consider antipyretics if needed"
            else:
                return "Check for hypothermia, ensure warmth"
        elif vs_type == VitalSignType.sp_o2:
            if value < mean:
                return "Check oxygen saturation, consider supplemental oxygen"
        elif vs_type == VitalSignType.respiratory_rate:
            if value > mean:
                return "Monitor for respiratory distress"
            else:
                return "Check for respiratory depression"
        
        return "Monitor closely and consult healthcare provider"
    
    async def analyze_trends(self, vital_signs: List[VitalSign]) -> List[TrendAnalysis]:
        """Analyze trends in vital signs over time"""
        trends = []
        
        # Group by type
        by_type = {}
        for vs in vital_signs:
            if vs.type not in by_type:
                by_type[vs.type] = []
            by_type[vs.type].append(vs)
        
        for vs_type, signs in by_type.items():
            if len(signs) < 2:
                continue
            
            # Sort by timestamp
            signs.sort(key=lambda x: x.timestamp)
            
            # Calculate trend
            values = [vs.value for vs in signs]
            timestamps = [vs.timestamp for vs in signs]
            
            # Simple linear regression
            x = np.array([(ts - timestamps[0]).total_seconds() for ts in timestamps])
            y = np.array(values)
            
            if len(x) > 1:
                slope = np.polyfit(x, y, 1)[0]
                change_percentage = (slope * (timestamps[-1] - timestamps[0]).total_seconds()) / values[0] * 100
                
                if abs(change_percentage) < 5:
                    trend = "stable"
                elif change_percentage > 0:
                    trend = "increasing"
                else:
                    trend = "decreasing"
                
                confidence = min(abs(change_percentage) / 10, 1.0)
                
                trend_analysis = TrendAnalysis(
                    type=vs_type,
                    trend=trend,
                    change_percentage=change_percentage,
                    confidence=confidence,
                    period_days=self.trend_window_days
                )
                trends.append(trend_analysis)
        
        return trends
    
    async def calculate_early_warning_score(self, vital_signs: List[VitalSign]) -> EarlyWarningScore:
        """Calculate Early Warning Score (EWS) based on vital signs"""
        score = 0
        factors = []
        
        # Get latest values for each type
        latest_values = {}
        for vs in vital_signs:
            if vs.type not in latest_values or vs.timestamp > latest_values[vs.type].timestamp:
                latest_values[vs.type] = vs
        
        # Heart Rate scoring
        if VitalSignType.heart_rate in latest_values:
            hr = latest_values[VitalSignType.heart_rate].value
            if hr < 40 or hr > 130:
                score += 3
                factors.append(f"Heart rate {hr} bpm (critical)")
            elif hr < 50 or hr > 110:
                score += 2
                factors.append(f"Heart rate {hr} bpm (abnormal)")
            elif hr < 60 or hr > 100:
                score += 1
                factors.append(f"Heart rate {hr} bpm (slightly abnormal)")
        
        # Blood Pressure scoring
        if VitalSignType.blood_pressure in latest_values:
            bp = latest_values[VitalSignType.blood_pressure].value
            if bp < 70 or bp > 200:
                score += 3
                factors.append(f"Blood pressure {bp} mmHg (critical)")
            elif bp < 90 or bp > 160:
                score += 2
                factors.append(f"Blood pressure {bp} mmHg (abnormal)")
            elif bp < 100 or bp > 140:
                score += 1
                factors.append(f"Blood pressure {bp} mmHg (slightly abnormal)")
        
        # Temperature scoring
        if VitalSignType.temperature in latest_values:
            temp = latest_values[VitalSignType.temperature].value
            if temp < 35 or temp > 39:
                score += 3
                factors.append(f"Temperature {temp}°C (critical)")
            elif temp < 36 or temp > 38:
                score += 2
                factors.append(f"Temperature {temp}°C (abnormal)")
            elif temp < 36.5 or temp > 37.5:
                score += 1
                factors.append(f"Temperature {temp}°C (slightly abnormal)")
        
        # SpO2 scoring
        if VitalSignType.sp_o2 in latest_values:
            spo2 = latest_values[VitalSignType.sp_o2].value
            if spo2 < 85:
                score += 3
                factors.append(f"SpO2 {spo2}% (critical)")
            elif spo2 < 90:
                score += 2
                factors.append(f"SpO2 {spo2}% (abnormal)")
            elif spo2 < 95:
                score += 1
                factors.append(f"SpO2 {spo2}% (slightly abnormal)")
        
        # Respiratory Rate scoring
        if VitalSignType.respiratory_rate in latest_values:
            rr = latest_values[VitalSignType.respiratory_rate].value
            if rr < 8 or rr > 25:
                score += 3
                factors.append(f"Respiratory rate {rr} breaths/min (critical)")
            elif rr < 12 or rr > 20:
                score += 2
                factors.append(f"Respiratory rate {rr} breaths/min (abnormal)")
            elif rr < 14 or rr > 18:
                score += 1
                factors.append(f"Respiratory rate {rr} breaths/min (slightly abnormal)")
        
        # Determine risk level
        if score >= 7:
            risk_level = "critical"
            recommendations = [
                "Immediate medical attention required",
                "Consider emergency response",
                "Continuous monitoring essential"
            ]
        elif score >= 5:
            risk_level = "high"
            recommendations = [
                "Close monitoring required",
                "Consider escalation to senior staff",
                "Review medication and treatment"
            ]
        elif score >= 3:
            risk_level = "medium"
            recommendations = [
                "Increased monitoring frequency",
                "Review vital signs trends",
                "Consider intervention"
            ]
        else:
            risk_level = "low"
            recommendations = [
                "Continue routine monitoring",
                "Maintain current care plan"
            ]
        
        return EarlyWarningScore(
            score=score,
            risk_level=risk_level,
            factors=factors,
            timestamp=datetime.now(),
            recommendations=recommendations
        )

# Global instance
ai_service = AIAnalysisService()
