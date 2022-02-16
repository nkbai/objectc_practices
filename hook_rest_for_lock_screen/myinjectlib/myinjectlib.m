//
//  myinjectlib.m
//  myinjectlib
//
//  Created by bai on 2/14/22.
//
//

#import <CoreGraphics/CoreGraphics.h>
#import <AppKit/AppKit.h>
#import <Carbon/Carbon.h>
#import "myinjectlib.h"
#import "CaptainHook.h"

CHDeclareClass(AppDelegate)
AppDelegate *storedAppDelegate = nil; //这个会一直有效,所以不存在ref问题

OSStatus hotKeyHandler(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData) {
    id aaa = storedAppDelegate;
    [aaa removeBreakScreens];
    return noErr;
}

// 注册快捷键
void registerHotKey() {

// 1、声明相关参数
    EventHotKeyRef myHotKeyRef;
    EventHotKeyID myHotKeyID;
    EventTypeSpec myEvenType;
    myEvenType.eventClass = kEventClassKeyboard;    // 键盘类型
    myEvenType.eventKind = kEventHotKeyPressed;     // 按压事件

// 2、定义快捷键
    myHotKeyID.signature = 'yuus';  // 自定义签名
    myHotKeyID.id = 4;              // 快捷键ID

// 3、注册快捷键
// 参数一：keyCode; 如18代表1，19代表2，21代表4，49代表空格键，36代表回车键
// 快捷键：command+4
//RegisterEventHotKey(21, cmdKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);

// 快捷键：command+option+4
    OSStatus status = RegisterEventHotKey(21, cmdKey + optionKey, myHotKeyID, GetApplicationEventTarget(), 0, &myHotKeyRef);
    NSLog(@"RegisterEventHotKey status=%d", status);

// 5、注册回调函数，响应快捷键
    status = InstallApplicationEventHandler(&hotKeyHandler, 1, &myEvenType, NULL, NULL);
    NSLog(@"InstallEventHandler status=%d", status);
}

typedef int (*SACLockScreenImmediatePointer)(void);

SACLockScreenImmediatePointer SACLockScreenImmediate = NULL;
//这种方式会segment 错误,不知道什么原因
//void removeBreakScreens() {
////    SACLockScreenImmediate();
//// 手工启动命令行吧.
//    if (SACLockScreenImmediate == NULL) {
//        NSLog(@"init SACLockScreenImmediate");
//        CFBundleRef myBundle;
//        CFURLRef bundleURL;
////    NSBundle * myBundle=[NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/login.framework"];
////    BOOL load=[myBundle load];
////    NSLog(@"load=%d",load);
////    CFBundleGetFunctionPointerForName(bundle, CFSTR("SACLockScreenImmediate"));
//        // Make a CFURLRef from the CFString representation of the
//// bundle’s path.
//        bundleURL = CFURLCreateWithFileSystemPath(
//                kCFAllocatorDefault,
//                CFSTR("/System/Library/PrivateFrameworks/login.framework"),
//                kCFURLPOSIXPathStyle,
//                true);
//
//// Make a bundle instance using the URLRef.
//        myBundle = CFBundleCreate(kCFAllocatorDefault, bundleURL);
//       NSLog(@"mybundle=%@",myBundle);
//// You can release the URL now.
//        CFRelease(bundleURL);
//        Boolean load=CFBundleLoadExecutable(myBundle);
//        NSLog(@"load=%d",load);
//        NSLog(@"mybundle=%@",myBundle);
//// Use the bundle...
//        NSLog(@"before");
//        SACLockScreenImmediate = (SACLockScreenImmediatePointer) CFBundleGetFunctionPointerForName( myBundle, CFSTR("SACLockScreenImmediate"));
//        NSLog(@"fp=%@",SACLockScreenImmediate);
//        // Release the bundle when done.
////    CFRelease( myBundle );
//    }
//    if (SACLockScreenImmediate != nil) {
//        SACLockScreenImmediate();
//    }
//}

NSString * lockCommand=@"import objc\n"
                       "from Foundation import NSBundle\n"
                       "def do_it():\n"
                       "    Login = NSBundle.bundleWithPath_('/System/Library/PrivateFrameworks/login.framework')\n"
                       "    functions = [\n"
                       "        ('SACLockScreenImmediate', '@'),\n"
                       "    ]\n"
                       "    objc.loadBundleFunctions(Login, globals(), functions)\n"
                       "    SACLockScreenImmediate();\n"
                       "do_it()";
void removeBreakScreens(){
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/python";
    task.arguments = @[@"-c", lockCommand];
    [task launch];
    [NSThread sleepForTimeInterval:1];
}
/*
 * 第一次调用的时候注册快捷键,并且保存appDelegate,然后在快捷键响应时,调用appDelegate的removeBreakScreens
 */
void setBreakScreens(AppDelegate *appDelegate) {
    if (storedAppDelegate == nil) {
        storedAppDelegate = appDelegate;
        registerHotKey();
    }
}

CHOptimizedMethod0(self, void, AppDelegate, removeBreakScreens) {
    NSLog(@"removeBreakScreens called");
    removeBreakScreens();
    CHSuper0(AppDelegate, removeBreakScreens);
}

CHOptimizedMethod0(self, void, AppDelegate, setBreakScreens) {
    NSLog(@"setBreakScreens called");
    CHSuper0(AppDelegate, setBreakScreens);
    setBreakScreens(self);
}

CHConstructor {
    CHLoadLateClass(AppDelegate);
    CHClassHook0(AppDelegate, removeBreakScreens);
    CHClassHook0(AppDelegate, setBreakScreens);
};

@implementation myinjectlib
+ (void)load {
    // DO YOUR WORKS...
    NSLog(@"myinjectlib");

}

- (void)privatef {
//    CGWindowLevelForKey();
//    [NSScreen screens];
    NSWindow *w = nil;
    [w makeKeyAndOrderFront:w];
    w.level = 13 + 100;
    w.opaque = 0;
    w.backgroundColor = [NSColor colorWithWhite:0 alpha:0];
    w.collectionBehavior = w.collectionBehavior | 1;
    [NSAnimationContext beginGrouping];
    NSAnimationContext *ctx = NSAnimationContext.currentContext;
    ctx.duration = 35;
}

- (void)removeBreakScreens {

}
@end
