#!/bin/bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"
export PATH="$PATH:$HOME/flutter/bin"

echo "Starting FastAPI server..."
source "$ROOT/venv/bin/activate"
"$ROOT/venv/bin/uvicorn" api.main:app --host 0.0.0.0 --port 8000 &
API_PID=$!

# Wait for the server to be ready
until curl -s http://localhost:8000/health > /dev/null 2>&1; do
  sleep 1
done
echo "API ready."

echo "Launching Flutter app..."
flutter run -d linux

# When Flutter exits, kill the API server
kill $API_PID 2>/dev/null
echo "Stopped."
