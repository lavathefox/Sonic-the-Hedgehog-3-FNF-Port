package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
#if android
import backend.MobileControls;
#end

class Hitbox extends FlxSpriteGroup
{
    public static inline var LANES:Int = 4;
    public static final STYLES:Array<String> = ['Gradient', 'Solid', 'Outline', 'Minimal'];

    public static var style:String = 'Gradient';
    public static var hitboxScale:Float = 0.82;
    public static var heightScale:Float = 1.0;
    public static var marginLeft:Float = 0;
    public static var marginRight:Float = 0;
    public static var offsetX:Float = 0;
    public static var offsetY:Float = 0;
    public static var opacity:Float = 0.95;
    public static var invisible:Bool = false;
    public static var showIdle:Bool = false;
    public static var ignoreTop:Float = 0;
    public static var idleOpacity:Float = 0.14;
    public static var fadeSpeed:Float = 12;
    public static var inputEnabled:Bool = true;
    public static var useNoteColors:Bool = true;

    static var held:Array<Bool> = [for (i in 0...LANES) false];
    static var previous:Array<Bool> = [for (i in 0...LANES) false];
    static var active:Hitbox;

    var lanes:Array<FlxSprite> = [];
    var lastWidth:Int = -1;
    var lastHeight:Int = -1;
    var lastLeft:Float = Math.NaN;
    var lastTop:Float = Math.NaN;
    var lastAreaWidth:Float = -1;
    var lastAreaHeight:Float = -1;
    var lastStyle:String = '';

    public static function pressed(lane:Int):Bool
    {
        return validLane(lane) && held[lane];
    }

    public static function justPressed(lane:Int):Bool
    {
        return validLane(lane) && held[lane] && !previous[lane];
    }

    public static function justReleased(lane:Int):Bool
    {
        return validLane(lane) && !held[lane] && previous[lane];
    }

    public static function resetInput():Void
    {
        for (i in 0...LANES)
        {
            held[i] = false;
            previous[i] = false;
        }
    }

    public static function setCompactness(scale:Float):Void
    {
        hitboxScale = clamp(scale, 0.25, 1.0);
        if (active != null) active.refresh();
    }

    public static function setMargins(left:Float, right:Float):Void
    {
        marginLeft = left;
        marginRight = right;
        if (active != null) active.refresh();
    }

    public static function setOffset(x:Float, y:Float):Void
    {
        offsetX = x;
        offsetY = y;
        if (active != null) active.refresh();
    }

    public static function getLaneAt(screenX:Float, screenY:Float):Int
    {
        var left = areaLeft();
        var top = areaTop();
        var width = areaWidth();
        var height = areaHeight();
        if (screenY < ignoreTop || screenX < left || screenX >= left + width || screenY < top || screenY >= top + height)
            return -1;
        var result = Std.int((screenX - left) * LANES / width);
        return result >= 0 && result < LANES ? result : -1;
    }

    public static function laneWidth():Float return areaWidth() / LANES;
    public static function getAreaLeft():Float return areaLeft();
    public static function getAreaTop():Float return areaTop();
    public static function getAreaWidth():Float return areaWidth();
    public static function getAreaHeight():Float return areaHeight();

    static inline function validLane(lane:Int):Bool return lane >= 0 && lane < LANES;

    static function clamp(value:Float, min:Float, max:Float):Float
    {
        if (Math.isNaN(value)) return min;
        return Math.max(min, Math.min(max, value));
    }

    static function areaWidth():Float
    {
        return Math.max(80, FlxG.width * clamp(hitboxScale, 0.25, 1.5) - marginLeft - marginRight);
    }

    static function areaHeight():Float
    {
        return Math.max(1, FlxG.height * clamp(heightScale, 0.1, 1.0));
    }

    static function areaLeft():Float
    {
        return (FlxG.width - areaWidth()) * 0.5 + (marginLeft - marginRight) * 0.5 + offsetX;
    }

    static function areaTop():Float
    {
        return (FlxG.height - areaHeight()) * 0.5 + offsetY;
    }

    public function new()
    {
        super();
        if (active != null && active != this) resetInput();
        active = this;
        scrollFactor.set(0, 0);
        for (i in 0...LANES)
        {
            var lane = new FlxSprite();
            lane.scrollFactor.set(0, 0);
            lane.antialiasing = false;
            lanes.push(lane);
            add(lane);
        }
        refresh();
    }

    public function refresh():Void
    {
        var left = areaLeft();
        var top = areaTop();
        var width = areaWidth();
        var height = areaHeight();
        var imageHeight = Std.int(Math.max(1, Math.ceil(height)));

        for (i in 0...LANES)
        {
            var x1 = left + width * i / LANES;
            var x2 = left + width * (i + 1) / LANES;
            var imageWidth = Std.int(Math.max(1, Math.ceil(x2 - x1)));
            var lane = lanes[i];
            lane.loadGraphic(createLaneBitmap(style, imageWidth, imageHeight), false, 0, 0, true);
            lane.setPosition(x1, top);
            lane.color = useNoteColors ? laneColor(i) : FlxColor.WHITE;
            lane.alpha = held[i] ? clamp(opacity, 0, 1) : (showIdle ? clamp(idleOpacity, 0, 1) : 0);
        }

        lastWidth = FlxG.width;
        lastHeight = FlxG.height;
        lastLeft = left;
        lastTop = top;
        lastAreaWidth = width;
        lastAreaHeight = height;
        lastStyle = style;
    }

    static function laneColor(index:Int):FlxColor
    {
        if (ClientPrefs.data.arrowRGB != null && ClientPrefs.data.arrowRGB.length > index)
        {
            var colors = ClientPrefs.data.arrowRGB[index];
            if (colors != null && colors.length > 0) return colors[0];
        }
        return FlxColor.WHITE;
    }

    static function createLaneBitmap(selectedStyle:String, width:Int, height:Int):BitmapData
    {
        var bitmap:BitmapData;
        switch (selectedStyle)
        {
            case 'Solid':
                bitmap = new BitmapData(width, height, true, 0x88FFFFFF);
            case 'Outline':
                bitmap = new BitmapData(width, height, true, 0x12FFFFFF);
                var thickness = Std.int(Math.max(1, Math.min(5, Math.min(width, height) / 8)));
                bitmap.fillRect(new Rectangle(0, 0, width, thickness), 0xFFFFFFFF);
                bitmap.fillRect(new Rectangle(0, height - thickness, width, thickness), 0xFFFFFFFF);
                bitmap.fillRect(new Rectangle(0, 0, thickness, height), 0xFFFFFFFF);
                bitmap.fillRect(new Rectangle(width - thickness, 0, thickness, height), 0xFFFFFFFF);
            case 'Minimal':
                bitmap = new BitmapData(width, height, true, 0x28FFFFFF);
                bitmap.fillRect(new Rectangle(0, 0, 2, height), 0xAAFFFFFF);
            default:
                bitmap = FlxGradient.createGradientBitmapData(width, height, [0x00FFFFFF, 0x28FFFFFF, 0xDDFFFFFF], 1, 90);
        }
        return bitmap;
    }

    static function pollTouches():Void
    {
        for (i in 0...LANES)
        {
            previous[i] = held[i];
            held[i] = false;
        }

        if (!inputEnabled) return;
        #if FLX_TOUCH
        for (touch in FlxG.touches.list)
        {
            if (!touch.pressed) continue;
            #if android
            if (MobileControls.isReservedTouch(touch)) continue;
            #end
            var lane = getLaneAt(touch.screenX, touch.screenY);
            if (lane >= 0) held[lane] = true;
        }
        #end
    }

    override public function update(elapsed:Float):Void
    {
        if (active == this) pollTouches();

        if (lastWidth != FlxG.width || lastHeight != FlxG.height || lastLeft != areaLeft()
            || lastTop != areaTop() || lastAreaWidth != areaWidth() || lastAreaHeight != areaHeight() || lastStyle != style)
            refresh();

        super.update(elapsed);
        var idle = showIdle ? clamp(idleOpacity, 0, 1) : 0.0;
        var amount = clamp(elapsed * Math.max(0, fadeSpeed), 0, 1);
        for (i in 0...LANES)
        {
            var lane = lanes[i];
            var target = held[i] ? clamp(opacity, 0, 1) : idle;
            lane.alpha += (target - lane.alpha) * (held[i] ? 1 : amount);
            if (Math.abs(lane.alpha - target) < 0.005) lane.alpha = target;
            lane.visible = !invisible;
        }
    }

    override public function destroy():Void
    {
        if (active == this)
        {
            active = null;
            resetInput();
        }
        lanes = [];
        super.destroy();
    }
}
