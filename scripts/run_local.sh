#!/bin/bash
# Run Flutter app connected to local backend (port 8000)
# Usage: ./scripts/run_local.sh [device]
# Examples:
#   ./scripts/run_local.sh              # Run on default device
#   ./scripts/run_local.sh -d emulator  # Run on Android emulator
#   ./scripts/run_local.sh -d iphone    # Run on iOS simulator

DEVICE_ARG=""
if [ ! -z "$1" ]; then
    DEVICE_ARG="-d $1"
fi

echo "Starting Flutter app with local backend (port 8000)..."
echo "Environment: development"
echo ""

flutter run $DEVICE_ARG \
    --dart-define=APP_ENV=development
