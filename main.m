#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>

static const NSTimeInterval ReminderInterval = 40 * 60;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate, UNUserNotificationCenterDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenu *menu;
@property(nonatomic, strong) NSMenuItem *stateItem;
@property(nonatomic, strong) NSMenuItem *countdownItem;
@property(nonatomic, strong) NSMenuItem *pauseItem;
@property(nonatomic, strong) NSTimer *reminderTimer;
@property(nonatomic, strong) NSTimer *displayTimer;
@property(nonatomic, strong) NSDate *nextReminderDate;
@property(nonatomic) NSTimeInterval remainingWhenPaused;
@property(nonatomic) BOOL paused;
@property(nonatomic) BOOL notificationsAllowed;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self configureNotificationCenter];
    [self configureMenuBarItem];
    [self scheduleNextReminderAfter:ReminderInterval];
    [self startDisplayTimer];
}

- (void)configureNotificationCenter {
    UNUserNotificationCenter *center = UNUserNotificationCenter.currentNotificationCenter;
    center.delegate = self;
    __weak typeof(self) weakSelf = self;
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                          completionHandler:^(BOOL granted, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.notificationsAllowed = granted;
            [weakSelf updateMenuText];
        });
    }];
}

- (NSImage *)menuBarLogoImage {
    NSImage *image = [NSImage imageWithSize:NSMakeSize(20, 20)
                                    flipped:NO
                             drawingHandler:^BOOL(NSRect destinationRect) {
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
    button.toolTip = @"Rest Reminder: every 40 minutes";

    self.menu = [[NSMenu alloc] init];
    self.menu.delegate = self;

    self.stateItem = [[NSMenuItem alloc] initWithTitle:@"Rest reminders are on" action:nil keyEquivalent:@""];
    self.stateItem.enabled = NO;
    [self.menu addItem:self.stateItem];

    self.countdownItem = [[NSMenuItem alloc] initWithTitle:@"Next reminder: 40:00" action:nil keyEquivalent:@""];
    self.countdownItem.enabled = NO;
    [self.menu addItem:self.countdownItem];
    [self.menu addItem:NSMenuItem.separatorItem];

    NSMenuItem *remindNowItem = [[NSMenuItem alloc] initWithTitle:@"Remind me now"
                                                            action:@selector(remindNow:)
                                                     keyEquivalent:@"r"];
    remindNowItem.target = self;
    [self.menu addItem:remindNowItem];

    self.pauseItem = [[NSMenuItem alloc] initWithTitle:@"Pause reminders"
                                                  action:@selector(togglePause:)
                                           keyEquivalent:@"p"];
    self.pauseItem.target = self;
    [self.menu addItem:self.pauseItem];

    NSMenuItem *restartItem = [[NSMenuItem alloc] initWithTitle:@"Reset 40-minute timer"
                                                          action:@selector(restartTimer:)
                                                   keyEquivalent:@"t"];
    restartItem.target = self;
    [self.menu addItem:restartItem];
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
    self.nextReminderDate = [NSDate dateWithTimeIntervalSinceNow:interval];
    self.remainingWhenPaused = interval;

    if (self.paused) {
        return;
    }

    self.reminderTimer = [[NSTimer alloc] initWithFireDate:self.nextReminderDate
                                                  interval:0
                                                    target:self
                                                  selector:@selector(timerDidFire:)
                                                  userInfo:nil
                                                   repeats:NO];
    [NSRunLoop.mainRunLoop addTimer:self.reminderTimer forMode:NSRunLoopCommonModes];
    [self updateMenuText];
}

- (void)startDisplayTimer {
    self.displayTimer = [NSTimer timerWithTimeInterval:1
                                               repeats:YES
                                                 block:^(NSTimer *timer) {
        [self updateMenuText];
    }];
    [NSRunLoop.mainRunLoop addTimer:self.displayTimer forMode:NSRunLoopCommonModes];
}

- (void)timerDidFire:(NSTimer *)timer {
    [self sendRestNotification];
    [self scheduleNextReminderAfter:ReminderInterval];
}

- (void)sendRestNotification {
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"Time to stand up and move";
    content.body = @"You have been focused for 40 minutes. Take a short walk and relax your eyes and shoulders.";
    content.sound = UNNotificationSound.defaultSound;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:NSUUID.UUID.UUIDString
                                                                           content:content
                                                                           trigger:nil];
    [UNUserNotificationCenter.currentNotificationCenter addNotificationRequest:request
                                                           withCompletionHandler:nil];
}

- (void)updateMenuText {
    if (self.paused) {
        self.stateItem.title = @"Rest reminders are paused";
        self.countdownItem.title = [NSString stringWithFormat:@"Remaining: %@", [self formattedTime:self.remainingWhenPaused]];
        self.pauseItem.title = @"Resume reminders";
        self.statusItem.button.toolTip = @"Rest reminders are paused";
        return;
    }

    NSTimeInterval remaining = MAX(0, self.nextReminderDate.timeIntervalSinceNow);
    self.stateItem.title = self.notificationsAllowed ? @"Rest reminders are on" : @"Notification permission needed";
    self.countdownItem.title = [NSString stringWithFormat:@"Next reminder: %@", [self formattedTime:remaining]];
    self.pauseItem.title = @"Pause reminders";
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"Next break in %@", [self formattedTime:remaining]];
}

- (NSString *)formattedTime:(NSTimeInterval)interval {
    NSInteger totalSeconds = MAX(0, (NSInteger)ceil(interval));
    return [NSString stringWithFormat:@"%02ld:%02ld", totalSeconds / 60, totalSeconds % 60];
}

- (void)menuWillOpen:(NSMenu *)menu {
    [self updateMenuText];
}

- (void)remindNow:(id)sender {
    [self sendRestNotification];
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
        [self updateMenuText];
    }
}

- (void)restartTimer:(id)sender {
    self.paused = NO;
    [self scheduleNextReminderAfter:ReminderInterval];
}

- (void)quit:(id)sender {
    [NSApplication.sharedApplication terminate:nil];
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center
       willPresentNotification:(UNNotification *)notification
         withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionBanner | UNNotificationPresentationOptionSound);
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = NSApplication.sharedApplication;
        AppDelegate *delegate = [[AppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [application run];
    }
    return 0;
}
