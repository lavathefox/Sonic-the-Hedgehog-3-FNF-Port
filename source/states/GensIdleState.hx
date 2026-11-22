package states;

import flixel.FlxG;
import flixel.FlxState;

class GensIdleState extends FlxState
{
	override function create():Void
	{
		super.create();
		FlxG.mouse.visible = true;
	}
}
