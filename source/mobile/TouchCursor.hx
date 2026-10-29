package mobile;

import openfl.Lib;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.system.Capabilities;
import backend.ClientPrefs;

/** A finger being followed: where it is, when it touched and, once lifted, when it was lifted. */
private typedef Finger =
{
	var id:Int;
	var x:Float;
	var y:Float;
	var bornAt:Int;
	var down:Bool;
	var releasedAt:Int;
	var trailX:Float;
	var trailY:Float;
}

/** A point of the trail left by a moving finger, or the start of a ripple. */
private typedef Mark =
{
	var x:Float;
	var y:Float;
	var bornAt:Int;
}

/**
 * Touch cursor: shows where the player touches, on EVERY screen of the game.
 *
 * It is not part of any state. It is a small overlay placed on top of the whole game
 * (above the black bars too) that listens to the touches of the window itself, so a touch
 * shows up the very moment it happens, in the menus, in the options and during songs.
 *
 * What it draws:
 *  - a ring with a dark outline (so it is visible on any background) and a dot in the middle;
 *  - a small "pop" when the finger lands and a ripple that spreads out from that point;
 *  - a short trail of fading dots while the finger moves;
 *  - a fade-out when the finger is lifted.
 * Every finger is followed on its own, so several fingers work at the same time.
 * The size follows the screen density, so it looks the same on any phone.
 *
 * It only works when the TOUCH CURSOR option is on, and only on Android.
 */
class TouchCursor extends Sprite
{
	static var instance:TouchCursor;

	// Sizes in "dp" (density independent pixels). They are multiplied by the phone's density.
	static inline var RING_DP:Float = 30;
	static inline var TRAIL_STEP_DP:Float = 10;

	// How long each effect lasts (milliseconds).
	static inline var POP_MS:Int = 120;
	static inline var RIPPLE_MS:Int = 380;
	static inline var RELEASE_MS:Int = 240;
	static inline var TRAIL_MS:Int = 280;

	static inline var MAX_TRAIL:Int = 48;
	static inline var MAX_RIPPLES:Int = 12;

	var canvas:Shape = new Shape();
	var fingers:Array<Finger> = [];
	var ripples:Array<Mark> = [];
	var trail:Array<Mark> = [];
	var running:Bool = false;

	/** Pixels in one dp on this phone. */
	var unit:Float = 1;

	/** Puts the cursor on top of the whole game. Safe to call more than once. */
	public static function install():Void
	{
		#if android
		if (instance != null)
			return;

		instance = new TouchCursor();
		Lib.current.stage.addChild(instance);
		#end
	}

	function new()
	{
		super();

		// The overlay must never take touches away from the game.
		mouseEnabled = false;
		mouseChildren = false;
		addChild(canvas);

		unit = Math.max(1, Math.min(4, Capabilities.screenDPI / 160));

		var stage = Lib.current.stage;
		stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 1000);
		stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 1000);
		stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 1000);
	}

	function enabled():Bool
	{
		return ClientPrefs.data.mobileTouchCursor;
	}

	// ---- Touch events ----

	function onTouchBegin(event:TouchEvent):Void
	{
		if (!enabled())
			return;

		var now:Int = Lib.getTimer();

		fingers.push({
			id: event.touchPointID,
			x: event.stageX,
			y: event.stageY,
			bornAt: now,
			down: true,
			releasedAt: 0,
			trailX: event.stageX,
			trailY: event.stageY
		});

		ripples.push({x: event.stageX, y: event.stageY, bornAt: now});

		if (ripples.length > MAX_RIPPLES)
			ripples.shift();

		start();
	}

	function onTouchMove(event:TouchEvent):Void
	{
		var finger:Finger = findDown(event.touchPointID);

		if (finger == null)
			return;

		finger.x = event.stageX;
		finger.y = event.stageY;

		// Leave a trail dot every few pixels of movement.
		var dx:Float = finger.x - finger.trailX;
		var dy:Float = finger.y - finger.trailY;
		var step:Float = TRAIL_STEP_DP * unit;

		if (dx * dx + dy * dy > step * step)
		{
			trail.push({x: finger.x, y: finger.y, bornAt: Lib.getTimer()});

			if (trail.length > MAX_TRAIL)
				trail.shift();

			finger.trailX = finger.x;
			finger.trailY = finger.y;
		}
	}

	function onTouchEnd(event:TouchEvent):Void
	{
		var finger:Finger = findDown(event.touchPointID);

		if (finger == null)
			return;

		finger.down = false;
		finger.releasedAt = Lib.getTimer();
	}

	function findDown(id:Int):Finger
	{
		for (finger in fingers)
		{
			if (finger.id == id && finger.down)
				return finger;
		}

		return null;
	}

	// ---- Drawing (only runs while there is something to show) ----

	function start():Void
	{
		if (running)
			return;

		running = true;
		addEventListener(Event.ENTER_FRAME, onFrame);
	}

	function stop():Void
	{
		if (!running)
			return;

		running = false;
		removeEventListener(Event.ENTER_FRAME, onFrame);
		canvas.graphics.clear();
	}

	function clearAll():Void
	{
		fingers = [];
		ripples = [];
		trail = [];
		stop();
	}

	static inline function easeOut(t:Float):Float
	{
		var k:Float = 1 - t;
		return 1 - k * k * k;
	}

	static function ring(g:Graphics, x:Float, y:Float, radius:Float, thickness:Float, color:Int, alpha:Float):Void
	{
		g.lineStyle(thickness, color, alpha);
		g.drawCircle(x, y, radius);
		g.lineStyle();
	}

	static function dot(g:Graphics, x:Float, y:Float, radius:Float, color:Int, alpha:Float):Void
	{
		g.beginFill(color, alpha);
		g.drawCircle(x, y, radius);
		g.endFill();
	}

	function onFrame(_:Event):Void
	{
		// The option was turned off while something was on screen: remove it right away.
		if (!enabled())
		{
			clearAll();
			return;
		}

		var now:Int = Lib.getTimer();
		var g:Graphics = canvas.graphics;
		g.clear();

		// Trail: small dots that shrink and fade.
		var i:Int = trail.length;

		while (i-- > 0)
		{
			var mark:Mark = trail[i];
			var t:Float = (now - mark.bornAt) / TRAIL_MS;

			if (t >= 1)
			{
				trail.splice(i, 1);
				continue;
			}

			dot(g, mark.x, mark.y, (6 * (1 - t) + 1.5) * unit, 0xFFFFFF, 0.5 * (1 - t));
		}

		// Ripples: a ring that spreads out from the place that was touched and fades.
		i = ripples.length;

		while (i-- > 0)
		{
			var ripple:Mark = ripples[i];
			var t:Float = (now - ripple.bornAt) / RIPPLE_MS;

			if (t >= 1)
			{
				ripples.splice(i, 1);
				continue;
			}

			var radius:Float = (RING_DP * 0.6 + RING_DP * 2.0 * easeOut(t)) * unit;
			ring(g, ripple.x, ripple.y, radius, Math.max(1, 3 * (1 - t)) * unit, 0xFFFFFF, 0.55 * (1 - t));
		}

		// Fingers: the ring that follows each touch.
		i = fingers.length;

		while (i-- > 0)
		{
			var finger:Finger = fingers[i];
			var alpha:Float = 1;
			var grow:Float = 1;

			if (!finger.down)
			{
				var t:Float = (now - finger.releasedAt) / RELEASE_MS;

				if (t >= 1)
				{
					fingers.splice(i, 1);
					continue;
				}

				// Lifted: the ring spreads a little and fades away.
				alpha = 1 - t;
				grow = 1 + 0.5 * easeOut(t);
			}

			// Just landed: starts bigger and settles down.
			var age:Int = now - finger.bornAt;
			var pop:Float = age < POP_MS ? 1 + 0.45 * (1 - easeOut(age / POP_MS)) : 1;
			var radius:Float = RING_DP * unit * pop * grow;

			dot(g, finger.x, finger.y, radius * 1.3, 0xFFFFFF, 0.12 * alpha); // soft glow
			ring(g, finger.x, finger.y, radius, 5.5 * unit, 0x000000, 0.4 * alpha); // dark outline, so it shows on light backgrounds
			ring(g, finger.x, finger.y, radius, 2.5 * unit, 0xFFFFFF, 0.95 * alpha); // the ring
			dot(g, finger.x, finger.y, 7 * unit, 0x000000, 0.35 * alpha); // dark base of the center dot
			dot(g, finger.x, finger.y, 5 * unit, 0xFFFFFF, 0.95 * alpha); // center dot
		}

		if (fingers.length == 0 && ripples.length == 0 && trail.length == 0)
			stop();
	}
}
