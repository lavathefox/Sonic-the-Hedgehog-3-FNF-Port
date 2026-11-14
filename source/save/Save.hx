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
    public static var recoveredFromBackup(default, null):Bool = false;
    public static var lastSavedAt(default, null):Float = 0;
    public static var maxFileBytes:Int = 8 * 1024 * 1024;
    public static var onSaved:Int->Void;
    public static var onLoaded:Int->Void;

    static inline var VERSION:Int = 1;
    static var elapsedSinceSave:Float = 0;
    static var saving:Bool = false;

    public static function initialize(?folder:String):Bool
    {
        #if sys
        try
        {
            var target = folder != null && StringTools.trim(folder).length > 0
                ? folder : Path.join([Sys.getCwd(), "saves"]);
            if (!ensureDirectory(target)) return false;
            directory = Path.addTrailingSlash(target);
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #else
        return fail("File saves require a sys target");
        #end
    }

    public static function load(slot:Int = 0):Bool
    {
        if (!validSlot(slot)) return fail("Invalid slot: " + slot);
        if (!ready()) return fail("Save system is not initialized");
        #if sys
        var primary = slotPath(slot);
        var backup = primary + ".bak";
        var temporary = primary + ".tmp";
        var value:Dynamic = null;
        var recovered = false;
        if (FileSystem.exists(primary)) value = readFile(primary);
        if (value == null && FileSystem.exists(backup))
        {
            value = readFile(backup);
            recovered = value != null;
        }
        if (value == null && FileSystem.exists(temporary))
        {
            value = readFile(temporary);
            recovered = value != null;
        }
        if (value == null && (FileSystem.exists(primary) || FileSystem.exists(backup) || FileSystem.exists(temporary)))
            return fail("No valid save or backup for slot " + slot);
        data = value == null ? {} : value;
        currentSlot = slot;
        recoveredFromBackup = recovered;
        dirty = recovered;
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
        if (!ready()) return fail("Save system is not initialized");
        if (!validSlot(currentSlot)) return fail("No active save slot");
        if (saving) return fail("Save already in progress");
        #if sys
        saving = true;
        var primary = slotPath(currentSlot);
        var backup = primary + ".bak";
        var temporary = primary + ".tmp";
        try
        {
            var payload = Json.stringify(data);
            if (payload == null || payload.length == 0 || payload.length > maxFileBytes)
            {
                saving = false;
                return fail("Invalid save payload or size limit exceeded");
            }
            var envelope = Json.stringify({version: VERSION, checksum: Sha256.encode(payload), payload: payload});
            if (envelope.length > maxFileBytes)
            {
                saving = false;
                return fail("Save envelope exceeds size limit");
            }
            File.saveContent(temporary, envelope);
            if (readFile(temporary) == null)
            {
                saving = false;
                return fail("Temporary save failed validation");
            }
            var validPrimary = FileSystem.exists(primary) && readFile(primary) != null;
            if (validPrimary)
            {
                if (FileSystem.exists(backup)) FileSystem.deleteFile(backup);
                FileSystem.rename(primary, backup);
            }
            else if (FileSystem.exists(primary))
            {
                var corrupt = primary + ".corrupt";
                if (FileSystem.exists(corrupt)) FileSystem.deleteFile(corrupt);
                FileSystem.rename(primary, corrupt);
            }
            FileSystem.rename(temporary, primary);
            dirty = false;
            recoveredFromBackup = false;
            elapsedSinceSave = 0;
            lastSavedAt = Timer.stamp();
            lastError = "";
            saving = false;
            if (onSaved != null) onSaved(currentSlot);
            return true;
        }
        catch (error:Dynamic)
        {
            saving = false;
            return fail(Std.string(error));
        }
        #else
        return false;
        #end
    }

    public static function set(key:String, value:Dynamic):Void
    {
        if (key == null || key.length == 0) return;
        if (data == null) data = {};
        Reflect.setField(data, key, value);
        dirty = true;
    }

    public static function get(key:String, ?fallback:Dynamic):Dynamic
    {
        if (key == null || data == null || !Reflect.hasField(data, key)) return fallback;
        return Reflect.field(data, key);
    }

    public static function remove(key:String):Bool
    {
        if (key == null || data == null || !Reflect.deleteField(data, key)) return false;
        dirty = true;
        return true;
    }

    public static function has(key:String):Bool
    {
        return key != null && data != null && Reflect.hasField(data, key);
    }

    public static function clear():Void
    {
        data = {};
        dirty = true;
    }

    public static function setInt(key:String, value:Int):Void set(key, value);
    public static function setFloat(key:String, value:Float):Void set(key, value);
    public static function setBool(key:String, value:Bool):Void set(key, value);
    public static function setString(key:String, value:String):Void set(key, value);

    public static function getInt(key:String, fallback:Int = 0):Int
    {
        var value = get(key);
        return Std.isOfType(value, Int) ? value : fallback;
    }

    public static function getFloat(key:String, fallback:Float = 0):Float
    {
        var value = get(key);
        return Std.isOfType(value, Float) || Std.isOfType(value, Int) ? value : fallback;
    }

    public static function getBool(key:String, fallback:Bool = false):Bool
    {
        var value = get(key);
        return Std.isOfType(value, Bool) ? value : fallback;
    }

    public static function getString(key:String, fallback:String = ""):String
    {
        var value = get(key);
        return Std.isOfType(value, String) ? value : fallback;
    }

    public static function update(elapsed:Float):Void
    {
        if (!dirty || autoSaveInterval <= 0 || elapsed <= 0 || Math.isNaN(elapsed)) return;
        elapsedSinceSave += elapsed;
        if (elapsedSinceSave >= autoSaveInterval)
        {
            elapsedSinceSave = 0;
            save();
        }
    }

    public static function flush():Bool
    {
        return !dirty || save();
    }

    public static function changeSlot(slot:Int, saveCurrent:Bool = true):Bool
    {
        if (!validSlot(slot)) return fail("Invalid slot: " + slot);
        if (saveCurrent && dirty && currentSlot >= 0 && !save()) return false;
        return load(slot);
    }

    public static function deleteSlot(slot:Int):Bool
    {
        if (!validSlot(slot)) return fail("Invalid slot: " + slot);
        if (!ready()) return fail("Save system is not initialized");
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
                recoveredFromBackup = false;
            }
            lastError = "";
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
        #else
        return false;
        #end
    }

    public static function slotExists(slot:Int):Bool
    {
        #if sys
        if (!validSlot(slot) || !ready()) return false;
        var path = slotPath(slot);
        return FileSystem.exists(path) || FileSystem.exists(path + ".bak") || FileSystem.exists(path + ".tmp");
        #else
        return false;
        #end
    }

    public static function slotIsValid(slot:Int):Bool
    {
        #if sys
        if (!validSlot(slot) || !ready()) return false;
        var path = slotPath(slot);
        return readFile(path) != null || readFile(path + ".bak") != null || readFile(path + ".tmp") != null;
        #else
        return false;
        #end
    }

    public static function listSlots(maxSlots:Int = 100):Array<Int>
    {
        var result:Array<Int> = [];
        if (maxSlots < 0) return result;
        var count = maxSlots > 10000 ? 10000 : maxSlots;
        for (slot in 0...count)
            if (slotExists(slot)) result.push(slot);
        return result;
    }

    public static function copySlot(source:Int, destination:Int, overwrite:Bool = false):Bool
    {
        if (!validSlot(source) || !validSlot(destination) || source == destination)
            return fail("Invalid source or destination slot");
        if (!ready()) return fail("Save system is not initialized");
        if (!overwrite && slotExists(destination)) return fail("Destination slot already exists");
        #if sys
        var path = slotPath(source);
        var value = readFile(path);
        if (value == null) value = readFile(path + ".bak");
        if (value == null) value = readFile(path + ".tmp");
        if (value == null) return fail("Source slot is invalid");
        var previousSlot = currentSlot;
        var previousData = data;
        var previousDirty = dirty;
        var previousRecovered = recoveredFromBackup;
        var previousElapsed = elapsedSinceSave;
        currentSlot = destination;
        data = value;
        dirty = true;
        var result = save();
        currentSlot = previousSlot;
        data = previousData;
        dirty = previousDirty;
        recoveredFromBackup = previousRecovered;
        elapsedSinceSave = previousElapsed;
        return result;
        #else
        return false;
        #end
    }

    public static function exportSlot(slot:Int):String
    {
        #if sys
        if (!validSlot(slot) || !ready()) return "";
        var path = slotPath(slot);
        var value = readFile(path);
        if (value == null) value = readFile(path + ".bak");
        if (value == null) value = readFile(path + ".tmp");
        return value == null ? "" : Json.stringify(value);
        #else
        return "";
        #end
    }

    public static function importSlot(slot:Int, json:String, overwrite:Bool = false):Bool
    {
        if (!validSlot(slot) || !ready()) return fail("Invalid slot or uninitialized system");
        if (!overwrite && slotExists(slot)) return fail("Destination slot already exists");
        if (json == null || json.length > maxFileBytes) return fail("Invalid import size");
        var value:Dynamic;
        try
        {
            value = Json.parse(json);
        }
        catch (error:Dynamic)
        {
            return fail("Invalid JSON: " + Std.string(error));
        }
        if (!validData(value)) return fail("Import must contain a JSON object");
        var previousSlot = currentSlot;
        var previousData = data;
        var previousDirty = dirty;
        var previousRecovered = recoveredFromBackup;
        var previousElapsed = elapsedSinceSave;
        currentSlot = slot;
        data = value;
        dirty = true;
        var result = save();
        currentSlot = previousSlot;
        data = previousData;
        dirty = previousDirty;
        recoveredFromBackup = previousRecovered;
        elapsedSinceSave = previousElapsed;
        return result;
    }

    public static function reset():Void
    {
        directory = "";
        currentSlot = -1;
        data = {};
        dirty = false;
        recoveredFromBackup = false;
        elapsedSinceSave = 0;
        lastError = "";
    }

    static function validSlot(slot:Int):Bool return slot >= 0 && slot <= 9999;
    static function ready():Bool return directory != null && directory.length > 0;
    static function slotPath(slot:Int):String return Path.join([directory, "slot_" + slot + ".json"]);

    static function validData(value:Dynamic):Bool
    {
        return value != null && Reflect.isObject(value) && !Std.isOfType(value, Array) && !Std.isOfType(value, String);
    }

    static function fail(message:String):Bool
    {
        lastError = message;
        return false;
    }

    #if sys
    static function ensureDirectory(path:String):Bool
    {
        try
        {
            if (FileSystem.exists(path)) return FileSystem.isDirectory(path);
            var parent = Path.directory(path);
            if (parent != null && parent.length > 0 && parent != path && !FileSystem.exists(parent))
                if (!ensureDirectory(parent)) return false;
            FileSystem.createDirectory(path);
            return true;
        }
        catch (error:Dynamic)
        {
            return fail(Std.string(error));
        }
    }

    static function readFile(path:String):Dynamic
    {
        try
        {
            if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) return null;
            if (FileSystem.stat(path).size > maxFileBytes) return null;
            var envelope:Dynamic = Json.parse(File.getContent(path));
            if (envelope == null || envelope.version != VERSION ||
                !Std.isOfType(envelope.payload, String) || !Std.isOfType(envelope.checksum, String)) return null;
            var payload:String = envelope.payload;
            if (Sha256.encode(payload) != envelope.checksum) return null;
            var value:Dynamic = Json.parse(payload);
            return validData(value) ? value : null;
        }
        catch (error:Dynamic)
        {
            return null;
        }
    }
    #end
}
