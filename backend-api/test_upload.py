#!/usr/bin/env python3
import requests
import sys

# Test image upload
url = "http://localhost:8000/analyze-clothing"

# Use the Nike sweatshirt image path (passed as argument)
if len(sys.argv) > 1:
    image_path = sys.argv[1]
else:
    print("Usage: python test_upload.py <image_path>")
    sys.exit(1)

# Prepare the multipart form data
files = {
    'file': open(image_path, 'rb')
}

data = {
    'user_id': 'test-nike-user',
    'remove_background': 'true'
}

print(f"Uploading image: {image_path}")
print("Making request to:", url)

try:
    response = requests.post(url, files=files, data=data)

    print(f"\nStatus Code: {response.status_code}")
    print(f"\nResponse:")
    print(response.json())
except Exception as e:
    print(f"Error: {e}")
    print(f"Response text: {response.text if 'response' in locals() else 'No response'}")
