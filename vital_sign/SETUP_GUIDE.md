# Vital Signs Monitor - Setup Guide

This guide will help you set up and run the simplified Vital Signs Monitor system with FastAPI backend and Flutter frontend.

## Prerequisites

### 1. Python Environment
- Python 3.8 or higher
- pip (Python package installer)

### 2. Flutter Environment
- Flutter SDK (latest stable version)
- Dart SDK (comes with Flutter)

### 3. MongoDB (Optional)
- MongoDB server running on your system (optional - system works in mock mode without MongoDB)
- Default connection: `mongodb://localhost:27017`

## Setup Instructions

### Step 1: Start MongoDB (Optional)
If you want to use MongoDB, make sure it's running on your system:
```bash
# On Windows (if installed as service)
net start MongoDB

# On macOS/Linux
sudo systemctl start mongod
# or
mongod
```

**Note**: The system will work in mock mode if MongoDB is not available.

### Step 2: Setup FastAPI Backend

1. **Navigate to the FastAPI server directory:**
   ```bash
   cd fastapi_server
   ```

2. **Install Python dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

3. **Verify the .env file exists:**
   The `.env` file should contain:
   ```env
   # MongoDB Configuration
   MONGO_URI=mongodb://localhost:27017
   DB_NAME=vital_signs_db
   COLLECTION_NAME=patients_v2

   # FastAPI Configuration
   HOST=0.0.0.0
   PORT=8000
   DEBUG=True

   # Security
   SECRET_KEY=your_secret_key_here_change_in_production
   ALGORITHM=HS256
   ACCESS_TOKEN_EXPIRE_MINUTES=30

   # CORS
   ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
   ```

4. **Start the FastAPI server:**
   ```bash
   python main.py
   ```
   
   Or using uvicorn directly:
   ```bash
   uvicorn main:app --host 0.0.0.0 --port 8000 --reload
   ```

5. **Verify the server is running:**
   - Open your browser and go to: `http://localhost:8000`
   - You should see the FastAPI documentation
   - API docs are available at: `http://localhost:8000/docs`

### Step 3: Setup Flutter Frontend

1. **Navigate back to the project root:**
   ```bash
   cd ..
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Update the .env file for Flutter:**
   Make sure your `.env` file in the root directory contains:
   ```env
   # MongoDB Configuration
   MONGO_URI=mongodb://localhost:27017
   DB_NAME=vital_signs_db
   COLLECTION_NAME=patients_v2
   API_BASE_URL=http://localhost:8000
   API_TIMEOUT=30000
   ```

4. **Run the Flutter app:**
   ```bash
   # For web (Chrome)
   flutter run -d chrome
   
   # For Android (if you have an emulator/device)
   flutter run -d android
   
   # For iOS (if you have Xcode and simulator)
   flutter run -d ios
   ```

## Running the Complete System

### Option 1: Run Both Services Separately

1. **Terminal 1 - FastAPI Server:**
   ```bash
   cd fastapi_server
   python main.py
   ```

2. **Terminal 2 - Flutter App:**
   ```bash
   flutter run -d chrome
   ```

### Option 2: Using Scripts (Recommended)

Create these batch files for easier startup:

**start_backend.bat** (Windows):
```batch
@echo off
cd fastapi_server
python main.py
pause
```

**start_frontend.bat** (Windows):
```batch
@echo off
flutter run -d chrome
pause
```

## Verification

### 1. Backend Health Check
- Visit: `http://localhost:8000/health`
- Should return: `{"status": "healthy", "timestamp": "..."}`

### 2. API Documentation
- Visit: `http://localhost:8000/docs`
- Interactive API documentation should load

### 3. Flutter App
- Should open in your browser (Chrome)
- Login screen should appear
- You can create test accounts and start using the app

## Testing the Integration

### 1. Create a Vital Sign
Use the Flutter app to:
- Navigate to "Input Vital Signs"
- Select a vital sign type (e.g., Heart Rate)
- Enter a value and save
- Check if it appears in the dashboard

### 2. Check API Response
Visit: `http://localhost:8000/vital-signs`
Should return JSON with your created vital signs.

### 3. Test AI Analysis
Visit: `http://localhost:8000/analysis/anomalies`
Should return anomaly detection results.

## Troubleshooting

### Common Issues

1. **MongoDB Connection Error:**
   - Ensure MongoDB is running
   - Check connection string in `.env`
   - Verify MongoDB is accessible on port 27017

2. **Python Import Errors:**
   - Run: `pip install -r requirements.txt`
   - Check Python version (3.8+)
   - Use virtual environment if needed

3. **Flutter Build Errors:**
   - Run: `flutter clean && flutter pub get`
   - Check Flutter version: `flutter --version`
   - Ensure all dependencies are compatible

4. **CORS Issues:**
   - Update `ALLOWED_ORIGINS` in FastAPI `.env`
   - Include your Flutter app's URL

5. **Port Conflicts:**
   - Change FastAPI port in `.env` if 8000 is busy
   - Update Flutter's `API_BASE_URL` accordingly

### Logs and Debugging

1. **FastAPI Logs:**
   - Check console output for errors
   - Enable debug mode in `.env`

2. **Flutter Logs:**
   - Use `flutter logs` command
   - Check browser developer tools (F12)

3. **MongoDB Logs:**
   - Check MongoDB log files
   - Use MongoDB Compass for database inspection

## Development Tips

1. **Hot Reload:**
   - FastAPI: Use `--reload` flag with uvicorn
   - Flutter: Use `r` key in terminal for hot reload

2. **Database Management:**
   - Use MongoDB Compass for visual database management
   - Clear test data: `db.patients_v2.deleteMany({})`

3. **API Testing:**
   - Use Postman or curl for API testing
   - FastAPI provides built-in testing interface at `/docs`

## Production Deployment

For production deployment:

1. **FastAPI:**
   - Use Gunicorn with Uvicorn workers
   - Set up reverse proxy (Nginx)
   - Use environment-specific `.env` files
   - Enable SSL/TLS

2. **Flutter:**
   - Build for production: `flutter build web`
   - Deploy to web server or CDN
   - Update API URLs for production

3. **MongoDB:**
   - Set up authentication
   - Configure replica sets
   - Enable SSL connections
   - Set up backups

## Support

If you encounter issues:
1. Check the logs for error messages
2. Verify all prerequisites are installed
3. Ensure all services are running
4. Check network connectivity between services
