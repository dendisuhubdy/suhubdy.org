#!/bin/bash
# Bootstrap script: creates the "teachings" collection in Directus
# Run this once after the first `docker compose up`

set -e

DIRECTUS_URL="${DIRECTUS_URL:-http://localhost:8055}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@suhubdy.org}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-admin123}"

echo "Waiting for Directus to be ready..."
until curl -sf "$DIRECTUS_URL/server/health" > /dev/null 2>&1; do
  sleep 2
  printf "."
done
echo " Ready!"

# Authenticate
echo "Logging in..."
TOKEN=$(curl -sf -X POST "$DIRECTUS_URL/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['access_token'])")

# Check if collection already exists
if curl -sf "$DIRECTUS_URL/collections/teachings" -H "Authorization: Bearer $TOKEN" > /dev/null 2>&1; then
  echo "Collection 'teachings' already exists. Skipping."
  exit 0
fi

# Create the teachings collection
echo "Creating 'teachings' collection..."
curl -sf -X POST "$DIRECTUS_URL/collections" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "collection": "teachings",
    "meta": {
      "icon": "school",
      "note": "Teaching materials and documents",
      "display_template": "{{title}}"
    },
    "schema": {},
    "fields": [
      {
        "field": "id",
        "type": "integer",
        "meta": { "hidden": true, "interface": "input", "readonly": true },
        "schema": { "is_primary_key": true, "has_auto_increment": true }
      },
      {
        "field": "status",
        "type": "string",
        "meta": {
          "width": "full",
          "interface": "select-dropdown",
          "display": "labels",
          "display_options": {
            "choices": [
              { "text": "Published", "value": "published", "foreground": "#fff", "background": "#16a34a" },
              { "text": "Draft", "value": "draft", "foreground": "#fff", "background": "#6b7280" }
            ]
          },
          "options": {
            "choices": [
              { "text": "Published", "value": "published" },
              { "text": "Draft", "value": "draft" }
            ]
          },
          "default_value": "draft",
          "sort": 1
        },
        "schema": { "default_value": "draft" }
      },
      {
        "field": "title",
        "type": "string",
        "meta": {
          "width": "full",
          "interface": "input",
          "required": true,
          "note": "Title of the teaching material",
          "sort": 2
        },
        "schema": { "is_nullable": false }
      },
      {
        "field": "description",
        "type": "text",
        "meta": {
          "width": "full",
          "interface": "input-multiline",
          "note": "Brief description of the material",
          "sort": 3
        }
      },
      {
        "field": "category",
        "type": "string",
        "meta": {
          "width": "half",
          "interface": "select-dropdown",
          "options": {
            "choices": [
              { "text": "Lecture", "value": "lecture" },
              { "text": "Presentation", "value": "presentation" },
              { "text": "Document", "value": "document" },
              { "text": "Other", "value": "other" }
            ]
          },
          "sort": 4
        }
      },
      {
        "field": "date_published",
        "type": "date",
        "meta": {
          "width": "half",
          "interface": "datetime",
          "sort": 5
        }
      }
    ]
  }' > /dev/null

# Add file field
echo "Adding file upload field..."
curl -sf -X POST "$DIRECTUS_URL/fields/teachings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "field": "file",
    "type": "uuid",
    "meta": {
      "interface": "file",
      "note": "Upload PDF, DOCX, PPT, or other files",
      "width": "full",
      "sort": 6,
      "special": ["file"]
    },
    "schema": {}
  }' > /dev/null

# Create the relation to directus_files
echo "Creating file relation..."
curl -sf -X POST "$DIRECTUS_URL/relations" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "collection": "teachings",
    "field": "file",
    "related_collection": "directus_files"
  }' > /dev/null

# Set public read access for teachings
echo "Setting public read permissions..."
curl -sf -X POST "$DIRECTUS_URL/permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "role": null,
    "collection": "teachings",
    "action": "read",
    "fields": ["*"]
  }' > /dev/null

# Allow public read on files (so downloads work without auth)
curl -sf -X POST "$DIRECTUS_URL/permissions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "role": null,
    "collection": "directus_files",
    "action": "read",
    "fields": ["*"]
  }' > /dev/null

echo ""
echo "=== Bootstrap complete! ==="
echo ""
echo "  Admin panel:  http://localhost:8055"
echo "  Frontend:     http://localhost:4321"
echo "  Login:        $ADMIN_EMAIL / $ADMIN_PASSWORD"
echo ""
echo "  Your dad can now log into the admin panel,"
echo "  go to 'Teachings', and upload his materials."
