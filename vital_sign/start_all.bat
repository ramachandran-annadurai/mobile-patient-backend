@echo off
echo Starting Vital Signs Monitor System...
echo.
echo 1. Starting FastAPI Backend Server with MongoDB...
start "FastAPI Server" cmd /k "cd fastapi_server && python main.py"
echo.
echo 2. Waiting 5 seconds for server to start...
timeout /t 5 /nobreak > nul
echo.
echo 3. Starting Flutter Frontend...
start "Flutter App" cmd /k "flutter run -d chrome"
echo.
echo Both services are starting...
echo FastAPI Server: http://localhost:8000
echo Flutter App: Will open in Chrome browser
echo.
pause
