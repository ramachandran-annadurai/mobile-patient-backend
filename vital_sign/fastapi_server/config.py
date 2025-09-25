import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Settings:
    # MongoDB Configuration
    MONGO_URI: str = os.getenv("MONGO_URI", "mongodb+srv://ramya:XxFn6n0NXx0wBplV@cluster0.c1g1bm5.mongodb.net/?retryWrites=true&w=majority")
    DB_NAME: str = os.getenv("DB_NAME", "patients_db")
    COLLECTION_NAME: str = os.getenv("COLLECTION_NAME", "patient")
    
    # FastAPI Configuration
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # Security
    SECRET_KEY: str = "your_secret_key_here_change_in_production"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS
    ALLOWED_ORIGINS: list = [
        "http://localhost:3000", 
        "http://127.0.0.1:3000",
        "http://localhost:8080",  # Flutter web default port
        "http://127.0.0.1:8080",
        "http://localhost:5000",  # Alternative Flutter web port
        "http://127.0.0.1:5000",
        "http://localhost:8000",  # Same port as backend (for testing)
        "http://127.0.0.1:8000",
        "*"  # Allow all origins for development
    ]
    
    # Rate Limiting
    RATE_LIMIT_PER_MINUTE: int = 100

settings = Settings()
