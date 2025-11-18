# 📷 Camera Setup Instructions

## Camera Feature Added! ✅

The Scan tab now has **two options**:
1. **📷 Take Photo** - Use camera to scan clothing
2. **🖼️ Choose Photo** - Pick from photo library

## Required: Add Camera Permissions in Xcode

To use the camera feature, you need to add privacy descriptions in Xcode:

### Steps:

1. **Open Xcode**
   ```bash
   open ClosetAI.xcodeproj
   ```

2. **Select the ClosetAI target** (click on the blue project icon in the left sidebar)

3. **Go to the "Info" tab**

4. **Add these keys** (click the + button next to "Custom iOS Target Properties"):

   | Key | Type | Value |
   |-----|------|-------|
   | `Privacy - Camera Usage Description` | String | `We need access to your camera to scan clothing items for AI analysis.` |
   | `Privacy - Photo Library Usage Description` | String | `We need access to your photo library to select clothing images for AI analysis.` |

### Alternative: Edit Info.plist directly

If you have an Info.plist file in your project:

```xml
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to scan clothing items for AI analysis.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select clothing images for AI analysis.</string>
```

## What Changed:

### 1. New UI in Scan Tab
- Beautiful two-button layout
- Camera button (indigo)
- Photo library button (purple)
- Icons and descriptions

### 2. ImagePicker Updated
- Now supports `sourceType` parameter
- Can be `.camera` or `.photoLibrary`
- Properly configured for both modes

### 3. State Management
- Added `showingCamera` state
- Added `showingSourceOptions` state
- Separate sheets for camera vs photo library

## Testing:

### On Simulator:
- Camera won't work (simulators don't have cameras)
- Photo library will work fine

### On Real Device:
1. Build and run on your iPhone
2. Tap "Take Photo"
3. Grant camera permission when prompted
4. Take a photo of clothing
5. AI will analyze it!

## Build Status:
```
** BUILD SUCCEEDED **
```

✅ Camera feature is ready!
✅ Just add the permissions in Xcode Info tab
✅ Then run on a real device to test camera

---

**Note**: If you see a permission error, make sure you've added the camera usage description in the Info tab of your Xcode project settings.
