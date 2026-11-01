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
    public static var lastLoadUsedBackup(default, null):Bool = false;
    public static var maxAutoSaveRetries:Int = 3;
    public static var autoSaveRetryDelay:Float = 5;
    public static var onSaved:Void->Void;
    public static var onLoaded:Int->Void;
    public static var onError:String->Void;

    static var consecutiveFailures:Int = 0;
    static var writing:Bool = false;

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
            createDirectories(directory);
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

        lastLoadUsedBackup = false;
        if (FileSystem.exists(primary))
            loaded = readFile(primary);
        if (loaded == null && FileSystem.exists(backup))
        {
            loaded = readFile(backup);
            lastLoadUsedBackup = loaded != null;
        }

        if (loaded == null && found)
            return fail("Save and backup are invalid for slot " + slot);

        data = loaded == null ? {} : loaded;
        currentSlot = slot;
        dirty = false;
        elapsedSinceSave = 0;
        lastError = "";
        consecutiveFailures = 0;
        if (onLoaded != null) try onLoaded(slot) catch (_:Dynamic) {}
        return true;
        #else
        return false;
        #end
    }

    public static function save():Bool
    {
        if (!ready() || !validSlot(currentSlot) || writing)
            return false;

        #if sys
        writing = true;
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
                throw "Temporary save failed validation";

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
            consecutiveFailures = 0;
            lastError = "";
            writing = false;
            if (onSaved != null) try onSaved() catch (_:Dynamic) {}
            return true;
        }
        catch (e:Dynamic)
        {
            writing = false;
            consecutiveFailures++;
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
        var wait = consecutiveFailures > 0 ? autoSaveRetryDelay : autoSaveInterval;
        if (consecutiveFailures >= maxAutoSaveRetries && maxAutoSaveRetries > 0)
            return;
        if (elapsedSinceSave >= wait)
        {
            elapsedSinceSave = 0;
            save();
        }
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

    public static function saveIfDirty():Bool
    {
        return !dirty || save();
    }

    public static function resetData():Void
    {
        data = {};
        dirty = true;
        elapsedSinceSave = 0;
    }

    public static function setMany(values:Dynamic):Void
    {
        if (values == null) return;
        for (field in Reflect.fields(values))
            set(field, Reflect.field(values, field));
    }

    public static function getInt(key:String, fallback:Int = 0):Int
    {
        var value = get(key);
        if (value == null) return fallback;
        var parsed = Std.parseInt(Std.string(value));
        return parsed == null ? fallback : parsed;
    }

    public static function getFloat(key:String, fallback:Float = 0):Float
    {
        var value = get(key);
        if (value == null) return fallback;
        var parsed = Std.parseFloat(Std.string(value));
        return Math.isNaN(parsed) ? fallback : parsed;
    }

    public static function getBool(key:String, fallback:Bool = false):Bool
    {
        var value = get(key);
        if (value == null) return fallback;
        if (Std.isOfType(value, Bool)) return value;
        return Std.string(value).toLowerCase() == "true";
    }

    public static function getString(key:String, fallback:String = ""):String
    {
        var value = get(key);
        return value == null ? fallback : Std.string(value);
    }

    public static function increment(key:String, amount:Int = 1):Int
    {
        var result = getInt(key) + amount;
        set(key, result);
        return result;
    }

    public static function copySlot(source:Int, destination:Int):Bool
    {
        if (!validSlot(source) || !validSlot(destination) || !ready()) return false;
        if (source == destination) return true;
        #if sys
        var originalSlot = currentSlot;
        var originalData = data;
        var originalDirty = dirty;
        var originalElapsed = elapsedSinceSave;
        if (!load(source)) return false;
        var copied = Json.parse(Json.stringify(data));
        currentSlot = destination;
        data = copied;
        dirty = true;
        var result = save();
        currentSlot = originalSlot;
        data = originalData;
        dirty = originalDirty;
        elapsedSinceSave = originalElapsed;
        return result;
        #else
        return false;
        #end
    }

    public static function flush():Bool
    {
        return saveIfDirty();
    }

    public static function getSlotPath(slot:Int):String
    {
        return validSlot(slot) && ready() ? slotPath(slot) : "";
    }

    #if sys
    static function createDirectories(path:String):Void
    {
        if (FileSystem.exists(path)) return;
        var parent = Path.directory(path);
        if (parent != null && parent != "" && parent != path && !FileSystem.exists(parent))
            createDirectories(parent);
        FileSystem.createDirectory(path);
    }
    #end

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
        if (onError != null) try onError(message) catch (_:Dynamic) {}
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
