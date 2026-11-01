package util.files;

import save.Save;
import haxe.Json;

class S3
{
    public static var loaded(default, null):Bool = false;
    public static var slot(default, null):Int = -1;
    public static var lastError(default, null):String = "";

    static inline var KEY:String = "sonic3_progress";
    static inline var VERSION:Int = 1;
    static var progress:Dynamic = null;

    public static function initialize(?folder:String, saveSlot:Int = 0):Bool
    {
        loaded = false;
        if (!Save.initialize(folder))
            return fail(Save.lastError);
        return load(saveSlot);
    }

    public static function load(saveSlot:Int = 0):Bool
    {
        loaded = false;
        if (!Save.load(saveSlot))
            return fail(Save.lastError);

        var stored:Dynamic = Save.get(KEY);
        if (stored == null)
        {
            progress = defaults();
            Save.set(KEY, progress);
        }
        else
        {
            if (!validProgress(stored))
                return fail("Invalid Sonic 3 progress structure");
            progress = stored;
        }

        slot = saveSlot;
        loaded = true;
        lastError = "";
        return true;
    }

    public static function save():Bool
    {
        if (!loaded)
            return fail("Progress is not loaded");
        Save.set(KEY, progress);
        if (!Save.save())
            return fail(Save.lastError);
        lastError = "";
        return true;
    }

    public static function update(elapsed:Float):Void
    {
        if (loaded)
            Save.update(elapsed);
    }

    public static function reset(?saveImmediately:Bool = true):Bool
    {
        if (!loaded)
            return fail("Progress is not loaded");
        progress = defaults();
        touch();
        return !saveImmediately || save();
    }

    public static function setPlayer(name:String):Bool
    {
        if (!loaded || name == null || name.length == 0)
            return false;
        progress.player = name;
        touch();
        return true;
    }

    public static function getPlayer():String
    {
        return loaded ? progress.player : "sonic";
    }

    public static function unlockLevel(level:String):Bool
    {
        if (!loaded || !validId(level))
            return false;
        var levels:Array<String> = progress.unlockedLevels;
        if (!levels.contains(level))
        {
            levels.push(level);
            touch();
        }
        return true;
    }

    public static function isLevelUnlocked(level:String):Bool
    {
        return loaded && validId(level) && (cast progress.unlockedLevels:Array<String>).contains(level);
    }

    public static function completeLevel(level:String, score:Int = 0, rings:Int = 0):Bool
    {
        if (!loaded || !validId(level))
            return false;
        var completed:Array<String> = progress.completedLevels;
        if (!completed.contains(level))
            completed.push(level);
        unlockLevel(level);
        setHighscore(level, score);
        addRings(rings);
        touch();
        return true;
    }

    public static function isLevelCompleted(level:String):Bool
    {
        return loaded && validId(level) && (cast progress.completedLevels:Array<String>).contains(level);
    }

    public static function setHighscore(level:String, score:Int):Bool
    {
        if (!loaded || !validId(level) || score < 0)
            return false;
        var scores:Dynamic = progress.highscores;
        var old:Dynamic = Reflect.field(scores, level);
        if (old == null || score > (cast old:Int))
        {
            Reflect.setField(scores, level, score);
            touch();
        }
        return true;
    }

    public static function getHighscore(level:String):Int
    {
        if (!loaded || !validId(level))
            return 0;
        var score:Dynamic = Reflect.field(progress.highscores, level);
        return score == null ? 0 : cast score;
    }

    public static function addRings(amount:Int):Bool
    {
        if (!loaded || amount < 0)
            return false;
        progress.rings = (cast progress.rings:Int) + amount;
        touch();
        return true;
    }

    public static function getRings():Int
    {
        return loaded ? progress.rings : 0;
    }

    public static function setLives(amount:Int):Bool
    {
        if (!loaded || amount < 0)
            return false;
        progress.lives = amount;
        touch();
        return true;
    }

    public static function getLives():Int
    {
        return loaded ? progress.lives : 3;
    }

    public static function collectEmerald(id:Int):Bool
    {
        if (!loaded || id < 0 || id >= 7)
            return false;
        var emeralds:Array<Int> = progress.emeralds;
        if (!emeralds.contains(id))
        {
            emeralds.push(id);
            touch();
        }
        return true;
    }

    public static function hasEmerald(id:Int):Bool
    {
        return loaded && id >= 0 && id < 7 && (cast progress.emeralds:Array<Int>).contains(id);
    }

    public static function emeraldCount():Int
    {
        return loaded ? (cast progress.emeralds:Array<Int>).length : 0;
    }

    public static function hasAllEmeralds():Bool
    {
        return emeraldCount() == 7;
    }

    public static function unlockCharacter(id:String):Bool
    {
        if (!loaded || !validId(id))
            return false;
        var characters:Array<String> = progress.characters;
        if (!characters.contains(id))
        {
            characters.push(id);
            touch();
        }
        return true;
    }

    public static function isCharacterUnlocked(id:String):Bool
    {
        return loaded && validId(id) && (cast progress.characters:Array<String>).contains(id);
    }

    public static function snapshot():Dynamic
    {
        return loaded ? Json.parse(Json.stringify(progress)) : null;
    }

    static function defaults():Dynamic
    {
        return {
            version: VERSION,
            player: "sonic",
            lives: 3,
            rings: 0,
            emeralds: [],
            unlockedLevels: [],
            completedLevels: [],
            characters: ["sonic"],
            highscores: {}
        };
    }

    static function validProgress(value:Dynamic):Bool
    {
        if (value == null || Reflect.field(value, "version") != VERSION)
            return false;
        if (!Std.isOfType(Reflect.field(value, "player"), String) ||
            !Std.isOfType(Reflect.field(value, "lives"), Int) ||
            !Std.isOfType(Reflect.field(value, "rings"), Int))
            return false;
        for (field in ["emeralds", "unlockedLevels", "completedLevels", "characters"])
            if (!Std.isOfType(Reflect.field(value, field), Array))
                return false;
        var scores = Reflect.field(value, "highscores");
        return scores != null && Reflect.isObject(scores) && !Std.isOfType(scores, Array);
    }

    static function validId(id:String):Bool
    {
        return id != null && id.length > 0 && id.length <= 128 && id != "__proto__";
    }

    static function touch():Void
    {
        Save.set(KEY, progress);
    }

    static function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }
}
