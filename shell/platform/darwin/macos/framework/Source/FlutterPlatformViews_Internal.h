
#include <map>
#include <unordered_set>

#include "flutter/fml/platform/darwin/scoped_nsobject.h"

namespace flutter {

class FlutterPlatformViewsController {
   public:
  FlutterPlatformViewsController();

  ~FlutterPlatformViewsController();
private:
  std::map<int, fml::scoped_nsobject<NSView>> views;
  std::unordered_set<int64_t> viewsToDispose;
  std::map<std::string, fml::scoped_nsobject<NSObject<FlutterPlatformViewFactory>>> factories_;
}

}  // namespace flutter