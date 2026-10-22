#!/bin/bash

echo "🧪 Testing QuikDawa Counters API"
echo "=================================="

# Test Dashboard Counters API
echo "📊 Testing Dashboard Counters API..."
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "usr_id=1" \
  "https://quikdawa.com/QdawaAPIs/public/index.php/usercounters" \
  -w "\n\nStatus: %{http_code}\nTime: %{time_total}s\n" \
  -s

echo ""
echo "🎯 Testing Banner API..."
curl -X POST \
  "https://quikdawa.com/QdawaAPIs/public/index.php/getBanner" \
  -w "\n\nStatus: %{http_code}\nTime: %{time_total}s\n" \
  -s

echo ""
echo "📦 Testing Last 3 Orders API..."
curl -X POST \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "usr_id=1" \
  "https://quikdawa.com/QdawaAPIs/public/index.php/getLastThreeOrders" \
  -w "\n\nStatus: %{http_code}\nTime: %{time_total}s\n" \
  -s

echo ""
echo "✅ API Testing Complete!"

