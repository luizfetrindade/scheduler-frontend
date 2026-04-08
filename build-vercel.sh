#!/bin/bash

# Exit on error
set -e

echo "--- Starting Resilient Flutter Web Build for Vercel ---"

# 1. Config Local Cache and Tools to avoid Permission Denied (Exit 69)
# We use the current directory for everything since Vercel allows writing here.
export PUB_CACHE=$(pwd)/.pub-cache
export PATH="$PATH:$(pwd)/flutter/bin"

# 2. Configure Git Auth for private repositories
if [ ! -z "$GITHUB_TOKEN" ]; then
  echo "Configuring Git authentication for private repositories..."
  git config --global url."https://$GITHUB_TOKEN@github.com/".insteadOf "https://github.com/"
fi

# 2. Clone Flutter SDK if not present
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1
else
  echo "Flutter SDK already exists."
fi

# 3. Explicitly set permissions
chmod -R +x flutter/bin

# 4. Disable analytics to speed up and avoid network blocks
flutter config --no-analytics
flutter config --enable-web

# 5. Verify installation
echo "Flutter version details:"
flutter --version

# 6. Build
echo "Fetching dependencies..."
flutter pub get

API_URL=${PROD_API_URL:-"https://scheduler-base-production.up.railway.app"}
echo "Building for Web with API_URL: $API_URL"

flutter build web --release \
  --dart-define=ENV=prod \
  --dart-define=API_URL=$API_URL

echo "--- Build Finished Successfully ---"
