package save;

import haxe.Json;
import haxe.Timer;
import haxe.crypto.Sha256;
import haxe.io.Path;
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
    public static var maxSlots:Int = 10000;
    public static var maxFileBytes:Int = 8 * 1024 * 1024;
    public static var onSaved:Int->Void;
    public static var onLoaded:Int->Void;
    public static var onError:String->Void;

    static inline var VERSION:Int = 1;
    static var elapsedSinceSave:Float = 0;
    static var lastSaveTime:Float = 0;

    public static function initialize(?folder:String):Bool
    {
        #if sys
        try
        {
            var root = folder != null && folder.trim().length > 0
                ? folder : #if mobile lime.system.System.applicationStorageDirectory #else Path.join([Sys.getCwd(), "saves"]) #end;
            if (!FileSystem.exists(root)) FileSystem.createDirectory(root);
            if (!FileSystem.isDirectory(root)) return fail("Save location is not a directory");
            directory = Path.addTrailingSlash(root);
            lastError = "";
            return true;
        }
        catch (e:Dynamic) return fail(Std.string(e));
        #else
        return fail("File saves require a sys target");
        #end
    }

    public static function load(slot:Int = 0):Bool
    {
        if (!checkSlot(slot)) return false;
        #if sys
        var primary = slotPath(slot);
        var backup = primary + ".bak";
        var loaded:Dynamic = readFile(primary);
        if (loaded == null) loaded = readFile(backup);
        if (loaded == null && (FileSystem.exists(primary) || FileSystem.exists(backup)))
            return fail("Save and backup are invalid for slot " + slot);
        data = loaded == null ? {} : loaded;
        currentSlot = slot;
        dirty = false;
        elapsedSinceSave = 0;
        lastError = "";
        if (onLoaded != null) onLoaded(slot);
        return true;
        #else
        return false;
        #end
    }

    public static function save():Bool
    {
        if (!checkSlot(currentSlot)) return false;
        #if sys
        var primary = slotPath(currentSlot);
        var backup = primary + ".bak";
        var temp = primary + ".tmp";
        try
        {
            var encoded = encode(data);
            if (encoded == null) return fail("Unable to serialize save data");
            if (maxFileBytes > 0 && encoded.length > maxFileBytes) return fail("Save exceeds size limit");
            File.saveContent(temp, encoded);
            if (readFile(temp) == null) return fail("Temporary save failed validation");
            if (FileSystem.exists(primary))
            {
                if (readFile(primary) != null)
                {
                    if (FileSystem.exists(backup)) FileSystem.deleteFile(backup);
                    FileSystem.rename(primary, backup);
                }
                else
                {
                    var corrupt = primary + ".corrupt";
                    if (FileSystem.exists(corrupt)) FileSystem.deleteFile(corrupt);
                    FileSystem.rename(primary, corrupt);
                }
            }
            try FileSystem.rename(temp, primary) catch (e:Dynamic)
            {
                if (!FileSystem.exists(primary) && FileSystem.exists(backup))
                    FileSystem.rename(backup, primary);
                throw e;
            }
            dirty = false;
            elapsedSinceSave = 0;
            lastSaveTime = Timer.stamp();
            lastError = "";
            if (onSaved != null) onSaved(currentSlot);
            return true;
        }
        catch (e:Dynamic) return fail(Std.string(e));
        #else
        return false;
        #end
    }

    public static function flush():Bool return !dirty || save();

    public static function switchSlot(slot:Int, saveCurrent:Bool = true):Bool
    {
        if (saveCurrent && !flush()) return false;
        return load(slot);
    }

    public static function set(key:String, value:Dynamic):Void
    {
        if (key == null || key.length == 0) return;
        Reflect.setField(data, key, value);
        dirty = true;
    }

    public static function get(key:String, ?fallback:Dynamic):Dynamic
    {
        if (key == null || !Reflect.hasField(data, key)) return fallback;
        return Reflect.field(data, key);
    }

    public static function has(key:String):Bool return key != null && Reflect.hasField(data, key);

    public static function remove(key:String):Bool
    {
        if (!has(key) || !Reflect.deleteField(data, key)) return false;
        dirty = true;
        return true;
    }

    public static function clear():Void
    {
        data = {};
        dirty = true;
    }

    public static function keys():Array<String> return Reflect.fields(data);

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
        if (Std.isOfType(value, Bool)) return value;
        if (value == "true" || value == 1) return true;
        if (value == "false" || value == 0) return false;
        return fallback;
    }

    public static function getString(key:String, fallback:String = ""):String
    {
        var value = get(key);
        return value == null ? fallback : Std.string(value);
    }

    public static function increment(key:String, amount:Float = 1):Float
    {
        var value = getFloat(key) + amount;
        set(key, value);
        return value;
    }

    public static function update(elapsed:Float):Void
    {
        if (!dirty || autoSaveInterval <= 0 || Math.isNaN(elapsed) || elapsed <= 0) return;
        elapsedSinceSave += elapsed;
        if (elapsedSinceSave >= autoSaveInterval)
        {
            if (!save()) elapsedSinceSave = 0;
        }
    }

    public static function slotExists(slot:Int):Bool
    {
        #if sys
        return validSlot(slot) && ready() && (FileSystem.exists(slotPath(slot)) || FileSystem.exists(slotPath(slot) + ".bak"));
        #else
        return false;
        #end
    }

    public static function listSlots():Array<Int>
    {
        var result:Array<Int> = [];
        #if sys
        if (!ready()) return result;
        try
        {
            var seen:Map<Int, Bool> = new Map();
            for (name in FileSystem.readDirectory(directory))
            {
                var match = ~/^slot_([0-9]+)\.json(\.bak)?$/;
                if (!match.match(name)) continue;
                var id = Std.parseInt(match.matched(1));
                if (id != null && validSlot(id) && !seen.exists(id))
                {
                    seen.set(id, true);
                    result.push(id);
                }
            }
            result.sort(function(a, b) return a - b);
        }
        catch (e:Dynamic) fail(Std.string(e));
        #end
        return result;
    }

    public static function deleteSlot(slot:Int):Bool
    {
        if (!checkSlot(slot)) return false;
        #if sys
        try
        {
            var path = slotPath(slot);
            for (suffix in ["", ".bak", ".tmp", ".corrupt"])
                if (FileSystem.exists(path + suffix)) FileSystem.deleteFile(path + suffix);
            if (currentSlot == slot)
            {
                currentSlot = -1;
                data = {};
                dirty = false;
                elapsedSinceSave = 0;
            }
            lastError = "";
            return true;
        }
        catch (e:Dynamic) return fail(Std.string(e));
        #else
        return false;
        #end
    }

    public static function copySlot(from:Int, to:Int, overwrite:Bool = false):Bool
    {
        if (!checkSlot(from) || !checkSlot(to)) return false;
        if (from == to) return fail("Source and destination are the same slot");
        if (!overwrite && slotExists(to)) return fail("Destination slot already exists");
        #if sys
        var value = readFile(slotPath(from));
        if (value == null) value = readFile(slotPath(from) + ".bak");
        if (value == null) return fail("Source slot is missing or invalid");
        var oldSlot = currentSlot;
        var oldData = data;
        var oldDirty = dirty;
        var oldElapsed = elapsedSinceSave;
        currentSlot = to;
        data = value;
        dirty = true;
        var ok = save();
        currentSlot = oldSlot;
        data = oldData;
        dirty = oldDirty;
        elapsedSinceSave = oldElapsed;
        return ok;
        #else
        return false;
        #end
    }

    public static function exportJSON(pretty:Bool = true):String
    {
        try return Json.stringify(data, null, pretty ? "  " : null) catch (e:Dynamic)
        {
            fail(Std.string(e));
            return "";
        }
    }

    public static function importJSON(json:String, merge:Bool = false):Bool
    {
        try
        {
            var parsed:Dynamic = Json.parse(json);
            if (!isRecord(parsed)) return fail("Imported data must be a JSON object");
            if (merge)
            {
                for (key in Reflect.fields(parsed)) Reflect.setField(data, key, Reflect.field(parsed, key));
            }
            else data = parsed;
            dirty = true;
            lastError = "";
            return true;
        }
        catch (e:Dynamic) return fail(Std.string(e));
    }

    public static function getLastSaveTime():Float return lastSaveTime;

    static function validSlot(slot:Int):Bool return slot >= 0 && slot < maxSlots;
    static function ready():Bool return directory != null && directory.length > 0;

    static function checkSlot(slot:Int):Bool
    {
        if (!ready()) return fail("Save system is not initialized");
        if (!validSlot(slot)) return fail("Invalid save slot: " + slot);
        return true;
    }

    static function slotPath(slot:Int):String return Path.join([directory, "slot_" + slot + ".json"]);

    static function fail(message:String):Bool
    {
        lastError = message;
        if (onError != null) onError(message);
        return false;
    }

    static function isRecord(value:Dynamic):Bool
    {
        return value != null && Reflect.isObject(value) && !Std.isOfType(value, Array) && !Std.isOfType(value, String);
    }

    static function encode(value:Dynamic):String
    {
        try
        {
            if (!isRecord(value)) return null;
            var payload = Json.stringify(value);
            return Json.stringify({version: VERSION, checksum: Sha256.encode(payload), payload: payload});
        }
        catch (e:Dynamic) return null;
    }

    #if sys
    static function readFile(path:String):Dynamic
    {
        try
        {
            if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) return null;
            if (maxFileBytes > 0 && FileSystem.stat(path).size > maxFileBytes) return null;
            var envelope:Dynamic = Json.parse(File.getContent(path));
            if (envelope == null || envelope.version != VERSION ||
                !Std.isOfType(envelope.payload, String) || !Std.isOfType(envelope.checksum, String)) return null;
            var payload:String = envelope.payload;
            if (Sha256.encode(payload) != envelope.checksum) return null;
            var value:Dynamic = Json.parse(payload);
            return isRecord(value) ? value : null;
        }
        catch (e:Dynamic) return null;
    }
    #end
}
