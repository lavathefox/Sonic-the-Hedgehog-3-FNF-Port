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

	/** Overall hitbox size multiplier. 1.0 fills the screen; lower values shrink it. */
	public static var hitboxScale:Float = 1.0;

	/**
	 * Gap, in game pixels, between the left edge of the touch area and where the lanes start.
	 * 0 = the lanes start at the screen edge. Can be negative to start before the edge (the lanes
	 * still take touches there, but are only drawn inside the game view).
	 */
	public static var marginLeft:Float = -50;

	/** Same as marginLeft, for the right side: where the lanes end, counted from the right screen edge. */
	public static var marginRight:Float = -50;

	/** Lane opacity while a finger is on it (0 to 1). */
	public static var opacity:Float = 0.95;

	/** Hide the lanes but keep the touch input working. */
	public static var invisible:Bool = false;

	/** Keep the lanes faintly visible even when nobody is touching them (the SHOW HITBOX option). Can change at any time. */
	public static var showIdle:Bool = false;

	/** Touches that start above this Y (game pixels) are ignored. 0 = the whole screen works; the pause button area is excluded separately. */
	public static var ignoreTop:Float = 0;

	static inline var FADE_OUT_SPEED:Float = 8;

	/** The touch area never gets narrower than this, so the four lanes always exist. */
	static inline var MIN_AREA_WIDTH:Float = 80;

	/** How visible an untouched lane is while showIdle is on. */
	static inline var IDLE_ALPHA:Float = 0.18;

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

	// The touch area is centered on the screen unless marginLeft / marginRight move its sides.
	// Touches and drawing both use these four functions, so what you see is exactly where you can touch.
	static function areaWidth():Float
	{
		// The screen width (scaled by hitboxScale) minus the two side margins.
		return Math.max(MIN_AREA_WIDTH, FlxG.width * hitboxScale - marginLeft - marginRight);
	}

	static function areaHeight():Float
	{
		return FlxG.height * hitboxScale;
	}

	static function areaLeft():Float
	{
		// Where the (scaled) area would start when centered, moved inwards by marginLeft.
		return (FlxG.width - FlxG.width * hitboxScale) * 0.5 + marginLeft;
	}

	static function areaTop():Float
	{
		return (FlxG.height - areaHeight()) * 0.5;
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
		// Same area the lanes are drawn in (see areaLeft / areaTop / areaWidth / areaHeight).
		var left:Float = areaLeft();
		var top:Float = areaTop();
		var width:Float = areaWidth();
		var height:Float = areaHeight();

		for (touch in FlxG.touches.list)
		{
			if (!touch.pressed || touch.screenY < ignoreTop)
				continue;

			if (touch.screenX < left || touch.screenX >= left + width || touch.screenY < top || touch.screenY >= top + height)
				continue;

			#if android
			// The pause button keeps its own area, so a touch there never counts as a lane.
			if (MobileControls.isReservedTouch(touch))
				continue;
			#end

			// The four lanes have the same width.
			var lane:Int = Std.int((touch.screenX - left) / width * LANES);

			if (lane < 0)
				lane = 0;
			else if (lane >= LANES)
				lane = LANES - 1;

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

		var left:Float = areaLeft();
		var top:Int = Std.int(areaTop());
		var width:Float = areaWidth();
		var height:Int = Std.int(areaHeight());

		for (i in 0...LANES)
		{
			// Four lanes with the same width (the edges are rounded so there is no gap between them).
			var laneX:Int = Std.int(left + width * i / LANES);
			var nextX:Int = Std.int(left + width * (i + 1) / LANES);
			var laneWidth:Int = nextX - laneX;

			var lane:FlxSprite = new FlxSprite(laneX, top);
			lane.loadGraphic(createLaneBitmap(style, laneWidth, height), false, 0, 0, true);
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

		// An untouched lane fades down to "idle": invisible, or faintly visible when showIdle is on.
		var idle:Float = showIdle ? IDLE_ALPHA : 0;

		for (i in 0...lanes.length)
		{
			if (held[i])
			{
				lanes[i].alpha = opacity;
			}
			else if (lanes[i].alpha > idle)
			{
				lanes[i].alpha -= (lanes[i].alpha - idle) * Math.min(1, elapsed * FADE_OUT_SPEED);

				if (lanes[i].alpha - idle < 0.01)
					lanes[i].alpha = idle;
			}
			else
			{
				lanes[i].alpha = idle;
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
