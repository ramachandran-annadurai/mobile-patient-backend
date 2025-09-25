from pydantic import BaseModel, Field
from typing import List, Dict, Any, Optional
from datetime import datetime

class Base64ImageRequest(BaseModel):
    """Request model for base64 image processing"""
    image: str = Field(..., description="Base64 encoded image string")

class OCRResult(BaseModel):
    """Model for individual OCR result"""
    text: str = Field(..., description="Extracted text")
    confidence: float = Field(..., description="Confidence score (0.0 to 1.0)")
    bbox: List[List[float]] = Field(..., description="Bounding box coordinates")

class WebhookDeliveryResult(BaseModel):
    """Model for individual webhook delivery result"""
    config_id: str = Field(..., description="Webhook configuration ID")
    config_name: str = Field(..., description="Webhook configuration name")
    url: str = Field(..., description="Webhook endpoint URL")
    success: bool = Field(..., description="Whether webhook delivery was successful")
    timestamp: str = Field(..., description="Webhook delivery timestamp")
    error: Optional[str] = Field(None, description="Error message if delivery failed")

class WebhookDeliveryStatus(BaseModel):
    """Model for webhook delivery status"""
    status: str = Field(..., description="Overall webhook delivery status (completed, failed, pending)")
    n8n_webhook_response: Optional[str] = Field(None, description="Actual response content from n8n webhook")
    results: List[WebhookDeliveryResult] = Field(..., description="List of webhook delivery results")
    timestamp: str = Field(..., description="Timestamp of webhook delivery completion")

class OCRResponse(BaseModel):
    """Response model for OCR operations"""
    success: bool = Field(..., description="Operation success status")
    filename: Optional[str] = Field(None, description="Original filename")
    text_count: int = Field(..., description="Number of text elements found")
    extracted_text: Optional[str] = Field(None, description="Combined extracted text content")
    results: List[OCRResult] = Field(..., description="List of extracted text results")
    
    # Additional fields for enhanced OCR service
    file_type: Optional[str] = Field(None, description="Type of processed file")
    total_pages: Optional[int] = Field(None, description="Total pages in document")
    full_content: Optional[str] = Field(None, description="Full extracted content description")
    processing_summary: Optional[Dict[str, Any]] = Field(None, description="Processing summary information")
    
    # Webhook delivery status
    webhook_delivery: Optional[WebhookDeliveryStatus] = Field(None, description="Webhook delivery status and results")
    
    # Error handling fields
    error: Optional[str] = Field(None, description="Error message if operation failed")
    error_code: Optional[str] = Field(None, description="Error code if operation failed")
    timestamp: Optional[str] = Field(None, description="Timestamp of operation")
    
    class Config:
        extra = "allow"  # Allow additional fields not defined in the model

class HealthResponse(BaseModel):
    """Health check response model"""
    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    timestamp: str = Field(..., description="Health check timestamp")
    version: str = Field(..., description="Service version")

class LanguagesResponse(BaseModel):
    """Supported languages response model"""
    supported_languages: List[str] = Field(..., description="List of supported languages")
    current_language: str = Field(..., description="Currently active language")

class ErrorResponse(BaseModel):
    """Error response model"""
    detail: str = Field(..., description="Error description")
    error_code: Optional[str] = Field(None, description="Error code")
    timestamp: Optional[str] = Field(None, description="Error timestamp")

class ServiceInfo(BaseModel):
    """Service information model"""
    name: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    description: str = Field(..., description="Service description")
    status: str = Field(..., description="Service status")
