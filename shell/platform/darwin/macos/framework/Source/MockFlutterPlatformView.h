#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>
#import <WebKit/WebKit.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViews.h"

@interface MockFlutterPlatformView : NSObject <FlutterPlatformView>
@property(nonatomic, strong) NSView* view;
@end

@interface MockPlatformView : WKWebView
@end

@interface MockFlutterPlatformFactory : NSObject <FlutterPlatformViewFactory>
@end
