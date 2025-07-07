#!/bin/bash

# API Testing Script
# Tests all endpoints of the DevOps Challenge API

set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

API_BASE_URL="http://localhost:8080"

echo -e "${GREEN}🧪 Testing DevOps Challenge API${NC}"
echo "=================================="

# Test 1: Health Check
echo -e "\n${YELLOW}Test 1: Health Check${NC}"
curl -s "$API_BASE_URL/api/health" | jq '.' || echo "❌ Health check failed"

# Test 2: GET /api
echo -e "\n${YELLOW}Test 2: GET /api${NC}"
curl -s -X GET "$API_BASE_URL/api" \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: test-value" | jq '.' || echo "❌ GET /api failed"

# Test 3: POST /api with JSON
echo -e "\n${YELLOW}Test 3: POST /api with JSON${NC}"
curl -s -X POST "$API_BASE_URL/api" \
  -H "Content-Type: application/json" \
  -H "X-Custom-Header: test-value" \
  -d '{"message": "Hello World", "timestamp": "2024-01-01T00:00:00Z"}' | jq '.' || echo "❌ POST /api failed"

# Test 4: PUT /api
echo -e "\n${YELLOW}Test 4: PUT /api${NC}"
curl -s -X PUT "$API_BASE_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"update": "data"}' | jq '.' || echo "❌ PUT /api failed"

# Test 5: DELETE /api
echo -e "\n${YELLOW}Test 5: DELETE /api${NC}"
curl -s -X DELETE "$API_BASE_URL/api" \
  -H "Content-Type: application/json" | jq '.' || echo "❌ DELETE /api failed"

# Test 6: Prometheus Metrics
echo -e "\n${YELLOW}Test 6: Prometheus Metrics${NC}"
curl -s "$API_BASE_URL/actuator/prometheus" | grep -E "(api_calls_total|http_server_requests)" | head -5 || echo "❌ Metrics failed"

# Test 7: Info Endpoint
echo -e "\n${YELLOW}Test 7: Info Endpoint${NC}"
curl -s "$API_BASE_URL/api/info" | jq '.' || echo "❌ Info endpoint failed"

echo -e "\n${GREEN}✅ All API tests completed!${NC}" 