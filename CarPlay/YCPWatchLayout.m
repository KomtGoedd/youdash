#import "YCPNative.h"
#import "YCPResponsiveLayout.h"
#import <objc/message.h>
#import <objc/runtime.h>

static const void *YCPWatchOriginalsKey = &YCPWatchOriginalsKey;

static IMP YCPWatchOriginal(id object, SEL selector) {
    for (Class cls = object_getClass(object); cls; cls = class_getSuperclass(cls)) {
        NSDictionary *methods = objc_getAssociatedObject(cls, YCPWatchOriginalsKey);
        NSValue *value = methods[NSStringFromSelector(selector)];
        if (value) return value.pointerValue;
    }
    return NULL;
}

static BOOL YCPCarWideWatchView(UIView *view) {
    UIWindow *car = YCPSurface.shared.activeWindow;
    return car && view && view.window == car && YCPShouldUseWideWatch(YCPSurface.shared.contentBounds.size);
}

static UIView *YCPWatchLayer(id object) {
    SEL getter = NSSelectorFromString(@"watchLayerView");
    id view = [object respondsToSelector:getter] ? ((id (*)(id, SEL))objc_msgSend)(object, getter) : nil;
    return [view isKindOfClass:UIView.class] ? view : nil;
}

static BOOL YCPWatchLayoutFlag(id object, SEL selector) {
    UIView *view = YCPWatchLayer(object);
    UIWindow *car = YCPSurface.shared.activeWindow;
    if (car && view.window == car) {
        CGSize size = YCPSurface.shared.contentBounds.size;
        if (selector == NSSelectorFromString(@"isLargeWideLayout")) return YCPShouldUseWideWatch(size);
        if (selector == NSSelectorFromString(@"isLandscape")) return size.width > size.height;
        return size.width >= 600;
    }
    IMP original = YCPWatchOriginal(object, selector);
    return original ? ((BOOL (*)(id, SEL))original)(object, selector) : NO;
}

static NSInteger YCPWatchOrientation(id object, SEL selector) {
    UIView *view = YCPWatchLayer(object);
    if (YCPSurface.shared.activeWindow && view.window == YCPSurface.shared.activeWindow) {
        CGSize size = YCPSurface.shared.contentBounds.size;
        return size.width > size.height ? UIInterfaceOrientationLandscapeLeft : UIInterfaceOrientationPortrait;
    }
    IMP original = YCPWatchOriginal(object, selector);
    return original ? ((NSInteger (*)(id, SEL))original)(object, selector) : UIInterfaceOrientationUnknown;
}

static BOOL YCPWideWatchDelegate(id object, SEL selector, UIView *watch) {
    if (YCPSurface.shared.activeWindow && watch.window == YCPSurface.shared.activeWindow) return YCPShouldUseWideWatch(YCPSurface.shared.contentBounds.size);
    IMP original = YCPWatchOriginal(object, selector);
    return original ? ((BOOL (*)(id, SEL, id))original)(object, selector, watch) : NO;
}

static CGFloat YCPWatchTopInset(id object, SEL selector) {
    UIView *view = [object isKindOfClass:UIViewController.class] ? ((UIViewController *)object).viewIfLoaded : nil;
    if (YCPCarWideWatchView(view)) return YCPSurface.shared.activeWindow.safeAreaInsets.top;
    IMP original = YCPWatchOriginal(object, selector);
    return original ? ((CGFloat (*)(id, SEL))original)(object, selector) : 0;
}

static UIEdgeInsets YCPNativeWindowInsets(UIView *view, SEL selector) {
    IMP original = YCPWatchOriginal(view, selector);
    UIEdgeInsets insets = original ? ((UIEdgeInsets (*)(id, SEL))original)(view, selector) : UIEdgeInsetsZero;
    UIWindow *car = YCPSurface.shared.activeWindow;
    // YouTube's category can use the phone window's cached status-bar height,
    // independently of the watch controller's statusBarHeight property.
    if (car && view.window == car) insets.top = car.safeAreaInsets.top;
    return insets;
}

static CGRect YCPMiniPlayerFrame(id object, SEL selector) {
    IMP original = YCPWatchOriginal(object, selector);
    CGRect frame = original ? ((CGRect (*)(id, SEL))original)(object, selector) : CGRectZero;
    if (!YCPSurface.shared.activeWindow) return frame;
    return YCPFitMiniPlayer(frame, YCPSurface.shared.contentBounds, YCPSurface.shared.miniPlayerSafeInsets);
}

// Keep the first below-player cell clear of the player's scrubber/clipping edge.
// Use the actual collection viewport, not phone dimensions or a scroll reset.
static UIEdgeInsets YCPWatchSectionInsets(UIViewController *controller, SEL selector, UICollectionView *collection, UICollectionViewLayout *layout, NSInteger section) {
    IMP original = YCPWatchOriginal(controller, selector);
    UIEdgeInsets insets = original ? ((UIEdgeInsets (*)(id, SEL, id, id, NSInteger))original)(controller, selector, collection, layout, section) : UIEdgeInsetsZero;
    UIWindow *car = YCPSurface.shared.activeWindow;
    if (section != 0 || !YCPCarWideWatchView(controller.viewIfLoaded) || collection.window != car) return insets;
    CGRect viewport = [collection convertRect:collection.bounds toView:car];
    // The metadata column is below the player, on the leading side. The queue
    // starts at the top on the trailing side and must retain its native insets.
    if (CGRectGetMinY(viewport) > car.safeAreaInsets.top + 44
        && CGRectGetMinX(viewport) < CGRectGetMidX(car.bounds)
        && CGRectGetWidth(viewport) < CGRectGetWidth(car.bounds) * 0.8)
        insets.top = MAX(12, insets.top);
    return insets;
}

static BOOL YCPSplitMetadataFix(id object, SEL selector) {
    if (YCPSurface.shared.activeWindow) return YES;
    IMP original = YCPWatchOriginal(object, selector);
    return original ? ((BOOL (*)(id, SEL))original)(object, selector) : NO;
}

static void YCPPatchWatch(Class cls, SEL selector, IMP replacement) {
    Method method = class_getInstanceMethod(cls, selector);
    if (!method || method_getImplementation(method) == replacement) return;
    NSMutableDictionary *methods = [objc_getAssociatedObject(cls, YCPWatchOriginalsKey) mutableCopy] ?: [NSMutableDictionary new];
    methods[NSStringFromSelector(selector)] = [NSValue valueWithPointer:method_getImplementation(method)];
    objc_setAssociatedObject(cls, YCPWatchOriginalsKey, methods, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (!class_addMethod(cls, selector, replacement, method_getTypeEncoding(method)))
        class_replaceMethod(cls, selector, replacement, method_getTypeEncoding(method));
}

void YCPInstallWatchLayoutHooks(void) {
    YCPPatchWatch(UIView.class, NSSelectorFromString(@"yt_safeAreaInsetsForWindow"), (IMP)YCPNativeWindowInsets);
    YCPPatchWatch(UIView.class, NSSelectorFromString(@"yt_safeAreaInsetsForBrowse"), (IMP)YCPNativeWindowInsets);
    // 21.42.4 implements this ObjC protocol in a Swift class with a mangled name.
    // Discover that implementation instead of depending on the Swift module name.
    Protocol *protocol = objc_getProtocol("YTWatchLayoutController");
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int index = 0; index < count; index++) {
        Class cls = classes[index];
        // Enable the native fix for metadata measured in a split watch column.
        SEL metadataFix = NSSelectorFromString(@"enableIosSplitMetadataViewFix");
        if (class_getInstanceMethod(cls, metadataFix))
            YCPPatchWatch(cls, metadataFix, (IMP)YCPSplitMetadataFix);
        if (!protocol || !class_conformsToProtocol(cls, protocol)
            || !class_getInstanceMethod(cls, NSSelectorFromString(@"watchLayerView"))) continue;
        for (NSString *name in @[@"isLargeLayout", @"isLargeWideLayout", @"isLandscape"])
            YCPPatchWatch(cls, NSSelectorFromString(name), (IMP)YCPWatchLayoutFlag);
        YCPPatchWatch(cls, NSSelectorFromString(@"interfaceOrientation"), (IMP)YCPWatchOrientation);
    }
    free(classes);
    Class results = NSClassFromString(@"YTWatchNextResultsViewController");
    if (results) YCPPatchWatch(results, NSSelectorFromString(@"collectionView:layout:insetForSectionAtIndex:"), (IMP)YCPWatchSectionInsets);
    Class mini = NSClassFromString(@"YTWatchMiniplayerLayoutOutput");
    if (mini) YCPPatchWatch(mini, NSSelectorFromString(@"miniplayerFrame"), (IMP)YCPMiniPlayerFrame);
    Class layer = NSClassFromString(@"YTWatchLayerViewController");
    if (layer) {
        YCPPatchWatch(layer, NSSelectorFromString(@"statusBarHeight"), (IMP)YCPWatchTopInset);
        YCPPatchWatch(layer, NSSelectorFromString(@"headerHeight"), (IMP)YCPWatchTopInset);
    }
    Class watch = NSClassFromString(@"YTWatchViewController");
    if (watch) YCPPatchWatch(watch, NSSelectorFromString(@"isWideLayoutForWatchView:"), (IMP)YCPWideWatchDelegate);
}
