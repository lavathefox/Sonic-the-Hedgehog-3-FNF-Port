package save;

import haxe.Json;
import haxe.crypto.Sha256;
import haxe.io.Path;
import haxe.Timer;
import StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

class Save
{
    public static var directory(default, null):String = "";
    public static var currentSlot(default, null):Int = -1;
    public static var data(default, null):Dynamic = {};
    public static var dirty(default, null):Bool = false;
    public static var autoSaveInterval:Float = 30;
    public static var lastError(default, null):String = "";

    static inline var VERSION:Int = 1;
    static var elapsedSinceSave:Float = 0;

    public static function initialize(?folder:String):Bool
    {
        #if sys
        try
        {
            directory = folder != null && folder.length > 0
                ? Path.addTrailingSlash(folder)
                : Path.addTrailingSlash(Path.join([Sys.getCwd(), "saves"]));
            if (!FileSystem.exists(directory))
                FileSystem.createDirectory(directory);
            return true;
        }
        catch (e:Dynamic)
        {
            return fail(Std.string(e));
        }
        #else
        return fail("File saves require a sys target");
        #end
    }

    public static function load(slot:Int = 0):Bool
    {
        if (!validSlot(slot) || !ready())
            return false;

        #if sys
        var primary = slotPath(slot);
        var backup = primary + ".bak";
        var loaded:Dynamic = null;
        var found = FileSystem.exists(primary) || FileSystem.exists(backup);

        if (FileSystem.exists(primary))
            loaded = readFile(primary);
        if (loaded == null && FileSystem.exists(backup))
            loaded = readFile(backup);

        if (loaded == null && found)
            return fail("Save and backup are invalid for slot " + slot);

        data = loaded == null ? {} : loaded;
        currentSlot = slot;
        dirty = false;
        elapsedSinceSave = 0;
        lastError = "";
        return true;
        #else
        return false;
        #end
    }

    public static function save():Bool
    {
        if (!ready() || !validSlot(currentSlot))
            return false;

        #if sys
        var primary = slotPath(currentSlot);
        var backup = primary + ".bak";
        var temp = primary + ".tmp";
        try
        {
            var payload = Json.stringify(data);
            var envelope = Json.stringify({
                version: VERSION,
                checksum: Sha256.encode(payload),
                payload: payload
            });

            File.saveContent(temp, envelope);
            if (readFile(temp) == null)
                return fail("Temporary save failed validation");

            if (FileSystem.exists(primary))
            {
                if (readFile(primary) != null)
                {
                    if (FileSystem.exists(backup))
                        FileSystem.deleteFile(backup);
                    FileSystem.rename(primary, backup);
                }
                else
                {
                    var corrupt = primary + ".corrupt";
                    if (FileSystem.exists(corrupt))
                        FileSystem.deleteFile(corrupt);
                    FileSystem.rename(primary, corrupt);
                }
            }

            FileSystem.rename(temp, primary);
            dirty = false;
            elapsedSinceSave = 0;
            lastError = "";
            return true;
        }
        catch (e:Dynamic)
        {
            return fail(Std.string(e));
        }
        #else
        return false;
        #end
    }

    public static function set(key:String, value:Dynamic):Void
    {
        if (key == null || key.length == 0)
            return;
        Reflect.setField(data, key, value);
        dirty = true;
    }

    public static function get(key:String, ?fallback:Dynamic):Dynamic
    {
        if (key == null || !Reflect.hasField(data, key))
            return fallback;
        return Reflect.field(data, key);
    }

    public static function remove(key:String):Bool
    {
        if (key == null || !Reflect.deleteField(data, key))
            return false;
        dirty = true;
        return true;
    }

    public static function has(key:String):Bool
    {
        return key != null && Reflect.hasField(data, key);
    }

    public static function update(elapsed:Float):Void
    {
        if (!dirty || autoSaveInterval <= 0 || elapsed <= 0)
            return;
        elapsedSinceSave += elapsed;
        if (elapsedSinceSave >= autoSaveInterval)
            save();
    }

    public static function deleteSlot(slot:Int):Bool
    {
        if (!validSlot(slot) || !ready())
            return false;
        #if sys
        try
        {
            var path = slotPath(slot);
            for (suffix in ["", ".bak", ".tmp"])
                if (FileSystem.exists(path + suffix))
                    FileSystem.deleteFile(path + suffix);
            if (currentSlot == slot)
            {
                currentSlot = -1;
                data = {};
                dirty = false;
            }
            lastError = "";
            return true;
        }
        catch (e:Dynamic)
        {
            return fail(Std.string(e));
        }
        #else
        return false;
        #end
    }

    public static function slotExists(slot:Int):Bool
    {
        #if sys
        return validSlot(slot) && ready() &&
            (FileSystem.exists(slotPath(slot)) || FileSystem.exists(slotPath(slot) + ".bak"));
        #else
        return false;
        #end
    }

    static function validSlot(slot:Int):Bool
    {
        return slot >= 0 && slot <= 9999;
    }

    static function ready():Bool
    {
        return directory != null && directory.length > 0;
    }

    static function slotPath(slot:Int):String
    {
        return Path.join([directory, "slot_" + slot + ".json"]);
    }

    static function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }

    #if sys
    static function readFile(path:String):Dynamic
    {
        try
        {
            var envelope:Dynamic = Json.parse(File.getContent(path));
            if (envelope == null || envelope.version != VERSION ||
                !Std.isOfType(envelope.payload, String) ||
                !Std.isOfType(envelope.checksum, String))
                return null;
            var payload:String = envelope.payload;
            if (Sha256.encode(payload) != envelope.checksum)
                return null;
            var value:Dynamic = Json.parse(payload);
            if (value == null || !Reflect.isObject(value) || Std.isOfType(value, Array))
                return null;
            return value;
        }
        catch (e:Dynamic)
        {
            return null;
        }
    }
    #end
}
