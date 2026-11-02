package graphics;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
import openfl.geom.Point;
import haxe.ds.StringMap;

class SonicGraphic
{
    public static var pixelPerfect:Bool = true;
    public static var defaultAntialiasing:Bool = false;

    private static var cache:StringMap<FlxGraphic> = new StringMap<FlxGraphic>();
    private static var serial:Int = 0;

    public static function solid(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, ?key:String):FlxGraphic
    {
        width = positive(width);
        height = positive(height);
        var id:String = key != null ? key : 'sonic:solid:$width:$height:${Std.string(color)}';
        var existing:FlxGraphic = cache.get(id);
        if (existing != null) return existing;

        var bitmap:BitmapData = new BitmapData(width, height, true, color);
        return register(id, bitmap);
    }

    public static function outline(width:Int, height:Int, thickness:Int = 2, color:FlxColor = FlxColor.WHITE, background:FlxColor = FlxColor.TRANSPARENT, ?key:String):FlxGraphic
    {
        width = positive(width);
        height = positive(height);
        thickness = positive(thickness);
        var id:String = key != null ? key : 'sonic:outline:$width:$height:$thickness:${Std.string(color)}:${Std.string(background)}';
        var existing = cache.get(id);
        if (existing != null) return existing;

        var bitmap = new BitmapData(width, height, true, background);
        var t:Int = Std.int(Math.min(thickness, Math.min(width, height)));
        bitmap.fillRect(new Rectangle(0, 0, width, t), color);
        bitmap.fillRect(new Rectangle(0, height - t, width, t), color);
        bitmap.fillRect(new Rectangle(0, 0, t, height), color);
        bitmap.fillRect(new Rectangle(width - t, 0, t, height), color);
        return register(id, bitmap);
    }

    public static function checkerboard(width:Int, height:Int, cellSize:Int = 16, first:FlxColor = 0xFF103080, second:FlxColor = 0xFF2048A0, ?key:String):FlxGraphic
    {
        width = positive(width);
        height = positive(height);
        cellSize = positive(cellSize);
        var id:String = key != null ? key : 'sonic:checker:$width:$height:$cellSize:${Std.string(first)}:${Std.string(second)}';
        var existing = cache.get(id);
        if (existing != null) return existing;

        var bitmap = new BitmapData(width, height, true, first);
        var columns:Int = Std.int(Math.ceil(width / cellSize));
        var rows:Int = Std.int(Math.ceil(height / cellSize));
        for (row in 0...rows)
        {
            for (column in 0...columns)
            {
                if ((row + column) % 2 == 1)
                    bitmap.fillRect(new Rectangle(column * cellSize, row * cellSize, cellSize, cellSize), second);
            }
        }
        return register(id, bitmap);
    }

    public static function verticalGradient(width:Int, height:Int, topColor:FlxColor, bottomColor:FlxColor, ?key:String):FlxGraphic
    {
        width = positive(width);
        height = positive(height);
        var id:String = key != null ? key : 'sonic:gradient:$width:$height:${Std.string(topColor)}:${Std.string(bottomColor)}';
        var existing = cache.get(id);
        if (existing != null) return existing;

        var bitmap = new BitmapData(width, height, true, 0);
        for (y in 0...height)
        {
            var t:Float = height == 1 ? 0 : y / (height - 1);
            var a:Int = interpolate((topColor >>> 24) & 255, (bottomColor >>> 24) & 255, t);
            var r:Int = interpolate((topColor >>> 16) & 255, (bottomColor >>> 16) & 255, t);
            var g:Int = interpolate((topColor >>> 8) & 255, (bottomColor >>> 8) & 255, t);
            var b:Int = interpolate(topColor & 255, bottomColor & 255, t);
            bitmap.fillRect(new Rectangle(0, y, width, 1), (a << 24) | (r << 16) | (g << 8) | b);
        }
        return register(id, bitmap);
    }

    public static function fromBitmap(bitmap:BitmapData, ?key:String, clone:Bool = true):Null<FlxGraphic>
    {
        if (bitmap == null) return null;
        var id:String = key != null ? key : 'sonic:custom:${serial++}';
        var existing = cache.get(id);
        if (existing != null) return existing;
        return register(id, clone ? bitmap.clone() : bitmap);
    }

    public static function apply(sprite:FlxSprite, graphic:FlxGraphic, width:Float = -1, height:Float = -1):FlxSprite
    {
        if (sprite == null || graphic == null) return sprite;
        sprite.loadGraphic(graphic);
        sprite.antialiasing = defaultAntialiasing;
        if (width > 0 && height > 0)
        {
            sprite.setGraphicSize(Std.int(width), Std.int(height));
            sprite.updateHitbox();
        }
        return sprite;
    }

    public static function makeSprite(x:Float, y:Float, graphic:FlxGraphic, width:Float = -1, height:Float = -1):FlxSprite
    {
        return apply(new FlxSprite(x, y), graphic, width, height);
    }

    public static function center(sprite:FlxSprite, horizontal:Bool = true, vertical:Bool = true):Void
    {
        if (sprite == null) return;
        if (horizontal) sprite.x = (FlxG.width - sprite.width) * 0.5;
        if (vertical) sprite.y = (FlxG.height - sprite.height) * 0.5;
    }

    public static function fit(sprite:FlxSprite, targetWidth:Float, targetHeight:Float, cover:Bool = false):Void
    {
        if (sprite == null || sprite.frameWidth <= 0 || sprite.frameHeight <= 0 || targetWidth <= 0 || targetHeight <= 0)
            return;
        var sx:Float = targetWidth / sprite.frameWidth;
        var sy:Float = targetHeight / sprite.frameHeight;
        var scale:Float = cover ? Math.max(sx, sy) : Math.min(sx, sy);
        sprite.scale.set(scale, scale);
        sprite.updateHitbox();
    }

    public static function has(key:String):Bool
    {
        return key != null && cache.exists(key);
    }

    public static function get(key:String):Null<FlxGraphic>
    {
        return key == null ? null : cache.get(key);
    }

    public static function clearReferences():Void
    {
        cache = new StringMap<FlxGraphic>();
    }

    private static function register(key:String, bitmap:BitmapData):FlxGraphic
    {
        var graphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
        graphic.persist = true;
        cache.set(key, graphic);
        return graphic;
    }

    private static inline function positive(value:Int):Int
    {
        return value < 1 ? 1 : value;
    }

    private static inline function interpolate(a:Int, b:Int, t:Float):Int
    {
        return Std.int(Math.round(a + (b - a) * t));
    }
}
