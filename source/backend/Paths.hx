package backend;

import flixel.FlxSprite;
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


#if MODS_ALLOWED
import backend.Mods;
#end

@:access(openfl.display.BitmapData)
class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
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
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				destroyGraphic(currentTrackedAssets.get(key)); // get rid of the graphic
				currentTrackedAssets.remove(key); // and remove the key from local cache map
			}
		}

		// run the garbage collector for good measure lmfao
		System.gc();
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	@:access(flixel.system.frontEnds.BitmapFrontEnd._cache)
	public static function clearStoredMemory()
	{
		// Folder listings used by the case-insensitive lookup may be outdated (files can be copied after startup).
		#if (MODS_ALLOWED && sys)
		clearDirectoryCache();
		#end

		// clear anything not in the tracked assets list
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedAssets.exists(key))
				destroyGraphic(FlxG.bitmap.get(key));
		}

		// clear all sounds that are cached
		for (key => asset in currentTrackedSounds)
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && asset != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static function freeGraphicsFromMemory()
	{
		var protectedGfx:Array<FlxGraphic> = [];
		function checkForGraphics(spr:Dynamic)
		{
			try
			{
				var grp:Array<Dynamic> = Reflect.getProperty(spr, 'members');
				if(grp != null)
				{
					//trace('is actually a group');
					for (member in grp)
					{
						checkForGraphics(member);
					}
					return;
				}
			}

			//trace('check...');
			try
			{
				var gfx:FlxGraphic = Reflect.getProperty(spr, 'graphic');
				if(gfx != null)
				{
					protectedGfx.push(gfx);
					//trace('gfx added to the list successfully!');
				}
			}
			//catch(haxe.Exception) {}
		}

		for (member in FlxG.state.members)
			checkForGraphics(member);

		if(FlxG.state.subState != null)
			for (member in FlxG.state.subState.members)
				checkForGraphics(member);

		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!dumpExclusions.contains(key))
			{
				var graphic:FlxGraphic = currentTrackedAssets.get(key);
				if(!protectedGfx.contains(graphic))
				{
					destroyGraphic(graphic); // get rid of the graphic
					currentTrackedAssets.remove(key); // and remove the key from local cache map
					//trace('deleted $key');
				}
			}
		}
	}

	inline static function destroyGraphic(graphic:FlxGraphic)
	{
		// free some gpu memory
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null)
			graphic.bitmap.__texture.dispose();
		FlxG.bitmap.remove(graphic);
	}

	static public var currentLevel:String;
	static public function setCurrentLevel(name:String)
		currentLevel = name.toLowerCase();

	/**
	 * Cleans an asset key coming from a script or a mod: Windows-style backslashes,
	 * repeated slashes, a leading "./" and surrounding spaces are fixed.
	 * Those only worked on Windows, so they are a common reason for missing sprites on Android.
	 */
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

		#if MODS_ALLOWED
		if(modsAllowed)
		{
			var customFile:String = file;
			if (parentfolder != null) customFile = '$parentfolder/$file';

			var modded:String = modFolders(customFile);
			if (FileSystem.exists(modded)) return modded;

			// Android storage is case-sensitive, unlike many Windows setups.
			// Resolve each path component without changing the stored filename.
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
	// Lowercase name -> real name, per folder. Reading a big folder (like images/) on every
	// failed lookup is slow on phones, so each listing is read once and kept.
	static var directoryCache:Map<String, Map<String, String>> = new Map();

	/** Forgets the cached folder listings (called when the memory is cleared and after files are copied). */
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

			// If two names only differ by case, keep the first one.
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
		#if MODS_ALLOWED
		return Mods.currentModDirectory;
		#else
		return '';
		#end
	}

	/**
	 * Android only: writes a line to asset_problems.txt (in the working directory, next to the
	 * mods folder) the first time an asset fails to load or looks risky, so the exact name can be
	 * read with a file manager. The file is replaced on every launch.
	 *
	 * @param kind IMAGE, ATLAS or SOUND.
	 */
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
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function sound(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('sounds/$key', modsAllowed);

	inline static public function music(key:String, ?modsAllowed:Bool = true):Sound
		return returnSound('music/$key', modsAllowed);

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
		var bitmap:BitmapData = null;
		if (currentTrackedAssets.exists(key))
		{
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		return cacheBitmap(key, parentFolder, bitmap, allowGPU);
	}

	public static function cacheBitmap(key:String, ?parentFolder:String = null, ?bitmap:BitmapData, ?allowGPU:Bool = true):FlxGraphic
	{
		if (bitmap == null)
		{
			var file:String = getPath(key, IMAGE, parentFolder, true);
			#if MODS_ALLOWED
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

		if (allowGPU && ClientPrefs.data.cacheOnGPU && bitmap.image != null)
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

		var graph:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		graph.persist = true;
		graph.destroyOnNoUse = false;

		currentTrackedAssets.set(key, graph);
		localTrackedAssets.push(key);
		return graph;
	}

	inline static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		var path:String = getPath(key, TEXT, !ignoreMods);
		#if sys
		return (FileSystem.exists(path)) ? File.getContent(path) : null;
		#else
		return (OpenFlAssets.exists(path, TEXT)) ? Assets.getText(path) : null;
		#end
	}

	inline static public function font(key:String)
	{
		var folderKey:String = Language.getFileTranslation('fonts/$key');
		#if MODS_ALLOWED
		var file:String = modFolders(folderKey);
		if(FileSystem.exists(file)) return file;
		#end
		return 'assets/$folderKey';
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?parentFolder:String = null)
	{
		#if MODS_ALLOWED
		if(!ignoreMods)
		{
			var modKey:String = normalizeKey(key);
			if(parentFolder == 'songs') modKey = 'songs/$modKey';

			// modFolders checks the current mod, the global mods and mods/<key>,
			// including the case-insensitive lookup used on Android.
			if (FileSystem.exists(modFolders(modKey)))
				return true;
		}
		#end
		return (OpenFlAssets.exists(getPath(key, type, parentFolder, false)));
	}

	static public function getAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var xmlPath:String = getPath('images/$key.xml', TEXT, parentFolder, true);
		var jsonPath:String = getPath('images/$key.json', TEXT, parentFolder, true);

		#if MODS_ALLOWED
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
		if (OpenFlAssets.exists(xmlPath, TEXT))
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlPath);

		#if MODS_ALLOWED
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
		if (OpenFlAssets.exists(jsonPath, TEXT))
			return FlxAtlasFrames.fromTexturePackerJson(imageLoaded, jsonPath);

		return getPackerAtlas(key, parentFolder, allowGPU);
	}
	static public function getMultiAtlas(keys:Array<String>, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		
		var parentFrames:FlxAtlasFrames = Paths.getAtlas(keys[0].trim());
		if(keys.length > 1)
		{
			var original:FlxAtlasFrames = parentFrames;
			parentFrames = new FlxAtlasFrames(parentFrames.parent);
			parentFrames.addAtlas(original, true);
			for (i in 1...keys.length)
			{
				var extraFrames:FlxAtlasFrames = Paths.getAtlas(keys[i].trim(), parentFolder, allowGPU);
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
		#if MODS_ALLOWED
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
		if (OpenFlAssets.exists(xmlPath, TEXT))
			return FlxAtlasFrames.fromSparrow(imageLoaded, xmlPath);
		trace('ATLAS ERROR: Sparrow XML not found: ' + xmlPath + ' (key=' + key + ')');
		reportAssetProblem('ATLAS', key, 'Sparrow XML not found: ' + xmlPath);
		return null;
	}

	inline static public function getPackerAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var txtPath:String = getPath(Language.getFileTranslation('images/$key') + '.txt', TEXT, parentFolder, true);
		#if MODS_ALLOWED
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
		if (OpenFlAssets.exists(txtPath, TEXT))
			return FlxAtlasFrames.fromSpriteSheetPacker(imageLoaded, txtPath);
		trace('ATLAS ERROR: Packer TXT not found: ' + txtPath + ' (key=' + key + ')');
		reportAssetProblem('ATLAS', key, 'no .xml/.json/.txt atlas found, last tried: ' + txtPath);
		return null;
	}

	inline static public function getAsepriteAtlas(key:String, ?parentFolder:String = null, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		var imageLoaded:FlxGraphic = image(key, parentFolder, allowGPU);
		var jsonPath:String = getPath(Language.getFileTranslation('images/$key') + '.json', TEXT, parentFolder, true);
		#if MODS_ALLOWED
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
		if (OpenFlAssets.exists(jsonPath, TEXT))
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
	public static function returnSound(key:String, ?path:String, ?modsAllowed:Bool = true, ?beepOnNull:Bool = true)
	{
		var file:String = getPath(Language.getFileTranslation(key) + '.$SOUND_EXT', SOUND, path, modsAllowed);

		//trace('precaching sound: $file');
		if(!currentTrackedSounds.exists(file))
		{
			#if android
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#elseif sys
			if(FileSystem.exists(file))
				currentTrackedSounds.set(file, Sound.fromFile(file));
			#else
			if(OpenFlAssets.exists(file, SOUND))
				currentTrackedSounds.set(file, OpenFlAssets.getSound(file));
			#end
			else if(beepOnNull)
			{
				trace('SOUND NOT FOUND: $key, PATH: $path');
				FlxG.log.error('SOUND NOT FOUND: $key, PATH: $path');
				reportAssetProblem('SOUND', key, 'not found, looked for: ' + file);
				return FlxAssets.getSound('flixel/sounds/beep');
			}
		}
		localTrackedAssets.push(file);
		return currentTrackedSounds.get(file);
	}

	#if MODS_ALLOWED
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
		// Resolve the active mod first. On Android, exact-case checks can fail
		// even when the file exists, and falling back to mods/<key> loses the
		// active mod's directory entirely.
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

	#if flxanimate
	public static function loadAnimateAtlas(spr:FlxAnimate, folderOrImg:Dynamic, spriteJson:Dynamic = null, animationJson:Dynamic = null)
	{
		var changedAnimJson = false;
		var changedAtlasJson = false;
		var changedImage = false;
		
		if(spriteJson != null)
		{
			changedAtlasJson = true;
			spriteJson = File.getContent(spriteJson);
		}

		if(animationJson != null) 
		{
			changedAnimJson = true;
			animationJson = File.getContent(animationJson);
		}

		// is folder or image path
		if(Std.isOfType(folderOrImg, String))
		{
			var originalPath:String = folderOrImg;
			for (i in 0...10)
			{
				var st:String = '$i';
				if(i == 0) st = '';

				if(!changedAtlasJson)
				{
					spriteJson = getTextFromFile('images/$originalPath/spritemap$st.json');
					if(spriteJson != null)
					{
						//trace('found Sprite Json');
						changedImage = true;
						changedAtlasJson = true;
						folderOrImg = image('$originalPath/spritemap$st');
						break;
					}
				}
				else if(fileExists('images/$originalPath/spritemap$st.png', IMAGE))
				{
					//trace('found Sprite PNG');
					changedImage = true;
					folderOrImg = image('$originalPath/spritemap$st');
					break;
				}
			}

			if(!changedImage)
			{
				//trace('Changing folderOrImg to FlxGraphic');
				changedImage = true;
				folderOrImg = image(originalPath);
			}

			if(!changedAnimJson)
			{
				//trace('found Animation Json');
				changedAnimJson = true;
				animationJson = getTextFromFile('images/$originalPath/Animation.json');
			}
		}

		//trace(folderOrImg);
		//trace(spriteJson);
		//trace(animationJson);
		spr.loadAtlasEx(folderOrImg, spriteJson, animationJson);
	}
	#end
}
