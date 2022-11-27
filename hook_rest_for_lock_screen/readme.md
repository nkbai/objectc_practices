## 背景
先说一下背景,Rest是一个在Mac上用的休息提醒工具,可以在AppStore中购买(**不免费**). 本来一直用的好好的,但是现在公司要求离开工位必须锁屏,这就导致我在休息的时候只能在工位边上,否则上个厕所回来,休息结束了,桌面就直接暴露出来了. 
简单看了一下Rest是用ObjectC编写的,基本满足我的要求,主要有以下问题:
1. 休息的时候,必须钩上`Prevent me from working during beaks`,否则如果有多个虚拟桌面,就会导致暴露桌面内容.
2. 休息结束后不能自动锁屏
3. 针对问题1,如果开启了`Prevent me from working during beaks`,在休息时,如果万一有应急工作,就不能立即响应了.


## 工具收集

### 1. 如何注入一个dylib

主要有两种方式,一种是动态注入,一种是持久注入. 如果是动态注入,因为不需要远程注入,所以很简单的,通过DYLD_INSERT_LIBRARIES启动即可,具体来说:
```bash
DYLD_INSERT_LIBRARIES=libmyinjectlib.dylib ./Res
```

另一种就麻烦一点,可以通过类似[inject_dylib](https://github.com/gengjf/insert_dylib)这样的工具静态注入, 但是我尝试后发现修改后的程序无法运行,所以暂用动态注入的方式,这种方式至少可以满足我的要求,只需要一个启动脚本即可.


### 2. 如何进行hook

这个要依赖的工具就是[CaptainHook](https://github.com/rpetrich/CaptainHook.git),只有一个头文件,用起来也比较简单.

## 注入点分析
休息窗口的特点是一个全屏的窗口,并且该窗口要在所有窗口之前. 因此NSWindow的setLevel就是一个比较好的入口点,经过搜索发现,该调用只有一处`-[AppDelegate setBreakScreens](AppDelegate *self, SEL a2)`. 
经过对该函数的分析,可以发现这个就是启动休息的函数.

注意到里面的`removeBreakScreens`,按照名字提示,应该是结束休息的函数. 所以对以上两个函数进行hook,应该可以达到我们的目的:
1. hook `removeBreakScreens`,结束的时候进行锁屏.
2. hook `setBreakScreens` 可以在里面注册一个快捷键(不是全局的),这样万一有工作的时候,可以立即结束休息.


## 注入
有了注入点,剩下就是用CaptainHook进行注入了.

```objectc
CHDeclareClass(AppDelegate)
CHOptimizedMethod0(self, void, AppDelegate, removeBreakScreens) {
    NSLog(@"removeBreakScreens called");
    CHSuper0(AppDelegate, removeBreakScreens);
}

CHOptimizedMethod0(self, void, AppDelegate, setBreakScreens) {
    NSLog(@"setBreakScreens called");
    CHSuper0(AppDelegate, setBreakScreens);
}

CHConstructor {
    CHLoadLateClass(AppDelegate);
    CHClassHook0(AppDelegate, removeBreakScreens);
    CHClassHook0(AppDelegate, setBreakScreens);
};

```

经过验证,确实每次启动休息都会调用`setBreakScreens`,而无论是正常结束休息,还是点击`let me work`都会调用`removeBreakScreens`. 



## 高版本启动失败的问题

由于mac在版本中删除了python 2.7,所以需要自行安装python2.7,并且记得安装pyobjc

pip install -U pyobjc


## 其他
这是首次在Mac上成功修改一个程序的逻辑,以前搞过Windows和Linux,Mac还是首次,ObjectC和C/C++比起来,运行时要复杂的多,特别适合注入.  完整的程序已经放在[我的github](https://github.com/nkbai/objectc_practices),欢迎试用.如果你们公司也有锁屏要求的话.





