package external.android;

import lime.app.Application;
import openfl.Lib;

#if android
import lime.system.JNI;
#end

class APIDroid
{
    public static var isAndroid(get, never):Bool;

    static function get_isAndroid():Bool
    {
        #if android
        return true;
        #else
        return false;
        #end
    }

    public static function getPackageName():String
    {
        #if android
        try
        {
            var fn = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getPackageName", "()Ljava/lang/String;");
            var result:Dynamic = fn();
            if (result != null) return Std.string(result);
        }
        catch (e:Dynamic) {}
        #end
        return "me.funkin.sonic3";
    }

    public static function getPlatform():String
    {
        #if android
        return "Android";
        #elseif windows
        return "Windows";
        #elseif linux
        return "Linux";
        #elseif mac
        return "macOS";
        #elseif html5
        return "Web";
        #else
        return "Unknown";
        #end
    }

    public static function getApplicationTitle():String
    {
        var app = Application.current;
        if (app != null && app.window != null) return app.window.title;
        return "Sonic 3 FNF Port";
    }

    public static function getScreenWidth():Int
    {
        var window = Application.current != null ? Application.current.window : null;
        return window != null ? window.width : 0;
    }

    public static function getScreenHeight():Int
    {
        var window = Application.current != null ? Application.current.window : null;
        return window != null ? window.height : 0;
    }

    public static function isLandscape():Bool
    {
        return getScreenWidth() >= getScreenHeight();
    }

    public static function getDisplayDensity():Float
    {
        #if android
        try
        {
            var fn = JNI.createStaticMethod("org/haxe/lime/GameActivity", "getDisplayDensity", "()F");
            var density:Dynamic = fn();
            if (density != null) return density;
        }
        catch (e:Dynamic) {}
        #end
        return 1;
    }

    public static function vibrate(milliseconds:Int = 50):Bool
    {
        #if android
        if (milliseconds <= 0) return false;
        try
        {
            var fn = JNI.createStaticMethod("org/haxe/lime/GameActivity", "vibrate", "(I)V");
            fn(milliseconds);
            return true;
        }
        catch (e:Dynamic) {}
        #end
        return false;
    }

    public static function openURL(url:String):Bool
    {
        if (url == null || url.length == 0) return false;
        if (!StringTools.startsWith(url, "https://") && !StringTools.startsWith(url, "http://")) return false;
        try
        {
            Lib.getURL(url, "_blank");
            return true;
        }
        catch (e:Dynamic) {}
        return false;
    }

    public static function getVersionLabel():String
    {
        return "0.2.8";
    }

    public static function getDeviceSummary():String
    {
        return getPlatform() + " | " + getScreenWidth() + "x" + getScreenHeight()
            + " | density " + getDisplayDensity();
    }
}
