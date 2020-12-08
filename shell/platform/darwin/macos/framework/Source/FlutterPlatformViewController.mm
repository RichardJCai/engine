// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/logging.h"

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterConstants.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewController_Internal.h"

@implementation FlutterPlatformViewController {
  bool _embedded_views_preview_enabled;
}

- (instancetype)init {
  self = [super init];

  _platformViewFactories = [[NSMutableDictionary alloc] init];
  _embedded_views_preview_enabled = [FlutterPlatformViewController embeddedViewsEnabled];
  return self;
}

- (void)onCreateWithViewId:(int64_t)viewId
                  viewType:(nonnull NSString*)viewType
                    result:(nonnull FlutterResult)result {
  if (!_embedded_views_preview_enabled) {
    NSLog(@"Must set `io.flutter_embedded_views_preview` to true in Info.plist to enable platform "
          @"views");
    return;
  }
  if (_platformViews.count(viewId) != 0) {
    result([FlutterError errorWithCode:@"recreating_view"
                               message:@"trying to create an already created view"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
  }

  NSObject<FlutterPlatformViewFactory>* factory = _platformViewFactories[viewType];
  if (factory == nil) {
    result([FlutterError
        errorWithCode:@"unregistered_view_type"
              message:@"trying to create a view with an unregistered type"
              details:[NSString stringWithFormat:@"unregistered view type: '%@'", viewType]]);
    return;
  }

  NSObject<FlutterPlatformView>* platform_view = [factory createWithFrame:CGRectZero
                                                           viewIdentifier:viewId
                                                                arguments:nil];

  _platformViews[viewId] = [platform_view view];
  result(nil);
}

- (void)onDisposeWithViewId:(int64_t)viewId result:(nonnull FlutterResult)result {
  if (!_embedded_views_preview_enabled) {
    NSLog(@"Must set `io.flutter_embedded_views_preview` to true in Info.plist to enable platform "
          @"views");
    return;
  }

  if (_platformViews.count(viewId) == 0) {
    result([FlutterError errorWithCode:@"unknown_view"
                               message:@"trying to dispose an unknown"
                               details:[NSString stringWithFormat:@"view id: '%lld'", viewId]]);
    return;
  }

  // The following disposePlatformViews call will dispose the views.
  _platformViewsToDispose.insert(viewId);
  result(nil);
}

- (void)registerViewFactory:(nonnull NSObject<FlutterPlatformViewFactory>*)factory
                     withId:(nonnull NSString*)factoryId {
  if (!_embedded_views_preview_enabled) {
    NSLog(@"Must set `io.flutter_embedded_views_preview` to true in Info.plist to enable platform "
          @"views");
    return;
  }
  _platformViewFactories[factoryId] = factory;
}

- (void)handleMethodCall:(nonnull FlutterMethodCall*)call result:(nonnull FlutterResult)result {
  if ([[call method] isEqualToString:@"create"]) {
    NSMutableDictionary<NSString*, id>* args = [call arguments];
    int64_t viewId = [args[@"id"] longValue];
    NSString* viewType = [NSString stringWithUTF8String:([args[@"viewType"] UTF8String])];
    [self onCreateWithViewId:viewId viewType:viewType result:result];
  } else if ([[call method] isEqualToString:@"dispose"]) {
    NSNumber* arg = [call arguments];
    int64_t viewId = [arg longLongValue];
    [self onDisposeWithViewId:viewId result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)disposePlatformViews {
  if (_platformViewsToDispose.empty()) {
    return;
  }

  FML_DCHECK([[NSThread currentThread] isMainThread])
      << "Must be on the main thread to handle disposing platform views";
  for (int64_t viewId : _platformViewsToDispose) {
    NSView* view = _platformViews[viewId];
    [view removeFromSuperview];
    _platformViews.erase(viewId);
  }
  _platformViewsToDispose.clear();
}

+ (bool)embeddedViewsEnabled {
  return [[[NSBundle mainBundle] objectForInfoDictionaryKey:@(kEmbeddedViewsPreview)] boolValue];
}

@end
