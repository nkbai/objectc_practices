import objc
from Foundation import NSBundle
def do_it():
    Login = NSBundle.bundleWithPath_('/System/Library/PrivateFrameworks/login.framework')
    functions = [
        ('SACLockScreenImmediate', '@'),
    ]
    objc.loadBundleFunctions(Login, globals(), functions)
    SACLockScreenImmediate();
do_it()