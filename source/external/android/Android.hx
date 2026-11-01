package external.android;

import flixel.FlxG;
import openfl.Lib;

#if sys
import sys.FileSystem;
import haxe.io.Path;
#end

class Android
{
    public static var initialized(default, null):Bool = false;
    public static var keepScreenOn(default, null):Bool = false;
    public static var immersiveMode(default, null):Bool = false;
    public static var batterySaver(default, null):Bool = false;
    public static var vibrationEnabled:Bool = true;

    public static var onBackPressed:Void->Void = null;
    public static var onPause:Void->Void = null;
    public static var onResume:Void->Void = null;

    static var paused:Bool = false;
    static var lastWidth:Int = 0;
    static var lastHeight:Int = 0;

    public static inline function isAndroid():Bool
    {
        #if android
        return true;
        #else
        return false;
        #end
    }

    public static inline function isMobile():Bool
    {
        #if (android || ios)
        return true;
        #else
        return false;
        #end
    }

    public static function initialize():Void
    {
        if (initialized) return;
        initialized = true;
        paused = false;
        refreshDisplay();
        if (Lib.current != null && Lib.current.stage != null)
        {
            Lib.current.stage.addEventListener(openfl.events.Event.DEACTIVATE, handleDeactivate);
            Lib.current.stage.addEventListener(openfl.events.Event.ACTIVATE, handleActivate);
        }
    }

    public static function dispose():Void
    {
        if (!initialized) return;
        if (Lib.current != null && Lib.current.stage != null)
        {
            Lib.current.stage.removeEventListener(openfl.events.Event.DEACTIVATE, handleDeactivate);
            Lib.current.stage.removeEventListener(openfl.events.Event.ACTIVATE, handleActivate);
        }
        initialized = false;
        onBackPressed = null;
        onPause = null;
        onResume = null;
    }

    static function handleDeactivate(event:openfl.events.Event):Void
    {
        if (paused) return;
        paused = true;
        if (onPause != null) onPause();
    }

    static function handleActivate(event:openfl.events.Event):Void
    {
        if (!paused) return;
        paused = false;
        refreshDisplay();
        if (onResume != null) onResume();
    }

    public static function isPaused():Bool return paused;

    public static function refreshDisplay():Void
    {
        if (Lib.current == null || Lib.current.stage == null) return;
        lastWidth = Lib.current.stage.stageWidth;
        lastHeight = Lib.current.stage.stageHeight;
    }

    public static function getScreenWidth():Int
    {
        refreshDisplay();
        return lastWidth;
    }

    public static function getScreenHeight():Int
    {
        refreshDisplay();
        return lastHeight;
    }

    public static function isLandscape():Bool return getScreenWidth() >= getScreenHeight();
    public static function getAspectRatio():Float
    {
        var height = getScreenHeight();
        return height > 0 ? getScreenWidth() / height : 1;
    }

    public static function getGameWidth():Int return FlxG.width;
    public static function getGameHeight():Int return FlxG.height;

    public static function setKeepScreenOn(value:Bool):Void
    {
        keepScreenOn = value;
        // Native wake-lock support requires an Android extension.
    }

    public static function setImmersiveMode(value:Bool):Void
    {
        immersiveMode = value;
        // Navigation/status bar control requires an Android extension.
    }

    public static function setBatterySaver(value:Bool):Void
    {
        batterySaver = value;
        // Game-specific rendering changes should be applied by the caller.
    }

    public static function vibrate(milliseconds:Int = 30):Bool
    {
        if (!isAndroid() || !vibrationEnabled || milliseconds <= 0) return false;
        // No built-in cross-version Android vibration API is assumed.
        return false;
    }

    public static function requestStoragePermission():Bool
    {
        // Delegate to backend.Sonic3Storage where supported.
        return false;
    }

    public static function hasStoragePermission():Bool
    {
        // Permission state is managed by backend.Sonic3Storage.
        return false;
    }

    public static function dispatchBackPressed():Void
    {
        if (onBackPressed != null) onBackPressed();
    }

    public static function getPlatformName():String
    {
        #if android
        return "Android";
        #elseif ios
        return "iOS";
        #elseif windows
        return "Windows";
        #elseif linux
        return "Linux";
        #elseif mac
        return "macOS";
        #else
        return "Unknown";
        #end
    }

    public static function getAppStoragePath():String
    {
        #if sys
        var path = Sys.getEnv("HOME");
        if (path != null && path.length > 0) return path;
        return Sys.getCwd();
        #else
        return "";
        #end
    }

    public static function ensureDirectory(path:String):Bool
    {
        #if sys
        if (path == null || path.length == 0) return false;
        try
        {
            if (FileSystem.exists(path)) return FileSystem.isDirectory(path);
            var parent = Path.directory(path);
            if (parent != null && parent != "" && parent != "." && parent != path)
                if (!ensureDirectory(parent)) return false;
            FileSystem.createDirectory(path);
            return FileSystem.isDirectory(path);
        }
        catch (_:Dynamic) return false;
        #else
        return false;
        #end
    }

    public static function getDeviceInfo():Dynamic
    {
        return {
            platform: getPlatformName(),
            android: isAndroid(),
            mobile: isMobile(),
            width: getScreenWidth(),
            height: getScreenHeight(),
            landscape: isLandscape(),
            aspectRatio: getAspectRatio(),
            paused: paused,
            immersiveRequested: immersiveMode,
            keepAwakeRequested: keepScreenOn,
            batterySaverRequested: batterySaver
        };
    }
}
