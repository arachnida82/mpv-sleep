# MPV-Android Sleep # Requirements


# Setup For the Dummies
In mpv-android

1. Set the gesture in `Settings > Touch gestures > Double tap (right)` (or other of your choice).


2. In `Settings > Advanced > Edit input.conf`
    add: `0x1000* script-binding sleep` where `*` should be set as 1, 2, or 3, based on your choice in #2. See key codes below.

Key Codes (gestures):
- `0x10001` ---> left
- `0x10002` ---> center
- `0x10003` ---> right<br><br>

<!--
| Gesture | Key Code  |
|---------|-----------|
| Left    | 0x10001   |
| Center  | 0x10002   |
| Right   | 0x10003   |
-->



3. edit `mpv.conf` In `Settings > Advanced > Edit mpv.conf` and add: `script=/storage/emulated/0/Android/media/is.xyz.mpv/scripts/sleep.lua`

4. Either download [sleep.lua](https://urlcom) on **mobile** to `Android/media/is.xyz.mpv/scripts/`

    or on **PC ---> Android**, use [adb](https://url.com).

    ```
    $: adb push sleep.lua /storage/emulated/0/Android/media/is.xyz.mpv/scripts/
    ```


## ignore
<!--
We need to retrieve user input. MPV OSD can output content, but not retrieve input.
We could use [termux-dialog](https://wiki.termux.com/wiki/Termux-dialog), but that's bloated.

Alternatively, we can write a small app that sleep.lua executes to retrieve user input through a simple dialogue
-->
