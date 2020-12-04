// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <map>
#include <unordered_set>

#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterViewController.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterView.h"

@interface FlutterViewController ()

// The FlutterView for this view controller.
@property(nonatomic, readonly, nullable) FlutterView* flutterView;

// @property() std::map<std::string, NSObject<FlutterPlatformViewFactory>*> factories_;

// A map of view ids to views.
@property() std::map<int, NSView*> platformViews;
// View ids that are going to be disposed on the next present call.
@property() std::unordered_set<int64_t> platformViewsToDispose;

/**
 * This just returns the NSPasteboard so that it can be mocked in the tests.
 */
@property(nonatomic, readonly, nonnull) NSPasteboard* pasteboard;

- (void)onCreate:(nonnull FlutterMethodCall*)call 
          result:(nonnull FlutterResult)result;

- (void)onDispose:(nonnull FlutterMethodCall*)call 
          result:(nonnull FlutterResult)result;

/**
 * Adds a responder for keyboard events. Key up and key down events are forwarded to all added
 * responders.
 */
- (void)addKeyResponder:(nonnull NSResponder*)responder;

/**
 * Removes a responder for keyboard events.
 */
- (void)removeKeyResponder:(nonnull NSResponder*)responder;

@end
