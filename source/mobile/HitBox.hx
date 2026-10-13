package mobile;

import flixel.FlxSprite;

/**
 * Debug overlay for a mobile control's touch area.
 * This sprite is visual only; input detection remains in MobileControls.
 */
class HitBox extends FlxSprite
{
	public var controlName:String;

	public function new(x:Float, y:Float, width:Float, height:Float, ?controlName:String = "control", ?color:Int = 0x55FF0000)
	{
		super(x, y);
		this.controlName = controlName;
		makeGraphic(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)), color);
		scrollFactor.set(0, 0);
		antialiasing = false;
		visible = false;
	}
	
	public function setBounds(x:Float, y:Float, width:Float, height:Float):Void
	{
		setPosition(x, y);
		makeGraphic(Std.int(Math.max(1, width)), Std.int(Math.max(1, height)), 0x55FF0000);
	}
}
