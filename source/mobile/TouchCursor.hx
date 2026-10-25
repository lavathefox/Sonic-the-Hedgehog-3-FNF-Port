package mobile;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import backend.ClientPrefs;

/**
 * Shows a ring where each finger touches the screen (up to MAX_TOUCHES fingers at once).
 *
 * MobileControls calls refresh() every frame, so the cursor also works inside
 * the options menu (a substate), where the state behind it is not updated.
 * It is drawn on the mobile controls camera, above everything else.
 *
 * Compiles on every platform; it only does something on Android.
 */
class TouchCursor extends FlxSpriteGroup
{
	static inline var MAX_TOUCHES:Int = 5;
	static inline var SIZE:Int = 56;

	var markers:Array<FlxSprite> = [];
	var wasActive:Array<Bool> = [];

	public function new()
	{
		super();

		for (i in 0...MAX_TOUCHES)
		{
			var marker:FlxSprite = createMarker();
			markers.push(marker);
			wasActive.push(false);
			add(marker);
		}
	}

	/** A white ring with a dot in the middle, drawn in code (no image file needed). */
	function createMarker():FlxSprite
	{
		var marker:FlxSprite = new FlxSprite(0, 0);
		marker.makeGraphic(SIZE, SIZE, FlxColor.TRANSPARENT, true);
		FlxSpriteUtil.drawCircle(marker, -1, -1, SIZE / 2 - 4, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.WHITE});
		FlxSpriteUtil.drawCircle(marker, -1, -1, 6, FlxColor.WHITE);
		marker.antialiasing = true;
		marker.scrollFactor.set();
		marker.alpha = 0;
		return marker;
	}

	/** Moves the rings to the current touches. Called once per frame by MobileControls.update(). */
	public function refresh():Void
	{
		#if (android && FLX_TOUCH)
		if (!ClientPrefs.data.mobileTouchCursor)
		{
			hideAll();
			return;
		}

		var touches = FlxG.touches.list;

		for (i in 0...MAX_TOUCHES)
		{
			var marker:FlxSprite = markers[i];
			var touch = i < touches.length ? touches[i] : null;

			if (touch != null && touch.pressed)
			{
				marker.setPosition(touch.screenX - SIZE / 2, touch.screenY - SIZE / 2);

				if (!wasActive[i])
				{
					// New touch: stop any fade-out and play a small "pop".
					FlxTween.cancelTweensOf(marker);
					FlxTween.cancelTweensOf(marker.scale);
					marker.scale.set(1.5, 1.5);
					FlxTween.tween(marker.scale, {x: 1, y: 1}, 0.12);
				}

				marker.alpha = 0.9;
				wasActive[i] = true;
			}
			else if (wasActive[i])
			{
				// The finger was lifted: fade the ring out where it was.
				wasActive[i] = false;
				FlxTween.tween(marker, {alpha: 0}, 0.18);
			}
		}
		#end
	}

	function hideAll():Void
	{
		for (i in 0...markers.length)
		{
			if (wasActive[i] || markers[i].alpha > 0)
			{
				FlxTween.cancelTweensOf(markers[i]);
				markers[i].alpha = 0;
				wasActive[i] = false;
			}
		}
	}
}
