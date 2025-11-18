#!/bin/bash
# =============================================================================
# Bulk Image Upload Script for StyleFinder
# =============================================================================
#
# This script uploads multiple images to StyleFinder's bulk processing API
# and polls for completion.
#
# Usage:
#   ./bulk_upload.sh image1.jpg image2.jpg image3.jpg
#   ./bulk_upload.sh ./closet_photos/*.jpg
#
# Requirements:
#   - curl
#   - jq (for JSON parsing)
#
# =============================================================================

set -e  # Exit on error

# =============================================================================
# Configuration - UPDATE THESE VALUES
# =============================================================================

DAYTONA_URL="https://8000-xxxxx.daytona.app"  # Your Daytona URL
USER_ID="test-user-123"                        # Your user ID
REMOVE_BACKGROUND="true"                       # true or false
POLL_INTERVAL=5                                # Seconds between status checks

# =============================================================================

# Check dependencies
command -v curl >/dev/null 2>&1 || { echo "❌ curl is required but not installed. Aborting." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq is required but not installed. Aborting." >&2; exit 1; }

# Check arguments
if [ $# -eq 0 ]; then
    echo "❌ Usage: $0 <image1.jpg> <image2.jpg> ..."
    exit 1
fi

# Check if Daytona URL is configured
if [ "$DAYTONA_URL" = "https://8000-xxxxx.daytona.app" ]; then
    echo "❌ Error: Please update DAYTONA_URL in the script"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "🚀 StyleFinder Bulk Image Upload"
echo "================================================================================"
echo "   Server:     $DAYTONA_URL"
echo "   User ID:    $USER_ID"
echo "   Images:     $# files"
echo "   Background: $([ "$REMOVE_BACKGROUND" = "true" ] && echo "Removed" || echo "Original")"
echo "================================================================================"

# Step 1: Upload images
echo ""
echo "📦 Uploading images..."

CURL_CMD="curl -s -X POST \"$DAYTONA_URL/bulk-analyze\" \
  -F \"user_id=$USER_ID\" \
  -F \"remove_background=$REMOVE_BACKGROUND\""

# Add each image as a file field
for img in "$@"; do
    if [ ! -f "$img" ]; then
        echo -e "${YELLOW}⚠️  Warning: $img not found, skipping${NC}"
        continue
    fi
    CURL_CMD="$CURL_CMD -F \"files=@$img\""
done

# Execute upload
RESPONSE=$(eval $CURL_CMD)

# Check for errors
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Upload failed${NC}"
    exit 1
fi

# Parse response
JOB_ID=$(echo "$RESPONSE" | jq -r '.job_id')
TOTAL_IMAGES=$(echo "$RESPONSE" | jq -r '.total_images')

if [ "$JOB_ID" = "null" ] || [ -z "$JOB_ID" ]; then
    echo -e "${RED}❌ Failed to create job${NC}"
    echo "Response: $RESPONSE"
    exit 1
fi

echo -e "${GREEN}✅ Upload successful!${NC}"
echo "   Job ID: $JOB_ID"
echo "   Images: $TOTAL_IMAGES"

# Step 2: Poll status
echo ""
echo "📊 Monitoring progress..."
echo "   (Polling every ${POLL_INTERVAL} seconds, press Ctrl+C to stop)"
echo ""

START_TIME=$(date +%s)

while true; do
    # Get status
    STATUS_RESPONSE=$(curl -s "$DAYTONA_URL/bulk-status/$JOB_ID")

    # Parse status
    STATE=$(echo "$STATUS_RESPONSE" | jq -r '.status')
    PROCESSED=$(echo "$STATUS_RESPONSE" | jq -r '.processed_images')
    FAILED=$(echo "$STATUS_RESPONSE" | jq -r '.failed_images')
    TOTAL=$(echo "$STATUS_RESPONSE" | jq -r '.total_images')
    PROGRESS=$(echo "$STATUS_RESPONSE" | jq -r '.progress_percent')

    # Calculate elapsed time
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))

    # Display progress bar
    BAR_LENGTH=30
    FILLED=$(awk "BEGIN {printf \"%.0f\", $BAR_LENGTH * $PROGRESS / 100}")
    BAR=$(printf '█%.0s' $(seq 1 $FILLED))
    EMPTY=$(printf '░%.0s' $(seq 1 $((BAR_LENGTH - FILLED))))

    printf "\r   [%s%s] %.1f%% | %d/%d | %ds elapsed" "$BAR" "$EMPTY" "$PROGRESS" "$PROCESSED" "$TOTAL" "$ELAPSED"

    # Check if complete
    if [ "$STATE" = "completed" ]; then
        echo ""
        echo -e "${GREEN}✅ Processing complete!${NC}"
        echo "   Processed: $PROCESSED items"
        if [ "$FAILED" -gt 0 ]; then
            echo -e "   ${YELLOW}Failed: $FAILED items${NC}"
        fi
        echo "   Time: ${ELAPSED}s"
        break
    elif [ "$STATE" = "failed" ]; then
        echo ""
        echo -e "${RED}❌ Job failed${NC}"
        ERROR_MSG=$(echo "$STATUS_RESPONSE" | jq -r '.error_message')
        if [ "$ERROR_MSG" != "null" ]; then
            echo "   Error: $ERROR_MSG"
        fi
        exit 1
    fi

    sleep $POLL_INTERVAL
done

# Step 3: Get results
echo ""
echo "📋 Fetching results..."

RESULTS=$(curl -s "$DAYTONA_URL/bulk-results/$JOB_ID")
TOTAL_ITEMS=$(echo "$RESULTS" | jq -r '.total_items')

echo ""
echo "🎉 Results for Job $JOB_ID"
echo "   Status: $(echo "$RESULTS" | jq -r '.status')"
echo "   Total Items: $TOTAL_ITEMS"
echo ""

if [ "$TOTAL_ITEMS" -eq 0 ]; then
    echo "   No items processed."
else
    echo "📋 Analyzed Items:"
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Parse and display each item
    echo "$RESULTS" | jq -r '.items[] | select(.status == "completed") |
        "\n✓ \(.item.type | ascii_upcase)
   Color:      \(.item.color)
   Pattern:    \(.item.pattern)
   Style:      \(.item.style)
   Confidence: \(.item.confidence * 100 | floor)%
   Seasons:    \(.item.season | join(", "))"'

    # Count failed items
    FAILED_COUNT=$(echo "$RESULTS" | jq '[.items[] | select(.status == "failed")] | length')
    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo ""
        echo -e "${YELLOW}⚠️  $FAILED_COUNT items failed to process${NC}"
    fi

    echo ""
    echo "────────────────────────────────────────────────────────────────────────────────"

    # Save full results to file
    OUTPUT_FILE="results_${JOB_ID}.json"
    echo "$RESULTS" | jq . > "$OUTPUT_FILE"
    echo ""
    echo "💾 Full results saved to: $OUTPUT_FILE"
fi

echo ""
echo "✨ Done!"
