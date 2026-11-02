package save.manual;

import save.Save;
import haxe.Json;
import StringTools;

#if sys
import sys.FileSystem;
import sys.io.File;
import haxe.io.Path;
#end

class SaveManualImport
{
    public static var lastError(default, null):String = "";
    public static var lastImportedKeys(default, null):Int = 0;
    public static var maxImportBytes:Int = 8 * 1024 * 1024;
    public static var onImported:Int->Void;
    public static var onError:String->Void;

    public static function validate(json:String):Bool
    {
        lastError = "";
        if (json == null || StringTools.trim(json).length == 0)
            return fail("Import data is empty");
        if (maxImportBytes > 0 && haxe.io.Bytes.ofString(json).length > maxImportBytes)
            return fail("Import exceeds size limit");
        try
        {
            var parsed:Dynamic = Json.parse(json);
            if (parsed == null || !Reflect.isObject(parsed) || Std.isOfType(parsed, Array) || Std.isOfType(parsed, String))
                return fail("Import must contain a JSON object");
            return true;
        }
        catch (error:Dynamic)
        {
            return fail("Invalid JSON: " + Std.string(error));
        }
    }

    public static function previewKeys(json:String):Array<String>
    {
        if (!validate(json)) return [];
        var result = Reflect.fields(Json.parse(json));
        result.sort(Reflect.compare);
        return result;
    }

    public static function importText(json:String, merge:Bool = false, persist:Bool = true):Bool
    {
        lastImportedKeys = 0;
        if (!validate(json)) return false;
        if (Save.currentSlot < 0) return fail("Load a save slot before importing");

        var keys = Reflect.fields(Json.parse(json));
        var previous = Save.exportJSON(false);
        if (previous.length == 0) return fail("Could not back up current save in memory");

        if (!Save.importJSON(json, merge)) return fail(Save.lastError);
        if (persist && !Save.save())
        {
            var error = Save.lastError;
            Save.importJSON(previous, false);
            return fail("Could not write imported save: " + error);
        }

        lastImportedKeys = keys.length;
        lastError = "";
        if (onImported != null) onImported(lastImportedKeys);
        return true;
    }

    public static function exportText(pretty:Bool = true):String
    {
        if (Save.currentSlot < 0)
        {
            fail("Load a save slot before exporting");
            return "";
        }
        return Save.exportJSON(pretty);
    }

    #if sys
    public static function importFile(path:String, merge:Bool = false, persist:Bool = true):Bool
    {
        if (path == null || StringTools.trim(path).length == 0) return fail("No import file specified");
        try
        {
            if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) return fail("Import file does not exist");
            if (maxImportBytes > 0 && FileSystem.stat(path).size > maxImportBytes) return fail("Import exceeds size limit");
            return importText(File.getContent(path), merge, persist);
        }
        catch (error:Dynamic) return fail("Unable to read import file: " + Std.string(error));
    }

    public static function exportFile(path:String, pretty:Bool = true, overwrite:Bool = false):Bool
    {
        if (path == null || StringTools.trim(path).length == 0) return fail("No export file specified");
        var json = exportText(pretty);
        if (json.length == 0) return false;
        try
        {
            if (FileSystem.exists(path) && !overwrite) return fail("Export file already exists");
            var parent = Path.directory(path);
            if (parent.length > 0 && !FileSystem.exists(parent)) return fail("Export directory does not exist");
            File.saveContent(path, json);
            lastError = "";
            return true;
        }
        catch (error:Dynamic) return fail("Unable to export file: " + Std.string(error));
    }
    #else
    public static function importFile(path:String, merge:Bool = false, persist:Bool = true):Bool
        return fail("File import is unavailable on this platform; use importText");

    public static function exportFile(path:String, pretty:Bool = true, overwrite:Bool = false):Bool
        return fail("File export is unavailable on this platform; use exportText");
    #end

    static function fail(message:String):Bool
    {
        lastError = message;
        if (onError != null) onError(message);
        return false;
    }
}
