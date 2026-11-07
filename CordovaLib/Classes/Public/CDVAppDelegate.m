/*
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.
*/

#import <Cordova/CDVAppDelegate.h>
#import <Cordova/CDVAvailability.h>
#import <Cordova/CDVPluginNotifications.h>
#import <Cordova/CDVSceneDelegate.h>
#import <Cordova/CDVViewController.h>

// Stand-ins for UIKit's archived UISceneSession and UISceneConfiguration that read only the
// configuration's delegate class name. Unarchiving the real UISceneSession before UIApplication
// exists doesn't restore its configuration. They are only ever decoded, never archived, so
// encodeWithCoder: (required by NSCoding) is empty.
@interface CDVSavedSceneConfiguration : NSObject <NSSecureCoding>
@property (nonatomic, copy, nullable) NSString *delegateClassName;
@end

@implementation CDVSavedSceneConfiguration

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        _delegateClassName = [coder decodeObjectOfClass:[NSString class] forKey:@"_UISceneConfigurationDelegateClassName"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

@end

@interface CDVSavedSceneSession : NSObject <NSSecureCoding>
@property (nonatomic, strong, nullable) CDVSavedSceneConfiguration *configuration;
@end

@implementation CDVSavedSceneSession

+ (BOOL)supportsSecureCoding
{
    return YES;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    if ((self = [super init])) {
        _configuration = [coder decodeObjectOfClass:[CDVSavedSceneConfiguration class] forKey:@"_UISceneSessionSceneConfiguration"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
}

@end

// A scene session saved by another build of this app with the same bundle ID (for example a
// SwiftUI-based one, after a switch from the Capacitor shell) is restored with that build's
// configuration: UIKit skips application:configurationForConnecting:options: and connects the scene
// without Cordova's scene delegate and storyboard. A restored session's configuration can't be
// changed, and UIKit loads the saved sessions when UIApplication is created, so this runs from +load.
// Deleting the saved state makes UIKit ask for a configuration with this launch's connection options.
// Cordova's own sessions archive no delegate class name (only the configuration name, or no
// configuration at all for older builds). The archive format is undocumented: if it can't be read,
// nothing is removed.
static void CDVRemoveForeignSceneSessions(void)
{
    NSString *savedStatePath = [NSString stringWithFormat:@"%@/Library/Saved Application State/%@.savedState", NSHomeDirectory(), [[NSBundle mainBundle] bundleIdentifier]];
    NSData *data = [NSData dataWithContentsOfFile:[savedStatePath stringByAppendingPathComponent:@"KnownSceneSessions/data.data"]];
    if (!data) {
        return;
    }
    NSDictionary *sessions = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:NULL];
    if (![sessions isKindOfClass:[NSDictionary class]]) {
        return;
    }

    // Any exception from a malformed archive means it can't be read, so nothing is removed.
    @try {
        for (NSData *archive in sessions.allValues) {
            if (![archive isKindOfClass:[NSData class]]) {
                continue;
            }
            // The session is archived under an undocumented top-level key, so try each one.
            NSDictionary *plist = [NSPropertyListSerialization propertyListWithData:archive options:NSPropertyListImmutable format:NULL error:NULL];
            NSDictionary *top = [plist isKindOfClass:[NSDictionary class]] ? plist[@"$top"] : nil;
            if (![top isKindOfClass:[NSDictionary class]]) {
                continue;
            }

            for (NSString *key in top) {
                // A new unarchiver per key: after a failed decode (a key holding another class), an
                // unarchiver returns nil for every later decode.
                NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingFromData:archive error:NULL];
                [unarchiver setClass:[CDVSavedSceneSession class] forClassName:@"UISceneSession"];
                [unarchiver setClass:[CDVSavedSceneConfiguration class] forClassName:@"UISceneConfiguration"];
                CDVSavedSceneSession *session = [unarchiver decodeObjectOfClass:[CDVSavedSceneSession class] forKey:key];
                [unarchiver finishDecoding];
                NSString *delegateClassName = [session isKindOfClass:[CDVSavedSceneSession class]] ? session.configuration.delegateClassName : nil;
                // A name that doesn't resolve to a class is foreign too: NSClassFromString returns nil.
                if (delegateClassName && ![NSClassFromString(delegateClassName) isSubclassOfClass:[CDVSceneDelegate class]]) {
                    [[NSFileManager defaultManager] removeItemAtPath:savedStatePath error:NULL];
#if DEBUG
                    NSLog(@"Removed saved scene state from another build of this app (scene delegate %@).", delegateClassName);
#endif
                    return;
                }
            }
        }
    } @catch (NSException *exception) {
        return;
    }
}

@implementation CDVAppDelegate

@synthesize window, viewController;

+ (void)load
{
    CDVRemoveForeignSceneSessions();
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
#if DEBUG
    NSLog(@"Apache Cordova iOS platform version %@ is starting.", CDV_VERSION);
#endif

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey, id> *)launchOptions
{
    return YES;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
// this happens while we are running ( in the background, or from within our own app )
// only valid if Info.plist specifies a protocol to handle
- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    if (!url) {
        return NO;
    }

    // all plugins will get the notification, and their handlers will be called
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVPluginHandleOpenURLNotification object:url userInfo:options];

    // TODO: This should be deprecated and removed in Cordova iOS 9, since we're passing this data in the notification userInfo now
    NSMutableDictionary * openURLData = [[NSMutableDictionary alloc] init];

    [openURLData setValue:url forKey:@"url"];

    if (options[UIApplicationOpenURLOptionsSourceApplicationKey]) {
        [openURLData setValue:options[UIApplicationOpenURLOptionsSourceApplicationKey] forKey:@"sourceApplication"];
    }

    if (options[UIApplicationOpenURLOptionsAnnotationKey]) {
        [openURLData setValue:options[UIApplicationOpenURLOptionsAnnotationKey] forKey:@"annotation"];
    }

    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLWithAppSourceAndAnnotationNotification object:openURLData]];

    return YES;
}
#pragma clang diagnostic pop

- (UIInterfaceOrientationMask)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
    // iPhone doesn't support upside down by default, while the iPad does.  Override to allow all orientations always, and let the root view controller decide what's allowed (the supported orientations mask gets intersected).
    NSUInteger supportedInterfaceOrientations = (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationPortraitUpsideDown);
    return supportedInterfaceOrientations;
}

@end
