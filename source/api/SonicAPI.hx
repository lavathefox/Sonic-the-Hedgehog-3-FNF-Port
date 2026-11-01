package api;

import flixel.FlxG;
import haxe.Timer;
import haxe.Json;
import util.files.S3;

class SonicAPI
{
    public static inline var NAME:String = "Sonic 3 FNF Port";
    public static inline var VERSION:String = "0.2.8";
    public static inline var DESIGN_WIDTH:Int = 959;
    public static inline var DESIGN_HEIGHT:Int = 670;

    public static var initialized(default, null):Bool = false;
    public static var sessionStart(default, null):Float = 0;
    public static var lastError(default, null):String = "";

    static var flags:Map<String, Bool> = new Map();
    static var values:Map<String, Dynamic> = new Map();

    public static function initialize():Void
    {
        if (initialized) return;
        sessionStart = Timer.stamp();
        lastError = "";
        initialized = true;
    }

    public static function shutdown():Void
    {
        flags.clear();
        values.clear();
        initialized = false;
    }

    public static function getPlatform():String
    {
        #if android
        return "android";
        #elseif ios
        return "ios";
        #elseif windows
        return "windows";
        #elseif linux
        return "linux";
        #elseif mac
        return "mac";
        #elseif html5
        return "html5";
        #else
        return "unknown";
        #end
    }

    public static function isMobile():Bool
    {
        #if mobile
        return true;
        #else
        return false;
        #end
    }

    public static function getFPS():Int
    {
        return FlxG.game == null ? 0 : FlxG.drawFramerate;
    }

    public static function getWidth():Int
    {
        return FlxG.game == null ? DESIGN_WIDTH : FlxG.width;
    }

    public static function getHeight():Int
    {
        return FlxG.game == null ? DESIGN_HEIGHT : FlxG.height;
    }

    public static function getSessionSeconds():Float
    {
        return initialized ? Math.max(0, Timer.stamp() - sessionStart) : 0;
    }

    public static function getStateName():String
    {
        if (FlxG.state == null) return "";
        return Type.getClassName(Type.getClass(FlxG.state));
    }

    public static function isFullscreen():Bool
    {
        return FlxG.game != null && FlxG.fullscreen;
    }

    public static function setFullscreen(value:Bool):Void
    {
        #if !mobile
        if (FlxG.game != null) FlxG.fullscreen = value;
        #end
    }

    public static function toggleFullscreen():Void
    {
        #if !mobile
        if (FlxG.game != null) FlxG.fullscreen = !FlxG.fullscreen;
        #end
    }

    public static function setFlag(key:String, value:Bool):Void
    {
        if (validKey(key)) flags.set(key, value);
    }

    public static function getFlag(key:String, fallback:Bool = false):Bool
    {
        return validKey(key) && flags.exists(key) ? flags.get(key) : fallback;
    }

    public static function setValue(key:String, value:Dynamic):Void
    {
        if (validKey(key)) values.set(key, value);
    }

    public static function getValue(key:String, ?fallback:Dynamic):Dynamic
    {
        return validKey(key) && values.exists(key) ? values.get(key) : fallback;
    }

    public static function removeValue(key:String):Bool
    {
        return validKey(key) && values.remove(key);
    }

    public static function getProgress():Dynamic
    {
        return S3.loaded ? S3.snapshot() : null;
    }

    public static function getPlayer():String
    {
        return S3.loaded ? S3.getPlayer() : "sonic";
    }

    public static function setPlayer(player:String):Bool
    {
        if (!S3.loaded || !validKey(player)) return fail("Progress is unavailable or player is invalid");
        S3.setPlayer(player);
        lastError = "";
        return true;
    }

    public static function isLevelUnlocked(level:String):Bool
    {
        return S3.loaded && validKey(level) && S3.isLevelUnlocked(level);
    }

    public static function unlockLevel(level:String):Bool
    {
        if (!S3.loaded || !validKey(level)) return fail("Progress is unavailable or level is invalid");
        S3.unlockLevel(level);
        lastError = "";
        return true;
    }

    public static function completeLevel(level:String, score:Int = 0, rings:Int = 0):Bool
    {
        if (!S3.loaded || !validKey(level)) return fail("Progress is unavailable or level is invalid");
        S3.completeLevel(level, score, rings);
        lastError = "";
        return true;
    }

    public static function getHighscore(level:String):Int
    {
        return S3.loaded && validKey(level) ? S3.getHighscore(level) : 0;
    }

    public static function getRings():Int
    {
        return S3.loaded ? S3.getRings() : 0;
    }

    public static function addRings(amount:Int):Bool
    {
        if (!S3.loaded || amount < 0) return fail("Progress is unavailable or ring amount is invalid");
        S3.addRings(amount);
        lastError = "";
        return true;
    }

    public static function getLives():Int
    {
        return S3.loaded ? S3.getLives() : 0;
    }

    public static function getEmeraldCount():Int
    {
        return S3.loaded ? S3.emeraldCount() : 0;
    }

    public static function hasAllEmeralds():Bool
    {
        return S3.loaded && S3.hasAllEmeralds();
    }

    public static function saveProgress():Bool
    {
        if (!S3.loaded) return fail("Progress has not been initialized");
        var success = S3.save();
        lastError = success ? "" : S3.lastError;
        return success;
    }

    public static function getInfo():Dynamic
    {
        return {
            name: NAME,
            version: VERSION,
            platform: getPlatform(),
            mobile: isMobile(),
            width: getWidth(),
            height: getHeight(),
            fps: getFPS(),
            state: getStateName(),
            fullscreen: isFullscreen(),
            sessionSeconds: getSessionSeconds(),
            progressLoaded: S3.loaded
        };
    }

    public static function getInfoJSON():String
    {
        return Json.stringify(getInfo());
    }

    static inline function validKey(key:String):Bool
    {
        return key != null && StringTools.trim(key).length > 0;
    }

    static function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }
}
