
#include <map>
#include <unordered_set>

class FlutterPlatformViewsController {
  
private:
  std::map<int, NSView*> views;
  std::unordered_set<int64_t> viewsToDispose;
}