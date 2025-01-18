# MPV-Android Sleep
A gesture-controlled sleep timer for mpv-android

<!--insert video demonstration or screenshots-->

## Features
 Set a sleep timer with simple touch gestures
- On-screen display (OSD) for timer countdown

## Usage
The available gestures in mpv-android are limited, so for now this script uses cycling logic.
- First gesture: begin the sleep timer
- Gesture again to cancel the sleep timer

## Requirements
- mpv-Android ([api29 or later](https://github.com/mpv-android/mpv-android/releases))


## Installation
1. Download Files
    ```
    $: git clone github.com/arachnida82/mpv-sleep &&
       adb push mpv-sleep/lua/sleep.lua /storage/emulated/0/Android/media/is.xyz.mpv/scripts/ &&
       adb push mpv-sleep/sleep.json /storage/emulated/0/Android/media/is.xyz.mpv/scripts
    ```
(`sleep.json` and `sleep.lua` must be placed in `is.xyz.mpv/*`, thus we have them in `scripts`)


## Setup
**Enable Script**

In mpv-android, navigate to `Settings > Advanced > Edit mpv.conf` and add the line:
```
script=/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.lua
```

**Configure Gestures**
1. Choose a *gesture* in `Settings > Touch gestures`

2. Edit `Settings > Advanced > Edit input.conf` and add:
    ```
    KEYCODE script-binding sleep
    ```
    Replace *KEYCODE* with the key code corresponding to the gesture you selected in touch gestures.
<div align="center">

| Gesture (double tap) | Key Code  |
|----------------------|-----------|
| Left                 | 0x10001   |
| Center               | 0x10002   |
| Right                | 0x10003   |

</div>

## Configuration
edit `sleep.json` to customize:
```json
{
    "config": {
        "default_time": 25,
        "display_time": true,
    }
}
```

For example, `"display_time": false,` removes the OSD countdown, but the timer continues in the background.

## Contributing
This script works well enough for my needs as is. Pull requests are more than welcomed, however.
