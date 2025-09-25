# Medication OCR API Module

A comprehensive Python module for Optical Character Recognition (OCR) processing of medication-related documents, including prescriptions, medical forms, and pharmaceutical labels.

## 🚀 Features

- **Enhanced OCR Processing**: Support for PDF, images, DOCX, and TXT files
- **Standard OCR**: Image-based text extraction with confidence scores
- **Webhook Integration**: Automatic delivery of OCR results to external systems
- **Dynamic Content Analysis**: Intelligent text summarization and categorization
- **FastAPI Framework**: Modern, fast web framework with automatic API documentation
- **Async Processing**: Non-blocking operations for better performance

## 📦 Installation

### Option 1: Install from source
```bash
git clone https://github.com/logicalminds/medication-ocr-api.git
cd medication-ocr-api
pip install -e .
```

### Option 2: Install with pip (when published)
```bash
pip install medication-ocr-api
```

### Option 3: Install with development dependencies
```bash
pip install -e ".[dev]"
```

## 🏗️ Module Structure

```
medication/                    # Root package
├── __init__.py              # Package initialization and exports
├── __main__.py              # Module entry point (python -m medication)
├── app/                     # Main application package
│   ├── __init__.py         # App package exports
│   ├── main.py             # FastAPI application
│   ├── config.py           # Configuration management
│   ├── api/                # API endpoints
│   │   ├── __init__.py
│   │   └── endpoints.py    # Route definitions
│   ├── models/             # Data models
│   │   ├── __init__.py
│   │   ├── schemas.py      # Pydantic schemas
│   │   └── webhook_config.py
│   └── services/           # Business logic
│       ├── __init__.py
│       ├── ocr_service.py  # Standard OCR
│       ├── enhanced_ocr_service.py  # Enhanced OCR
│       ├── webhook_service.py
│       └── webhook_config_service.py
├── tests/                   # Test suite
├── setup.py                 # Package setup
├── pyproject.toml          # Modern Python packaging
├── MANIFEST.in             # Package manifest
└── requirements.txt        # Dependencies
```

## 🚀 Usage

### As a Python Module

```python
from medication import app, settings, EnhancedOCRService

# Use the FastAPI app
fastapi_app = app

# Access configuration
host = settings.HOST
port = settings.PORT

# Use services
ocr_service = EnhancedOCRService()
```

### As a Command Line Tool

```bash
# Run the API server
medication-ocr-api

# Or run as a module
python -m medication
```

### As a FastAPI Application

```python
from medication.app.main import app
import uvicorn

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

## 🔧 Configuration

The module uses environment variables for configuration:

```bash
# Server settings
HOST=0.0.0.0
PORT=8000
DEBUG=false

# Logging
LOG_LEVEL=INFO
LOG_FORMAT=%(asctime)s - %(name)s - %(levelname)s - %(message)s

# CORS
CORS_ORIGINS=["*"]
CORS_ALLOW_CREDENTIALS=true
```

## �� API Endpoints

### Core Endpoints

- `GET /health` - Health check endpoint
- `GET /` - Service information and available endpoints
- `POST /api/v1/ocr/upload` - **Single-Click OCR Processing** (Upload → OCR → Webhook → Final Result)
- `POST /api/v1/ocr/base64` - Base64 image OCR processing
- `GET /api/v1/ocr/enhanced/formats` - Get supported file formats
- `GET /api/v1/webhook/configs` - Get webhook configurations
- `POST /api/v1/webhook/configs` - Create webhook configuration
- `PUT /api/v1/webhook/configs/{webhook_id}` - Update webhook configuration
- `DELETE /api/v1/webhook/configs/{webhook_id}` - Delete webhook configuration

### Single-Click OCR Flow

The main endpoint `/api/v1/ocr/upload` provides a **complete OCR workflow in one API call**:

1. **📁 File Upload** - Accepts images, PDFs, DOC, DOCX, TXT files
2. **🔍 OCR Processing** - Extracts text using PaddleOCR with confidence scores
3. **🔗 Webhook Delivery** - Automatically sends results to configured webhooks (n8n)
4. **📤 Final Response** - Returns complete result including webhook delivery status

**Response includes:**
- OCR extracted text and results
- `extracted_text` field (combined text)
- `full_content` field (descriptive summary)
- `webhook_delivery` status and results
- File metadata and processing information

**Example Response:**
```json
{
  "success": true,
  "filename": "medication.pdf",
  "text_count": 25,
  "extracted_text": "Complete extracted text content...",
  "full_content": "Description of content...",
  "results": [
    {
      "text": "Sample text",
      "confidence": 0.95,
      "bbox": [[10, 20], [100, 20], [100, 40], [10, 40]]
    }
  ],
  "file_type": "PDF",
  "total_pages": 2,
  "processing_summary": {
    "total_pages": 2,
    "native_text_pages": 0,
    "ocr_pages": 2
  },
  "webhook_delivery": {
    "status": "completed",
    "n8n_webhook_response": "Actual response content from n8n webhook",
    "results": [
      {
        "config_id": "fba6b54c-97a8-4a11-a7d1-e72e2eb5dd74",
        "config_name": "Default n8n Webhook",
        "url": "https://n8n.example.com/webhook/...",
        "success": true,
        "timestamp": "2025-08-26T15:30:00.000000",
        "error": null
      }
    ],
    "timestamp": "2025-08-26T15:30:00.000000"
  }
}
```

### Utility Endpoints
- `GET /docs` - Interactive API documentation
- `GET /redoc` - ReDoc API documentation

## 🧪 Testing

Run the test suite:

```bash
# Install test dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Run with coverage
pytest --cov=medication

# Run specific test file
pytest tests/test_main.py
```

## 📦 Development

### Setup Development Environment

```bash
# Clone repository
git clone https://github.com/logicalminds/medication-ocr-api.git
cd medication-ocr-api

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install development dependencies
pip install -e ".[dev]"

# Install pre-commit hooks
pre-commit install
```

### Code Quality

```bash
# Format code
black medication/ tests/

# Lint code
flake8 medication/ tests/

# Type checking
mypy medication/

# Run all quality checks
pre-commit run --all-files
```

## 📋 Dependencies

### Core Dependencies
- `fastapi>=0.104.0` - Web framework
- `uvicorn[standard]>=0.24.0` - ASGI server
- `pydantic>=2.0.0` - Data validation
- `paddleocr>=2.7.0.3` - OCR engine
- `PyMuPDF>=1.20.2` - PDF processing
- `opencv-python>=4.8.0` - Image processing
- `Pillow>=10.0.0` - Image handling

### Development Dependencies
- `pytest>=6.0` - Testing framework
- `pytest-asyncio>=0.18.0` - Async testing
- `black>=21.0` - Code formatting
- `flake8>=3.8` - Linting
- `mypy>=0.800` - Type checking

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/logicalminds/medication-ocr-api/issues)
- **Documentation**: [API Docs](http://localhost:8000/docs) (when running)
- **Email**: info@logicalminds.com

## 🔄 Version History

- **v1.0.0** - Initial release with OCR and webhook functionality
- **v1.1.0** - Enhanced OCR with dynamic content analysis
- **v1.2.0** - Improved module structure and packaging

---

**Made with ❤️ by LogicalMinds**
