package util;

import haxe.Timer;
import haxe.io.Path;
import lime.app.Application;
import lime.system.System;
import openfl.Lib;
import openfl.system.Capabilities;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if (windows && cpp)
import external.windows.WinAPI;
#end

class SystemUtil
{
    public static var lastError(default, null):String = "";
    public static var startedAt(default, null):Float = Timer.stamp();

    public static function getPlatform():String
    {
        #if android
        return "Android";
        #elseif ios
        return "iOS";
        #elseif windows
        return "Windows";
        #elseif mac
        return "macOS";
        #elseif linux
        return "Linux";
        #elseif html5
        return "HTML5";
        #else
        return "Unknown";
        #end
    }

    public static function isMobile():Bool
    {
        #if mobile
        return true;
        #else
        return false;
        #end
    }

    public static function isDesktop():Bool
    {
        #if (windows || linux || mac)
        return true;
        #else
        return false;
        #end
    }

    public static function isWeb():Bool
    {
        #if html5
        return true;
        #else
        return false;
        #end
    }

    public static function getOSVersion():String
    {
        #if (windows && cpp)
        return WinAPI.getWindowsVersion();
        #elseif sys
        return Sys.systemName();
        #else
        return getPlatform();
        #end
    }

    public static function getArchitecture():String
    {
        #if arm64
        return "ARM64";
        #elseif arm
        return "ARM";
        #elseif x86_64
        return "x64";
        #elseif (x86 || i386)
        return "x86";
        #else
        return "Unknown";
        #end
    }

    public static function getLanguage():String
    {
        try
        {
            var value:String = Capabilities.language;
            return value == null || value.length == 0 ? "unknown" : value;
        }
        catch (error:Dynamic)
        {
            return "unknown";
        }
    }

    public static function getScreenWidth():Int
    {
        try
        {
            return Std.int(Capabilities.screenResolutionX);
        }
        catch (error:Dynamic)
        {
            return 0;
        }
    }

    public static function getScreenHeight():Int
    {
        try
        {
            return Std.int(Capabilities.screenResolutionY);
        }
        catch (error:Dynamic)
        {
            return 0;
        }
    }

    public static function getWindowWidth():Int
    {
        var window = Application.current != null ? Application.current.window : null;
        return window == null ? 0 : window.width;
    }

    public static function getWindowHeight():Int
    {
        var window = Application.current != null ? Application.current.window : null;
        return window == null ? 0 : window.height;
    }

    public static function getUptime():Float
    {
        return Math.max(0, Timer.stamp() - startedAt);
    }

    public static function getMemoryUsageBytes():Float
    {
        #if (windows && cpp)
        return WinAPI.getMemoryUsage();
        #elseif cpp
        return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
        #else
        return 0;
        #end
    }

    public static function getMemoryUsageMB():Float
    {
        return getMemoryUsageBytes() / (1024 * 1024);
    }

    public static function getProcessID():Int
    {
        #if (windows && cpp)
        return WinAPI.getProcessID();
        #elseif sys
        return Sys.getPid();
        #else
        return -1;
        #end
    }

    public static function getStorageDirectory():String
    {
        try
        {
            return System.applicationStorageDirectory;
        }
        catch (error:Dynamic)
        {
            return "";
        }
    }

    public static function getWorkingDirectory():String
    {
        #if sys
        return Sys.getCwd();
        #else
        return "";
        #end
    }

    public static function getEnvironment(name:String, fallback:String = ""):String
    {
        #if sys
        if (name == null || name.length == 0) return fallback;
        var value = Sys.getEnv(name);
        return value == null ? fallback : value;
        #else
        return fallback;
        #end
    }

    public static function directoryExists(path:String):Bool
    {
        #if sys
        try
        {
            return path != null && FileSystem.exists(path) && FileSystem.isDirectory(path);
        }
        catch (error:Dynamic) {}
        #end
        return false;
    }

    public static function fileExists(path:String):Bool
    {
        #if sys
        try
        {
            return path != null && FileSystem.exists(path) && !FileSystem.isDirectory(path);
        }
        catch (error:Dynamic) {}
        #end
        return false;
    }

    public static function ensureDirectory(path:String):Bool
    {
        #if sys
        try
        {
            if (path == null || path.length == 0) return fail("Invalid directory");
            if (FileSystem.exists(path)) return FileSystem.isDirectory(path);
            var parent = Path.directory(path);
            if (parent.length > 0 && parent != path && !FileSystem.exists(parent))
            {
                if (!ensureDirectory(parent)) return false;
            }
            FileSystem.createDirectory(path);
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #else
        return fail("Filesystem is not supported on this target");
        #end
    }

    public static function readText(path:String, fallback:String = ""):String
    {
        #if sys
        try
        {
            if (!fileExists(path)) return fallback;
            var result = File.getContent(path);
            lastError = "";
            return result;
        }
        catch (error:Dynamic)
        {
            lastError = Std.string(error);
        }
        #end
        return fallback;
    }

    public static function writeText(path:String, content:String, createDirectories:Bool = true):Bool
    {
        #if sys
        try
        {
            if (path == null || path.length == 0) return fail("Invalid file path");
            var parent = Path.directory(path);
            if (createDirectories && parent.length > 0 && !ensureDirectory(parent)) return false;
            File.saveContent(path, content == null ? "" : content);
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #else
        return fail("Filesystem is not supported on this target");
        #end
    }

    public static function appendText(path:String, content:String, createDirectories:Bool = true):Bool
    {
        #if sys
        try
        {
            if (path == null || path.length == 0) return fail("Invalid file path");
            var parent = Path.directory(path);
            if (createDirectories && parent.length > 0 && !ensureDirectory(parent)) return false;
            var output = File.append(path, false);
            output.writeString(content == null ? "" : content);
            output.close();
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #else
        return fail("Filesystem is not supported on this target");
        #end
    }

    public static function safeFilename(value:String, replacement:String = "_"):String
    {
        if (value == null || value.length == 0) return "unnamed";
        var result = ~/[\x00-\x1F<>:"\/\\|?*]/g.replace(value, replacement);
        result = StringTools.trim(result);
        while (StringTools.endsWith(result, ".") || StringTools.endsWith(result, " "))
            result = result.substr(0, result.length - 1);
        if (result.length == 0) return "unnamed";
        switch (result.toUpperCase())
        {
            case "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9":
                return "_" + result;
            default:
                return result;
        }
    }

    public static function setWindowTitle(title:String):Bool
    {
        #if (windows && cpp)
        return WinAPI.setWindowTitle(title);
        #else
        try
        {
            var window = Application.current != null ? Application.current.window : null;
            if (window == null || title == null) return false;
            window.title = title;
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #end
    }

    public static function showMessage(title:String, message:String, error:Bool = false):Bool
    {
        #if (windows && cpp)
        WinAPI.showMessage(title, message, error);
        return true;
        #else
        try
        {
            var window = Application.current != null ? Application.current.window : null;
            if (window == null) return false;
            window.alert(message, title);
            return true;
        }
        catch (exception:Dynamic)
        {
            return fail(Std.string(exception));
        }
        #end
    }

    public static function getSummary():String
    {
        return "Platform: " + getPlatform()
            + "\nOS: " + getOSVersion()
            + "\nArchitecture: " + getArchitecture()
            + "\nLanguage: " + getLanguage()
            + "\nScreen: " + getScreenWidth() + "x" + getScreenHeight()
            + "\nWindow: " + getWindowWidth() + "x" + getWindowHeight()
            + "\nPID: " + getProcessID()
            + "\nMemory: " + Math.round(getMemoryUsageMB() * 100) / 100 + " MB"
            + "\nUptime: " + Math.round(getUptime()) + "s";
    }

    private static function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }
}
