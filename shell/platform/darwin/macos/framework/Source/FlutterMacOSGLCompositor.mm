// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMacOSGLCompositor.h"

#import <OpenGL/gl.h>
#import "flutter/fml/logging.h"
#import "flutter/fml/platform/darwin/cf_utils.h"
#import "flutter/shell/platform/darwin/macos/framework/Source/MacOSSwitchableGLContext.h"
#import "third_party/skia/include/core/SkCanvas.h"
#import "third_party/skia/include/core/SkSurface.h"
#import "third_party/skia/include/gpu/gl/GrGLAssembleInterface.h"
#import "third_party/skia/include/utils/mac/SkCGUtils.h"

#include <unistd.h>

namespace flutter {

FlutterMacOSGLCompositor::FlutterMacOSGLCompositor(FlutterViewController* view_controller,
                                                   NSOpenGLContext* open_gl_context)
    : view_controller_(view_controller) {
  openGLContext_ = [[NSOpenGLContext alloc] initWithFormat:open_gl_context.pixelFormat
                                              shareContext:open_gl_context];
}

FlutterMacOSGLCompositor::~FlutterMacOSGLCompositor() = default;

bool FlutterMacOSGLCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                                  FlutterBackingStore* backing_store_out) {
  return CreateBackingStoreUsingSurfaceManager(config, backing_store_out);
}

bool FlutterMacOSGLCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  // Currently no memory has to be released.
  return true;
}

bool FlutterMacOSGLCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore: {
        FlutterSurfaceManager* surfaceManager =
            (__bridge FlutterSurfaceManager*)backing_store->user_data;

        CGSize size = CGSizeMake(layer->size.width, layer->size.height);
        [view_controller_.flutterView getFrameBufferIdForSize:size];
        [surfaceManager setLayerContentWithIOSurface:[surfaceManager getIOSurface]];
        break;
      }
      case kFlutterLayerContentTypePlatformView:
        // Add functionality in follow up PR.
        FML_CHECK(false) << "Presenting PlatformViews not yet supported";
        break;
    };
  }
  return present_callback_();
}

bool FlutterMacOSGLCompositor::CreateBackingStoreUsingSurfaceManager(
    const FlutterBackingStoreConfig* config,
    FlutterBackingStore* backing_store_out) {
  FlutterSurfaceManager* surfaceManager =
      [[FlutterSurfaceManager alloc] initWithLayer:view_controller_.flutterView.layer
                                     openGLContext:openGLContext_];

  GLuint fbo = [surfaceManager getFramebuffer];
  GLuint texture = [surfaceManager getTexture];
  IOSurfaceRef* io_surface_ref = [surfaceManager getIOSurface];

  CGSize size = CGSizeMake(config->size.width, config->size.height);

  [surfaceManager backTextureWithIOSurface:io_surface_ref size:size backingTexture:texture fbo:fbo];

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = (__bridge_retained void*)surfaceManager;
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = GL_RGBA8;
  backing_store_out->open_gl.framebuffer.name = fbo;
  // surfaceManager is managed by ARC. Nothing to be done in destruction callback.
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* user_data) {};

  return true;
}

void FlutterMacOSGLCompositor::SetPresentCallback(
    const FlutterMacOSGLCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

}  // namespace flutter
