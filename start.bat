@echo off
title FinGoals
color 0A

echo.
echo  FinGoals - Financial Command Center
echo  =====================================
echo.

echo  [1/3] Installing Python dependencies...
pip install -r requirements.txt -q

echo  [2/3] Starting Backend API (port 8000)...
start "FinGoals API" cmd /k "python run.py"
timeout /t 3 /nobreak >nul

echo  [3/3] Starting Frontend (port 5173)...
cd frontend
start "FinGoals UI" cmd /k "npm run dev"
cd ..

echo.
echo  FinGoals is starting...
echo.
echo  Open: http://localhost:5173
echo  API:  http://localhost:8000
echo  Docs: http://localhost:8000/docs
echo.
pause
