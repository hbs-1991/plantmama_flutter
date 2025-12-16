#!/bin/bash
# Run Flutter app with custom backend URL
# Usage: ./scripts/run_custom.sh <backend_url> [device]
# Examples:
#   ./scripts/run_custom.sh http://192.168.1.100:8000/api
#   ./scripts/run_custom.sh https://your-ngrok-url.ngrok.io/api -d emulator

if [ -z "$1" ]; then
    echo "Usage: ./scripts/run_custom.sh <backend_url> [device]"
    echo "Example: ./scripts/run_custom.sh http://192.168.1.100:8000/api"
    exit 1
fi

BACKEND_URL=$1
DEVICE_ARG=""
if [ ! -z "$2" ]; then
    DEVICE_ARG="-d $2"
fi

echo "Starting Flutter app with custom backend..."
echo "API: $BACKEND_URL"
echo ""

flutter run $DEVICE_ARG \
    --dart-define=API_BASE_URL=$BACKEND_URL \
    --dart-define=APP_ENV=development
