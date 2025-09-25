# Vital Signs Monitor FastAPI Server

A FastAPI-based backend server for monitoring and analyzing patient vital signs with AI-powered anomaly detection and trend analysis.

## Features

- **Vital Signs Management**: CRUD operations for vital signs data
- **AI Analysis**: Anomaly detection, trend analysis, and early warning scores
- **Real-time Monitoring**: Health summaries and alert management
- **MongoDB Integration**: Scalable data storage with proper indexing
- **RESTful API**: Clean, documented API endpoints
- **CORS Support**: Ready for frontend integration

## Installation

1. **Install Python dependencies**:
   ```bash
   cd fastapi_server
   pip install -r requirements.txt
   ```

2. **Set up environment variables**:
   Create a `.env` file in the `fastapi_server` directory:
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

   # Rate Limiting
   RATE_LIMIT_PER_MINUTE=100
   ```

3. **Start MongoDB**:
   Make sure MongoDB is running on your system.

## Running the Server

### Development Mode
```bash
cd fastapi_server
python main.py
```

### Production Mode
```bash
cd fastapi_server
uvicorn main:app --host 0.0.0.0 --port 8000
```

The server will be available at `http://localhost:8000`

## API Documentation

Once the server is running, you can access:
- **Interactive API docs**: `http://localhost:8000/docs`
- **ReDoc documentation**: `http://localhost:8000/redoc`

## API Endpoints

### Vital Signs
- `POST /vital-signs` - Create a new vital sign record
- `GET /vital-signs` - Get vital signs with filtering
- `GET /vital-signs/{id}` - Get a specific vital sign
- `PUT /vital-signs/{id}` - Update a vital sign
- `DELETE /vital-signs/{id}` - Delete a vital sign
- `GET /vital-signs/stats` - Get vital signs statistics

### AI Analysis
- `GET /analysis/anomalies` - Detect anomalies in vital signs
- `GET /analysis/trends` - Analyze trends in vital signs
- `GET /analysis/early-warning-score` - Calculate Early Warning Score

### Health Monitoring
- `GET /health-summary` - Get comprehensive health summary
- `GET /health` - Health check endpoint

### Alerts
- `POST /alerts` - Create a new alert
- `GET /alerts` - Get alerts with filtering
- `PUT /alerts/{id}` - Update an alert

## Data Models

### VitalSign
```json
{
  "id": "string",
  "type": "heartRate|bloodPressure|temperature|spO2|respiratoryRate",
  "value": 0.0,
  "secondary_value": 0.0,
  "timestamp": "2024-01-01T00:00:00Z",
  "notes": "string",
  "is_anomaly": false,
  "confidence": 0.0
}
```

### VitalSignAlert
```json
{
  "id": "string",
  "type": "heartRate|bloodPressure|temperature|spO2|respiratoryRate",
  "severity": "low|medium|high|critical",
  "message": "string",
  "timestamp": "2024-01-01T00:00:00Z",
  "action_required": "string",
  "is_resolved": false
}
```

## AI Features

### Anomaly Detection
- Uses statistical methods (Z-score analysis)
- Configurable sensitivity threshold
- Provides confidence scores and suggested actions

### Trend Analysis
- Linear regression analysis
- Trend classification (increasing/decreasing/stable)
- Change percentage calculation

### Early Warning Score (EWS)
- Clinical scoring system
- Risk level assessment
- Actionable recommendations

## Configuration

The server uses environment variables for configuration. Key settings:

- `MONGO_URI`: MongoDB connection string
- `DB_NAME`: Database name
- `COLLECTION_NAME`: Collection name for vital signs
- `HOST`: Server host (default: 0.0.0.0)
- `PORT`: Server port (default: 8000)
- `DEBUG`: Enable debug mode
- `ALLOWED_ORIGINS`: CORS allowed origins

## Security

- Input validation using Pydantic models
- CORS configuration for frontend integration
- Rate limiting support
- Secure MongoDB connection

## Monitoring

- Health check endpoint at `/health`
- Comprehensive logging
- Error handling and reporting
- Performance monitoring ready

## Integration with Flutter

This FastAPI server is designed to work seamlessly with the Flutter frontend. The API endpoints match the expected data structures and provide all necessary functionality for:

- Real-time vital signs monitoring
- AI-powered analysis and alerts
- Historical data visualization
- User preference management

## Development

### Adding New Features
1. Define Pydantic models in `models.py`
2. Add database operations in `database.py`
3. Create API endpoints in `main.py`
4. Add AI analysis in `ai_service.py`

### Testing
```bash
# Run tests (when implemented)
pytest

# Test specific endpoint
curl http://localhost:8000/health
```

## Production Deployment

For production deployment:

1. Set `DEBUG=False` in environment
2. Use a secure `SECRET_KEY`
3. Configure proper CORS origins
4. Set up SSL/TLS
5. Use a production ASGI server like Gunicorn
6. Set up monitoring and logging
7. Configure MongoDB with authentication

## Troubleshooting

### Common Issues

1. **MongoDB Connection Error**:
   - Ensure MongoDB is running
   - Check connection string in `.env`
   - Verify network connectivity

2. **Import Errors**:
   - Install all dependencies: `pip install -r requirements.txt`
   - Check Python version compatibility

3. **CORS Issues**:
   - Update `ALLOWED_ORIGINS` in `.env`
   - Check frontend URL configuration

### Logs
Check server logs for detailed error information. The server logs all operations and errors for debugging.
