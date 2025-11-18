# 🧹 Xcode Clean Build Instructions

If you're still seeing build errors after the fixes, Xcode might be using cached build data. Follow these steps:

## Step 1: Clean Build Folder

```
Cmd + Shift + K
```

Or via menu:
```
Product → Clean Build Folder
```

## Step 2: Delete Derived Data

1. **Close Xcode** completely
2. **Open Terminal** and run:

```bash
# Delete all derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Or delete just this project's derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/ClosetAI-*
```

## Step 3: Restart Xcode

```bash
# Open the project fresh
open ClosetAI.xcodeproj
```

## Step 4: Rebuild

```
Cmd + B
```

## If Error Still Persists

### Check File Is Actually Saved

1. Make sure the file is saved (Cmd + S)
2. Check git status to verify changes:

```bash
git status
git diff ClosetAI/Services/EncryptionService.swift
```

### Verify the Init Method

The init should look like this (lines 32-35):

```swift
private init() {
    // Ensure encryption key exists on first use
    // Key will be created lazily when first encryption/decryption is attempted
}
```

If it still has a call to `getOrCreateEncryptionKey()`, the file didn't save properly.

### Re-pull Latest Changes

```bash
# Discard any uncommitted changes
git reset --hard HEAD

# Verify you're on the latest commit
git log -1

# Should show: "fix: Move UIKit import to top of EncryptionService"
```

## Common Issues

### "Build Succeeded" but Xcode Shows Red Error

- This is an Xcode UI bug
- Close and reopen Xcode
- The error indicator should disappear

### Error on Different Line Number

- Xcode's error line numbers can be off
- Clean build folder and rebuild
- Check the actual code, not just the error message

### Multiple Errors Appear

Clean build in this order:
1. Clean Build Folder (Cmd + Shift + K)
2. Close Xcode
3. Delete Derived Data
4. Reopen Xcode
5. Build (Cmd + B)

## Success Indicators

✅ **Build Succeeded** appears in Xcode
✅ No red errors in navigator
✅ Can run on simulator (Cmd + R)

---

**Still having issues?** Check the actual file content:

```bash
cat ClosetAI/Services/EncryptionService.swift | grep -A 5 "private init"
```

Should output:
```swift
private init() {
    // Ensure encryption key exists on first use
    // Key will be created lazily when first encryption/decryption is attempted
}
```
