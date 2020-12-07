// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewController_Internal.h"

#import <OCMock/OCMock.h>

#import "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#import "flutter/shell/platform/darwin/macos/framework/Headers/FlutterEngine.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterDartProject_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterEngine_Internal.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViewMock.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterPlatformViews.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"

#include "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterViewController, HasStringsWhenPasteboardEmpty) {
  // Mock FlutterViewController so that it behaves like the pasteboard is empty.
  id viewControllerMock = CreateMockViewController(nil);

  // Call hasStrings and expect it to be false.
  __block bool calledAfterClear = false;
  __block bool valueAfterClear;
  FlutterResult resultAfterClear = ^(id result) {
    calledAfterClear = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    valueAfterClear = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCallAfterClear =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCallAfterClear result:resultAfterClear];
  EXPECT_TRUE(calledAfterClear);
  EXPECT_FALSE(valueAfterClear);
}

TEST(FlutterViewController, HasStringsWhenPasteboardFull) {
  // Mock FlutterViewController so that it behaves like the pasteboard has a
  // valid string.
  id viewControllerMock = CreateMockViewController(@"some string");

  // Call hasStrings and expect it to be true.
  __block bool called = false;
  __block bool value;
  FlutterResult result = ^(id result) {
    called = true;
    NSNumber* valueNumber = [result valueForKey:@"value"];
    value = [valueNumber boolValue];
  };
  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"Clipboard.hasStrings" arguments:nil];
  [viewControllerMock handleMethodCall:methodCall result:result];
  EXPECT_TRUE(called);
  EXPECT_TRUE(value);
}

TEST(FlutterViewController, TestCreatePlatformViewNoMatchingViewType) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  // Use id so we can access handleMethodCall method.
  id viewController = [[FlutterViewController alloc] initWithProject:project];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"FlutterPlatformViewMock"
                                        }];

  __block bool errored = false;
  FlutterResult result = ^(id result) {
    if ([result isKindOfClass:[FlutterError class]]) {
      errored = true;
    }
  };

  [viewController handleMethodCall:methodCall result:result];

  // We expect the call to error since no factories are registered.
  EXPECT_TRUE(errored);
}

TEST(FlutterViewController, TestRegisterPlatformViewFactoryAndCreate) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  // Use id so we can access handleMethodCall method.
  id viewController = [[FlutterViewController alloc] initWithProject:project];

  FlutterPlatformViewMockFactory* factory = [FlutterPlatformViewMockFactory alloc];

  [viewController registerViewFactory:factory withId:@"MockPlatformView"];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"MockPlatformView"
                                        }];

  __block bool success = false;
  FlutterResult result = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      success = true;
    }
  };
  [viewController handleMethodCall:methodCall result:result];

  EXPECT_TRUE(success);
}

TEST(FlutterViewController, TestCreateAndDispose) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  // Use id so we can access handleMethodCall method.
  id viewController = [[FlutterViewController alloc] initWithProject:project];

  FlutterPlatformViewMockFactory* factory = [FlutterPlatformViewMockFactory alloc];

  [viewController registerViewFactory:factory withId:@"MockPlatformView"];

  FlutterMethodCall* methodCallOnCreate =
      [FlutterMethodCall methodCallWithMethodName:@"create"
                                        arguments:@{
                                          @"id" : @2,
                                          @"viewType" : @"MockPlatformView"
                                        }];

  __block bool created = false;
  FlutterResult resultOnCreate = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      created = true;
    }
  };

  [viewController handleMethodCall:methodCallOnCreate result:resultOnCreate];

  FlutterMethodCall* methodCallOnDispose =
      [FlutterMethodCall methodCallWithMethodName:@"dispose"
                                        arguments:[NSNumber numberWithLongLong:2]];

  __block bool disposed = false;
  FlutterResult resultOnDispose = ^(id result) {
    // If a platform view is successfully created, the result is nil.
    if (result == nil) {
      disposed = true;
    }
  };

  [viewController handleMethodCall:methodCallOnDispose result:resultOnDispose];

  EXPECT_TRUE(created);
  EXPECT_TRUE(disposed);
}

TEST(FlutterViewController, TestDisposeOnMissingViewId) {
  NSString* fixtures = @(testing::GetFixturesPath());
  FlutterDartProject* project = [[FlutterDartProject alloc]
      initWithAssetsPath:fixtures
             ICUDataPath:[fixtures stringByAppendingString:@"/icudtl.dat"]];

  // Use id so we can access handleMethodCall method.
  id viewController = [[FlutterViewController alloc] initWithProject:project];

  FlutterMethodCall* methodCall =
      [FlutterMethodCall methodCallWithMethodName:@"dispose"
                                        arguments:[NSNumber numberWithLongLong:20]];

  __block bool errored = false;
  FlutterResult result = ^(id result) {
    if ([result isKindOfClass:[FlutterError class]]) {
      errored = true;
    }
  };

  [viewController handleMethodCall:methodCall result:result];

  EXPECT_TRUE(errored);
}

}  // flutter::testing
