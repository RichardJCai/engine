#import <Cocoa/Cocoa.h>

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MockFlutterPlatformView.h"

@implementation MockPlatformView

- (instancetype)initWithFrame:(CGRect)frame {
  WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
  self = [super initWithFrame:frame configuration:config];

  NSURL *nsurl=[NSURL URLWithString:@"http://www.google.com"];
  NSURLRequest *nsrequest=[NSURLRequest requestWithURL:nsurl];
  [self loadRequest:nsrequest];
  // self = [super initWithFrame:frame];
  // [super setString:@"hello"];
  // [super setTextColor:[NSColor blueColor]];
  // super.drawsBackground = true;
  // super.backgroundColor = [NSColor redColor];
  // [self.layer setBackgroundColor:[[NSColor redColor] CGColor]];

  return self;
}
@end

@implementation MockFlutterPlatformView

- (instancetype)initWithFrame:(CGRect)frame arguments:(id _Nullable)args {
  if (self = [super init]) {
    // _view = [[MockPlatformView alloc] initWithFrame:frame];
    
    // Try getting WKWebView working.
    WKUserContentController* userContentController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration* configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = userContentController;

    WKWebView* webView = [[WKWebView alloc] initWithFrame:frame];

    NSURL *url = [NSURL URLWithString:@"https://flutter.dev/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [webView loadRequest:request];
    // webView.frame = NSMakeRect(500, 0, 300, 300);
    _view = webView;

    NSLog(@"webView initWithFrame");
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
