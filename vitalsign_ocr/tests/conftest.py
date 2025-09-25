"""
Pytest configuration and fixtures for Medication OCR API tests
"""

import pytest
import asyncio
from fastapi.testclient import TestClient
from medication.app.main import app
from medication.app.config import settings

@pytest.fixture
def client():
    """Test client for FastAPI application"""
    return TestClient(app)

@pytest.fixture
def test_settings():
    """Test configuration settings"""
    return settings

@pytest.fixture(scope="session")
def event_loop():
    """Create an instance of the default event loop for the test session"""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def sample_image_base64():
    """Sample base64 encoded image for testing"""
    return "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=="

@pytest.fixture
def sample_webhook_url():
    """Sample webhook URL for testing"""
    return "https://webhook.site/test-123"
