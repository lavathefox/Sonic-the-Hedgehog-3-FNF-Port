package util;

import flixel.FlxG;
import flixel.system.scaleModes.RatioScaleMode;
import lime.app.Application;
import lime.ui.Window;

class FullScreenRatio
{
    public static var designWidth(default, null):Int = 959;
    public static var designHeight(default, null):Int = 670;
    public static var ratio(default, null):Float = 959 / 670;
    public static var enabled(default, null):Bool = false;

    static var window:Window;
    static var initialized:Bool = false;

    public static function initialize(?width:Int = 959, ?height:Int = 670):Bool
    {
        if (width <= 0 || height <= 0 || FlxG.game == null)
            return false;

        designWidth = width;
        designHeight = height;
        ratio = width / height;
        window = Application.current != null ? Application.current.window : null;
        enabled = true;
        initialized = true;
        apply();
        return true;
    }

    public static function setRatio(width:Int, height:Int):Bool
    {
        if (width <= 0 || height <= 0)
            return false;

        ratio = width / height;
        apply();
        return true;
    }

    public static function useOriginal():Void
    {
        setRatio(designWidth, designHeight);
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
        #if !mobile
        if (window == null && Application.current != null)
            window = Application.current.window;
        if (window != null)
            window.fullscreen = value;
        #end
    }

    public static function toggleFullscreen():Void
    {
        #if !mobile
        if (window == null && Application.current != null)
            window = Application.current.window;
        if (window != null)
            window.fullscreen = !window.fullscreen;
        #end
    }

    public static function apply():Void
    {
        if (!enabled || FlxG.game == null)
            return;

        FlxG.game.x = 0;
        FlxG.game.y = 0;
        FlxG.game.scaleX = 1;
        FlxG.game.scaleY = 1;

        if (!Std.isOfType(FlxG.scaleMode, RatioScaleMode))
            FlxG.scaleMode = new RatioScaleMode();

        FlxG.resizeGame(FlxG.width, FlxG.height);
    }

    public static function dispose():Void
    {
        initialized = false;
        enabled = false;
        window = null;
    }
}
