// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/macos/framework/Source/FlutterMacOSGLCompositor.h"

#import <OpenGL/gl.h>
#import "flutter/fml/logging.h"
#import "flutter/fml/platform/darwin/cf_utils.h"
#import "third_party/skia/include/core/SkCanvas.h"
#import "third_party/skia/include/core/SkSurface.h"
#import "third_party/skia/include/gpu/gl/GrGLAssembleInterface.h"
#import "third_party/skia/include/utils/mac/SkCGUtils.h"

#include <unistd.h>

namespace flutter {

FlutterMacOSGLCompositor::FlutterMacOSGLCompositor(FlutterViewController* view_controller)
    : view_controller_(view_controller) {
  auto interface = GrGLMakeNativeInterface();
  GrContextOptions options;
  context_ = GrDirectContext::MakeGL(GrGLMakeNativeInterface(), options);
}

FlutterMacOSGLCompositor::~FlutterMacOSGLCompositor() = default;

bool FlutterMacOSGLCompositor::CreateBackingStore(const FlutterBackingStoreConfig* config,
                                                FlutterBackingStore* backing_store_out) {
  NSLog(@"FlutterMacOSGLCompositor::CreateBackingStore");
  return CreateFramebuffer(config, backing_store_out);
}

bool FlutterMacOSGLCompositor::CollectBackingStore(const FlutterBackingStore* backing_store) {
  // We have already set the destruction callback for the various backing
  // stores. Our user_data is just the canvas from that backing store and does
  // not need to be explicitly collected. Embedders might have some other state
  // they want to collect though.
  NSLog(@"FlutterMacOSGLCompositor::CollectBackingStore");
  return true;
}

bool FlutterMacOSGLCompositor::Present(const FlutterLayer** layers, size_t layers_count) {
  GLuint fbo_id;
  // GLuint dest_fbo_id;
  CGSize size;

  // CALayer* content_layer;

  // IOSurfaceRef io_surface_ref;
  unsigned pixelFormat;
  unsigned bytesPerElement;
  size_t bytesPerRow;
  size_t totalBytes;
  uint32_t texture_id;
  NSDictionary* options;
  NSLog(@"layers count: %zu", layers_count);

  for (size_t i = 0; i < layers_count; ++i) {
    const auto* layer = layers[i];
    FlutterBackingStore* backing_store = const_cast<FlutterBackingStore*>(layer->backing_store);
    switch (layer->type) {
      case kFlutterLayerContentTypeBackingStore:
        NSLog(@"kFlutterLayerContentTypeBackingStore, Layer: %zu", i);
        fbo_id = backing_store->open_gl.framebuffer.name;
        NSLog(@"Presenting FBOID: %u", fbo_id);
        size = CGSizeMake(layer->size.width, layer->size.height);

        if (backing_store->ca_layer == nullptr) {
          NSLog(@"ca_layer == nullptr");
          content_layer = [[CALayer alloc] init];
          [content_layer setFrame:CGRectMake(layer->offset.x, layer->offset.y, size.width, size.height)];
          backing_store->ca_layer = (__bridge void*)content_layer;
          [content_layer setBackgroundColor:[[NSColor yellowColor] CGColor]];
          [view_controller_.flutterView.layer addSublayer:content_layer];
        } else {
          NSLog(@"ca_layer != nullptr");
          content_layer = (__bridge CALayer*)backing_store->ca_layer;
          // [content_layer setFrame:CGRectMake(layer->offset.x, layer->offset.y, size.width, size.height)];
        }

        // IOSurfaceRef
        pixelFormat = 'BGRA';
        bytesPerElement = 4;

        bytesPerRow =
          IOSurfaceAlignProperty(kIOSurfaceBytesPerRow, size.width * bytesPerElement);
        totalBytes = IOSurfaceAlignProperty(kIOSurfaceAllocSize, size.height * bytesPerRow);
        options = @{
          (id)kIOSurfaceWidth : @(size.width),
          (id)kIOSurfaceHeight : @(size.height),
          (id)kIOSurfacePixelFormat : @(pixelFormat),
          (id)kIOSurfaceBytesPerElement : @(bytesPerElement),
          (id)kIOSurfaceBytesPerRow : @(bytesPerRow),
          (id)kIOSurfaceAllocSize : @(totalBytes),
        };
        // backing_store->io_surface_ref = (void*)IOSurfaceCreate((CFDictionaryRef)options);
        if (_ioSurfaceRef) {
          CFRelease(_ioSurfaceRef);
        }
        _ioSurfaceRef = IOSurfaceCreate((CFDictionaryRef)options);

        texture_id = backing_store->open_gl.framebuffer.texture;

        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture_id);

        CGLTexImageIOSurface2D(CGLGetCurrentContext(), GL_TEXTURE_RECTANGLE_ARB, GL_RGBA,
                           int(size.width), int(size.height), GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV,
                           _ioSurfaceRef, 0 /* plane */);
        glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

        glBindFramebuffer(GL_FRAMEBUFFER, fbo_id);
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_RECTANGLE_ARB,
                           texture_id, 0);

        FML_DCHECK(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

        content_layer.transform = CATransform3DMakeScale(1, -1, 1);
        [content_layer setContents:(__bridge id)_ioSurfaceRef];
        break;
      case kFlutterLayerContentTypePlatformView:
        NSLog(@"kFlutterLayerContentTypePlatformView");
        [view_controller_.view addSubview: view_controller_.view_map.at(1)];
        break;
    };
  }
  // return true;
  return present_callback_();
}

bool FlutterMacOSGLCompositor::CreateFramebuffer(const FlutterBackingStoreConfig* config,
                                               FlutterBackingStore* backing_store_out) {
  NSLog(@"CreateFramebuffer");
  // GrGLFramebufferInfo framebuffer_info;

  // framebuffer_info = {};
  // glGenFramebuffersEXT(1, &framebuffer_info.fFBOID);
  // glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_info.fFBOID);

  // NSLog(@"framebuffer id %u:", framebuffer_info.fFBOID);
  // GLuint texture;
  // glGenTextures(1, &texture);
  // glBindTexture(GL_TEXTURE_2D, texture);

  // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  // glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  // glTexImage2D( GL_TEXTURE_2D, 0, GL_RGBA, config->size.width, config->size.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
  // glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
  //                 GL_TEXTURE_2D, texture, 0);
                  
  // if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
  //   NSLog(@"invalid framebuffer");
  //   return false;
  // }

  // Logic from FlutterSurfaceManager.
  GrGLFramebufferInfo framebuffer_info = {};
  GLuint texture;

  glGenFramebuffers(1, &framebuffer_info.fFBOID);
  glGenTextures(1, &texture);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_info.fFBOID);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, texture);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_RECTANGLE_ARB, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_RECTANGLE_ARB, 0);

  framebuffer_info.fFormat = GL_RGBA8;
  const SkColorType color_type = kN32_SkColorType;

  GrBackendRenderTarget render_target(config->size.width,   // width
                                      config->size.height,  // height
                                      1,                    // sample count
                                      0,                    // stencil bits
                                      framebuffer_info      // framebuffer info
  );

  if (!render_target.isValid()) {
    FML_LOG(ERROR) << "Backend render target was invalid.";
    return false;
  }

  sk_sp<SkColorSpace> colorspace = SkColorSpace::MakeSRGB();
  SkSurfaceProps surface_props(0, kUnknown_SkPixelGeometry);

  auto surface = SkSurface::MakeFromBackendRenderTarget(
      context_.get(),                                // gr context
      render_target,                                 // render target
      GrSurfaceOrigin::kBottomLeft_GrSurfaceOrigin,  // origin
      color_type,                                    // color type
      colorspace,                                    // colorspace
      &surface_props                                 // surface properties
  );

  if (!surface) {
    FML_LOG(ERROR) << "Could not create render target for compositor layer.";
    return false;
  }

  backing_store_out->type = kFlutterBackingStoreTypeOpenGL;
  backing_store_out->user_data = surface.get();
  backing_store_out->open_gl.type = kFlutterOpenGLTargetTypeFramebuffer;
  backing_store_out->open_gl.framebuffer.target = framebuffer_info.fFormat;
  backing_store_out->open_gl.framebuffer.texture = texture;
  backing_store_out->open_gl.framebuffer.name = framebuffer_info.fFBOID;
  // The balancing unref is in the destruction callback.
  surface->ref();
  backing_store_out->open_gl.framebuffer.user_data = surface.get();
  backing_store_out->open_gl.framebuffer.destruction_callback = [](void* user_data) {
    reinterpret_cast<SkSurface*>(user_data)->unref();
  };

  return true;
}

void FlutterMacOSGLCompositor::SetPresentCallback(
    const FlutterMacOSGLCompositor::PresentCallback& present_callback) {
  present_callback_ = present_callback;
}

}  // namespace flutter
