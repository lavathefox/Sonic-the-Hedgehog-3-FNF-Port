package backend;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import states.TitleState;
import save.Save;

@:structInit class SaveVariables
{
    public var sonicTitleCardStyle:String = 'DEFAULT';
    public var sonicHUDStyle:String = 'DEFAULT';
    public var mobileShowHitbox:Bool = false;
    public var mobilePauseButton:Bool = true;
    public var mobileTouchCursor:Bool = false;
    public var mobileControlsOpacity:Int = 3;
    public var mobileVibration:Int = 0;
    public var mobileKeepScreenOn:Bool = true;
    public var mobileLaneStyle:Int = 0;
    public var mobileLaneOpacity:Int = 1;
    public var mobileControlsSize:Int = 1;
    public var mobileLeftHanded:Bool = false;
    public var mobileBrightness:Int = 0;
    public var mobileTouchCursorSize:Int = 1;
    public var mobileVibrateOnMiss:Bool = false;
    public var mobileSwapAB:Bool = false;
    public var mobileImmersive:Bool = true;
    public var mobileBatterySaver:Bool = false;
    public var downScroll:Bool = false;
    public var middleScroll:Bool = false;
    public var opponentStrums:Bool = true;
    public var showFPS:Bool = true;
    public var flashing:Bool = true;
    public var autoPause:Bool = true;
    public var antialiasing:Bool = true;
    public var noteSkin:String = 'Default';
    public var splashSkin:String = 'Psych';
    public var splashAlpha:Float = 0.6;
    public var lowQuality:Bool = false;
    public var shaders:Bool = true;
    public var cacheOnGPU:Bool = #if !switch false #else true #end;
    public var framerate:Int = 60;
    public var camZooms:Bool = true;
    public var hideHud:Bool = false;
    public var noteOffset:Int = 0;
    public var arrowRGB:Array<Array<FlxColor>> = [
        [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56],
        [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7],
        [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447],
        [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
    ];
    public var arrowRGBPixel:Array<Array<FlxColor>> = [
        [0xFFE276FF, 0xFFFFF9FF, 0xFF60008D],
        [0xFF3DCAFF, 0xFFF4FFFF, 0xFF003060],
        [0xFF71E300, 0xFFF6FFE6, 0xFF003100],
        [0xFFFF884E, 0xFFFFFAF5, 0xFF6C0000]
    ];
    public var ghostTapping:Bool = true;
    public var timeBarType:String = 'Time Left';
    public var scoreZoom:Bool = true;
    public var noReset:Bool = false;
    public var healthBarAlpha:Float = 1;
    public var hitsoundVolume:Float = 0;
    public var pauseMusic:String = 'Tea Time';
    public var checkForUpdates:Bool = true;
    public var comboStacking:Bool = true;
    public var gameplaySettings:Map<String, Dynamic> = [
        'scrollspeed' => 1.0,
        'scrolltype' => 'multiplicative',
        'songspeed' => 1.0,
        'healthgain' => 1.0,
        'healthloss' => 1.0,
        'instakill' => false,
        'practice' => false,
        'botplay' => false,
        'opponentplay' => false
    ];
    public var comboOffset:Array<Int> = [0, 0, 0, 0];
    public var ratingOffset:Int = 0;
    public var sickWindow:Float = 45.0;
    public var goodWindow:Float = 90.0;
    public var badWindow:Float = 135.0;
    public var safeFrames:Float = 10.0;
    public var guitarHeroSustains:Bool = true;
    public var discordRPC:Bool = true;
    public var loadingScreen:Bool = true;
    public var language:String = 'en-US';
}

class ClientPrefs
{
    public static var data:SaveVariables = {};
    public static var defaultData:SaveVariables = {};
    public static var lastSaveError(default, null):String = '';
    public static var currentGameSlot(default, null):Int = 0;
    public static var optionsDirty(default, null):Bool = false;

    static inline var OPTIONS_NAME:String = 'sonic_options_v1';
    static inline var CONTROLS_NAME:String = 'controls_v3';
    static var optionsSave:FlxSave;
    static var controlsSave:FlxSave;
    static var loaded:Bool = false;

    public static var keyBinds:Map<String, Array<FlxKey>> = [
        'note_up' => [W, UP], 'note_left' => [A, LEFT],
        'note_down' => [S, DOWN], 'note_right' => [D, RIGHT],
        'ui_up' => [W, UP], 'ui_left' => [A, LEFT],
        'ui_down' => [S, DOWN], 'ui_right' => [D, RIGHT],
        'accept' => [SPACE, ENTER], 'back' => [BACKSPACE, ESCAPE],
        'pause' => [ENTER, ESCAPE], 'reset' => [R],
        'volume_mute' => [ZERO], 'volume_up' => [NUMPADPLUS, PLUS],
        'volume_down' => [NUMPADMINUS, MINUS],
        'debug_1' => [SEVEN], 'debug_2' => [EIGHT]
    ];
    public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> = [
        'note_up' => [DPAD_UP, Y], 'note_left' => [DPAD_LEFT, X],
        'note_down' => [DPAD_DOWN, A], 'note_right' => [DPAD_RIGHT, B],
        'ui_up' => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
        'ui_left' => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
        'ui_down' => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
        'ui_right' => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
        'accept' => [A, START], 'back' => [B],
        'pause' => [START], 'reset' => [BACK]
    ];
    public static var defaultKeys:Map<String, Array<FlxKey>> = null;
    public static var defaultButtons:Map<String, Array<FlxGamepadInputID>> = null;

    static function ensureSaves():Bool
    {
        if (loaded) return true;
        try
        {
            optionsSave = new FlxSave();
            controlsSave = new FlxSave();
            if (!optionsSave.bind(OPTIONS_NAME, CoolUtil.getSavePath()))
                return error('Could not bind options save');
            if (!controlsSave.bind(CONTROLS_NAME, CoolUtil.getSavePath()))
                return error('Could not bind controls save');
            loaded = true;
            return true;
        }
        catch (e:Dynamic)
        {
            return error(Std.string(e));
        }
    }

    static function error(message:String):Bool
    {
        lastSaveError = message;
        return false;
    }

    public static function markDirty():Void
    {
        optionsDirty = true;
    }

    public static function saveSettings():Void
    {
        trySaveSettings();
    }

    public static function trySaveSettings():Bool
    {
        if (!ensureSaves()) return false;
        try
        {
            normalize();
            for (field in Reflect.fields(data))
                Reflect.setField(optionsSave.data, field, Reflect.field(data, field));
            optionsSave.data.schemaVersion = 1;
            optionsSave.data.migrated = true;
            controlsSave.data.keyboard = keyBinds;
            controlsSave.data.gamepad = gamepadBinds;
            #if ACHIEVEMENTS_ALLOWED
            Achievements.save();
            #end
            var ok:Bool = optionsSave.flush() && controlsSave.flush();
            if (!ok) return error('Could not flush options or controls');
            optionsDirty = false;
            lastSaveError = '';
            return true;
        }
        catch (e:Dynamic)
        {
            return error(Std.string(e));
        }
    }

    public static function loadPrefs():Void
    {
        if (!ensureSaves()) return;
        #if ACHIEVEMENTS_ALLOWED
        Achievements.load();
        #end
        var source:Dynamic = optionsSave.data;
        var migrate:Bool = source.migrated != true;
        if (migrate && FlxG.save != null)
            source = FlxG.save.data;
        for (field in Reflect.fields(data))
        {
            if (field == 'gameplaySettings') continue;
            if (Reflect.hasField(source, field))
            {
                var value:Dynamic = Reflect.field(source, field);
                if (value != null) Reflect.setField(data, field, value);
            }
        }
        var savedGameplay:Dynamic = Reflect.field(source, 'gameplaySettings');
        if (savedGameplay != null)
        {
            try
            {
                var map:Map<String, Dynamic> = cast savedGameplay;
                for (key => value in map)
                    if (data.gameplaySettings.exists(key)) data.gameplaySettings.set(key, value);
            }
            catch (_:Dynamic) {}
        }
        normalize();
        applySettings();
        loadControls();
        if (migrate) trySaveSettings();
    }

    static function normalize():Void
    {
        data.framerate = Std.int(FlxMath.bound(data.framerate, 30, 240));
        data.splashAlpha = FlxMath.bound(data.splashAlpha, 0, 1);
        data.healthBarAlpha = FlxMath.bound(data.healthBarAlpha, 0, 1);
        data.hitsoundVolume = FlxMath.bound(data.hitsoundVolume, 0, 1);
        data.noteOffset = Std.int(FlxMath.bound(data.noteOffset, -500, 500));
        data.mobileControlsOpacity = Std.int(FlxMath.bound(data.mobileControlsOpacity, 0, 10));
        data.mobileControlsSize = Std.int(FlxMath.bound(data.mobileControlsSize, 0, 2));
        data.mobileVibration = Std.int(FlxMath.bound(data.mobileVibration, 0, 2));
        data.mobileLaneStyle = Std.int(FlxMath.bound(data.mobileLaneStyle, 0, 2));
        data.mobileTouchCursorSize = Std.int(FlxMath.bound(data.mobileTouchCursorSize, 0, 2));
        if (data.language == null || data.language.length == 0) data.language = 'en-US';
    }

    public static function applySettings():Void
    {
        if (Main.fpsVar != null) Main.fpsVar.visible = data.showFPS;
        FlxG.autoPause = data.autoPause;
        if (data.framerate > FlxG.drawFramerate)
        {
            FlxG.updateFramerate = data.framerate;
            FlxG.drawFramerate = data.framerate;
        }
        else
        {
            FlxG.drawFramerate = data.framerate;
            FlxG.updateFramerate = data.framerate;
        }
        if (FlxG.save != null)
        {
            if (FlxG.save.data.volume != null) FlxG.sound.volume = FlxG.save.data.volume;
            if (FlxG.save.data.mute != null) FlxG.sound.muted = FlxG.save.data.mute;
        }
        #if DISCORD_ALLOWED
        DiscordClient.check();
        #end
    }

    static function loadControls():Void
    {
        if (controlsSave == null) return;
        try
        {
            if (controlsSave.data.keyboard != null)
            {
                var savedKeys:Map<String, Array<FlxKey>> = controlsSave.data.keyboard;
                for (key => value in savedKeys)
                    if (keyBinds.exists(key) && value != null) keyBinds.set(key, value.copy());
            }
            if (controlsSave.data.gamepad != null)
            {
                var savedPads:Map<String, Array<FlxGamepadInputID>> = controlsSave.data.gamepad;
                for (key => value in savedPads)
                    if (gamepadBinds.exists(key) && value != null) gamepadBinds.set(key, value.copy());
            }
        }
        catch (_:Dynamic) {}
        reloadVolumeKeys();
    }

    public static function restoreDefaults(?saveNow:Bool = true):Void
    {
        data = {};
        optionsDirty = true;
        applySettings();
        if (saveNow) saveSettings();
    }

    public static function loadDefaultKeys():Void
    {
        defaultKeys = new Map();
        defaultButtons = new Map();
        for (key => value in keyBinds) defaultKeys.set(key, value.copy());
        for (key => value in gamepadBinds) defaultButtons.set(key, value.copy());
    }

    public static function resetKeys(controller:Null<Bool> = null):Void
    {
        if (defaultKeys == null || defaultButtons == null) loadDefaultKeys();
        if (controller != true)
            for (key => value in defaultKeys) keyBinds.set(key, value.copy());
        if (controller != false)
            for (key => value in defaultButtons) gamepadBinds.set(key, value.copy());
        optionsDirty = true;
    }

    public static function clearInvalidKeys(key:String):Void
    {
        var keys = keyBinds.get(key);
        var buttons = gamepadBinds.get(key);
        if (keys != null) while (keys.remove(FlxKey.NONE)) {}
        if (buttons != null) while (buttons.remove(FlxGamepadInputID.NONE)) {}
    }

    inline public static function getGameplaySetting(name:String, defaultValue:Dynamic = null, ?customDefaultValue:Bool = false):Dynamic
    {
        if (!customDefaultValue) defaultValue = defaultData.gameplaySettings.get(name);
        return data.gameplaySettings.exists(name) ? data.gameplaySettings.get(name) : defaultValue;
    }

    public static function reloadVolumeKeys():Void
    {
        TitleState.muteKeys = keyBinds.get('volume_mute').copy();
        TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
        TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
        toggleVolumeKeys(true);
    }

    public static function toggleVolumeKeys(?turnOn:Bool = true):Void
    {
        FlxG.sound.muteKeys = turnOn ? TitleState.muteKeys : [];
        FlxG.sound.volumeDownKeys = turnOn ? TitleState.volumeDownKeys : [];
        FlxG.sound.volumeUpKeys = turnOn ? TitleState.volumeUpKeys : [];
    }

    public static function loadGame(?slot:Int = 0):Bool
    {
        if (!Save.initialize()) return error(Save.lastError);
        if (!Save.load(slot)) return error(Save.lastError);
        currentGameSlot = slot;
        lastSaveError = '';
        return true;
    }

    public static function saveGame(?slot:Int = -1):Bool
    {
        if (!Save.initialize()) return error(Save.lastError);
        var target = slot >= 0 ? slot : currentGameSlot;
        if (Save.currentSlot != target && !Save.load(target))
            return error(Save.lastError);
        if (!Save.save()) return error(Save.lastError);
        currentGameSlot = target;
        lastSaveError = '';
        return true;
    }

    public static function setGameValue(key:String, value:Dynamic):Void
    {
        Save.set(key, value);
    }

    public static function getGameValue(key:String, ?fallback:Dynamic):Dynamic
    {
        var value = Save.get(key);
        return value == null ? fallback : value;
    }
}
