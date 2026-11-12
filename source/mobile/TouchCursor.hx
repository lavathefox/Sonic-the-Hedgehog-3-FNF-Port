package mobile;

import backend.ClientPrefs;
import openfl.Lib;
import openfl.display.Graphics;
import openfl.display.Shape;
import openfl.display.Sprite;
import openfl.events.Event;
import openfl.events.TouchEvent;
import openfl.system.Capabilities;

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

private typedef Mark =
{
	var x:Float;
	var y:Float;
	var bornAt:Int;
}

class TouchCursor extends Sprite
{
	static var instance:TouchCursor;

	static inline var RING_DP:Float = 30;
	static inline var TRAIL_STEP_DP:Float = 10;

	static inline var POP_MS:Int = 120;
	static inline var RIPPLE_MS:Int = 380;
	static inline var RELEASE_MS:Int = 240;
	static inline var TRAIL_MS:Int = 280;

	static inline var MAX_TRAIL:Int = 48;
	static inline var MAX_RIPPLES:Int = 12;
	static inline var MAX_FINGERS:Int = 10;

	var canvas:Shape = new Shape();
	var fingers:Array<Finger> = [];
	var ripples:Array<Mark> = [];
	var trail:Array<Mark> = [];
	var running:Bool = false;

	var baseUnit:Float = 1;

	var unit:Float = 1;

	public static function install():Void
	{
		#if mobile
		if (instance != null)
			return;

		instance = new TouchCursor();
		Lib.current.stage.addChild(instance);
		#end
	}

	function new()
	{
		super();

		mouseEnabled = false;
		mouseChildren = false;
		addChild(canvas);

		baseUnit = Math.max(1, Math.min(4, Capabilities.screenDPI / 160));
		refreshUnit();

		var stage = Lib.current.stage;
		stage.addEventListener(TouchEvent.TOUCH_BEGIN, onTouchBegin, false, 1000);
		stage.addEventListener(TouchEvent.TOUCH_MOVE, onTouchMove, false, 1000);
		stage.addEventListener(TouchEvent.TOUCH_END, onTouchEnd, false, 1000);

		stage.addEventListener(Event.DEACTIVATE, onDeactivate, false, 1000);
	}

	function enabled():Bool
	{
		return ClientPrefs.data.mobileTouchCursor;
	}

	function refreshUnit():Void
	{
		unit = baseUnit * AndroidOptions.touchCursorScale();
	}

	function onTouchBegin(event:TouchEvent):Void
	{
		if (!enabled())
			return;

		refreshUnit();

		var now:Int = Lib.getTimer();

		var stale:Finger = findDown(event.touchPointID);
		if (stale != null)
		{
			stale.down = false;
			stale.releasedAt = now;
		}

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

		if (fingers.length > MAX_FINGERS)
			fingers.shift();

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

	function onDeactivate(_:Event):Void
	{
		var now:Int = Lib.getTimer();

		for (finger in fingers)
		{
			if (finger.down)
			{
				finger.down = false;
				finger.releasedAt = now;
			}
		}
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
		if (!enabled())
		{
			clearAll();
			return;
		}

		refreshUnit();

		var now:Int = Lib.getTimer();
		var g:Graphics = canvas.graphics;
		g.clear();

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

				alpha = 1 - t;
				grow = 1 + 0.5 * easeOut(t);
			}

			var age:Int = now - finger.bornAt;
			var pop:Float = age < POP_MS ? 1 + 0.45 * (1 - easeOut(age / POP_MS)) : 1;
			var radius:Float = RING_DP * unit * pop * grow;

			dot(g, finger.x, finger.y, radius * 1.3, 0xFFFFFF, 0.12 * alpha);
			ring(g, finger.x, finger.y, radius, 5.5 * unit, 0x000000, 0.4 * alpha);
			ring(g, finger.x, finger.y, radius, 2.5 * unit, 0xFFFFFF, 0.95 * alpha);
			dot(g, finger.x, finger.y, 7 * unit, 0x000000, 0.35 * alpha);
			dot(g, finger.x, finger.y, 5 * unit, 0xFFFFFF, 0.95 * alpha);
		}

		if (fingers.length == 0 && ripples.length == 0 && trail.length == 0)
			stop();
	}
}
