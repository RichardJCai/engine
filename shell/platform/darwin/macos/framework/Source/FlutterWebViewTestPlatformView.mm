#import <Cocoa/Cocoa.h>

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterWebViewTestPlatformView.h"

@implementation MockFlutterPlatformView

- (instancetype)initWithFrame:(CGRect)frame arguments:(id _Nullable)args {
  if (self = [super init]) {
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;

    WKWebView* webView = [[WKWebView alloc] initWithFrame:frame];

    NSURL *url = [NSURL URLWithString:@"https://flutter.dev/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [webView loadRequest:request];
    _view = webView;
  }
  return self;
}

- (void)dealloc {
  _view = nil;
}

@end

@implementation MockFlutterPlatformFactory
- (NSObject<FlutterPlatformView>*)createWithFrame:(CGRect)frame
                                   viewIdentifier:(int64_t)viewId
                                        arguments:(id _Nullable)args {
  return [[MockFlutterPlatformView alloc] initWithFrame:frame arguments:args];
}

- (NSObject<FlutterMessageCodec>*)createArgsCodec {
  return [FlutterStandardMessageCodec sharedInstance];
}

@end
