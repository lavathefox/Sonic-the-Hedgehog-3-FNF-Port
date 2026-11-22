package states;

import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;

class GensState extends FlxState
{
	public static final ROM_FILE:String = "Sonic The Hedgehog 3 (W) [!].md";
	public static final ROM_EXTS:Array<String> = ["md", "bin", "gen", "smd"];

	public static var romLoaded(get, never):Bool;

	static function get_romLoaded():Bool
	{
		#if (desktop && sys)
		return gens.GensFrame.romLoaded;
		#else
		return false;
		#end
	}

	override function create():Void
	{
		super.create();
		bgColor = FlxColor.BLACK;
		FlxG.mouse.visible = true;
		#if (desktop && sys)
		gens.GensFrame.init();
		#end
	}

	public function msg(s:String):Void
	{
		#if (desktop && sys)
		gens.GensFrame.message(s);
		#end
	}
}
