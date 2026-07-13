#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

static const NSInteger DefaultIntervalMinutes = 40;
static const NSInteger MinimumIntervalMinutes = 1;
static const NSInteger MaximumIntervalMinutes = 480;
static NSString *const IntervalMinutesKey = @"ReminderIntervalMinutes";
static NSString *const LastNotificationStatusKey = @"LastNotificationStatus";
static NSString *const LastNotificationDateKey = @"LastNotificationDate";

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *menu;
@property(nonatomic, strong) NSMenuItem *stateItem;
@property(nonatomic, strong) NSMenuItem *intervalItem;
@property(nonatomic, strong) NSMenuItem *countdownItem;
@property(nonatomic, strong) NSMenuItem *lastNotificationItem;
@property(nonatomic, strong) NSMenuItem *pauseItem;
@property(nonatomic, strong) NSMenuItem *restartItem;
@property(nonatomic, strong) NSTimer *reminderTimer;
@property(nonatomic, strong) NSTimer *displayTimer;
@property(nonatomic, strong) NSDate *nextReminderDate;
@property(nonatomic, copy) NSString *scheduledReminderIdentifier;
@property(nonatomic, copy) NSString *notificationStatusText;
@property(nonatomic) NSTimeInterval remainingWhenPaused;
@property(nonatomic) NSInteger intervalMinutes;
@property(nonatomic) BOOL paused;
@property(nonatomic) BOOL notificationsAllowed;
- (void)recordNotificationStatus:(NSString *)status;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSInteger savedMinutes = [NSUserDefaults.standardUserDefaults integerForKey:IntervalMinutesKey];
    self.intervalMinutes = (savedMinutes >= MinimumIntervalMinutes && savedMinutes <= MaximumIntervalMinutes)
        ? savedMinutes
        : DefaultIntervalMinutes;
    self.notificationStatusText = @"Notifications: Checking permission...";

    [self configureMenuBarItem];
    [self scheduleNextReminderAfter:[self reminderInterval]];
    [self startDisplayTimer];
    [self configureNotificationCenter];
}

- (void)configureNotificationCenter {
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    center.delegate = self;
    __weak typeof(self) weakSelf = self;

    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *settings) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                                      completionHandler:^(BOOL granted, NSError *error) {
                    (void)granted;
                    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *updatedSettings) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf applyNotificationSettings:updatedSettings error:error];
                        });
                    }];
                }];
            } else {
                [weakSelf applyNotificationSettings:settings error:nil];
            }
        });
    }];
}

- (void)applyNotificationSettings:(UNNotificationSettings *)settings error:(NSError *)error {
    BOOL authorized = (settings.authorizationStatus == UNAuthorizationStatusAuthorized ||
                       settings.authorizationStatus == UNAuthorizationStatusProvisional);
    BOOL alertsEnabled = (settings.alertSetting == UNNotificationSettingEnabled);
    self.notificationsAllowed = authorized;

    if (error) {
        self.notificationStatusText = [NSString stringWithFormat:@"Notifications: Error (%@)", error.localizedDescription];
    } else if (authorized && !alertsEnabled) {
        self.notificationStatusText = @"Notifications: Banners disabled in System Settings";
        if (!self.paused && self.nextReminderDate) {
            [self scheduleSystemNotificationAfter:MAX(1, self.nextReminderDate.timeIntervalSinceNow)];
        }
    } else if (authorized) {
        self.notificationStatusText = @"Notifications: Enabled";
        if (!self.paused && self.nextReminderDate) {
            [self scheduleSystemNotificationAfter:MAX(1, self.nextReminderDate.timeIntervalSinceNow)];
        }
    } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
        self.notificationStatusText = @"Notifications: Disabled in System Settings";
        [self cancelScheduledSystemNotification];
    } else {
        self.notificationStatusText = @"Notifications: Permission required";
    }
    [self updateMenuText];
}

- (NSTimeInterval)reminderInterval {
    return self.intervalMinutes * 60.0;
}

- (NSString *)intervalDescription {
    return [NSString stringWithFormat:@"%ld %@",
            self.intervalMinutes,
            self.intervalMinutes == 1 ? @"minute" : @"minutes"];
}

- (NSImage *)menuBarLogoImage {
    NSImage *image = [NSImage imageWithSize:NSMakeSize(20, 20)
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect destinationRect) {
        (void)destinationRect;
        [NSColor.blackColor setStroke];
        [NSColor.blackColor setFill];

        NSBezierPath *ring = [NSBezierPath bezierPath];
        [ring appendBezierPathWithArcWithCenter:NSMakePoint(10, 10)
                                         radius:8
                                     startAngle:30
                                       endAngle:330];
        ring.lineWidth = 1.7;
        ring.lineCapStyle = NSLineCapStyleRound;
        [ring stroke];

        NSBezierPath *timerTick = [NSBezierPath bezierPath];
        [timerTick moveToPoint:NSMakePoint(16.1, 14.1)];
        [timerTick lineToPoint:NSMakePoint(17.2, 15.3)];
        timerTick.lineWidth = 1.9;
        timerTick.lineCapStyle = NSLineCapStyleRound;
        [timerTick stroke];

        [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(8.2, 10.5, 3.6, 3.6)] fill];

        NSBezierPath *person = [NSBezierPath bezierPath];
        [person moveToPoint:NSMakePoint(10, 10.5)];
        [person lineToPoint:NSMakePoint(10, 6.5)];
        [person moveToPoint:NSMakePoint(10, 10.2)];
        [person lineToPoint:NSMakePoint(6.9, 13.7)];
        [person moveToPoint:NSMakePoint(10, 10.2)];
        [person lineToPoint:NSMakePoint(13.1, 13.7)];
        [person moveToPoint:NSMakePoint(10, 6.5)];
        [person lineToPoint:NSMakePoint(7.8, 4.1)];
        [person moveToPoint:NSMakePoint(10, 6.5)];
        [person lineToPoint:NSMakePoint(12.2, 4.1)];
        person.lineWidth = 2.1;
        person.lineCapStyle = NSLineCapStyleRound;
        person.lineJoinStyle = NSLineJoinStyleRound;
        [person stroke];
        return YES;
    }];
    image.template = YES;
    return image;
}

- (void)configureMenuBarItem {
    self.statusItem = [NSStatusBar.systemStatusBar statusItemWithLength:NSVariableStatusItemLength];
    NSStatusBarButton *button = self.statusItem.button;
    button.image = [self menuBarLogoImage];
    button.image.accessibilityDescription = @"Rest Reminder";
    button.imageScaling = NSImageScaleProportionallyDown;
    button.toolTip = [NSString stringWithFormat:@"Rest Reminder: every %@", [self intervalDescription]];

    self.menu = [[NSMenu alloc] init];
    self.menu.delegate = self;

    self.stateItem = [[NSMenuItem alloc] initWithTitle:self.notificationStatusText action:nil keyEquivalent:@""];
    self.stateItem.enabled = NO;
    [self.menu addItem:self.stateItem];

    self.intervalItem = [[NSMenuItem alloc] initWithTitle:@"Interval" action:nil keyEquivalent:@""];
    self.intervalItem.enabled = NO;
    [self.menu addItem:self.intervalItem];

    self.countdownItem = [[NSMenuItem alloc] initWithTitle:@"Next reminder" action:nil keyEquivalent:@""];
    self.countdownItem.enabled = NO;
    [self.menu addItem:self.countdownItem];

    self.lastNotificationItem = [[NSMenuItem alloc] initWithTitle:@"Last notification: Not sent yet" action:nil keyEquivalent:@""];
    self.lastNotificationItem.enabled = NO;
    [self.menu addItem:self.lastNotificationItem];
    [self.menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *testItem = [[NSMenuItem alloc] initWithTitle:@"Send Test Notification"
                                                       action:@selector(remindNow:)
                                                keyEquivalent:@"r"];
    testItem.target = self;
    [self.menu addItem:testItem];

    NSMenuItem *setIntervalItem = [[NSMenuItem alloc] initWithTitle:@"Set Reminder Interval..."
                                                               action:@selector(setReminderInterval:)
                                                        keyEquivalent:@"i"];
    setIntervalItem.target = self;
    [self.menu addItem:setIntervalItem];

    self.pauseItem = [[NSMenuItem alloc] initWithTitle:@"Pause Reminders"
                                                  action:@selector(togglePause:)
                                           keyEquivalent:@"p"];
    self.pauseItem.target = self;
    [self.menu addItem:self.pauseItem];

    self.restartItem = [[NSMenuItem alloc] initWithTitle:@"Reset Timer"
                                                    action:@selector(restartTimer:)
                                             keyEquivalent:@"t"];
    self.restartItem.target = self;
    [self.menu addItem:self.restartItem];
    [self.menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *notificationSettingsItem = [[NSMenuItem alloc] initWithTitle:@"Open Notification Settings"
                                                                        action:@selector(openNotificationSettings:)
                                                                 keyEquivalent:@""];
    notificationSettingsItem.target = self;
    [self.menu addItem:notificationSettingsItem];
    [self.menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit Rest Reminder"
                                                       action:@selector(quit:)
                                                keyEquivalent:@"q"];
    quitItem.target = self;
    [self.menu addItem:quitItem];

    self.statusItem.menu = self.menu;
    [self updateMenuText];
}

- (void)scheduleNextReminderAfter:(NSTimeInterval)interval {
    [self.reminderTimer invalidate];
    [self cancelScheduledSystemNotification];
    self.nextReminderDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    self.remainingWhenPaused = interval;

    if (self.paused) {
        [self updateMenuText];
        return;
    }

    self.reminderTimer = [[NSTimer alloc] initWithFireDate:self.nextReminderDate
                                                  interval:0
                                                    target:self
                                                  selector:@selector(timerDidFire:)
                                                  userInfo:nil
                                                   repeats:NO];
    [NSRunLoop.mainRunLoop addTimer:self.reminderTimer forMode:NSRunLoopCommonModes];
    if (self.notificationsAllowed) {
        [self scheduleSystemNotificationAfter:interval];
    }
    [self updateMenuText];
}

- (void)scheduleSystemNotificationAfter:(NSTimeInterval)interval {
    [self cancelScheduledSystemNotification];

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Time to stand up and move";
    content.body = [NSString stringWithFormat:@"Your %@ focus interval is complete. Take a short walk and relax your eyes and shoulders.", [self intervalDescription]];
    content.sound = UNNotificationSound.defaultSound;

    NSString *identifier = [NSString stringWithFormat:@"rest-reminder-%@", NSUUID.UUID.UUIDString];
    self.scheduledReminderIdentifier = identifier;
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:MAX(1, interval)
                                                                                                       repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                           content:content
                                                                           trigger:trigger];
    __weak typeof(self) weakSelf = self;
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request
                                                           withCompletionHandler:^(NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([weakSelf.scheduledReminderIdentifier isEqualToString:identifier]) {
                    weakSelf.scheduledReminderIdentifier = nil;
                }
                weakSelf.notificationStatusText = [NSString stringWithFormat:@"Notifications: Scheduling failed (%@)", error.localizedDescription];
                [weakSelf recordNotificationStatus:@"Scheduling failed"];
                [weakSelf updateMenuText];
            });
        }
    }];
}

- (void)cancelScheduledSystemNotification {
    if (!self.scheduledReminderIdentifier) {
        return;
    }
    [UNUserNotificationCenter.currentNotificationCenter
        removePendingNotificationRequestsWithIdentifiers:@[self.scheduledReminderIdentifier]];
    self.scheduledReminderIdentifier = nil;
}

- (void)startDisplayTimer {
    self.displayTimer = [NSTimer timerWithTimeInterval:1
                                               repeats:YES
                                                 block:^(NSTimer *timer) {
        (void)timer;
        [self updateMenuText];
    }];
    [NSRunLoop.mainRunLoop addTimer:self.displayTimer forMode:NSRunLoopCommonModes];
}

- (void)timerDidFire:(NSTimer *)timer {
    NSString *deliveredIdentifier = self.scheduledReminderIdentifier;
    self.scheduledReminderIdentifier = nil;
    [self markNotificationSentAndVerify:deliveredIdentifier];
    [self scheduleNextReminderAfter:[self reminderInterval]];
}

- (void)sendTestNotification {
    if (!self.notificationsAllowed) {
        self.lastNotificationItem.title = @"Last notification: Permission is disabled";
        [self recordNotificationStatus:@"Permission is disabled"];
        [self updateMenuText];
        return;
    }

    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Rest Reminder test";
    content.body = @"Notifications are working. Your next reminder timer has not been reset.";
    content.sound = UNNotificationSound.defaultSound;

    NSString *identifier = [NSString stringWithFormat:@"rest-reminder-test-%@", NSUUID.UUID.UUIDString];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:identifier
                                                                           content:content
                                                                           trigger:trigger];
    __weak typeof(self) weakSelf = self;
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request
                                                           withCompletionHandler:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                weakSelf.lastNotificationItem.title = [NSString stringWithFormat:@"Last notification: Failed (%@)", error.localizedDescription];
                weakSelf.notificationStatusText = @"Notifications: Test failed";
                [weakSelf recordNotificationStatus:@"Test failed"];
                [weakSelf updateMenuText];
            } else {
                [weakSelf markNotificationSentAndVerify:identifier];
            }
        });
    }];
}

- (void)markNotificationSentAndVerify:(NSString *)identifier {
    if (!identifier) {
        self.lastNotificationItem.title = @"Last notification: No system notification was scheduled";
        [self recordNotificationStatus:@"No system notification was scheduled"];
        return;
    }

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterNoStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    self.lastNotificationItem.title = [NSString stringWithFormat:@"Last notification: Sent to macOS at %@", [formatter stringFromDate:NSDate.date]];
    [self recordNotificationStatus:@"Sent to macOS"];

    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)),
                   dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [UNUserNotificationCenter.currentNotificationCenter getDeliveredNotificationsWithCompletionHandler:^(NSArray<UNNotification *> *notifications) {
            BOOL delivered = NO;
            for (UNNotification *notification in notifications) {
                if ([notification.request.identifier isEqualToString:identifier]) {
                    delivered = YES;
                    break;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (delivered) {
                    NSDateFormatter *deliveryFormatter = [[NSDateFormatter alloc] init];
                    deliveryFormatter.dateStyle = NSDateFormatterNoStyle;
                    deliveryFormatter.timeStyle = NSDateFormatterShortStyle;
                    weakSelf.lastNotificationItem.title = [NSString stringWithFormat:@"Last notification: Delivered at %@", [deliveryFormatter stringFromDate:NSDate.date]];
                    [weakSelf recordNotificationStatus:@"Delivered"];
                } else {
                    weakSelf.lastNotificationItem.title = @"Last notification: Not found in Notification Center";
                    [weakSelf recordNotificationStatus:@"Not found in Notification Center"];
                }
            });
        }];
    });
}

- (void)recordNotificationStatus:(NSString *)status {
    [NSUserDefaults.standardUserDefaults setObject:status forKey:LastNotificationStatusKey];
    [NSUserDefaults.standardUserDefaults setObject:NSDate.date forKey:LastNotificationDateKey];
}

- (void)updateMenuText {
    self.intervalItem.title = [NSString stringWithFormat:@"Interval: %@", [self intervalDescription]];
    self.restartItem.title = [NSString stringWithFormat:@"Reset %@ Timer", [self intervalDescription]];

    if (self.paused) {
        self.stateItem.title = @"Reminders: Paused";
        self.countdownItem.title = [NSString stringWithFormat:@"Remaining: %@", [self formattedTime:self.remainingWhenPaused]];
        self.pauseItem.title = @"Resume Reminders";
        self.statusItem.button.toolTip = @"Rest Reminder is paused";
        return;
    }

    NSTimeInterval remaining = MAX(0, self.nextReminderDate.timeIntervalSinceNow);
    self.stateItem.title = self.notificationStatusText;
    self.countdownItem.title = [NSString stringWithFormat:@"Next reminder: %@", [self formattedTime:remaining]];
    self.pauseItem.title = @"Pause Reminders";
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"Next break in %@", [self formattedTime:remaining]];
}

- (NSString *)formattedTime:(NSTimeInterval)interval {
    NSInteger totalSeconds = MAX(0, (NSInteger)ceil(interval));
    if (totalSeconds >= 3600) {
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", totalSeconds / 3600, (totalSeconds % 3600) / 60, totalSeconds % 60];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", totalSeconds / 60, totalSeconds % 60];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self updateMenuText];
}

- (void)remindNow:(id)sender {
    [self sendTestNotification];
}

- (void)setReminderInterval:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Set Reminder Interval";
    alert.informativeText = [NSString stringWithFormat:@"Enter a whole number from %ld to %ld minutes.", MinimumIntervalMinutes, MaximumIntervalMinutes];
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 220, 24)];
    input.stringValue = [NSString stringWithFormat:@"%ld", self.intervalMinutes];
    input.placeholderString = @"Minutes";
    alert.accessoryView = input;

    if ([alert runModal] != NSAlertFirstButtonReturn) {
        return;
    }

    NSInteger minutes = input.integerValue;
    if (minutes < MinimumIntervalMinutes || minutes > MaximumIntervalMinutes) {
        NSAlert *invalidAlert = [[NSAlert alloc] init];
        invalidAlert.messageText = @"Invalid Interval";
        invalidAlert.informativeText = [NSString stringWithFormat:@"Please enter a whole number from %ld to %ld.", MinimumIntervalMinutes, MaximumIntervalMinutes];
        [invalidAlert addButtonWithTitle:@"OK"];
        [invalidAlert runModal];
        return;
    }

    self.intervalMinutes = minutes;
    [NSUserDefaults.standardUserDefaults setInteger:minutes forKey:IntervalMinutesKey];
    self.paused = NO;
    [self scheduleNextReminderAfter:[self reminderInterval]];
}

- (void)togglePause:(id)sender {
    if (self.paused) {
        self.paused = NO;
        [self scheduleNextReminderAfter:MAX(1, self.remainingWhenPaused)];
    } else {
        self.remainingWhenPaused = MAX(1, self.nextReminderDate.timeIntervalSinceNow);
        self.paused = YES;
        [self.reminderTimer invalidate];
        self.reminderTimer = nil;
        [self cancelScheduledSystemNotification];
        [self updateMenuText];
    }
}

- (void)restartTimer:(id)sender {
    self.paused = NO;
    [self scheduleNextReminderAfter:[self reminderInterval]];
}

- (void)openNotificationSettings:(id)sender {
    NSURL *url = [NSURL URLWithString:@"x-apple.systempreferences:com.apple.Notifications-Settings.extension"];
    [NSWorkspace.sharedWorkspace openURL:url];
}

- (void)quit:(id)sender {
    [self cancelScheduledSystemNotification];
    [NSApplication.sharedApplication terminate:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self cancelScheduledSystemNotification];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

@end

int main(void) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [application run];
    }
    return 0;
}
