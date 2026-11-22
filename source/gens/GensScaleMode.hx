package gens;

import flixel.FlxG;
import flixel.system.scaleModes.RatioScaleMode;

class GensScaleMode extends RatioScaleMode
{
	override public function onMeasure(Width:Int, Height:Int):Void
	{
		var bar = GensFrame.barHeight;
		super.onMeasure(Width, Std.int(Math.max(1, Height - bar)));
		offset.y += bar;
		if (FlxG.game != null) FlxG.game.y = offset.y;
	}
}
