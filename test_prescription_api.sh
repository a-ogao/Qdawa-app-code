#!/bin/bash

# Test script for fetchPrescriptions API
# Replace USER_ID with actual user ID from your app

echo "🧪 Testing fetchPrescriptions API"
echo "=================================="
echo ""

# Set your test parameters here
USER_ID="1"  # Replace with actual user ID
FROM_DATE="2024-01-01"
TO_DATE="2025-12-31"
API_URL="https://quikdawa.com/QdawaAPIs/public/index.php/fetchPrescriptions"

echo "📋 Test Parameters:"
echo "   User ID: $USER_ID"
echo "   From Date: $FROM_DATE"
echo "   To Date: $TO_DATE"
echo "   API URL: $API_URL"
echo ""

echo "📡 Sending request..."
echo ""

# Make the API request
response=$(curl -s -X POST "$API_URL" \
  -d "usr_id=$USER_ID" \
  -d "from_date=$FROM_DATE" \
  -d "to_date=$TO_DATE")

echo "📥 API Response:"
echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
echo ""

# Parse and analyze response
echo "🔍 Analysis:"
success=$(echo "$response" | grep -o '"success":[^,}]*' | cut -d':' -f2)
echo "   Success: $success"

if echo "$response" | grep -q '"data":\[\]'; then
  echo "   Data: ❌ Empty array (no prescriptions found)"
elif echo "$response" | grep -q '"data":null'; then
  echo "   Data: ❌ Null (no prescriptions found)"
elif echo "$response" | grep -q '"data":\['; then
  count=$(echo "$response" | grep -o '"qit_item_name"' | wc -l)
  echo "   Data: ✅ Contains items (found $count items)"
  
  # Show first item structure
  echo ""
  echo "📋 Sample data structure:"
  echo "$response" | python3 -c "import sys, json; data=json.load(sys.stdin); print(json.dumps(data.get('data', [])[0] if data.get('data') else {}, indent=2))" 2>/dev/null
else
  echo "   Data: ⚠️  Unknown format"
fi

echo ""
echo "💡 Tips:"
echo "   1. Update USER_ID to match a user who has prescriptions"
echo "   2. Adjust date range to include when prescriptions were created"
echo "   3. Check if API endpoint exists and is accessible"
echo "   4. Verify database has prescription data with correct field names"
echo ""

