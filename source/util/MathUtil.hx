package util;

class MathUtil
{
    public static inline var DEG2RAD:Float = Math.PI / 180;
    public static inline var RAD2DEG:Float = 180 / Math.PI;
    public static inline var EPSILON:Float = 0.000001;

    public static inline function clamp(value:Float, min:Float, max:Float):Float
    {
        return Math.max(Math.min(min, max), Math.min(Math.max(min, max), value));
    }

    public static inline function clamp01(value:Float):Float
    {
        return clamp(value, 0, 1);
    }

    public static inline function lerp(a:Float, b:Float, t:Float):Float
    {
        return a + (b - a) * clamp01(t);
    }

    public static inline function lerpUnclamped(a:Float, b:Float, t:Float):Float
    {
        return a + (b - a) * t;
    }

    public static inline function inverseLerp(a:Float, b:Float, value:Float):Float
    {
        return Math.abs(b - a) <= EPSILON ? 0 : clamp01((value - a) / (b - a));
    }

    public static inline function remap(value:Float, inMin:Float, inMax:Float, outMin:Float, outMax:Float):Float
    {
        return lerp(outMin, outMax, inverseLerp(inMin, inMax, value));
    }

    public static inline function remapUnclamped(value:Float, inMin:Float, inMax:Float, outMin:Float, outMax:Float):Float
    {
        return Math.abs(inMax - inMin) <= EPSILON ? outMin : lerpUnclamped(outMin, outMax, (value - inMin) / (inMax - inMin));
    }

    public static inline function moveTowards(current:Float, target:Float, maxDelta:Float):Float
    {
        var delta = target - current;
        var step = Math.max(0, maxDelta);
        return Math.abs(delta) <= step ? target : current + (delta < 0 ? -step : step);
    }

    public static inline function damp(current:Float, target:Float, smoothing:Float, elapsed:Float):Float
    {
        return lerp(current, target, 1 - Math.exp(-Math.max(0, smoothing) * Math.max(0, elapsed)));
    }

    public static inline function smoothStep(a:Float, b:Float, t:Float):Float
    {
        var x = clamp01(t);
        return lerpUnclamped(a, b, x * x * (3 - 2 * x));
    }

    public static inline function smootherStep(a:Float, b:Float, t:Float):Float
    {
        var x = clamp01(t);
        return lerpUnclamped(a, b, x * x * x * (x * (x * 6 - 15) + 10));
    }

    public static inline function repeat(value:Float, length:Float):Float
    {
        if (length <= 0) return 0;
        return value - Math.floor(value / length) * length;
    }

    public static inline function pingPong(value:Float, length:Float):Float
    {
        if (length <= 0) return 0;
        var x = repeat(value, length * 2);
        return length - Math.abs(x - length);
    }

    public static inline function wrap(value:Float, min:Float, max:Float):Float
    {
        var range = max - min;
        return range <= 0 ? min : min + repeat(value - min, range);
    }

    public static inline function degToRad(degrees:Float):Float
    {
        return degrees * DEG2RAD;
    }

    public static inline function radToDeg(radians:Float):Float
    {
        return radians * RAD2DEG;
    }

    public static inline function deltaAngle(from:Float, to:Float):Float
    {
        var delta = repeat(to - from + 180, 360) - 180;
        return delta == -180 ? 180 : delta;
    }

    public static inline function lerpAngle(from:Float, to:Float, t:Float):Float
    {
        return from + deltaAngle(from, to) * clamp01(t);
    }

    public static inline function moveTowardsAngle(from:Float, to:Float, maxDelta:Float):Float
    {
        return moveTowards(from, from + deltaAngle(from, to), maxDelta);
    }

    public static inline function distance(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        var dx = x2 - x1;
        var dy = y2 - y1;
        return Math.sqrt(dx * dx + dy * dy);
    }

    public static inline function distanceSquared(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        var dx = x2 - x1;
        var dy = y2 - y1;
        return dx * dx + dy * dy;
    }

    public static inline function angleBetween(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        return radToDeg(Math.atan2(y2 - y1, x2 - x1));
    }

    public static inline function approximately(a:Float, b:Float, epsilon:Float = EPSILON):Bool
    {
        return Math.abs(a - b) <= Math.max(0, epsilon);
    }

    public static inline function roundTo(value:Float, decimals:Int = 0):Float
    {
        var places = Std.int(Math.max(-12, Math.min(12, decimals)));
        var factor = Math.pow(10, places);
        return Math.round(value * factor) / factor;
    }

    public static inline function sign(value:Float):Int
    {
        return value > 0 ? 1 : (value < 0 ? -1 : 0);
    }

    public static inline function isEven(value:Int):Bool
    {
        return value % 2 == 0;
    }

    public static inline function isOdd(value:Int):Bool
    {
        return value % 2 != 0;
    }

    public static inline function randomRange(min:Float, max:Float):Float
    {
        return min + Math.random() * (max - min);
    }

    public static function randomInt(min:Int, max:Int):Int
    {
        var low = min < max ? min : max;
        var high = min > max ? min : max;
        return low + Std.int(Math.floor(Math.random() * (high - low + 1)));
    }

    public static inline function percent(value:Float, total:Float):Float
    {
        return Math.abs(total) <= EPSILON ? 0 : value / total * 100;
    }

    public static inline function fromPercent(percentValue:Float, total:Float):Float
    {
        return total * percentValue / 100;
    }
}
