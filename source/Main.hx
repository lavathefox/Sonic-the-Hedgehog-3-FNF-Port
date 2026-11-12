package;

import debug.FPSCounter;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.util.FlxColor;
import haxe.Timer;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.events.Event;
import lime.app.Application;
import lime.system.System;
import states.Sonic3TitleStateV2;
import backend.Highscore;
import backend.Sonic3Storage;
#if sys
import save.Save;
#end
#if html5
import external.html5.HtmlSupport;
import js.Browser;
import js.html.Event as BrowserEvent;
#end

#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import psychlua.HScript.HScriptInfos;
#end
#if (linux || mac)
import lime.graphics.Image;
#end
#if (windows && cpp)
import external.windows.WinAPI;
#end
#if CRASH_HANDLER
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import sys.FileSystem;
import sys.io.File;
#end

#if (linux && !debug)
@:cppInclude('./external/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end
class Main extends Sprite
{
    public static final game = {
        width: 959,
        height: 670,
        initialState: Sonic3TitleStateV2,
        framerate: 60,
        skipSplash: true,
        startFullscreen: false
    };

    public static var fpsVar:FPSCounter;
    public static var instance(default, null):Main;
    public static var initialized(default, null):Bool = false;
    public static var shuttingDown(default, null):Bool = false;
    public static var startupTime(default, null):Float = 0;
    public static var lastFrameTime(default, null):Float = 0;
    public static var saveEnabled(default, null):Bool = false;

    #if html5
    static var browserPageHide:BrowserEvent->Void;
    static var browserBeforeUnload:BrowserEvent->Void;
    #end

    static inline var GAME_TITLE:String = 'Sonic the Hedgehog 3 (FNF Port)';
    #if (CRASH_HANDLER && sys)
    static inline var CRASH_LOG_NAME:String = 'CRASH_LOG.txt';
    static inline var CRASH_LOG_LIMIT:Int = 512 * 1024;
    static var handlingCrash:Bool = false;
    #end

    public static function main():Void
    {
        Lib.current.addChild(new Main());
    }

    public function new()
    {
        super();
        #if SWITCH_BUILD
        backend.SwitchHeap.init();
        #end
        if (instance != null) return;
        instance = this;
        startupTime = Timer.stamp();
        lastFrameTime = startupTime;

        #if (CRASH_HANDLER && sys)
        Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
        #end
        #if (cpp && windows)
        backend.Native.fixScaling();
        #end

        var needsPermission:Bool = setupStorage();
        setupProgress();
        #if (CRASH_HANDLER && android)
        writeLaunchLog();
        #end

        #if (VIDEOS_ALLOWED && !html5)
        hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0") ['--no-lua'] #end);
        #end
        #if (LUA_ALLOWED && cpp)
        Mods.pushGlobalMods();
        #end
        Mods.loadTopMod();

        #if html5
        FlxG.save.bind('funkin', 'sonic3-fnf-port');
        #else
        FlxG.save.bind('funkin', CoolUtil.getSavePath());
        #end
        Highscore.load();

        #if (HSCRIPT_ALLOWED && !html5)
        setupScriptLogging();
        #end
        #if (LUA_ALLOWED && cpp)
        Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(psychlua.CallbackHandler.call));
        #end
        Controls.instance = new Controls();
        ClientPrefs.loadDefaultKeys();
        #if ACHIEVEMENTS_ALLOWED
        Achievements.load();
        #end

        var startState:Class<FlxState> = needsPermission ? states.PermissionState : game.initialState;
        addChild(new FlxGame(game.width, game.height, startState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));

        setupStage();
        setupFPS();
        setupWindow();
        setupRuntime();
        #if html5
        setupBrowser();
        #end
        registerEvents();
        initialized = true;
    }

    static function setupProgress():Void
    {
        #if sys
        var folder:String;
        #if mobile
        folder = Path.join([System.applicationStorageDirectory, 'sonic3-progress']);
        #else
        folder = Path.join([Sys.getCwd(), 'saves']);
        #end
        saveEnabled = Save.initialize(folder);
        if (saveEnabled)
            saveEnabled = Save.load(0);
        #end
    }

    static function setupStage():Void
    {
        #if !mobile
        Lib.current.stage.align = StageAlign.TOP_LEFT;
        Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
        #end
    }

    static function setupWindow():Void
    {
        #if (linux || mac)
        try
        {
            Lib.current.stage.window.setIcon(Image.fromFile('icon.png'));
        }
        catch (error:Dynamic) {}
        #end
        #if (windows && cpp)
        WinAPI.setWindowTitle(GAME_TITLE);
        #end
    }

    static function setupRuntime():Void
    {
        #if html5
        FlxG.autoPause = true;
        #end
        #if (mobile || html5)
        hideMouseCursor();
        #end
        FlxG.fixedTimestep = false;
        FlxG.game.focusLostFramerate = 60;
        FlxG.keys.preventDefaultKeys = [TAB];
        #if (DISCORD_ALLOWED && !html5)
        DiscordClient.prepare();
        #end
    }

    function registerEvents():Void
    {
        FlxG.signals.gameResized.add(onGameResized);
        addEventListener(Event.ENTER_FRAME, onFrame);
        if (Lib.current.stage != null)
            Lib.current.stage.addEventListener(Event.DEACTIVATE, onDeactivated);
    }

    public static function hideMouseCursor():Void
    {
        #if (mobile || html5)
        if (FlxG.mouse != null)
            FlxG.mouse.visible = false;
        #end
    }

    function onFrame(event:Event):Void
    {
        #if mobile
        hideMouseCursor();
        #end
        var now = Timer.stamp();
        var elapsed = now - lastFrameTime;
        lastFrameTime = now;
        if (elapsed < 0 || elapsed > 5) return;
        #if sys
        if (saveEnabled) Save.update(elapsed);
        #end
    }

    function onDeactivated(event:Event):Void
    {
        #if mobile
        hideMouseCursor();
        #end
        flushProgress();
        flushFlixelSave();
    }

    public static function flushProgress():Bool
    {
        #if sys
        if (!saveEnabled || !Save.dirty) return true;
        return Save.save();
        #else
        return true;
        #end
    }

    public static function shutdownSystems():Void
    {
        if (shuttingDown) return;
        shuttingDown = true;
        flushProgress();
        flushFlixelSave();
        #if html5
        disposeBrowser();
        #end
        if (instance != null)
        {
            instance.removeEventListener(Event.ENTER_FRAME, instance.onFrame);
            if (Lib.current.stage != null)
                Lib.current.stage.removeEventListener(Event.DEACTIVATE, instance.onDeactivated);
        }
        if (FlxG.signals != null)
            FlxG.signals.gameResized.remove(onGameResized);
        #if (DISCORD_ALLOWED && !html5)
        DiscordClient.shutdown();
        #end
        #if (windows && cpp)
        WinAPI.shutdown();
        #end
        initialized = false;
    }

    static function flushFlixelSave():Void
    {
        try
        {
            if (FlxG.save != null)
                FlxG.save.flush();
        }
        catch (error:Dynamic) {}
    }

    #if html5
    static function setupBrowser():Void
    {
        HtmlSupport.initialize();
        HtmlSupport.setPageTitle(GAME_TITLE);
        HtmlSupport.onFocusChanged = function(focused:Bool):Void
        {
            if (!focused)
            {
                flushProgress();
                flushFlixelSave();
            }
        };
        HtmlSupport.onVisibilityChanged = function(visible:Bool):Void
        {
            if (!visible)
            {
                flushProgress();
                flushFlixelSave();
            }
        };
        browserPageHide = function(_:BrowserEvent):Void
        {
            flushProgress();
            flushFlixelSave();
        };
        browserBeforeUnload = function(_:BrowserEvent):Void
        {
            flushProgress();
            flushFlixelSave();
        };
        Browser.window.addEventListener('pagehide', browserPageHide);
        Browser.window.addEventListener('beforeunload', browserBeforeUnload);
    }

    static function disposeBrowser():Void
    {
        if (browserPageHide != null)
            Browser.window.removeEventListener('pagehide', browserPageHide);
        if (browserBeforeUnload != null)
            Browser.window.removeEventListener('beforeunload', browserBeforeUnload);
        browserPageHide = null;
        browserBeforeUnload = null;
        HtmlSupport.onFocusChanged = null;
        HtmlSupport.onVisibilityChanged = null;
        HtmlSupport.dispose();
    }
    #end

    static function setupFPS():Void
    {
        if (fpsVar != null) return;
        fpsVar = new FPSCounter(10, #if mobile 10 #else 3 #end, 0xFFFFFF);
        fpsVar.visible = ClientPrefs.data.showFPS;
        Lib.current.addChild(fpsVar);
    }

    public static function refreshFPSVisibility():Void
    {
        if (fpsVar != null) fpsVar.visible = ClientPrefs.data.showFPS;
    }

    public static function setFPSVisible(value:Bool):Void
    {
        if (fpsVar != null) fpsVar.visible = value;
    }

    public static function getUptime():Float
    {
        return Timer.stamp() - startupTime;
    }

    static function setupStorage():Bool
    {
        #if android
        if (!Sonic3Storage.hasPermission())
        {
            useAppStorage();
            return true;
        }
        if (Sonic3Storage.ensureFolders(true))
            Sonic3Storage.syncBundledMods();
        else
            useAppStorage();
        #elseif ios
        useAppStorage();
        #end
        return false;
    }

    #if mobile
    static function useAppStorage():Void
    {
        Sys.setCwd(Path.addTrailingSlash(System.applicationStorageDirectory));
    }
    #end

    #if (HSCRIPT_ALLOWED && !html5)
    static function setupScriptLogging():Void
    {
        Iris.warn = function(x, ?pos:haxe.PosInfos)
        {
            Iris.logLevel(WARN, x, pos);
            showScriptMessage('WARNING', x, pos, FlxColor.YELLOW);
        };
        Iris.error = function(x, ?pos:haxe.PosInfos)
        {
            Iris.logLevel(ERROR, x, pos);
            showScriptMessage('ERROR', x, pos, FlxColor.RED);
        };
        Iris.fatal = function(x, ?pos:haxe.PosInfos)
        {
            Iris.logLevel(FATAL, x, pos);
            showScriptMessage('FATAL', x, pos, 0xFFBB0000);
        };
    }

    static function showScriptMessage(prefix:String, message:Dynamic, pos:haxe.PosInfos, color:FlxColor):Void
    {
        if (PlayState.instance == null || pos == null) return;
        var info:HScriptInfos = cast pos;
        var showLine:Bool = info.showLine != false;
        var location:String = (info.funcName != null ? '(${info.funcName}) - ' : '') + '${info.fileName}:';
        #if (LUA_ALLOWED && cpp)
        if (info.isLua == true)
        {
            location += 'HScript:';
            showLine = false;
        }
        #end
        if (showLine) location += '${info.lineNumber}:';
        PlayState.instance.addTextToDebug('$prefix: $location $message', color);
    }
    #end

    static function onGameResized(width:Int, height:Int):Void
    {
        #if mobile
        hideMouseCursor();
        #end
        if (FlxG.cameras != null)
            for (cam in FlxG.cameras.list)
                if (cam != null && cam.filters != null)
                    resetSpriteCache(cam.flashSprite);
        if (FlxG.game != null) resetSpriteCache(FlxG.game);
    }

    static function resetSpriteCache(sprite:Sprite):Void
    {
        if (sprite == null) return;
        @:privateAccess
        {
            sprite.__cacheBitmap = null;
            sprite.__cacheBitmapData = null;
        }
    }

    #if (CRASH_HANDLER && sys)
    static function getCrashFolder():String
    {
        #if android
        return Path.addTrailingSlash(System.applicationStorageDirectory) + 'Crashes/';
        #else
        return './crash/';
        #end
    }

    static function appendToLog(path:String, content:String):Bool
    {
        try
        {
            var folder = Path.directory(path);
            if (folder.length > 0 && !FileSystem.exists(folder)) FileSystem.createDirectory(folder);
            if (FileSystem.exists(path) && FileSystem.stat(path).size > CRASH_LOG_LIMIT)
            {
                var rotated = path + '.old';
                if (FileSystem.exists(rotated)) FileSystem.deleteFile(rotated);
                FileSystem.rename(path, rotated);
            }
            var output = File.append(path, false);
            output.writeString(content);
            output.close();
            return true;
        }
        catch (error:Dynamic) { return false; }
    }

    #if android
    static function writeLaunchLog():Void
    {
        appendToLog(getCrashFolder() + CRASH_LOG_NAME,
            '\n=== START: ' + Date.now().toString() + ' ===\n' +
            'Storage: ' + System.applicationStorageDirectory + '\n');
    }
    #end

    static function buildCrashReport(error:Dynamic):String
    {
        var report = new StringBuf();
        report.add('Game: ' + GAME_TITLE + '\n');
        report.add('Date: ' + Date.now().toString() + '\n');
        report.add('Uptime: ' + getUptime() + 's\n');
        report.add('Error: ' + Std.string(error) + '\n\n');
        for (item in CallStack.exceptionStack(true)) report.add(Std.string(item) + '\n');
        report.add('\nReport: https://github.com/lavathefox/Sonic-the-Hedgehog-3-FNF-Port');
        return report.toString();
    }

    function onCrash(e:UncaughtErrorEvent):Void
    {
        if (handlingCrash) return;
        handlingCrash = true;
        var message = buildCrashReport(e.error);
        #if android
        var path = getCrashFolder() + CRASH_LOG_NAME;
        #else
        var stamp = Date.now().toString().split(' ').join('_').split(':').join('-');
        var path = getCrashFolder() + 'Sonic3FNF_' + stamp + '.txt';
        #end
        appendToLog(path, '\n=== CRASH ===\n' + message + '\n');
        flushProgress();
        #if !android
        if (Application.current != null && Application.current.window != null)
            Application.current.window.alert(message, 'Error!');
        #end
        Sys.exit(1);
    }
    #end
}
