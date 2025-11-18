#!/usr/bin/env python3
import sys
import os
import shutil
from pathlib import Path

# Find the most recent image in temp folders
temp_dirs = [
    "/var/folders/by/x31fwqkn4qjgc4trby7nbtjc0000gn/T",
    "/private/var/folders/by/x31fwqkn4qjgc4trby7nbtjc0000gn/T"
]

recent_image = None
latest_time = 0

for temp_dir in temp_dirs:
    if not os.path.exists(temp_dir):
        continue
    for root, dirs, files in os.walk(temp_dir):
        for file in files:
            if file.endswith(('.jpg', '.jpeg', '.png')) and 'image_' in file:
                filepath = os.path.join(root, file)
                try:
                    mtime = os.path.getmtime(filepath)
                    if mtime > latest_time:
                        latest_time = mtime
                        recent_image = filepath
                except:
                    pass

if recent_image and os.path.exists(recent_image):
    dest = "purple_jacket_test.jpg"
    shutil.copy2(recent_image, dest)
    print(f"✅ Found and copied: {recent_image}")
    print(f"✅ Saved as: {dest}")
    
    # Check dimensions
    from PIL import Image
    img = Image.open(dest)
    print(f"📐 Dimensions: {img.size[0]}x{img.size[1]}")
    if img.size[0] > img.size[1]:
        print(f"🔄 This is LANDSCAPE - will be auto-rotated to portrait")
    else:
        print(f"✅ This is PORTRAIT - already correct orientation")
else:
    print("❌ Could not find recent image in temp folders")
