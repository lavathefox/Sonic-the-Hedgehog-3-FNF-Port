package util;

import flixel.FlxG;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;

class PlayerSettings
{
    public static var instance(default, null):PlayerSettings;

    public var enabled:Bool = true;
    public var keyboardEnabled:Bool = true;
    public var gamepadEnabled:Bool = true;
    public var playerIndex:Int = 0;

    public var leftKeys:Array<FlxKey> = [A, LEFT];
    public var downKeys:Array<FlxKey> = [S, DOWN];
    public var upKeys:Array<FlxKey> = [W, UP];
    public var rightKeys:Array<FlxKey> = [D, RIGHT];
    public var acceptKeys:Array<FlxKey> = [ENTER, SPACE];
    public var backKeys:Array<FlxKey> = [ESCAPE, BACKSPACE];
    public var pauseKeys:Array<FlxKey> = [ENTER, ESCAPE];
    public var resetKeys:Array<FlxKey> = [R];

    public var leftButtons:Array<FlxGamepadInputID> = [DPAD_LEFT];
    public var downButtons:Array<FlxGamepadInputID> = [DPAD_DOWN];
    public var upButtons:Array<FlxGamepadInputID> = [DPAD_UP];
    public var rightButtons:Array<FlxGamepadInputID> = [DPAD_RIGHT];
    public var acceptButtons:Array<FlxGamepadInputID> = [A, START];
    public var backButtons:Array<FlxGamepadInputID> = [B, BACK];
    public var pauseButtons:Array<FlxGamepadInputID> = [START];

    public function new()
    {
        if (instance == null) instance = this;
    }

    public static function init():PlayerSettings
    {
        if (instance == null) instance = new PlayerSettings();
        return instance;
    }

    public static function get():PlayerSettings
    {
        return init();
    }

    public function getGamepad():FlxGamepad
    {
        if (!enabled || !gamepadEnabled || FlxG.gamepads == null) return null;
        return FlxG.gamepads.getByID(playerIndex);
    }

    public function pressed(keys:Array<FlxKey>, ?buttons:Array<FlxGamepadInputID>):Bool
    {
        if (!enabled) return false;
        if (keyboardEnabled && keys != null && FlxG.keys.anyPressed(keys)) return true;
        var pad = getGamepad();
        return pad != null && buttons != null && pad.anyPressed(buttons);
    }

    public function justPressed(keys:Array<FlxKey>, ?buttons:Array<FlxGamepadInputID>):Bool
    {
        if (!enabled) return false;
        if (keyboardEnabled && keys != null && FlxG.keys.anyJustPressed(keys)) return true;
        var pad = getGamepad();
        return pad != null && buttons != null && pad.anyJustPressed(buttons);
    }

    public function justReleased(keys:Array<FlxKey>, ?buttons:Array<FlxGamepadInputID>):Bool
    {
        if (!enabled) return false;
        if (keyboardEnabled && keys != null && FlxG.keys.anyJustReleased(keys)) return true;
        var pad = getGamepad();
        return pad != null && buttons != null && pad.anyJustReleased(buttons);
    }

    public function notePressed(direction:Int):Bool
    {
        return switch (direction)
        {
            case 0: pressed(leftKeys, leftButtons);
            case 1: pressed(downKeys, downButtons);
            case 2: pressed(upKeys, upButtons);
            case 3: pressed(rightKeys, rightButtons);
            default: false;
        };
    }

    public function noteJustPressed(direction:Int):Bool
    {
        return switch (direction)
        {
            case 0: justPressed(leftKeys, leftButtons);
            case 1: justPressed(downKeys, downButtons);
            case 2: justPressed(upKeys, upButtons);
            case 3: justPressed(rightKeys, rightButtons);
            default: false;
        };
    }

    public function noteJustReleased(direction:Int):Bool
    {
        return switch (direction)
        {
            case 0: justReleased(leftKeys, leftButtons);
            case 1: justReleased(downKeys, downButtons);
            case 2: justReleased(upKeys, upButtons);
            case 3: justReleased(rightKeys, rightButtons);
            default: false;
        };
    }

    public function accept():Bool return justPressed(acceptKeys, acceptButtons);
    public function back():Bool return justPressed(backKeys, backButtons);
    public function pause():Bool return justPressed(pauseKeys, pauseButtons);
    public function reset():Bool return justPressed(resetKeys);

    public function setNoteKeys(direction:Int, keys:Array<FlxKey>):Void
    {
        if (keys == null) return;
        switch (direction)
        {
            case 0: leftKeys = keys.copy();
            case 1: downKeys = keys.copy();
            case 2: upKeys = keys.copy();
            case 3: rightKeys = keys.copy();
        }
    }

    public function resetBindings():Void
    {
        leftKeys = [A, LEFT];
        downKeys = [S, DOWN];
        upKeys = [W, UP];
        rightKeys = [D, RIGHT];
        acceptKeys = [ENTER, SPACE];
        backKeys = [ESCAPE, BACKSPACE];
        pauseKeys = [ENTER, ESCAPE];
        resetKeys = [R];
        leftButtons = [DPAD_LEFT];
        downButtons = [DPAD_DOWN];
        upButtons = [DPAD_UP];
        rightButtons = [DPAD_RIGHT];
        acceptButtons = [A, START];
        backButtons = [B, BACK];
        pauseButtons = [START];
    }
}
