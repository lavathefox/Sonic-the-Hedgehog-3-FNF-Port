package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.display.BlendMode;

class SonicFadeTransition extends MusicBeatSubstate
{
	public static var finishCallback:Void->Void;

	var blue:FlxSprite;
	var black:FlxSprite;

	var duration:Float;
	var isTransIn:Bool = false;

	public function new(duration:Float, isTransIn:Bool)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		blue = new FlxSprite(-300, -300).makeGraphic(1, 1, 0xFF0026FF);
		blue.cameras = cameras;
		blue.scale.set(10 * FlxG.width, 10 * FlxG.height);
		blue.updateHitbox();
		blue.scrollFactor.set();
		blue.blend = BlendMode.MULTIPLY;
		blue.alpha = isTransIn ? 1 : 0;
		add(blue);

		black = new FlxSprite(-50, 0).makeGraphic(1, 1, FlxColor.BLACK);
		black.cameras = cameras;
		black.scale.set(6 * FlxG.width, 6 * FlxG.height);
		black.updateHitbox();
		black.scrollFactor.set();
		black.alpha = isTransIn ? 1 : 0;
		add(black);

		super.create();

		if(isTransIn)
		{
			FlxTween.tween(blue, {alpha: 0}, 0.6, {
				ease: FlxEase.sineOut
			});

			FlxTween.tween(black, {alpha: 0}, 0.5, {
				ease: FlxEase.sineOut,
				onComplete: function(tween:FlxTween)
				{
					blue.alpha = 0;
					black.alpha = 0;
					close();
				}
			});
		}
		else
		{
			FlxTween.tween(blue, {alpha: 1}, 0.6, {
				ease: FlxEase.sineOut
			});

			FlxTween.tween(black, {alpha: 1}, 0.5, {
				ease: FlxEase.sineOut,
				onComplete: function(tween:FlxTween)
				{
					blue.alpha = 1;
					black.alpha = 1;

					if(finishCallback != null)
					{
						var callback:Void->Void = finishCallback;
						finishCallback = null;
						callback();
					}
				}
			});
		}
	}

	override function close():Void
	{
		if(!isTransIn)
			return;

		super.close();

		if(finishCallback != null)
		{
			var callback:Void->Void = finishCallback;
			finishCallback = null;
			callback();
		}
	}
}
