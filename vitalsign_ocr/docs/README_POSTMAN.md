# Medication OCR API - Postman Collection

A comprehensive Postman collection for testing all endpoints of the Medication OCR API. This collection includes pre-configured requests, automated tests, and environment variables for easy API testing.

## 📁 Collection File

- **File**: `Medication_OCR_API.postman_collection.json`
- **Import**: Use this file to import the collection into Postman

## 🚀 Quick Start

### 1. Import the Collection

1. Open Postman
2. Click **Import** button
3. Drag and drop `Medication_OCR_API.postman_collection.json` or click to browse
4. The collection will be imported with all endpoints organized

### 2. Set Environment Variables

The collection uses these variables that you can customize:

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `base_url` | `http://localhost:8000` | Your API server URL |
| `base64_image` | `iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==` | Sample base64 image for testing |
| `webhook_id` | `your-webhook-id-here` | Webhook ID for update/delete operations |

## 📋 Available Endpoints

### 🔍 Health & Status
- **Health Check** - `GET /health`
- **Root Service Info** - `GET /`

### 🚀 Enhanced OCR
- **Enhanced OCR Upload** - `POST /api/v1/ocr/enhanced/upload`
- **Enhanced OCR Base64** - `POST /api/v1/ocr/enhanced/base64`

### 📷 Standard OCR
- **Standard OCR Upload** - `POST /api/v1/ocr/upload`
- **Standard OCR Base64** - `POST /api/v1/ocr/base64`

### 🔗 Webhook Management
- **Get Webhook Configs** - `GET /api/v1/webhook/configs`
- **Create Webhook Config** - `POST /api/v1/webhook/configs`
- **Update Webhook Config** - `PUT /api/v1/webhook/configs/{id}`
- **Delete Webhook Config** - `DELETE /api/v1/webhook/configs/{id}`

### 📚 API Documentation
- **Swagger UI** - `GET /docs`
- **ReDoc** - `GET /redoc`

## 🧪 Testing Features

### Automated Tests
Each request includes automated tests that verify:
- ✅ Status code is 200
- ✅ Response time is under 5 seconds
- ✅ Response has content
- ✅ JSON responses are valid
- ✅ Required fields are present

### Pre-request Scripts
- Sets default User-Agent header
- Logs request details for debugging
- Prepares common request setup

### Post-request Scripts
- Validates response structure
- Checks response performance
- Logs response details

## 📝 Usage Examples

### Testing OCR Upload

1. **Select "Enhanced OCR Upload" request**
2. **In the Body tab, select "form-data"**
3. **Click "Select Files" next to the "file" key**
4. **Choose an image file (JPEG, PNG, etc.)**
5. **Click "Send"**

### Testing Base64 OCR

1. **Select "Enhanced OCR Base64" request**
2. **The request body is pre-filled with a sample base64 image**
3. **Replace the base64 string with your own image data if needed**
4. **Click "Send"**

### Testing Webhook Configuration

1. **Select "Create Webhook Config" request**
2. **Modify the JSON body with your webhook details:**
   ```json
   {
     "name": "My Webhook",
     "url": "https://your-server.com/webhook",
     "enabled": true,
     "description": "Custom webhook for OCR results",
     "headers": {
       "Authorization": "Bearer your-token"
     },
     "timeout": 30,
     "retry_count": 3,
     "retry_delay": 5
   }
   ```
3. **Click "Send"**

## 🔧 Customization

### Adding New Endpoints

1. **Right-click on a folder** in the collection
2. **Select "Add Request"**
3. **Configure the request method, URL, and body**
4. **Add tests in the Tests tab**

### Modifying Tests

1. **Select any request**
2. **Go to the Tests tab**
3. **Modify the JavaScript test code**
4. **Save the request**

### Environment Variables

1. **Click the gear icon** (⚙️) in the top right
2. **Select "Add" to create a new environment**
3. **Add your variables:**
   - `base_url`: Your API server URL
   - `api_key`: Your authentication token (if needed)
   - `webhook_url`: Your webhook endpoint

## 🐛 Troubleshooting

### Common Issues

1. **Connection Refused**
   - Verify your API server is running
   - Check the `base_url` variable
   - Ensure no firewall blocking the connection

2. **File Upload Errors**
   - Check file size limits
   - Verify supported file formats
   - Ensure proper form-data encoding

3. **Authentication Errors**
   - Add required headers (Authorization, API-Key, etc.)
   - Verify token validity
   - Check permission settings

### Debug Information

- **Console logs** show request/response details
- **Test results** display validation status
- **Response headers** show server information
- **Response time** indicates performance

## 📊 Response Examples

### Successful OCR Response
```json
{
  "success": true,
  "filename": "medication_image.jpg",
  "text_count": 3,
  "results": [
    {
      "text": "Aspirin 100mg",
      "confidence": 0.95,
      "bbox": [[10, 20], [200, 20], [200, 40], [10, 40]]
    },
    {
      "text": "Take 1 tablet daily",
      "confidence": 0.88,
      "bbox": [[10, 50], [250, 50], [250, 70], [10, 70]]
    }
  ]
}
```

### Health Check Response
```json
{
  "status": "healthy",
  "service": "Medication OCR API",
  "timestamp": "2024-01-15T10:30:00Z",
  "version": "1.0.0"
}
```

## 🔄 Running Tests

### Individual Request Tests
1. **Select any request**
2. **Click "Send"**
3. **View test results in the Test Results tab**

### Collection Runner
1. **Click the collection name**
2. **Click "Run collection"**
3. **Select requests to run**
4. **Click "Run Medication OCR API"**

### Newman CLI (Automated Testing)
```bash
# Install Newman
npm install -g newman

# Run collection
newman run Medication_OCR_API.postman_collection.json

# Run with environment
newman run Medication_OCR_API.postman_collection.json -e environment.json

# Generate HTML report
newman run Medication_OCR_API.postman_collection.json -r html
```

## 📱 Mobile Testing

### Postman Mobile App
1. **Install Postman mobile app**
2. **Import the collection**
3. **Test APIs on mobile devices**
4. **Use device camera for image uploads**

### Mobile-Specific Tests
- Test image capture and upload
- Verify mobile network performance
- Check responsive design endpoints

## 🔒 Security Considerations

### API Keys
- Store sensitive tokens in environment variables
- Use different keys for development/production
- Rotate keys regularly

### File Uploads
- Test with various file types
- Verify file size restrictions
- Check for malicious file handling

### Webhook Security
- Use HTTPS for webhook URLs
- Implement proper authentication
- Validate webhook payloads

## 📈 Performance Testing

### Load Testing
- Use Postman's collection runner with iterations
- Monitor response times
- Test concurrent requests

### Stress Testing
- Send large files
- Test with multiple concurrent users
- Monitor server resource usage

## 🎯 Best Practices

1. **Organize requests** in logical folders
2. **Use descriptive names** for requests
3. **Add comprehensive tests** for validation
4. **Document request parameters** clearly
5. **Use environment variables** for configuration
6. **Regularly update** the collection
7. **Share collections** with team members
8. **Version control** your collections

## 📞 Support

For issues or questions:
1. Check the troubleshooting section
2. Verify API server configuration
3. Review test results and console logs
4. Check Postman documentation
5. Verify environment variables

## 🔄 Updates

This collection is designed to work with the latest version of the Medication OCR API. Check for updates when:
- New endpoints are added
- API response formats change
- Authentication methods are updated
- New features are implemented
