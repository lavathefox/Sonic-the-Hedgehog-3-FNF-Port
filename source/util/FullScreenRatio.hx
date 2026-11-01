package util;

import flixel.FlxG;
import lime.app.Application;
import lime.ui.Window;

class FullScreenRatio
{
    public static var designWidth(default, null):Int = 959;
    public static var designHeight(default, null):Int = 670;
    public static var ratio(default, null):Float = 959 / 670;
    public static var enabled(default, null):Bool = false;

    private static var window:Window;
    private static var initialized:Bool = false;
    private static var applying:Bool = false;

    public static function initialize(?width:Int = 959, ?height:Int = 670):Bool
    {
        if (width <= 0 || height <= 0)
            return false;

        window = Application.current != null ? Application.current.window : null;
        if (window == null)
            return false;

        designWidth = width;
        designHeight = height;
        ratio = width / height;

        if (!initialized)
        {
            window.onResize.add(onResize);
            initialized = true;
        }

        enabled = true;
        apply();
        return true;
    }

    public static function setRatio(width:Int, height:Int):Bool
    {
        if (width <= 0 || height <= 0)
            return false;

        designWidth = width;
        designHeight = height;
        ratio = width / height;
        apply();
        return true;
    }

    public static function useOriginal():Void
    {
        setRatio(959, 670);
    }

    public static function useWidescreen():Void
    {
        setRatio(16, 9);
    }

    public static function useClassic():Void
    {
        setRatio(4, 3);
    }

    public static function setFullscreen(value:Bool):Void
    {
        if (window == null)
            window = Application.current != null ? Application.current.window : null;

        if (window != null)
            window.fullscreen = value;
    }

    public static function toggleFullscreen():Void
    {
        if (window == null)
            window = Application.current != null ? Application.current.window : null;

        if (window != null)
            window.fullscreen = !window.fullscreen;
    }

    public static function apply():Void
    {
        if (!enabled || applying || window == null || FlxG.game == null)
            return;

        var width:Int = window.width;
        var height:Int = window.height;

        if (width <= 0 || height <= 0)
            return;

        applying = true;

        var targetWidth:Int = width;
        var targetHeight:Int = Std.int(Math.round(width / ratio));

        if (targetHeight > height)
        {
            targetHeight = height;
            targetWidth = Std.int(Math.round(height * ratio));
        }

        if (targetWidth < 1)
            targetWidth = 1;
        if (targetHeight < 1)
            targetHeight = 1;

        FlxG.game.scaleX = targetWidth / FlxG.width;
        FlxG.game.scaleY = targetHeight / FlxG.height;
        FlxG.game.x = (width - targetWidth) * 0.5;
        FlxG.game.y = (height - targetHeight) * 0.5;

        applying = false;
    }

    private static function onResize(width:Int, height:Int):Void
    {
        apply();
    }

    public static function dispose():Void
    {
        if (initialized && window != null)
            window.onResize.remove(onResize);

        initialized = false;
        enabled = false;
        window = null;
    }
}
