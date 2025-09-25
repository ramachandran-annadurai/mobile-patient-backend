"""
Medication OCR API Package

A comprehensive OCR (Optical Character Recognition) API for processing medication-related documents,
including prescriptions, medical forms, and pharmaceutical labels.

Features:
- Enhanced OCR processing for various document types (PDF, images, DOCX, TXT)
- Standard OCR for image processing
- Webhook integration for external systems
- Support for file uploads and base64 encoded images
- Comprehensive text extraction with confidence scores
- Dynamic content analysis and summarization

Author: LogicalMinds
Version: 1.0.0
"""

__version__ = "1.0.0"
__author__ = "LogicalMinds"
__description__ = "Medication OCR API for processing medical documents"

# Import main components for easy access
from .app.main import app
from .app.config import settings
from .app.services.enhanced_ocr_service import EnhancedOCRService
from .app.services.webhook_service import WebhookService

__all__ = [
    "app",
    "settings", 
    "EnhancedOCRService",
    "WebhookService",
    "__version__",
    "__author__",
    "__description__"
]
