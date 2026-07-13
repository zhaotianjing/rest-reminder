<p align="center">
  <img src="Assets/RestReminderLogo.png" width="160" alt="Rest Reminder logo">
</p>

<h1 align="center">Rest Reminder</h1>

A tiny native macOS menu bar app that reminds you to stand up and move every 40 minutes.

## Download and install

You do **not** need to download the source code or the entire GitHub repository.

1. Download the ready-to-use app: **[Rest-Reminder-macOS.zip](https://github.com/zhaotianjing/rest-reminder/releases/latest/download/Rest-Reminder-macOS.zip)**
2. Double-click the downloaded ZIP file to extract it.
3. Drag `Rest Reminder.app` into your **Applications** folder.
4. Double-click `Rest Reminder.app`. If macOS blocks it, click **Done** in the warning.
5. Open **System Settings > Privacy & Security**. Scroll down to the **Security** section and click **Open Anyway** next to the Rest Reminder message.
6. Authenticate with your password or Touch ID if asked, then click **Open** in the final confirmation.
7. Click **Allow** when macOS asks for notification permission.

The **Open Anyway** steps are only required for the first launch. If the app opens normally in step 4, skip steps 5 and 6.

Do not use **Code > Download ZIP** unless you specifically want the source code and plan to build the app yourself.

## Daily use

The 40-minute timer starts as soon as the app opens. There is no desktop window and no Dock icon.

Look for the standing-person icon in the top-right menu bar. Click it to:

- See the time remaining until the next reminder
- Send a reminder immediately
- Pause or resume reminders
- Reset the timer to 40 minutes
- Quit the app

The app must remain running to send reminders. After restarting your Mac, open it again or follow the optional login-item instructions below.

## Start automatically after login (optional)

1. Open **System Settings**.
2. Go to **General > Login Items**.
3. Under **Open at Login**, click **+** and select `Rest Reminder.app` from your Applications folder.

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

## Build from source (for developers)

The app uses only native macOS frameworks and the command-line tools included with Xcode or Apple Command Line Tools.

```sh
./build.sh
```

The app will be created at `dist/Rest Reminder.app`.

## Privacy

Rest Reminder runs entirely on your Mac. It does not connect to the internet, collect analytics, read your files, or send personal data anywhere. The only permission it requests is permission to display local notifications.

## License

MIT
