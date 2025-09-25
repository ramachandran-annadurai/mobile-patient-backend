"""
Medication OCR API Application Package

This package contains the main FastAPI application and all its components.
"""

__version__ = "1.0.0"

# Import main components
from .main import app
from .config import settings

# Import services
from .services.enhanced_ocr_service import EnhancedOCRService
from .services.webhook_service import WebhookService
from .services.webhook_config_service import WebhookConfigService

# Import models
from .models.schemas import (
    Base64ImageRequest,
    OCRResponse,
    HealthResponse,
    LanguagesResponse,
    ServiceInfo,
    ErrorResponse
)
from .models.webhook_config import (
    WebhookConfig,
    WebhookConfigCreate,
    WebhookConfigUpdate
)

# Import API endpoints
from .api.endpoints import router

__all__ = [
    # Main app
    "app",
    "settings",
    
    # Services
    "EnhancedOCRService", 
    "WebhookService",
    "WebhookConfigService",
    
    # Models
    "Base64ImageRequest",
    "OCRResponse",
    "HealthResponse",
    "LanguagesResponse",
    "ServiceInfo",
    "ErrorResponse",
    "WebhookConfig",
    "WebhookConfigCreate",
    "WebhookConfigUpdate",
    
    # API
    "router",
    
    # Version
    "__version__"
]
