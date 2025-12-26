# iPad Air (Model A2316) App Specification

## Purpose
This is a simple offline iPad app that plays a looping trailer movie and a main movie triggered by a physical switch connected via Arduino.  
The app should be accessible from the home screen and run without an internet connection.

## Platform
- iPad Air Model A2316
- Offline functionality
- Home screen accessibility

## Features

1. **Loading Screen**
   - Display a loading animation for 3 seconds when the app is opened.
   
2. **Trailer Movie Playback**
   - After loading, automatically start playing a looping trailer movie.
   - Trailer loops indefinitely until a "space" event is received.

3. **Main Movie Playback**
   - Triggered by a "space" event from the Arduino Pro Micro (acting as an HID device).
   - Main movie plays once; if another "space" event is received while the main movie is playing, restart the main movie from the beginning.
   - After the main movie finishes, return to the looping trailer movie.

4. **Arduino HID Integration**
   - Accept keyboard HID events (specifically the "space" key) from the Arduino.
   - Handle events reliably without missing inputs.

5. **Playback Logic**
   - Trailer loops continuously until main movie is triggered.
   - Main movie interrupts trailer; trailer resumes after main movie ends.
   - Multiple triggers during main movie restart it from the beginning.

## Notes
- Arduino side is already stable and implemented.
- The app should be optimized for smooth playback on the iPad Air hardware.
- Consider performance for seamless transitions between trailer and main movie.
