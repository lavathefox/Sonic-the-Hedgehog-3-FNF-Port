package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import openfl.display.BlendMode;

class SonicFadeTransition extends MusicBeatSubstate
{
	public static var finishCallback:Void->Void;

	public static inline var SECRET_CODE:String = "FunIsInfinite";

	// Tempo (em segundos) entre digitar o código e começar o fade out
	static inline var SECRET_FADE_DELAY:Float = 2;

	var blue:FlxSprite;
	var black:FlxSprite;
	var yellowFlash:FlxSprite;
	var whiteFlash:FlxSprite;

	var duration:Float;
	var isTransIn:Bool = false;
	var isSecret:Bool = false;
	var finished:Bool = false;

	var tweens:Array<FlxTween> = [];
	var secretTimer:FlxTimer;

	public function new(duration:Float, isTransIn:Bool, secret:Bool = false)
	{
		this.duration = duration;
		this.isTransIn = isTransIn;
		// O modo secreto só faz sentido na saída (fade out)
		this.isSecret = secret && !isTransIn;
		super();
	}

	function makeCover(x:Float, y:Float, color:FlxColor, mult:Float, startAlpha:Float):FlxSprite
	{
		var spr = new FlxSprite(x, y).makeGraphic(1, 1, color);
		spr.cameras = cameras;
		spr.scale.set(mult * FlxG.width, mult * FlxG.height);
		spr.updateHitbox();
		spr.scrollFactor.set();
		spr.alpha = startAlpha;
		add(spr);
		return spr;
	}

	function tw(obj:Dynamic, values:Dynamic, time:Float, ?options:TweenOptions):FlxTween
	{
		var t = FlxTween.tween(obj, values, time, options);
		tweens.push(t);
		return t;
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		var startAlpha:Float = isTransIn ? 1 : 0;

		blue = makeCover(-300, -300, 0xFF0026FF, 10, startAlpha);
		blue.blend = BlendMode.MULTIPLY;

		black = makeCover(-50, 0, FlxColor.BLACK, 6, startAlpha);

		if (isSecret)
		{
			yellowFlash = makeCover(-300, -300, 0xFFFFFF00, 10, 0);
			whiteFlash = makeCover(-300, -300, FlxColor.WHITE, 10, 0);
		}

		super.create();

		if (isTransIn)
			startTransIn();
		else if (isSecret)
			startSecretOut();
		else
			startNormalOut();
	}

	function startTransIn():Void
	{
		tw(blue, {alpha: 0}, 0.6, {ease: FlxEase.sineOut});
		tw(black, {alpha: 0}, 0.5, {
			ease: FlxEase.sineOut,
			onComplete: function(_)
			{
				blue.alpha = 0;
				black.alpha = 0;
				close();
			}
		});
	}

	function startNormalOut():Void
	{
		tw(blue, {alpha: 1}, 0.6, {ease: FlxEase.sineOut});
		tw(black, {alpha: 1}, 0.5, {
			ease: FlxEase.sineOut,
			onComplete: function(_)
			{
				blue.alpha = 1;
				black.alpha = 1;
				finish();
			}
		});
	}

	function startSecretOut():Void
	{
		// Flashes (mesmos tempos do Lua)
		tw(yellowFlash, {alpha: 1}, 0.6, {ease: FlxEase.sineOut});
		tw(whiteFlash, {alpha: 1}, 0.8, {ease: FlxEase.sineOut});
		FlxG.sound.play(Paths.sound('sonkteleport'), 1);

		// Depois de 2s: flashes somem enquanto o fade out cobre a tela
		secretTimer = new FlxTimer().start(SECRET_FADE_DELAY, function(_)
		{
			tw(whiteFlash, {alpha: 0}, 0.5, {ease: FlxEase.sineIn});
			tw(yellowFlash, {alpha: 0}, 0.5, {ease: FlxEase.sineIn});
			tw(blue, {alpha: 1}, 0.6, {ease: FlxEase.sineOut});
			tw(black, {alpha: 1}, 0.5, {
				ease: FlxEase.sineOut,
				onComplete: function(_)
				{
					blue.alpha = 1;
					black.alpha = 1;
					finish();
				}
			});
		});
	}

	// Garante que o callback roda só uma vez
	function finish():Void
	{
		if (finished) return;
		finished = true;

		if (finishCallback != null)
		{
			var callback:Void->Void = finishCallback;
			finishCallback = null;
			callback();
		}
	}

	override function close():Void
	{
		if (!isTransIn)
			return;

		super.close();
		finish();
	}

	override function destroy():Void
	{
		if (secretTimer != null)
		{
			secretTimer.cancel();
			secretTimer = null;
		}

		for (t in tweens)
			if (t != null) t.cancel();
		tweens = null;

		super.destroy();
	}
}
