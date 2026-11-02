package util;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.scaleModes.RatioScaleMode;
import lime.app.Application;
import lime.ui.Window;

class FullScreenRatio
{
    public static var designWidth(default, null):Int = 959;
    public static var designHeight(default, null):Int = 670;
    public static var ratio(default, null):Float = 959 / 670;
    public static var enabled(default, null):Bool = false;
    public static var touchEnabled:Bool = true;
    public static var allowFullscreen:Bool = true;

    public static var viewportX(default, null):Float = 0;
    public static var viewportY(default, null):Float = 0;
    public static var viewportWidth(default, null):Float = 959;
    public static var viewportHeight(default, null):Float = 670;
    public static var scaleFactor(default, null):Float = 1;
    public static var screenWidth(default, null):Int = 959;
    public static var screenHeight(default, null):Int = 670;

    public static var onViewportChanged:Void->Void;

    static var window:Window;
    static var listening:Bool = false;
    static var applying:Bool = false;

    public static function initialize(?width:Int = 959, ?height:Int = 670):Bool
    {
        if (width <= 0 || height <= 0) return false;
        designWidth = width;
        designHeight = height;
        ratio = width / height;
        enabled = true;
        bindWindow();
        apply();
        return true;
    }

    static function bindWindow():Void
    {
        var current:Window = Application.current != null ? Application.current.window : null;
        if (current == window && listening) return;
        if (window != null && listening) window.onResize.remove(onResize);
        window = current;
        listening = false;
        if (window != null)
        {
            window.onResize.add(onResize);
            listening = true;
        }
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
    public static function useUltrawide():Void setRatio(21, 9);
    public static function useSquare():Void setRatio(1, 1);

    public static function setFullscreen(value:Bool):Void
    {
        if (!allowFullscreen) return;
        if (window == null) bindWindow();
        if (window != null) window.fullscreen = value;
    }

    public static function toggleFullscreen():Void
    {
        if (!allowFullscreen) return;
        if (window == null) bindWindow();
        if (window != null) window.fullscreen = !window.fullscreen;
    }

    public static function isFullscreen():Bool
    {
        if (window == null) bindWindow();
        return window != null && window.fullscreen;
    }

    public static function apply():Void
    {
        if (!enabled || applying) return;
        applying = true;
        try
        {
            if (window == null) bindWindow();
            var width:Int = window != null ? window.width : designWidth;
            var height:Int = window != null ? window.height : designHeight;
            if (width <= 0 || height <= 0)
            {
                applying = false;
                return;
            }

            screenWidth = width;
            screenHeight = height;
            var targetRatio:Float = ratio;
            if (targetRatio <= 0 || Math.isNaN(targetRatio)) targetRatio = designWidth / designHeight;

            viewportWidth = width;
            viewportHeight = width / targetRatio;
            if (viewportHeight > height)
            {
                viewportHeight = height;
                viewportWidth = height * targetRatio;
            }
            viewportX = (width - viewportWidth) * 0.5;
            viewportY = (height - viewportHeight) * 0.5;
            scaleFactor = viewportWidth / designWidth;

            if (FlxG.game != null)
            {
                if (!Std.isOfType(FlxG.scaleMode, RatioScaleMode))
                    FlxG.scaleMode = new RatioScaleMode();
                FlxG.resizeGame(FlxG.width, FlxG.height);
            }
            if (onViewportChanged != null) onViewportChanged();
        }
        catch (error:Dynamic)
        {
            FlxG.log.warn('FullScreenRatio apply failed: ' + Std.string(error));
        }
        applying = false;
    }

    static function onResize(width:Int, height:Int):Void apply();

    public static function isInsideViewport(screenX:Float, screenY:Float):Bool
    {
        return screenX >= viewportX && screenX <= viewportX + viewportWidth
            && screenY >= viewportY && screenY <= viewportY + viewportHeight;
    }

    public static function screenToDesign(screenX:Float, screenY:Float, ?result:FlxPoint):FlxPoint
    {
        if (result == null) result = FlxPoint.get();
        var sx:Float = viewportWidth > 0 ? designWidth / viewportWidth : 1;
        var sy:Float = viewportHeight > 0 ? designHeight / viewportHeight : 1;
        result.set((screenX - viewportX) * sx, (screenY - viewportY) * sy);
        return result;
    }

    public static function designToScreen(designX:Float, designY:Float, ?result:FlxPoint):FlxPoint
    {
        if (result == null) result = FlxPoint.get();
        result.set(viewportX + designX * viewportWidth / designWidth,
            viewportY + designY * viewportHeight / designHeight);
        return result;
    }

    public static function getTouchPosition(touch:Dynamic, ?camera:FlxCamera):FlxPoint
    {
        #if FLX_TOUCH
        if (!touchEnabled || touch == null) return null;
        var target:FlxCamera = camera != null ? camera : FlxG.camera;
        if (target == null) return null;
        return touch.getScreenPosition(target);
        #else
        return null;
        #end
    }

    public static function touchOverlaps(touch:Dynamic, target:FlxSprite, ?camera:FlxCamera):Bool
    {
        #if FLX_TOUCH
        if (!touchEnabled || touch == null || target == null || !target.exists || !target.visible) return false;
        var cam:FlxCamera = camera;
        if (cam == null && target.cameras != null && target.cameras.length > 0)
            cam = target.cameras[0];
        if (cam == null) cam = FlxG.camera;
        return touch.overlaps(target, cam);
        #else
        return false;
        #end
    }

    public static function dispose():Void
    {
        if (window != null && listening) window.onResize.remove(onResize);
        window = null;
        listening = false;
        enabled = false;
        onViewportChanged = null;
    }
}
