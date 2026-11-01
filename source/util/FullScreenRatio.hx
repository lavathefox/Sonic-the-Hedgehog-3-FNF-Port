package util;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.system.scaleModes.RatioScaleMode;
import flixel.math.FlxPoint;
import lime.app.Application;
import lime.ui.Window;
#if FLX_TOUCH
import flixel.input.touch.FlxTouch;
#end

class FullScreenRatio
{
    public static var designWidth(default, null):Int = 959;
    public static var designHeight(default, null):Int = 670;
    public static var ratio(default, null):Float = 959 / 670;
    public static var enabled(default, null):Bool = false;
    public static var touchEnabled:Bool = true;

    static var window:Window;

    public static function initialize(?width:Int = 959, ?height:Int = 670):Bool
    {
        if (width <= 0 || height <= 0 || FlxG.game == null) return false;
        designWidth = width;
        designHeight = height;
        ratio = width / height;
        enabled = true;
        window = Application.current != null ? Application.current.window : null;
        apply();
        return true;
    }

    public static function setRatio(width:Int, height:Int):Bool
    {
        if (width <= 0 || height <= 0) return false;
        ratio = width / height;
        apply();
        return true;
    }

    public static function useOriginal():Void setRatio(designWidth, designHeight);
    public static function useWidescreen():Void setRatio(16, 9);
    public static function useClassic():Void setRatio(4, 3);

    public static function setFullscreen(value:Bool):Void
    {
        #if !mobile
        if (window == null && Application.current != null) window = Application.current.window;
        if (window != null) window.fullscreen = value;
        #end
    }

    public static function toggleFullscreen():Void
    {
        #if !mobile
        if (window == null && Application.current != null) window = Application.current.window;
        if (window != null) window.fullscreen = !window.fullscreen;
        #end
    }

    public static function apply():Void
    {
        if (!enabled || FlxG.game == null) return;
        if (!Std.isOfType(FlxG.scaleMode, RatioScaleMode))
            FlxG.scaleMode = new RatioScaleMode();
        FlxG.resizeGame(FlxG.width, FlxG.height);
    }

    public static function getTouchPosition(touch:Dynamic, ?camera:FlxCamera):FlxPoint
    {
        #if FLX_TOUCH
        if (!touchEnabled || touch == null) return null;
        var target = camera != null ? camera : FlxG.camera;
        if (target == null) return null;
        return touch.getScreenPosition(target);
        #else
        return null;
        #end
    }

    public static function touchOverlaps(touch:Dynamic, target:FlxSprite, ?camera:FlxCamera):Bool
    {
        #if FLX_TOUCH
        if (!touchEnabled || touch == null || target == null || !target.exists || !target.visible)
            return false;
        var targetCamera = camera;
        if (targetCamera == null && target.cameras != null && target.cameras.length > 0)
            targetCamera = target.cameras[0];
        if (targetCamera == null) targetCamera = FlxG.camera;
        return touch.overlaps(target, targetCamera);
        #else
        return false;
        #end
    }

    public static function anyTouchJustPressed(target:FlxSprite, ?camera:FlxCamera):Bool
    {
        #if FLX_TOUCH
        if (!touchEnabled || target == null) return false;
        for (touch in FlxG.touches.list)
            if (touch != null && touch.justPressed && touchOverlaps(touch, target, camera))
                return true;
        #end
        return false;
    }

    public static function anyTouchPressed(target:FlxSprite, ?camera:FlxCamera):Bool
    {
        #if FLX_TOUCH
        if (!touchEnabled || target == null) return false;
        for (touch in FlxG.touches.list)
            if (touch != null && touch.pressed && touchOverlaps(touch, target, camera))
                return true;
        #end
        return false;
    }

    public static function dispose():Void
    {
        enabled = false;
        window = null;
    }
}
