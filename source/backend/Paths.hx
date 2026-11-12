package backend;

import flixel.FlxG;
import flixel.FlxSprite;
import backend.Language;
import backend.ClientPrefs;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
#if flxanimate
import flxanimate.FlxAnimate;
#end
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxRect;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.system.System;
import openfl.geom.Rectangle;

import lime.utils.Assets;
import flash.media.Sound;

import haxe.Json;


#if (MODS_ALLOWED && sys)
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if (web || html5) "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/shared/music/freakyMenu.$SOUND_EXT'];
	// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		var stale:Array<String> = [];
		for (key in currentTrackedAssets.keys())
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) stale.push(key);
		for (key in stale)
		{
			destroyGraphic(currentTrackedAssets.get(key));
			currentTrackedAssets.remove(key);
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		#if (MODS_ALLOWED && sys)
		clearDirectoryCache();
		#end

		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory():Void
	{
		var protectedGfx:Array<FlxGraphic> = [];
		var visited:Array<Dynamic> = [];
		function scan(object:Dynamic):Void
		{
			if (object == null || visited.contains(object)) return;
			visited.push(object);
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(object, 'graphic');
				if (gfx != null && !protectedGfx.contains(gfx)) protectedGfx.push(gfx);
				var members:Array<Dynamic> = Reflect.getProperty(object, 'members');
				if (members != null) for (member in members) scan(member);
			}
			catch (e:Dynamic) {}
		}
		if (FlxG.state != null)
		{
			scan(FlxG.state);
			if (FlxG.state.subState != null) scan(FlxG.state.subState);
		}
		var removed:Array<String> = [];
		for (key in currentTrackedAssets.keys())
		{
			var graphic = currentTrackedAssets.get(key);
			if (!dumpExclusions.contains(key) && !protectedGfx.contains(graphic))
			{
				destroyGraphic(graphic);
				removed.push(key);
			}
		}
		for (key in removed) currentTrackedAssets.remove(key);
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		if (graphic != null) FlxG.bitmap.remove(graphic);
	}

	public static function clearAllTrackedSounds():Void
	{
		var keys:Array<String> = [];
		for (key in currentTrackedSounds.keys()) keys.push(key);
		for (key in keys)
		{
			Assets.cache.clear(key);
			currentTrackedSounds.remove(key);
		}
	}

	public static function invalidateAssetCache():Void
	{
		localTrackedAssets = [];
		#if (MODS_ALLOWED && sys)
		clearDirectoryCache();
		#end
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name == null ? null : name.toLowerCase();

	public static function normalizeKey(key:String):String
	{
		if (key == null)
			return key;

		key = StringTools.trim(StringTools.replace(key, '\\', '/'));

		while (key.indexOf('//') != -1)
			key = StringTools.replace(key, '//', '/');

		while (StringTools.startsWith(key, './'))
			key = key.substr(2);

		return key;
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentfolder:String, ?modsAllowed:Bool = true):String
	{
		file = normalizeKey(file);
		parentfolder = normalizeKey(parentfolder);

		#if (MODS_ALLOWED && sys)
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if (FileSystem.exists(modded)) return modded;

			#if sys
			var resolvedModded:String = resolveModPathCaseInsensitive(modded);
			if (resolvedModded != null && FileSystem.exists(resolvedModded))
			{
				trace('MOD PATH CASE FALLBACK: ' + modded + ' -> ' + resolvedModded);
				return resolvedModded;
			}
			#end
		}
		#end

		if (parentfolder != null)
			return getFolderPath(file, parentfolder);

		if (currentLevel != null && currentLevel != 'shared')
		{
			var levelPath = getFolderPath(file, currentLevel);
			if (OpenFlAssets.exists(levelPath, type))
				return levelPath;
		}
		return getSharedPath(file);
	}

	#if (MODS_ALLOWED && sys)
	static var directoryCache:Map<String, Map<String, String>> = new Map();

	public static function clearDirectoryCache():Void
	{
		directoryCache = new Map();
	}

	static function listDirectory(directory:String):Map<String, String>
	{
		var cached:Map<String, String> = directoryCache.get(directory);

		if (cached != null)
			return cached;

		var listing:Map<String, String> = new Map();

		for (entry in FileSystem.readDirectory(directory))
		{
			var lower:String = entry.toLowerCase();
			
			if (!listing.exists(lower))
				listing.set(lower, entry);
		}

		directoryCache.set(directory, listing);
		return listing;
	}

	static function resolveModPathCaseInsensitive(path:String):String
	{
		if (path == null || path.length == 0)
			return null;

		try
		{
			var absolute:Bool = StringTools.startsWith(path, '/');
			var current:String = absolute ? '/' : '';
			var parts:Array<String> = path.split('/');

			for (part in parts)
			{
				if (part == null || part.length == 0 || part == '.')
					continue;

				if (part == '..')
				{
					current = haxe.io.Path.normalize(current + '/../');
					continue;
				}

				var directory:String = current.length == 0 ? '.' : current;
				if (!FileSystem.exists(directory) || !FileSystem.isDirectory(directory))
					return null;

				var match:String = listDirectory(directory).get(part.toLowerCase());

				if (match == null)
					return null;

				if (current == '')
					current = match;
				else if (current == '/')
					current += match;
				else
					current += '/' + match;
			}

			return current;
		}
		catch (e:Dynamic)
		{
			trace('MOD PATH RESOLVE ERROR: ' + path + ' | ' + Std.string(e));
			return null;
		}
	}
	#end

	static var reportedProblems:Map<String, Bool> = new Map();
	static var reportedCount:Int = 0;

	static function currentModName():String
	{
		#if (MODS_ALLOWED && sys)
		return Mods.currentModDirectory;
		#else
		return '';
		#end
	}

	public static function reportAssetProblem(kind:String, key:String, detail:String):Void
	{
		#if (android && sys)
		var id:String = kind + '|' + key;

		if (reportedProblems.exists(id) || reportedCount >= 300)
			return;

		reportedProblems.set(id, true);
		reportedCount++;

		try
		{
			var output = reportedCount == 1 ? File.write('asset_problems.txt', false) : File.append('asset_problems.txt', false);

			if (reportedCount == 1)
				output.writeString('Assets that failed to load. Each line: type, key, details.\n');

			output.writeString(kind + '  ' + key + '  |  ' + detail + '  |  mod: ' + currentModName() + '\n');
			output.close();
		}
		catch (e:Dynamic) {}
		#end
	}

	inline static public function getFolderPath(file:String, folder = "shared")
		return 'assets/$folder/$file';

	inline public static function getSharedPath(file:String = '')
		return 'assets/shared/$file';

	inline static public function txt(key:String, ?folder:String)
		return getPath('data/$key.txt', TEXT, folder, true);

	inline static public function xml(key:String, ?folder:String)
		return getPath('data/$key.xml', TEXT, folder, true);

	inline static public function json(key:String, ?folder:String)
		return getPath('data/$key.json', TEXT, folder, true);

	inline static public function shaderFragment(key:String, ?folder:String)
		return getPath('shaders/$key.frag', TEXT, folder, true);

	inline static public function shaderVertex(key:String, ?folder:String)
		return getPath('shaders/$key.vert', TEXT, folder, true);

	inline static public function lua(key:String, ?folder:String)
		return getPath('$key.lua', TEXT, folder, true);

	static public function video(key:String)
	{
		#if (MODS_ALLOWED && sys)
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', null, modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', null, modsAllowed);

	inline static public function inst(song:String, ?modsAllowed:Bool = true):Sound
		return returnSound('${formatToSongPath(song)}/Inst', 'songs', modsAllowed);

	inline static public function voices(song:String, postfix:String = null, ?modsAllowed:Bool = true):Sound
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if(postfix != null) songKey += '-' + postfix;
		//trace('songKey test: $songKey');
		return returnSound(songKey, 'songs', modsAllowed, false);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?modsAllowed:Bool = true)
		return sound(key + FlxG.random.int(min, max), modsAllowed);

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	static public function image(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxGraphic
	{
		key = Language.getFileTranslation('images/' + normalizeKey(key)) + '.png';
		var resolved:String = getPath(key, IMAGE, parentFolder, true);
		var cacheKey:String = resolved;
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(cacheKey))
		{
			localTrackedAssets.push(cacheKey);
			return currentTrackedAssets.get(cacheKey);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		var file:String = getPath(key, IMAGE, parentFolder, true);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		if (bitmap == null)
		{
			#if (MODS_ALLOWED && sys)
			if (FileSystem.exists(file))
			{
				try
				{
					bitmap = BitmapData.fromFile(file);
				}
				catch (e:Dynamic)
				{
					trace('BITMAP ERROR: File.load failed for ' + file + ' | ' + Std.string(e));
				}
			}
			#end

			if (bitmap == null)
			{
				try
				{
					if (OpenFlAssets.exists(file, IMAGE))
						bitmap = OpenFlAssets.getBitmapData(file);
				}
				catch (e:Dynamic)
				{
					trace('BITMAP ERROR: OpenFL.load failed for ' + file + ' | ' + Std.string(e));
				}
			}

			if (bitmap == null)
			{
				trace('BITMAP ERROR: Bitmap not found or unreadable: ' + file + ' | key: ' + key);
				reportAssetProblem('IMAGE', key, 'not found or unreadable, looked for: ' + file);
				return null;
			}
		}

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null && FlxG.stage != null && FlxG.stage.context3D != null)
		{
			bitmap.lock();
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			bitmap.image.data = null;
			bitmap.image = null;
			bitmap.readable = true;
		}

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(file, graph);
		localTrackedAssets.push(file);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, null, !ignoreMods);
		#if sys
		if (FileSystem.exists(path) && !FileSystem.isDirectory(path))
			return File.getContent(path);
		return OpenFlAssets.exists(path, TEXT) ? OpenFlAssets.getText(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if (MODS_ALLOWED && sys)
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if (MODS_ALLOWED && sys)
		if(!ignoreMods)
		{
			var modKey:String = normalizeKey(key);
			if(parentFolder == 'songs') modKey = 'songs/$modKey';

			if (FileSystem.exists(modFolders(modKey)))
				return true;
		}
		#end
		var file:String = getPath(key, type, parentFolder, false);
		#if sys
		if (FileSystem.exists(file)) return true;
		#end
		return OpenFlAssets.exists(file, type);
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var xmlPath:String = getPath('images/$key.xml', TEXT, parentFolder, true);
		var jsonPath:String = getPath('images/$key.json', TEXT, parentFolder, true);
		if (imageLoaded == null) return null;

		#if (MODS_ALLOWED && sys)
		if (FileSystem.exists(xmlPath))
		{
			var xmlContent:String = File.getContent(xmlPath);
			if (imageLoaded == null || xmlContent == null || xmlContent.length == 0)
			{
				trace('ATLAS ERROR: Sparrow key=' + key + ' image=' + (imageLoaded == null ? 'NULL' : 'OK') + ' xml=' + xmlPath);
				reportAssetProblem('ATLAS', key, 'image=' + (imageLoaded == null ? 'missing' : 'ok') + ', xml=' + xmlPath + (xmlContent == null || xmlContent.length == 0 ? ' (empty)' : ''));
				return null;
			}
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
		}
		#end
		if (imageLoaded != null && OpenFlAssets.exists(xmlPath, TEXT))
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlPath);

		#if (MODS_ALLOWED && sys)
		if (FileSystem.exists(jsonPath))
		{
			var jsonContent:String = File.getContent(jsonPath);
			if (imageLoaded == null || jsonContent == null || jsonContent.length == 0)
			{
				trace('ATLAS ERROR: TexturePacker key=' + key + ' image=' + (imageLoaded == null ? 'NULL' : 'OK') + ' json=' + jsonPath);
				reportAssetProblem('ATLAS', key, 'image=' + (imageLoaded == null ? 'missing' : 'ok') + ', json=' + jsonPath + (jsonContent == null || jsonContent.length == 0 ? ' (empty)' : ''));
				return null;
			}
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonContent);
		}
		#end
		if (imageLoaded != null && OpenFlAssets.exists(jsonPath, TEXT))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonPath);

		return getPackerAtlas(key, parentFolder, allowGPU);
	}
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		if (keys == null || keys.length == 0) return null;
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(StringTools.trim(keys[0]), parentFolder, allowGPU);
		if (parentFrames == null) return null;
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(StringTools.trim(keys[i]), parentFolder, allowGPU);
				if(extraFrames != null)
					parentFrames.addAtlas(extraFrames, true);
			}
		}
		return parentFrames;
	}

	inline static public function getSparrowAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var xmlPath:String = getPath(Language.getFileTranslation('images/$key') + '.xml', TEXT, parentFolder, true);
		#if (MODS_ALLOWED && sys)
		if (FileSystem.exists(xmlPath))
		{
			var xmlContent:String = File.getContent(xmlPath);
			if (imageLoaded == null || xmlContent == null || xmlContent.length == 0)
			{
				trace('ATLAS ERROR: key=' + key + ' image=' + (imageLoaded == null ? 'NULL' : 'OK') + ' xml=' + xmlPath + ' xmlLength=' + (xmlContent == null ? -1 : xmlContent.length));
				reportAssetProblem('ATLAS', key, 'image=' + (imageLoaded == null ? 'missing' : 'ok') + ', xml=' + xmlPath + (xmlContent == null || xmlContent.length == 0 ? ' (empty)' : ''));
				return null;
			}
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlContent);
		}
		#end
		if (imageLoaded != null && OpenFlAssets.exists(xmlPath, TEXT))
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlPath);
		trace('ATLAS ERROR: Sparrow XML not found: ' + xmlPath + ' (key=' + key + ')');
		reportAssetProblem('ATLAS', key, 'Sparrow XML not found: ' + xmlPath);
		return null;
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var txtPath:String = getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder, true);
		#if (MODS_ALLOWED && sys)
		if (FileSystem.exists(txtPath))
		{
			var txtContent:String = File.getContent(txtPath);
			if (imageLoaded == null || txtContent == null || txtContent.length == 0)
			{
				trace('ATLAS ERROR: Packer key=' + key + ' image=' + (imageLoaded == null ? 'NULL' : 'OK') + ' txt=' + txtPath);
				reportAssetProblem('ATLAS', key, 'image=' + (imageLoaded == null ? 'missing' : 'ok') + ', txt=' + txtPath + (txtContent == null || txtContent.length == 0 ? ' (empty)' : ''));
				return null;
			}
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, txtContent);
		}
		#end
		if (imageLoaded != null && OpenFlAssets.exists(txtPath, TEXT))
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, txtPath);
		trace('ATLAS ERROR: Packer TXT not found: ' + txtPath + ' (key=' + key + ')');
		reportAssetProblem('ATLAS', key, 'no .xml/.json/.txt atlas found, last tried: ' + txtPath);
		return null;
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var jsonPath:String = getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder, true);
		#if (MODS_ALLOWED && sys)
		if (FileSystem.exists(jsonPath))
		{
			var jsonContent:String = File.getContent(jsonPath);
			if (imageLoaded == null || jsonContent == null || jsonContent.length == 0)
			{
				trace('ATLAS ERROR: JSON key=' + key + ' image=' + (imageLoaded == null ? 'NULL' : 'OK') + ' json=' + jsonPath);
				reportAssetProblem('ATLAS', key, 'image=' + (imageLoaded == null ? 'missing' : 'ok') + ', json=' + jsonPath + (jsonContent == null || jsonContent.length == 0 ? ' (empty)' : ''));
				return null;
			}
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonContent);
		}
		#end
		if (imageLoaded != null && OpenFlAssets.exists(jsonPath, TEXT))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonPath);
		trace('ATLAS ERROR: Aseprite JSON not found: ' + jsonPath + ' (key=' + key + ')');
		reportAssetProblem('ATLAS', key, 'Aseprite JSON not found: ' + jsonPath);
		return null;
	}

	inline static public function formatToSongPath(path:String) {
		final invalidChars = ~/[~&;:<>#\s]/g;
		final hideChars = ~/[.,'"%?!]/g;

		return hideChars.replace(invalidChars.replace(path, '-'), '').trim().toLowerCase();
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	#if html5
	static var soundIdIndex:Map<String, String> = null;
	static var missingSounds:Map<String, Bool> = new Map();

	static function buildSoundIdIndex():Void
	{
		soundIdIndex = new Map();
		for (type in [AssetType.SOUND, AssetType.MUSIC])
		{
			var ids:Array<String> = OpenFlAssets.list(type);
			if (ids == null) continue;
			for (id in ids)
				soundIdIndex.set(id.toLowerCase(), id);
		}
	}

	static function resolveSoundId(file:String):String
	{
		if (OpenFlAssets.exists(file, SOUND))
			return file;

		if (soundIdIndex == null)
			buildSoundIdIndex();

		var dot:Int = file.lastIndexOf('.');
		var baseName:String = dot > -1 ? file.substr(0, dot) : file;
		var otherExt:String = SOUND_EXT == 'mp3' ? 'ogg' : 'mp3';

		for (ext in [SOUND_EXT, otherExt])
		{
			var found:String = soundIdIndex.get((baseName + '.' + ext).toLowerCase());
			if (found != null)
				return found;
		}
		return null;
	}
	#end

	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true):Sound
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.' + SOUND_EXT, SOUND, path, modsAllowed);
		if (currentTrackedSounds.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		var result:Sound = null;
		try
		{
			#if sys
			if (FileSystem.exists(file) && !FileSystem.isDirectory(file))
				result = Sound.fromFile(file);
			#end
			#if html5
			if (result == null)
			{
				var id:String = resolveSoundId(file);
				if (id != null)
					result = OpenFlAssets.getSound(id);
			}
			#else
			if (result == null && OpenFlAssets.exists(file, SOUND))
				result = OpenFlAssets.getSound(file);
			#end
		}
		catch (e:Dynamic)
		{
			reportAssetProblem('SOUND', key, Std.string(e));
		}
		if (result == null)
		{
			reportAssetProblem('SOUND', key, 'not found: ' + file);
			#if html5
			// Never play the Flixel beep on the web: log the missing file once and stay silent instead.
			if (!missingSounds.exists(file))
			{
				missingSounds.set(file, true);
				trace('[Paths] Sound not found in the HTML5 manifest: ' + file + ' (key: ' + key + ')');
			}
			return null;
			#else
			return beepOnNull ? FlxAssets.getSound('flixel/sounds/beep') : null;
			#end
		}
		currentTrackedSounds.set(file, result);
		localTrackedAssets.push(file);
		return result;
	}

	#if (MODS_ALLOWED && sys)
	inline static public function mods(key:String = '')
		return 'mods/' + key;

	inline static public function modsJson(key:String)
		return modFolders('data/' + key + '.json');

	inline static public function modsVideo(key:String)
		return modFolders('videos/' + key + '.' + VIDEO_EXT);

	inline static public function modsSounds(path:String, key:String)
		return modFolders(path + '/' + key + '.' + SOUND_EXT);

	inline static public function modsImages(key:String)
		return modFolders('images/' + key + '.png');

	inline static public function modsXml(key:String)
		return modFolders('images/' + key + '.xml');

	inline static public function modsTxt(key:String)
		return modFolders('images/' + key + '.txt');

	inline static public function modsImagesJson(key:String)
		return modFolders('images/' + key + '.json');

	static public function modFolders(key:String)
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;

			#if sys
			var resolved:String = resolveModPathCaseInsensitive(fileToCheck);
			if (resolved != null && FileSystem.exists(resolved))
			{
				trace('MOD FILE CASE FALLBACK: ' + fileToCheck + ' -> ' + resolved);
				return resolved;
			}
			#end
		}

		for (mod in Mods.getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck))
				return fileToCheck;

			#if sys
			var resolved:String = resolveModPathCaseInsensitive(fileToCheck);
			if (resolved != null && FileSystem.exists(resolved))
			{
				trace('MOD FILE CASE FALLBACK: ' + fileToCheck + ' -> ' + resolved);
				return resolved;
			}
			#end
		}
		return 'mods/' + key;
	}
	#end

	public static function getCacheStats():Dynamic
	{
		var images:Int = 0;
		var sounds:Int = 0;
		for (key in currentTrackedAssets.keys()) images++;
		for (key in currentTrackedSounds.keys()) sounds++;
		return {images: images, sounds: sounds, localReferences: localTrackedAssets.length};
	}

	public static function precacheImages(keys:Array<String>, ?parentFolder:String = null):Int
	{
		if (keys == null) return 0;
		var loaded:Int = 0;
		for (key in keys)
		{
			if (key != null && key.length > 0 && image(key, parentFolder) != null) loaded++;
		}
		return loaded;
	}

	public static function precacheSounds(keys:Array<String>, ?musicAssets:Bool = false):Int
	{
		if (keys == null) return 0;
		var loaded:Int = 0;
		for (key in keys)
		{
			if (key == null || key.length == 0) continue;
			var audio:Sound = musicAssets ? music(key) : sound(key);
			if (audio != null) loaded++;
		}
		return loaded;
	}

	public static function hasAsset(key:String, ?type:AssetType = TEXT, ?parentFolder:String = null):Bool
	{
		if (key == null || key.length == 0) return false;
		return fileExists(normalizeKey(key), type, false, parentFolder);
	}

	public static function resetAssetDiagnostics():Void
	{
		reportedProblems = new Map();
		reportedCount = 0;
	}

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null):Void
	{
		if (spr == null || folderOrImg == null) return;
		try
		{
			spr.loadAtlas(folderOrImg);
		}
		catch (e:Dynamic)
		{
			reportAssetProblem('ANIMATE', Std.string(folderOrImg), Std.string(e));
		}
	}
	#end
}
