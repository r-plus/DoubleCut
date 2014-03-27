@interface UIKeyboardImpl : UIView
- (void)deleteBackward;
@end

static NSString *mailAddress;
static BOOL isDoubleCuting = NO;
static NSString * const kPreferencePath = @"/var/mobile/Library/Preferences/jp.r-plus.DoubleCut.plist";

%hook UIKeyboardImpl
- (id)inputEventForInputString:(NSString *)text
{
    static NSDate *prevTime = nil;
    static NSString *prevString = nil;
    if (prevTime && prevString) {
        NSTimeInterval elapsedTime = -1.0 * [prevTime timeIntervalSinceNow];
        isDoubleCuting = (elapsedTime < 0.2 && [text isEqualToString:@"@"] && [prevString isEqualToString:text]) ? YES : NO;
        [prevTime release];
        [prevString release];
    }
    prevTime = [[NSDate date] retain];
    prevString = [text copy];
    return %orig;
}

- (void)insertText:(NSString *)text
{
    if (mailAddress && isDoubleCuting) {
        [self deleteBackward];
        %orig(mailAddress);
    } else {
        %orig;
    }
    isDoubleCuting = NO;
}
%end

static void LoadSettings()
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:kPreferencePath];
    if (mailAddress) {
        [mailAddress release];
        mailAddress = nil;
    }
    id mailAddressPref = [dict objectForKey:@"MailAddress"];
    mailAddress = mailAddressPref ? [mailAddressPref copy] : nil;
}

static void PostNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
    LoadSettings();
}

%ctor
{
    @autoreleasepool {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, PostNotification, CFSTR("jp.r-plus.DoubleCut.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        LoadSettings();
    }
}
