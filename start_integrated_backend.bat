@echo off
echo ========================================
echo Starting Integrated Backend Server
echo ========================================
echo.
echo This backend now includes:
echo ✅ User authentication & patient profiles
echo ✅ Medication tracking & reminders
echo ✅ Mental health tracking
echo ✅ Voice transcription (Whisper AI)
echo ✅ Food analysis (GPT-4)
echo ✅ All services on PORT 5000
echo.
echo Starting server...
echo.
cd /d "%~dp0"

REM Set OpenAI API Key (replace with your actual key)
set OPENAI_API_KEY=your_actual_openai_key_here
python app_simple.py
pause
