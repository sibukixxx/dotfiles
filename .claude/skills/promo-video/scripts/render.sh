#!/bin/bash
# Render promo video composition
# Usage: ./render.sh <CompositionId> [output_name]

set -e

COMPOSITION_ID="${1:?Usage: ./render.sh <CompositionId> [output_name]}"
OUTPUT_NAME="${2:-$COMPOSITION_ID}"

# Navigate to promo-video directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR}/../../../../apps/promo-video"

if [ ! -d "$PROJECT_DIR" ]; then
  echo "Error: promo-video project not found at $PROJECT_DIR"
  echo "Please run this script from within the lp-packages repository"
  exit 1
fi

cd "$PROJECT_DIR"

# Ensure dependencies are installed
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Create output directory
mkdir -p out

# Render 16:9 version
echo "Rendering ${COMPOSITION_ID} (1920x1080)..."
npx remotion render "$COMPOSITION_ID" "out/${OUTPUT_NAME}.mp4"

# Render square version if it exists
SQUARE_ID="${COMPOSITION_ID}-Square"
if npx remotion compositions 2>/dev/null | grep -q "$SQUARE_ID"; then
  echo "Rendering ${SQUARE_ID} (1080x1080)..."
  npx remotion render "$SQUARE_ID" "out/${OUTPUT_NAME}-square.mp4"
fi

echo ""
echo "Done! Output files:"
ls -la out/${OUTPUT_NAME}*.mp4
