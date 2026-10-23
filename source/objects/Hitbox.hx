package objects;

import flixel.FlxG;
import backend.MobileControls;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

/**
 * Touch hitbox for gameplay on mobile.
 *
 * The screen is split into 4 full-height lanes (left, down, up, right).
 * Touching a lane works like pressing the matching note key, and holding a
 * finger on it keeps sustain notes alive. Several fingers can be used at once.
 *
 * Input is exposed through static functions so PlayState can read it:
 *   Hitbox.pressed(lane), Hitbox.justPressed(lane), Hitbox.justReleased(lane)
 *
 * The hitbox must be added to the state (it polls the touches in update()).
 */
class Hitbox extends FlxSpriteGroup
{
	public static inline var LANES:Int = 4;

	public static final STYLES:Array<String> = ['Gradient', 'Solid', 'Outline'];

	// ---- Settings (change them before creating the hitbox) ----

	/** One of STYLES. */
	public static var style:String = 'Gradient';

	/** Lane opacity while a finger is on it (0 to 1). */
	public static var opacity:Float = 0.35;

	/** Hide the lanes but keep the touch input working. */
	public static var invisible:Bool = false;

	/** Touches that start above this Y (game pixels) are ignored, e.g. to keep a pause button free. */
	public static var ignoreTop:Float = 0;

	static inline var FADE_OUT_SPEED:Float = 8;

	static var held:Array<Bool> = [for (i in 0...LANES) false];
	static var previous:Array<Bool> = [for (i in 0...LANES) false];

	var lanes:Array<FlxSprite> = [];

	// ---- Input state ----

	public static function pressed(lane:Int):Bool
	{
		return lane >= 0 && lane < LANES && held[lane];
	}

	public static function justPressed(lane:Int):Bool
	{
		return lane >= 0 && lane < LANES && held[lane] && !previous[lane];
	}

	public static function justReleased(lane:Int):Bool
	{
		return lane >= 0 && lane < LANES && !held[lane] && previous[lane];
	}

	/** Reads the current touches and works out which lanes are being held. */
	static function pollTouches():Void
	{
		for (i in 0...LANES)
		{
			previous[i] = held[i];
			held[i] = false;
		}

		#if FLX_TOUCH
		// Wider outer lanes make Left and Right easier to hit on mobile.
		// On a 959px screen: Left/Right get 30% each, Down/Up get 20% each.
		var screenWidth:Float = FlxG.width;
		var leftBoundary:Float = screenWidth * 0.30;
		var downBoundary:Float = screenWidth * 0.50;
		var upBoundary:Float = screenWidth * 0.70;

		for (touch in FlxG.touches.list)
		{
			if (!touch.pressed || touch.screenY < ignoreTop)
				continue;

			#if android
			if (MobileControls.isReservedTouch(touch))
				continue;
			#end

			var lane:Int;
			if (touch.screenX < leftBoundary)
				lane = 0;
			else if (touch.screenX < downBoundary)
				lane = 1;
			else if (touch.screenX < upBoundary)
				lane = 2;
			else
				lane = 3;

			held[lane] = true;
		}
		#end
	}

	// ---- Visuals ----

	public function new()
	{
		super();

		for (i in 0...LANES)
		{
			held[i] = false;
			previous[i] = false;
		}

		var screenWidth:Int = FlxG.width;
		var boundaries:Array<Int> = [
			0,
			Std.int(screenWidth * 0.30),
			Std.int(screenWidth * 0.50),
			Std.int(screenWidth * 0.70),
			screenWidth
		];

		for (i in 0...LANES)
		{
			var laneX:Int = boundaries[i];
			var laneWidth:Int = boundaries[i + 1] - laneX;
			var lane:FlxSprite = new FlxSprite(laneX, 0);
			lane.loadGraphic(createLaneBitmap(style, laneWidth, FlxG.height), false, 0, 0, true);
			lane.color = laneColor(i);
			lane.alpha = 0;
			lane.antialiasing = ClientPrefs.data.antialiasing;
			lanes.push(lane);
			add(lane);
		}

		scrollFactor.set();
		visible = !invisible;
	}

	/** Same color as the note arrow of that lane. */
	static function laneColor(lane:Int):FlxColor
	{
		var colors:Array<FlxColor> = null;

		if (ClientPrefs.data.arrowRGB != null && ClientPrefs.data.arrowRGB.length > 0)
			colors = ClientPrefs.data.arrowRGB[lane % ClientPrefs.data.arrowRGB.length];

		return (colors != null && colors.length > 0) ? colors[0] : FlxColor.WHITE;
	}

	static function createLaneBitmap(style:String, width:Int, height:Int):BitmapData
	{
		var bitmap:BitmapData;

		switch (style)
		{
			case 'Solid':
				bitmap = new BitmapData(width, height, true, 0x70FFFFFF);
				bitmap.fillRect(new Rectangle(0, 0, 3, height), 0xFFFFFFFF);
				bitmap.fillRect(new Rectangle(width - 3, 0, 3, height), 0xFFFFFFFF);

			case 'Outline':
				bitmap = new BitmapData(width, height, true, 0x18FFFFFF);
				var thickness:Int = 8;
				var inset:Int = 4;
				bitmap.fillRect(new Rectangle(inset, inset, width - inset * 2, thickness), 0xFFFFFFFF);
				bitmap.fillRect(new Rectangle(inset, height - inset - thickness, width - inset * 2, thickness), 0xFFFFFFFF);
				bitmap.fillRect(new Rectangle(inset, inset, thickness, height - inset * 2), 0xFFFFFFFF);
				bitmap.fillRect(new Rectangle(width - inset - thickness, inset, thickness, height - inset * 2), 0xFFFFFFFF);

			default: // Gradient: transparent at the top, brighter at the bottom
				bitmap = FlxGradient.createGradientBitmapData(width, height, [0x00FFFFFF, 0x20FFFFFF, 0xD0FFFFFF], 1, 90);
		}

		return bitmap;
	}

	override function update(elapsed:Float)
	{
		pollTouches();
		super.update(elapsed);

		for (i in 0...lanes.length)
		{
			if (held[i])
			{
				lanes[i].alpha = opacity;
			}
			else if (lanes[i].alpha > 0)
			{
				lanes[i].alpha -= lanes[i].alpha * Math.min(1, elapsed * FADE_OUT_SPEED);

				if (lanes[i].alpha < 0.01)
					lanes[i].alpha = 0;
			}
		}
	}

	override function destroy()
	{
		for (i in 0...LANES)
		{
			held[i] = false;
			previous[i] = false;
		}

		super.destroy();
	}
}
