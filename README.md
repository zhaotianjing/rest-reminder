<p align="center">
  <img src="Assets/RestReminderLogo.png" width="160" alt="Rest Reminder logo">
</p>

<h1 align="center">Rest Reminder</h1>

A tiny native macOS menu bar app that reminds you to stand up and move at an interval you choose.

## Download and install

You do **not** need to download the source code or the entire GitHub repository.

1. Download the ready-to-use app: **[Rest-Reminder-macOS.zip](https://github.com/zhaotianjing/rest-reminder/releases/latest/download/Rest-Reminder-macOS.zip)**
2. Double-click the downloaded ZIP file to extract it.
3. Drag `Rest Reminder.app` into your **Applications** folder.
4. Double-click `Rest Reminder.app`. If macOS blocks it, click **Done** in the warning.
5. Open **System Settings > Privacy & Security**. Scroll down to the **Security** section and click **Open Anyway** next to the Rest Reminder message.
6. Authenticate with your password or Touch ID if asked, then click **Open** in the final confirmation.
7. Click **Allow** when macOS asks for notification permission. This enables the backup Notification Center alert; the prominent reminder window itself does not require notification permission.

The **Open Anyway** steps are only required for the first launch. If the app opens normally in step 4, skip steps 5 and 6.

Rest Reminder uses App Sandbox and Hardened Runtime. The free release is still locally signed rather than Apple-notarized, which is why macOS may require **Open Anyway**.

When upgrading from v1.3.0 or earlier, macOS moves the existing Rest Reminder settings into the app's private sandbox container on the first launch.

Do not use **Code > Download ZIP** unless you specifically want the source code and plan to build the app yourself.

## Daily use

The timer starts as soon as the app opens. The default interval is 40 minutes, and your chosen interval is saved between launches. There is no persistent desktop window and no Dock icon.

When the interval ends, Rest Reminder opens a large reminder window in front of your other apps. The window stays visible until you click **I’m Up — Start Next Timer**. Only then does the next interval begin, so time spent on your break is never counted as part of the next work interval.

Look for the standing-person icon in the top-right menu bar. Click it to:

- See the time remaining until the next reminder
- Choose any whole-minute interval from 1 to 480 minutes
- Preview the prominent reminder window without resetting the timer
- See whether the last notification was accepted and delivered by macOS
- Pause or resume reminders
- Reset the timer using the selected interval
- Open macOS notification settings
- Quit the app

The app must remain running to send reminders. After restarting your Mac, open it again or follow the optional login-item instructions below.

## Test the reminder window

Click the menu bar icon and choose **Test Reminder Alert**. A preview window will open in front of your other apps. Click **Close Preview** to dismiss it. This preview does not reset or otherwise change your current timer.

## If a reminder does not appear

1. Click the menu bar icon and choose **Test Reminder Alert**.
2. If the reminder window appears, the in-app reminder is working. It does not depend on notification permission, Focus mode, or banner settings.
3. The app must remain running. Confirm that the standing-person icon is still visible in the menu bar.
4. The system notification is a secondary alert. Check the **Notifications** and **Last notification** lines if you also want to diagnose its delivery.
5. If system notifications or banners are disabled, choose **Open Notification Settings** and enable **Allow notifications** and **Show notifications on desktop** for Rest Reminder.

**Delivered** means macOS placed the notification in Notification Center. A Focus mode or the screen-sharing setting can still prevent a banner from appearing on screen.

## Start automatically after login (optional)

1. Open **System Settings**.
2. Go to **General > Login Items**.
3. Under **Open at Login**, click **+** and select `Rest Reminder.app` from your Applications folder.

## Features

- Lives in the menu bar with no Dock icon or persistent desktop window
- Opens a prominent reminder window only when a break is due
- Waits for your confirmation before starting the next timer
- Supports a user-selected interval from 1 to 480 minutes
- Schedules reminders with macOS so sleep does not silently break the timer
- Includes a reminder-window preview, system-notification diagnostics, and visible delivery status
- Shows the time remaining until the next reminder
- Supports pause, resume, reset, and quit
- No analytics, telemetry, accounts, or network access
- Uses App Sandbox with no network, user-file, camera, microphone, location, or automation entitlements
- Uses Hardened Runtime to protect against code injection and unauthorized dynamic libraries

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

Rest Reminder runs entirely on your Mac. App Sandbox gives the app a private container, and the app is granted no network or user-file access. It stores only your selected interval and the most recent notification delivery status and time in its local macOS preferences. It does not connect to the internet, collect analytics, read your files, or send personal data anywhere. The prominent reminder window is created locally and does not capture your screen or require any additional permission. The only permission the app requests is permission to display its backup local notification.

The free GitHub build uses an ad-hoc signature because it is distributed without an Apple Developer ID certificate. On macOS 14 or later, a future update signed with a different identity may ask for permission to access the existing sandbox container. A stable Developer ID signature and Apple notarization are the long-term way to avoid that update prompt.

## License

MIT
