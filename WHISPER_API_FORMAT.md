# Whisper Transcription API Format

## Backend Endpoints

### Main Backend (Integrated)
- **URL**: `http://127.0.0.1:5000/nutrition/transcribe`
- **Method**: POST
- **Content-Type**: application/json

### Standalone Nutrition Backend
- **URL**: `http://127.0.0.1:8002/transcribe`
- **Method**: POST
- **Content-Type**: application/json

## Request Format

### Required Headers
```json
{
  "Content-Type": "application/json"
}
```

### Request Body Structure
```json
{
  "audio": "base64_encoded_audio_data",
  "language": "language_code_or_auto",
  "method": "whisper"
}
```

### Parameters Explanation

#### 1. `audio` (Required)
- **Type**: String
- **Format**: Base64 encoded audio data
- **Supported Formats**: WebM, WAV, MP3, M4A, OGG
- **Example**: `"UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqF..."`

#### 2. `language` (Optional)
- **Type**: String
- **Default**: `"auto"`
- **Options**:
  - `"auto"` - Auto-detect language (tries Tamil first, then English)
  - `"en"` - English
  - `"ta"` - Tamil
  - `"hi"` - Hindi
  - Any ISO 639-1 language code supported by OpenAI Whisper

#### 3. `method` (Optional)
- **Type**: String
- **Default**: `"whisper"`
- **Options**: Currently only `"whisper"` is supported

## Complete Request Example

```json
{
  "audio": "UklGRnoGAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQoGAACBhYqF...",
  "language": "auto",
  "method": "whisper"
}
```

## Response Format

### Success Response (200)
```json
{
  "success": true,
  "transcription": "The transcribed text from the audio",
  "language": "detected_or_specified_language",
  "method": "whisper",
  "translation_note": "Additional notes if Tamil detected",
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Error Response (400/500)
```json
{
  "success": false,
  "message": "Error description"
}
```

## Common Error Messages

1. **Missing API Key**
   ```json
   {
     "success": false,
     "message": "OpenAI API key not configured"
   }
   ```

2. **Missing Audio Data**
   ```json
   {
     "success": false,
     "message": "Audio data is required"
   }
   ```

3. **Invalid Audio Format**
   ```json
   {
     "success": false,
     "message": "Invalid audio data: Invalid base64 encoding"
   }
   ```

4. **Transcription Failed**
   ```json
   {
     "success": false,
     "message": "Transcription failed: [OpenAI error message]"
   }
   ```

## Audio Format Requirements

### From Flutter Web (Recommended)
```dart
// MediaRecorder configuration
_mediaRecorder = html.MediaRecorder(stream, {
  'mimeType': 'audio/webm;codecs=opus',
  'audioBitsPerSecond': 128000,
});
```

### Audio Quality Guidelines
- **Sample Rate**: 44100 Hz (recommended)
- **Channels**: Mono (1 channel) or Stereo
- **Bit Rate**: 128kbps minimum
- **Duration**: Minimum 0.1 seconds, Maximum 25MB file size
- **Format**: WebM (preferred), WAV, MP3, M4A, OGG

## Language Detection Logic

When `language` is set to `"auto"`:

1. **First Attempt**: Try Tamil (`"ta"`) detection
2. **Fallback**: If Tamil fails, try English (`"en"`)
3. **Detection**: Look for Tamil keywords in result
4. **Response**: Include translation note if Tamil detected

## cURL Testing Example

```bash
curl -X POST http://127.0.0.1:5000/nutrition/transcribe \
  -H "Content-Type: application/json" \
  -d '{
    "audio": "YOUR_BASE64_AUDIO_HERE",
    "language": "auto",
    "method": "whisper"
  }'
```

## Flutter Implementation Example

```dart
final response = await http.post(
  Uri.parse('${ApiConfig.nutritionBaseUrl}/nutrition/transcribe'),
  headers: {
    'Content-Type': 'application/json',
  },
  body: json.encode({
    'audio': base64AudioData,
    'language': 'auto',
    'method': 'whisper',
  }),
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  if (data['success'] == true) {
    final transcription = data['transcription'];
    print('✅ Transcription: $transcription');
  }
}
```

## Environment Setup

Make sure the OpenAI API key is set in your environment:

```bash
# Windows
set OPENAI_API_KEY=your_openai_api_key_here

# Linux/Mac
export OPENAI_API_KEY=your_openai_api_key_here
```

## Backend Processing Flow

1. **Receive Request**: POST to `/nutrition/transcribe`
2. **Validate Input**: Check for required `audio` field
3. **Decode Audio**: Base64 decode to binary data
4. **Create Temp File**: Save as temporary file (.webm/.wav)
5. **Call OpenAI**: Send to Whisper-1 model
6. **Process Response**: Extract transcription text
7. **Cleanup**: Delete temporary file
8. **Return Result**: JSON response with transcription

## Notes

- **File Size Limit**: OpenAI Whisper has a 25MB file size limit
- **Timeout**: Backend requests timeout after 60 seconds
- **Cleanup**: Temporary files are automatically deleted
- **Error Handling**: All errors are caught and returned as JSON
- **Logging**: All requests are logged to console for debugging
