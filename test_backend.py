#!/usr/bin/env python3
"""
Test script to upload an image to the backend and see the response.

Usage:
    python3 test_backend.py /path/to/image.jpg
"""

import sys
import requests
import json

if len(sys.argv) < 2:
    print("Usage: python3 test_backend.py /path/to/image.jpg")
    sys.exit(1)

image_path = sys.argv[1]

print(f"📸 Testing backend with image: {image_path}")
print("=" * 60)

try:
    with open(image_path, 'rb') as f:
        files = {'file': f}
        response = requests.post('http://localhost:8000/analyze-clothing', files=files)

    print(f"Status Code: {response.status_code}")
    print("=" * 60)

    if response.status_code == 200:
        data = response.json()

        print(f"✅ SUCCESS!")
        print(f"Item Count: {data.get('item_count', 1)}")
        print(f"All Items: {len(data.get('all_items', []))}")
        print("=" * 60)

        if data.get('all_items'):
            print("\n📦 All Items Detected:")
            for i, item in enumerate(data['all_items']):
                print(f"\n  Item {i+1}:")
                print(f"    Type: {item.get('type')}")
                print(f"    Color: {item.get('color')}")
                print(f"    Style: {item.get('style')}")
                print(f"    Has extracted_image: {('extracted_image' in item)}")

                # Save extracted image if present
                if 'extracted_image' in item:
                    import base64
                    img_data = base64.b64decode(item['extracted_image'])
                    output_path = f"extracted_item_{i+1}.png"
                    with open(output_path, 'wb') as f:
                        f.write(img_data)
                    print(f"    ✅ Saved to: {output_path}")

        print("\n" + "=" * 60)
        print("Full Response:")
        print(json.dumps(data, indent=2))

    else:
        print(f"❌ Error: {response.text}")

except Exception as e:
    print(f"❌ Error: {e}")
