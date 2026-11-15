package util.mobile;

import flixel.FlxG;
import flixel.math.FlxPoint;
import flixel.FlxCamera;
import flixel.input.touch.FlxTouch;

class TouchUtil
{
    public static var enabled:Bool = true;
    public static var deadZone:Float = 12;
    public static var tapMaxDuration:Float = 0.3;
    public static var longPressDuration:Float = 0.55;
    public static var swipeMinDistance:Float = 48;

    static var tracked:Map<Int, TouchRecord> = new Map();
    static var taps:Array<TouchGesture> = [];
    static var swipes:Array<TouchGesture> = [];
    static var longPresses:Array<TouchGesture> = [];
    static var lastTouchCount:Int = 0;

    public static function update(elapsed:Float):Void
    {
        taps = [];
        swipes = [];
        longPresses = [];
        if (!enabled)
        {
            tracked = new Map();
            lastTouchCount = 0;
            return;
        }

        var active:Map<Int, Bool> = new Map();
        var touches = FlxG.touches.list;
        lastTouchCount = touches.length;

        for (touch in touches)
        {
            var id = touch.touchPointID;
            var x = touch.screenX;
            var y = touch.screenY;
            active.set(id, true);
            var record = tracked.get(id);
            if (record == null)
            {
                record = new TouchRecord(id, x, y);
                tracked.set(id, record);
            }
            else
            {
                record.x = x;
                record.y = y;
                record.duration += Math.max(0, elapsed);
            }

            if (!record.longPressSent && record.duration >= longPressDuration && distance(record.startX, record.startY, x, y) <= deadZone)
            {
                record.longPressSent = true;
                longPresses.push(new TouchGesture(id, record.startX, record.startY, x, y, record.duration));
            }
        }

        var finished:Array<Int> = [];
        for (id in tracked.keys())
        {
            if (active.exists(id)) continue;
            var record = tracked.get(id);
            if (record != null)
            {
                var moved = distance(record.startX, record.startY, record.x, record.y);
                var gesture = new TouchGesture(id, record.startX, record.startY, record.x, record.y, record.duration);
                if (moved >= swipeMinDistance) swipes.push(gesture);
                else if (moved <= deadZone && record.duration <= tapMaxDuration) taps.push(gesture);
            }
            finished.push(id);
        }
        for (id in finished) tracked.remove(id);
    }

    public static function reset():Void
    {
        tracked = new Map();
        taps = [];
        swipes = [];
        longPresses = [];
        lastTouchCount = 0;
    }

    public static function isTouching():Bool
    {
        return enabled && FlxG.touches.list.length > 0;
    }

    public static function touchCount():Int
    {
        return enabled ? FlxG.touches.list.length : 0;
    }

    public static function justPressed():Bool
    {
        if (!enabled) return false;
        for (touch in FlxG.touches.list)
            if (touch.justPressed) return true;
        return false;
    }

    public static function justReleased():Bool
    {
        if (!enabled) return false;
        for (touch in FlxG.touches.list)
            if (touch.justReleased) return true;
        return false;
    }

    public static function pressedInRect(x:Float, y:Float, width:Float, height:Float, just:Bool = false):Bool
    {
        if (!enabled || width <= 0 || height <= 0) return false;
        for (touch in FlxG.touches.list)
            if ((!just || touch.justPressed) && touch.pressed && contains(touch.screenX, touch.screenY, x, y, width, height)) return true;
        return false;
    }

    public static function pressedInCircle(x:Float, y:Float, radius:Float, just:Bool = false):Bool
    {
        if (!enabled || radius <= 0) return false;
        for (touch in FlxG.touches.list)
            if ((!just || touch.justPressed) && touch.pressed && distance(touch.screenX, touch.screenY, x, y) <= radius) return true;
        return false;
    }

    public static function getFirstScreenPosition():Null<FlxPoint>
    {
        if (!enabled) return null;
        for (touch in FlxG.touches.list)
            return FlxPoint.get(touch.screenX, touch.screenY);
        return null;
    }

    public static function getFirstWorldPosition(?camera:FlxCamera):Null<FlxPoint>
    {
        if (!enabled) return null;
        for (touch in FlxG.touches.list)
            return touch.getWorldPosition(camera);
        return null;
    }

    public static function getTaps():Array<TouchGesture>
    {
        return taps.copy();
    }

    public static function getSwipes():Array<TouchGesture>
    {
        return swipes.copy();
    }

    public static function getLongPresses():Array<TouchGesture>
    {
        return longPresses.copy();
    }

    public static function isPinching():Bool
    {
        return enabled && FlxG.touches.list.length >= 2;
    }

    public static function pinchDistance():Float
    {
        if (!isPinching()) return 0;
        var a = FlxG.touches.list[0];
        var b = FlxG.touches.list[1];
        return distance(a.screenX, a.screenY, b.screenX, b.screenY);
    }

    public static inline function contains(px:Float, py:Float, x:Float, y:Float, width:Float, height:Float):Bool
    {
        return px >= x && py >= y && px <= x + width && py <= y + height;
    }

    public static inline function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        var dx = x2 - x1;
        var dy = y2 - y1;
        return Math.sqrt(dx * dx + dy * dy);
    }
}

class TouchGesture
{
    public var id(default, null):Int;
    public var startX(default, null):Float;
    public var startY(default, null):Float;
    public var endX(default, null):Float;
    public var endY(default, null):Float;
    public var duration(default, null):Float;
    public var deltaX(get, never):Float;
    public var deltaY(get, never):Float;
    public var length(get, never):Float;

    public function new(id:Int, startX:Float, startY:Float, endX:Float, endY:Float, duration:Float)
    {
        this.id = id;
        this.startX = startX;
        this.startY = startY;
        this.endX = endX;
        this.endY = endY;
        this.duration = duration;
    }

    function get_deltaX():Float return endX - startX;
    function get_deltaY():Float return endY - startY;
    function get_length():Float return TouchUtil.distance(startX, startY, endX, endY);
}

private class TouchRecord
{
    public var id:Int;
    public var startX:Float;
    public var startY:Float;
    public var x:Float;
    public var y:Float;
    public var duration:Float = 0;
    public var longPressSent:Bool = false;

    public function new(id:Int, x:Float, y:Float)
    {
        this.id = id;
        this.startX = x;
        this.startY = y;
        this.x = x;
        this.y = y;
    }
}
