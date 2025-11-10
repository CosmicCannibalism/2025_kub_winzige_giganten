# Arduino Variants - Installation Guide

## Overview
Each exhibition installation requires a specific Arduino sketch with relay timing matched to the video duration.

## Variants

### 1. Pasteur Version (index.html)
- **Location**: `arduino_variants/pasteur_index/`
- **Video**: Pasteur.mp4 (119 seconds)
- **Relay Duration**: 120000ms (120s)
- **Usage**: For installations using default `index.html`

### 2. Robert Hooke Version (index01.html)
- **Location**: `arduino_variants/robert_hooke_index01/`
- **Video**: Robert_Hooke.mp4 (154 seconds)
- **Relay Duration**: 155000ms (155s)
- **Usage**: For installations using `index01.html`

### 3. Van Leevenhoek Version (index02.html)
- **Location**: `arduino_variants/van_leevenhoek_index02/`
- **Video**: Van_Leevenhoek.mp4 (122 seconds)
- **Relay Duration**: 125000ms (125s)
- **Usage**: For installations using `index02.html`

## Upload Instructions

1. Open Arduino IDE
2. Select the appropriate sketch for your installation
3. Connect Arduino via USB
4. Select: **Tools → Board → Arduino Leonardo** (or your board model)
5. Select: **Tools → Port → /dev/cu.usbmodemXXXXX** (your Arduino port)
6. Click **Upload** button
7. Wait for "Done uploading" message
8. Test with physical button press

## Hardware Connections

- **Button Pin**: Digital Pin 6 (with internal pull-up)
- **Relay Pin**: Digital Pin 7
- **Relay Logic**: HIGH = open, LOW = closed

## Customization

To adjust relay timing:
```cpp
const unsigned long relayDuration = 125000; // Change this value (in milliseconds)
```

Video duration + ~1-3 seconds buffer recommended.
