# Rest Reminder

A tiny native macOS menu bar app that reminds you to stand up and move every 40 minutes.

## Features

- Lives only in the menu bar
- No desktop window and no Dock icon
- Sends a local macOS notification every 40 minutes
- Shows the time remaining until the next reminder
- Supports pause, resume, reset, remind now, and quit
- No analytics, telemetry, accounts, or network access

## Requirements

- macOS 13 or later
- Apple silicon or Intel Mac

## Build

The app uses only native macOS frameworks and the command-line tools included with Xcode or Apple Command Line Tools.

```sh
./build.sh
```

The app will be created at `dist/Rest Reminder.app`.

## Use

1. Open `Rest Reminder.app`.
2. Allow notifications when macOS asks.
3. Use the standing-person icon in the menu bar to view the countdown or control the timer.

If macOS blocks a downloaded build because it is not notarized, Control-click the app, choose **Open**, and confirm once.

## Privacy

Rest Reminder runs entirely on your Mac. It does not connect to the internet, collect analytics, read your files, or send personal data anywhere. The only permission it requests is permission to display local notifications.

## License

MIT
