"""
Tests for main application endpoints
"""

import pytest
from fastapi.testclient import TestClient

def test_health_check(client: TestClient):
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "service" in data

def test_root_endpoint(client: TestClient):
    """Test root endpoint"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "name" in data
    assert "version" in data
    assert "description" in data
    assert "status" in data
    assert "endpoints" in data

def test_api_docs_available(client: TestClient):
    """Test that API documentation is available"""
    response = client.get("/docs")
    assert response.status_code == 200

def test_redoc_available(client: TestClient):
    """Test that ReDoc documentation is available"""
    response = client.get("/redoc")
    assert response.status_code == 200
