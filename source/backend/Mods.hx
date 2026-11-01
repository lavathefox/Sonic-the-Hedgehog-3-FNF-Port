package backend;

import haxe.io.Path;
import StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef ModsList = {
    enabled:Array<String>,
    disabled:Array<String>,
    all:Array<String>
};

class Mods
{
    public static var currentModDirectory:String = '';
    public static var updatedOnState:Bool = false;
    public static final ignoreModFolders:Array<String> = [
        'characters', 'custom_events', 'custom_notetypes', 'data', 'songs',
        'music', 'sounds', 'shaders', 'videos', 'images', 'stages',
        'states', 'weeks', 'fonts', 'scripts', 'achievements'
    ];

    private static var globalMods:Array<String> = [];
    private static var cachedList:ModsList = null;

    public static function getGlobalMods():Array<String>
        return globalMods.copy();

    public static function pushGlobalMods():Array<String>
    {
        globalMods = [];
        for (mod in parseList().enabled)
        {
            var pack:Dynamic = getPack(mod);
            if (pack != null && Reflect.field(pack, 'runsGlobally') == true)
                globalMods.push(mod);
        }
        return globalMods.copy();
    }

    public static function getModDirectories():Array<String>
    {
        var result:Array<String> = [];
        #if (MODS_ALLOWED && sys)
        var root = Paths.mods();
        if (FileSystem.exists(root) && FileSystem.isDirectory(root))
        {
            for (name in FileSystem.readDirectory(root))
            {
                if (!validFolder(name)) continue;
                var full = Path.join([root, name]);
                if (FileSystem.isDirectory(full)) result.push(name);
            }
        }
        result.sort(function(a, b) return Reflect.compare(a.toLowerCase(), b.toLowerCase()));
        #end
        return result;
    }

    private static function validFolder(name:String):Bool
    {
        if (name == null || name.length == 0 || name == '.' || name == '..') return false;
        if (name.indexOf('/') >= 0 || name.indexOf('\\') >= 0 || name.indexOf(':') >= 0) return false;
        return !ignoreModFolders.contains(name.toLowerCase());
    }

    private static function readSavedList():ModsList
    {
        var list:ModsList = {enabled: [], disabled: [], all: []};
        #if (MODS_ALLOWED && sys)
        if (FileSystem.exists('modsList.txt'))
        {
            try
            {
                for (line in File.getContent('modsList.txt').split('\n'))
                {
                    var parts = StringTools.trim(line).split('|');
                    var folder = StringTools.trim(parts[0]);
                    if (!validFolder(folder) || list.all.contains(folder)) continue;
                    list.all.push(folder);
                    if (parts.length > 1 && parts[1] == '0') list.disabled.push(folder);
                    else list.enabled.push(folder);
                }
            }
            catch (e:Dynamic) {}
        }
        #end
        return list;
    }

    public static function updateModList():Void
    {
        var saved = readSavedList();
        var installed = getModDirectories();
        var result:ModsList = {enabled: [], disabled: [], all: []};
        for (folder in saved.all)
            if (installed.contains(folder)) addEntry(result, folder, !saved.disabled.contains(folder));
        for (folder in installed)
            if (!result.all.contains(folder)) addEntry(result, folder, true);
        cachedList = result;
        updatedOnState = true;
        saveList(result);
    }

    private static function addEntry(list:ModsList, folder:String, enabled:Bool):Void
    {
        list.all.push(folder);
        if (enabled) list.enabled.push(folder);
        else list.disabled.push(folder);
    }

    public static function parseList():ModsList
    {
        if (!updatedOnState || cachedList == null) updateModList();
        return {
            enabled: cachedList.enabled.copy(),
            disabled: cachedList.disabled.copy(),
            all: cachedList.all.copy()
        };
    }

    public static function saveList(list:ModsList):Bool
    {
        #if (MODS_ALLOWED && sys)
        try
        {
            var lines:Array<String> = [];
            var seen:Array<String> = [];
            for (folder in list.all)
            {
                if (!validFolder(folder) || seen.contains(folder)) continue;
                seen.push(folder);
                lines.push(folder + '|' + (list.disabled.contains(folder) ? '0' : '1'));
            }
            File.saveContent('modsList.txt', lines.join('\n'));
            cachedList = {all: seen, enabled: [], disabled: []};
            for (folder in seen)
            {
                if (list.disabled.contains(folder)) cachedList.disabled.push(folder);
                else cachedList.enabled.push(folder);
            }
            updatedOnState = true;
            pushGlobalMods();
            return true;
        }
        catch (e:Dynamic) return false;
        #else
        return false;
        #end
    }

    public static function setEnabled(folder:String, enabled:Bool):Bool
    {
        var list = parseList();
        if (!list.all.contains(folder)) return false;
        list.enabled.remove(folder);
        list.disabled.remove(folder);
        if (enabled) list.enabled.push(folder);
        else list.disabled.push(folder);
        return saveList(list);
    }

    public static function moveMod(folder:String, index:Int):Bool
    {
        var list = parseList();
        if (!list.all.remove(folder)) return false;
        if (index < 0) index = 0;
        if (index > list.all.length) index = list.all.length;
        list.all.insert(index, folder);
        return saveList(list);
    }

    public static function refresh():Void
    {
        updatedOnState = false;
        updateModList();
        loadTopMod();
    }

    public static function getPack(?folder:String):Dynamic
    {
        #if (MODS_ALLOWED && sys)
        if (folder == null) folder = currentModDirectory;
        if (!validFolder(folder)) return null;
        var path = Paths.mods(folder + '/pack.json');
        if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
        {
            try return tjson.TJSON.parse(File.getContent(path)) catch (e:Dynamic) {}
        }
        #end
        return null;
    }

    public static function loadTopMod():Void
    {
        currentModDirectory = '';
        var enabled = parseList().enabled;
        if (enabled.length > 0) currentModDirectory = enabled[0];
        pushGlobalMods();
    }

    public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true):Array<String>
    {
        var found:Array<String> = [];
        #if sys
        addIfExists(found, Path.join([path, fileToFind]));
        if (Paths.currentLevel != null && Paths.currentLevel != path)
            addIfExists(found, Paths.getFolderPath(fileToFind, Paths.currentLevel));
        #if MODS_ALLOWED
        if (mods)
        {
            for (folder in getGlobalMods())
                addIfExists(found, Paths.mods(folder + '/' + fileToFind));
            addIfExists(found, Paths.mods(fileToFind));
            if (currentModDirectory != null && currentModDirectory.length > 0)
                addIfExists(found, Paths.mods(currentModDirectory + '/' + fileToFind));
        }
        #end
        #end
        return found;
    }

    private static function addIfExists(list:Array<String>, path:String):Void
    {
        #if sys
        if (path != null && FileSystem.exists(path) && !FileSystem.isDirectory(path) && !list.contains(path))
            list.push(path);
        #end
    }

    public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String, allowDuplicates:Bool = false):Array<String>
    {
        if (defaultDirectory == null) defaultDirectory = Paths.getSharedPath();
        defaultDirectory = StringTools.trim(defaultDirectory);
        if (!StringTools.startsWith(defaultDirectory, 'assets/')) defaultDirectory = 'assets/' + defaultDirectory;
        var found = directoriesWithFile(defaultDirectory, path);
        var result:Array<String> = [];
        #if sys
        for (file in found)
        {
            try
            {
                for (line in File.getContent(file).split('\n'))
                {
                    var value = StringTools.trim(line);
                    if (value.length > 0 && (allowDuplicates || !result.contains(value))) result.push(value);
                }
            }
            catch (e:Dynamic) {}
        }
        #end
        return result;
    }

    public static function getStateScripts(stateName:String, ?extension:String = 'hx'):Array<String>
    {
        var result:Array<String> = [];
        #if (MODS_ALLOWED && sys)
        if (stateName == null || stateName.length == 0 || stateName.indexOf('/') >= 0 || stateName.indexOf('\\') >= 0 || stateName.indexOf('..') >= 0)
            return result;
        if (extension != 'hx' && extension != 'hxs') return result;
        var file = 'states/' + stateName + '.' + extension;
        for (mod in parseList().enabled)
            addIfExists(result, Paths.mods(mod + '/' + file));
        addIfExists(result, Paths.mods(file));
        #end
        return result;
    }
}
