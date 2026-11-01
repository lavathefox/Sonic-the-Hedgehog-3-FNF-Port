package backend;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

class Controls
{
	public static var instance:Controls;

	public var keyboardBinds:Map<String, Array<FlxKey>>;
	public var gamepadBinds:Map<String, Array<FlxGamepadInputID>>;
	public var controllerMode:Bool = false;
	public var touchMode(default, null):Bool = false;
	public var lastInput(default, null):String = "keyboard";

	private var touchSources:Map<String, Map<Int, Bool>> = new Map();
	private var touchDown:Map<String, Bool> = new Map();
	private var touchPrevious:Map<String, Bool> = new Map();
	private var touchJustPressed:Map<String, Bool> = new Map();
	private var touchJustReleased:Map<String, Bool> = new Map();

	public var UI_UP_P(get, never):Bool;
	public var UI_DOWN_P(get, never):Bool;
	public var UI_LEFT_P(get, never):Bool;
	public var UI_RIGHT_P(get, never):Bool;
	public var NOTE_UP_P(get, never):Bool;
	public var NOTE_DOWN_P(get, never):Bool;
	public var NOTE_LEFT_P(get, never):Bool;
	public var NOTE_RIGHT_P(get, never):Bool;
	public var UI_UP(get, never):Bool;
	public var UI_DOWN(get, never):Bool;
	public var UI_LEFT(get, never):Bool;
	public var UI_RIGHT(get, never):Bool;
	public var NOTE_UP(get, never):Bool;
	public var NOTE_DOWN(get, never):Bool;
	public var NOTE_LEFT(get, never):Bool;
	public var NOTE_RIGHT(get, never):Bool;
	public var UI_UP_R(get, never):Bool;
	public var UI_DOWN_R(get, never):Bool;
	public var UI_LEFT_R(get, never):Bool;
	public var UI_RIGHT_R(get, never):Bool;
	public var NOTE_UP_R(get, never):Bool;
	public var NOTE_DOWN_R(get, never):Bool;
	public var NOTE_LEFT_R(get, never):Bool;
	public var NOTE_RIGHT_R(get, never):Bool;
	public var ACCEPT(get, never):Bool;
	public var BACK(get, never):Bool;
	public var PAUSE(get, never):Bool;
	public var RESET(get, never):Bool;

	private function get_UI_UP_P():Bool return justPressed("ui_up");
	private function get_UI_DOWN_P():Bool return justPressed("ui_down");
	private function get_UI_LEFT_P():Bool return justPressed("ui_left");
	private function get_UI_RIGHT_P():Bool return justPressed("ui_right");
	private function get_NOTE_UP_P():Bool return justPressed("note_up");
	private function get_NOTE_DOWN_P():Bool return justPressed("note_down");
	private function get_NOTE_LEFT_P():Bool return justPressed("note_left");
	private function get_NOTE_RIGHT_P():Bool return justPressed("note_right");
	private function get_UI_UP():Bool return pressed("ui_up");
	private function get_UI_DOWN():Bool return pressed("ui_down");
	private function get_UI_LEFT():Bool return pressed("ui_left");
	private function get_UI_RIGHT():Bool return pressed("ui_right");
	private function get_NOTE_UP():Bool return pressed("note_up");
	private function get_NOTE_DOWN():Bool return pressed("note_down");
	private function get_NOTE_LEFT():Bool return pressed("note_left");
	private function get_NOTE_RIGHT():Bool return pressed("note_right");
	private function get_UI_UP_R():Bool return justReleased("ui_up");
	private function get_UI_DOWN_R():Bool return justReleased("ui_down");
	private function get_UI_LEFT_R():Bool return justReleased("ui_left");
	private function get_UI_RIGHT_R():Bool return justReleased("ui_right");
	private function get_NOTE_UP_R():Bool return justReleased("note_up");
	private function get_NOTE_DOWN_R():Bool return justReleased("note_down");
	private function get_NOTE_LEFT_R():Bool return justReleased("note_left");
	private function get_NOTE_RIGHT_R():Bool return justReleased("note_right");
	private function get_ACCEPT():Bool return justPressed("accept");
	private function get_BACK():Bool return justPressed("back");
	private function get_PAUSE():Bool return justPressed("pause");
	private function get_RESET():Bool return justPressed("reset");

	public function new()
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
	}

	public function refreshBinds():Void
	{
		keyboardBinds = ClientPrefs.keyBinds;
		gamepadBinds = ClientPrefs.gamepadBinds;
	}

	private function keyboardKeys(action:String):Array<FlxKey>
	{
		if (keyboardBinds == null) return [];
		var keys = keyboardBinds.get(action);
		return keys == null ? [] : keys;
	}

	private function gamepadKeys(action:String):Array<FlxGamepadInputID>
	{
		if (gamepadBinds == null) return [];
		var keys = gamepadBinds.get(action);
		return keys == null ? [] : keys;
	}

	private function checkGamepad(action:String, state:Int):Bool
	{
		if (FlxG.gamepads == null) return false;
		for (key in gamepadKeys(action))
		{
			var active = switch (state)
			{
				case 0: FlxG.gamepads.anyPressed(key);
				case 1: FlxG.gamepads.anyJustPressed(key);
				default: FlxG.gamepads.anyJustReleased(key);
			};
			if (active) return true;
		}
		return false;
	}

	private function query(action:String, state:Int):Bool
	{
		var keys = keyboardKeys(action);
		var keyboard = keys.length > 0 && switch (state)
		{
			case 0: FlxG.keys.anyPressed(keys);
			case 1: FlxG.keys.anyJustPressed(keys);
			default: FlxG.keys.anyJustReleased(keys);
		};
		var gamepad = checkGamepad(action, state);
		var touch = switch (state)
		{
			case 0: touchDown.get(action) == true;
			case 1: touchJustPressed.get(action) == true;
			default: touchJustReleased.get(action) == true;
		};
		if (touch)
		{
			touchMode = true;
			controllerMode = false;
			lastInput = "touch";
		}
		else if (gamepad)
		{
			touchMode = false;
			controllerMode = true;
			lastInput = "gamepad";
		}
		else if (keyboard)
		{
			touchMode = false;
			controllerMode = false;
			lastInput = "keyboard";
		}
		return keyboard || gamepad || touch;
	}

	public function pressed(action:String):Bool return query(action, 0);
	public function justPressed(action:String):Bool return query(action, 1);
	public function justReleased(action:String):Bool return query(action, 2);

	public function setTouchAction(action:String, sourceId:Int, down:Bool):Void
	{
		if (action == null || action.length == 0) return;
		var sources = touchSources.get(action);
		if (sources == null)
		{
			sources = new Map<Int, Bool>();
			touchSources.set(action, sources);
		}
		if (down) sources.set(sourceId, true);
		else sources.remove(sourceId);
		var any = false;
		for (value in sources) if (value) { any = true; break; }
		touchDown.set(action, any);
	}

	public function releaseTouchSource(sourceId:Int):Void
	{
		for (action in touchSources.keys()) setTouchAction(action, sourceId, false);
	}

	public function clearTouch():Void
	{
		for (action in touchDown.keys()) touchDown.set(action, false);
		touchSources = new Map();
	}

	public function updateTouch():Void
	{
		var actions = new Map<String, Bool>();
		for (action in touchDown.keys()) actions.set(action, true);
		for (action in touchPrevious.keys()) actions.set(action, true);
		for (action in actions.keys())
		{
			var now = touchDown.get(action) == true;
			var before = touchPrevious.get(action) == true;
			touchJustPressed.set(action, now && !before);
			touchJustReleased.set(action, !now && before);
			touchPrevious.set(action, now);
		}
	}
}
