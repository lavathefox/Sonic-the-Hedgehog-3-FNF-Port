package mobile.input;

import openfl.Lib;
import openfl.display.Stage;
import openfl.events.TouchEvent;
import haxe.Timer;

private typedef TouchPoint =
{
    var id:Int;
    var x:Float;
    var y:Float;
    var startX:Float;
    var startY:Float;
    var startTime:Float;
}

class TouchInput
{
    public static var enabled(default, null):Bool = false;
    public static var tapMaxDuration:Float = 0.25;
    public static var longPressDuration:Float = 0.55;
    public static var swipeMinDistance:Float = 48;
    public static var maxTapDistance:Float = 24;

    public static dynamic function onDown(id:Int, x:Float, y:Float):Void {}
    public static dynamic function onMove(id:Int, x:Float, y:Float):Void {}
    public static dynamic function onUp(id:Int, x:Float, y:Float):Void {}
    public static dynamic function onTap(x:Float, y:Float):Void {}
    public static dynamic function onLongPress(x:Float, y:Float):Void {}
    public static dynamic function onSwipe(dx:Float, dy:Float):Void {}

    static var stage:Stage;
    static var points:Map<Int, TouchPoint> = new Map();
    static var longPressed:Map<Int, Bool> = new Map();

    public static function initialize():Void
    {
        if (enabled || Lib.current == null || Lib.current.stage == null)
            return;

        stage = Lib.current.stage;
        stage.addEventListener(TouchEvent.TOUCH_BEGIN, handleDown);
        stage.addEventListener(TouchEvent.TOUCH_MOVE, handleMove);
        stage.addEventListener(TouchEvent.TOUCH_END, handleUp);
        enabled = true;
    }

    public static function dispose():Void
    {
        if (!enabled)
            return;

        stage.removeEventListener(TouchEvent.TOUCH_BEGIN, handleDown);
        stage.removeEventListener(TouchEvent.TOUCH_MOVE, handleMove);
        stage.removeEventListener(TouchEvent.TOUCH_END, handleUp);
        points = new Map();
        longPressed = new Map();
        stage = null;
        enabled = false;
    }

    public static function update():Void
    {
        if (!enabled)
            return;

        var now = Timer.stamp();
        for (point in points)
        {
            if (!longPressed.exists(point.id)
                && now - point.startTime >= longPressDuration
                && distance(point.x - point.startX, point.y - point.startY) <= maxTapDistance)
            {
                longPressed.set(point.id, true);
                onLongPress(point.x, point.y);
            }
        }
    }

    public static function isDown(id:Int):Bool
    {
        return points.exists(id);
    }

    public static function touchCount():Int
    {
        var count = 0;
        for (_ in points) count++;
        return count;
    }

    public static function isAreaPressed(x:Float, y:Float, width:Float, height:Float):Bool
    {
        for (point in points)
            if (point.x >= x && point.y >= y && point.x < x + width && point.y < y + height)
                return true;
        return false;
    }

    public static function getX(id:Int):Float
    {
        var point = points.get(id);
        return point == null ? -1 : point.x;
    }

    public static function getY(id:Int):Float
    {
        var point = points.get(id);
        return point == null ? -1 : point.y;
    }

    static function handleDown(event:TouchEvent):Void
    {
        var id = event.touchPointID;
        var point:TouchPoint = {
            id: id,
            x: event.stageX,
            y: event.stageY,
            startX: event.stageX,
            startY: event.stageY,
            startTime: Timer.stamp()
        };
        points.set(id, point);
        longPressed.remove(id);
        onDown(id, point.x, point.y);
    }

    static function handleMove(event:TouchEvent):Void
    {
        var point = points.get(event.touchPointID);
        if (point == null)
            return;
        point.x = event.stageX;
        point.y = event.stageY;
        onMove(point.id, point.x, point.y);
    }

    static function handleUp(event:TouchEvent):Void
    {
        var id = event.touchPointID;
        var point = points.get(id);
        if (point == null)
            return;

        var dx = event.stageX - point.startX;
        var dy = event.stageY - point.startY;
        var duration = Timer.stamp() - point.startTime;
        var movement = distance(dx, dy);

        points.remove(id);
        var wasLongPress = longPressed.exists(id);
        longPressed.remove(id);
        onUp(id, event.stageX, event.stageY);

        if (movement >= swipeMinDistance)
            onSwipe(dx, dy);
        else if (!wasLongPress && duration <= tapMaxDuration && movement <= maxTapDistance)
            onTap(event.stageX, event.stageY);
    }

    static inline function distance(dx:Float, dy:Float):Float
    {
        return Math.sqrt(dx * dx + dy * dy);
    }
}
