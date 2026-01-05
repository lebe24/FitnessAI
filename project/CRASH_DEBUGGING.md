# iOS Crash Debugging Guide

## Methods to Diagnose Crashes

### 1. **Xcode Console Logs (During Development)**
When running from Xcode or Flutter, check the console output:
```bash
# Run with verbose logging
flutter run --verbose

# Or check Xcode console when running from Xcode
```

### 2. **Xcode Organizer - Crashes Tab**
- Open Xcode → Window → Organizer
- Select "Crashes" tab
- View detailed crash reports with stack traces
- Shows crash location, thread, and device info

### 3. **Device Console Logs**
```bash
# View device logs in real-time
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"'

# For physical device (connected via USB)
# Use Console.app or Xcode → Window → Devices and Simulators → View Device Logs
```

### 4. **Flutter Error Handling (Already Added)**
The app now catches:
- Flutter framework errors
- Async errors
- Initialization errors

All errors are logged to console with stack traces.

### 5. **Xcode Debugger**
- Set breakpoints in AppDelegate.swift
- Use "Exception Breakpoint" to catch all exceptions
- View call stack when crash occurs

### 6. **Crash Log Files**
Crash logs are stored at:
- **Simulator**: `~/Library/Logs/DiagnosticReports/`
- **Physical Device**: Sync via Xcode Organizer or Console.app

### 7. **Symbolicate Crash Reports**
If you have a crash log file:
```bash
# Symbolicate using Xcode
# Xcode → Window → Organizer → Crashes → Right-click crash → "Reveal in Finder"
# Or use atos command with dSYM file
```

### 8. **Add Crash Reporting Service (Optional)**
Consider adding:
- **Firebase Crashlytics**: `firebase_crashlytics`
- **Sentry**: `sentry_flutter`
- **Bugsnag**: `bugsnag_flutter`

These provide:
- Automatic crash reporting
- Stack traces with line numbers
- User context
- Crash grouping and analytics

## Common Crash Types

### Swift Runtime Crashes
- **Symptom**: `swift_getObjectType`, `EXC_BAD_ACCESS`
- **Cause**: Memory issues, Swift version mismatch, plugin incompatibility
- **Solution**: Check Podfile Swift version, update plugins

### Memory Crashes
- **Symptom**: `EXC_BAD_ACCESS`, low memory warnings
- **Cause**: Memory leaks, large objects, image loading
- **Solution**: Use Instruments to profile memory

### Thread Crashes
- **Symptom**: Thread-related errors in stack trace
- **Cause**: UI updates from background thread, race conditions
- **Solution**: Ensure UI updates on main thread

### Plugin Initialization Crashes
- **Symptom**: Crash during app startup, plugin-related stack trace
- **Cause**: Plugin incompatibility, missing configuration
- **Solution**: Check plugin versions, iOS deployment target

## Quick Debugging Steps

1. **Check Console Output**: Look for error messages before crash
2. **Review Stack Trace**: Identify the exact function causing crash
3. **Check Device Logs**: Use Console.app or Xcode device logs
4. **Test on Simulator**: Reproduce crash in simulator for easier debugging
5. **Add Logging**: Add debugPrint statements around suspected code
6. **Use Breakpoints**: Set breakpoints to pause execution before crash

## Current Error Handling

The app now includes:
- ✅ Flutter error catching
- ✅ Async error catching  
- ✅ Initialization error catching
- ✅ Stack trace logging

All errors will appear in console output when running the app.

