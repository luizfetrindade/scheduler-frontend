#!/bin/bash

# Exit on error
set -e

echo "--- Starting Flutter Web Build for Vercel ---"

# 1. Clone Flutter SDK if not present (Vercel cache might keep it)
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK already exists, skipping clone."
fi

# 2. Setup PATH
export PATH="$PATH:$(pwd)/flutter/bin"

# 3. Verify Flutter installation
echo "Flutter path: $(which flutter)"
flutter --version

# 4. Enable web support (just in case)
flutter config --enable-web

# 5. Get dependencies
echo "Fetching dependencies..."
flutter pub get

# 6. Build Web
# Use the PROD_API_URL environment variable from Vercel if available, 
# otherwise use a placeholder or the one provided directly.
API_URL=${PROD_API_URL:-"https://scheduler-base-production.up.railway.app"}

echo "Building for Web with API_URL: $API_URL"

flutter build web --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=$API_URL

echo "--- Build Finished Successfully ---"
