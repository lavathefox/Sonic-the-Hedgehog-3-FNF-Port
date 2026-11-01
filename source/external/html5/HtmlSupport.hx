package external.html5;

import haxe.Timer;
import StringTools;

#if html5
import js.Browser;
import js.html.Event;
import js.html.VisibilityState;
#end

class HtmlSupport
{
    public static var initialized(default, null):Bool = false;
    public static var focused(default, null):Bool = true;
    public static var visible(default, null):Bool = true;
    public static var lastError(default, null):String = "";
    public static var onFocusChanged:Bool->Void;
    public static var onVisibilityChanged:Bool->Void;

    static var startTime:Float = 0;
    static var focusListener:Dynamic;
    static var blurListener:Dynamic;
    static var visibilityListener:Dynamic;

    public static function initialize():Bool
    {
        if (initialized) return true;
        lastError = "";
        startTime = Timer.stamp();
        #if html5
        try
        {
            focused = Browser.document.hasFocus();
            visible = !Browser.document.hidden;
            focusListener = function(_:Event):Void { updateFocus(true); };
            blurListener = function(_:Event):Void { updateFocus(false); };
            visibilityListener = function(_:Event):Void { updateVisibility(!Browser.document.hidden); };
            Browser.window.addEventListener("focus", focusListener);
            Browser.window.addEventListener("blur", blurListener);
            Browser.document.addEventListener("visibilitychange", visibilityListener);
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
            return false;
        }
        #end
        initialized = true;
        return true;
    }

    public static function dispose():Void
    {
        #if html5
        if (initialized)
        {
            Browser.window.removeEventListener("focus", focusListener);
            Browser.window.removeEventListener("blur", blurListener);
            Browser.document.removeEventListener("visibilitychange", visibilityListener);
        }
        #end
        focusListener = null;
        blurListener = null;
        visibilityListener = null;
        initialized = false;
    }

    static function updateFocus(value:Bool):Void
    {
        if (focused == value) return;
        focused = value;
        if (onFocusChanged != null) onFocusChanged(value);
    }

    static function updateVisibility(value:Bool):Void
    {
        if (visible == value) return;
        visible = value;
        if (onVisibilityChanged != null) onVisibilityChanged(value);
    }

    public static function isHtml5():Bool
    {
        #if html5
        return true;
        #else
        return false;
        #end
    }

    public static function getUptime():Float
    {
        return initialized ? Timer.stamp() - startTime : 0;
    }

    public static function getPixelRatio():Float
    {
        #if html5
        return Browser.window.devicePixelRatio;
        #else
        return 1;
        #end
    }

    public static function getViewportWidth():Int
    {
        #if html5
        return Browser.window.innerWidth;
        #else
        return 0;
        #end
    }

    public static function getViewportHeight():Int
    {
        #if html5
        return Browser.window.innerHeight;
        #else
        return 0;
        #end
    }

    public static function getLanguage():String
    {
        #if html5
        return Browser.navigator.language;
        #else
        return "";
        #end
    }

    public static function getUserAgent():String
    {
        #if html5
        return Browser.navigator.userAgent;
        #else
        return "";
        #end
    }

    public static function isOnline():Bool
    {
        #if html5
        return Browser.navigator.onLine;
        #else
        return true;
        #end
    }

    public static function getCurrentURL():String
    {
        #if html5
        return Browser.window.location.href;
        #else
        return "";
        #end
    }

    public static function openURL(url:String, newTab:Bool = true):Bool
    {
        if (url == null) return false;
        var cleaned = StringTools.trim(url);
        if (!(StringTools.startsWith(cleaned, "https://") || StringTools.startsWith(cleaned, "http://")))
        {
            lastError = "Only HTTP and HTTPS URLs are allowed";
            return false;
        }
        #if html5
        try
        {
            if (newTab)
                Browser.window.open(cleaned, "_blank");
            else
                Browser.window.location.href = cleaned;
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
            return false;
        }
        #else
        lastError = "Browser functions are only available on HTML5";
        return false;
        #end
    }

    public static function setPageTitle(title:String):Void
    {
        #if html5
        Browser.document.title = title == null ? "" : title;
        #end
    }

    public static function getPageTitle():String
    {
        #if html5
        return Browser.document.title;
        #else
        return "";
        #end
    }

    public static function requestFullscreen():Bool
    {
        #if html5
        try
        {
            var element:Dynamic = Browser.document.documentElement;
            if (element.requestFullscreen == null) return false;
            element.requestFullscreen();
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
            return false;
        }
        #else
        return false;
        #end
    }

    public static function exitFullscreen():Bool
    {
        #if html5
        try
        {
            var doc:Dynamic = Browser.document;
            if (doc.exitFullscreen == null) return false;
            doc.exitFullscreen();
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
            return false;
        }
        #else
        return false;
        #end
    }

    public static function isFullscreen():Bool
    {
        #if html5
        var doc:Dynamic = Browser.document;
        return doc.fullscreenElement != null;
        #else
        return false;
        #end
    }

    public static function readLocal(key:String, ?fallback:String = ""):String
    {
        #if html5
        try
        {
            var value = Browser.window.localStorage.getItem(key);
            return value == null ? fallback : value;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
        #end
        return fallback;
    }

    public static function writeLocal(key:String, value:String):Bool
    {
        #if html5
        try
        {
            Browser.window.localStorage.setItem(key, value);
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
        #end
        return false;
    }

    public static function removeLocal(key:String):Bool
    {
        #if html5
        try
        {
            Browser.window.localStorage.removeItem(key);
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
        #end
        return false;
    }

    public static function clearLocal():Bool
    {
        #if html5
        try
        {
            Browser.window.localStorage.clear();
            return true;
        }
        catch (e:Dynamic)
        {
            lastError = Std.string(e);
        }
        #end
        return false;
    }
}
