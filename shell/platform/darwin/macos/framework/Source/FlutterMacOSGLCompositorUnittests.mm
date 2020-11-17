// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import <Foundation/Foundation.h>

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMacOSGLCompositor.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterViewControllerTestUtils.h"
#import "flutter/testing/testing.h"

namespace flutter::testing {

TEST(FlutterMacOSGLCompositorTest, TestPresent) {
  id mockViewController = CreateMockViewController(nil);

  std::unique_ptr<flutter::FlutterMacOSGLCompositor> macos_compositor =
      std::make_unique<FlutterMacOSGLCompositor>(mockViewController);

  bool flag = false;
  macos_compositor->SetPresentCallback([f = &flag]() {
    *f = true;
    return true;
  });

  ASSERT_TRUE(macos_compositor->Present(nil, 0));
  ASSERT_TRUE(flag);
}

}  // flutter::testing
