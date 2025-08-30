@echo off
echo Starting Nutrition Backend...
cd /d "%~dp0"

REM Set OpenAI API Key (replace with your actual key)
set OPENAI_API_KEY=your_actual_openai_key_here

python nutrition_backend.py
pause
