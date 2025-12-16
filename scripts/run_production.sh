#!/bin/bash
# Run Flutter app connected to production backend
# Usage: ./scripts/run_production.sh [device]

DEVICE_ARG=""
if [ ! -z "$1" ]; then
    DEVICE_ARG="-d $1"
fi

echo "Starting Flutter app with PRODUCTION backend..."
echo "API: https://plantmama.cloud/api"
echo ""

flutter run $DEVICE_ARG \
    --dart-define=API_BASE_URL=https://plantmama.cloud/api \
    --dart-define=APP_ENV=production
