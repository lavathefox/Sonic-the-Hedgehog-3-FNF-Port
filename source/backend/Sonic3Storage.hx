package backend;

import haxe.io.Path;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.utils.Assets;
#if android
import lime.system.JNI;
#end

/**
 * Creates the ".Sonic3Funkin" storage folder (with a "mods" folder inside)
 * on the Android internal storage and can copy the mods bundled in the APK
 * into it.
 *
 * Usage (call once at startup, before the game reads any mod files):
 *
 *   Sonic3Storage.ensureFolders();
 *   Sonic3Storage.copyBundledMods(); // optional
 *
 * Notes:
 * - Writing to /storage/emulated/0 needs the storage permission
 *   ("All files access" on Android 11+). Without it, every function
 *   here fails safely and returns false / 0 instead of crashing.
 * - On non-Android targets nothing is created; the working directory is used.
 */
class Sonic3Storage
{
	public static inline var FOLDER_NAME:String = '.Sonic3Funkin';

	/** Root folder, always ending with "/". */
	public static function getRoot():String
	{
		#if android
		return '/storage/emulated/0/' + FOLDER_NAME + '/';
		#elseif sys
		return Sys.getCwd();
		#else
		return './';
		#end
	}

	/** Mods folder, always ending with "/". */
	public static function getModsFolder():String
	{
		return getRoot() + 'mods/';
	}

	/**
	 * True when the app may write to the shared storage
	 * ("All files access" on Android 11+, the storage permission below that).
	 * Needs project/StorageHelper.java to be part of the Android build.
	 */
	public static function hasPermission():Bool
	{
		#if android
		try
		{
			var check:Dynamic = JNI.createStaticMethod('me/funkin/sonic3/StorageHelper', 'hasAllFilesAccess', '()Z');
			return check();
		}
		catch (e:Dynamic)
		{
			trace('Sonic3Storage: permission check failed -> ' + e);
			return false;
		}
		#else
		return true;
		#end
	}

	/**
	 * Opens the system screen (Android 11+) or dialog (Android 6-10) where the
	 * user grants storage access. The user has to relaunch the game afterwards.
	 */
	public static function requestPermission():Void
	{
		#if android
		try
		{
			var request:Dynamic = JNI.createStaticMethod('me/funkin/sonic3/StorageHelper', 'requestAllFilesAccess', '()V');
			request();
		}
		catch (e:Dynamic)
		{
			trace('Sonic3Storage: permission request failed -> ' + e);
		}
		#end
	}

	/**
	 * Creates the root folder and the "mods" folder inside it.
	 *
	 * @param useAsWorkingDirectory If true, also calls Sys.setCwd() on the root
	 *        folder. Leave it false if your Android port already sets the
	 *        working directory in its own StorageUtil.
	 * @return true if both folders exist when the function returns.
	 */
	public static function ensureFolders(useAsWorkingDirectory:Bool = false):Bool
	{
		#if (android && sys)
		try
		{
			createDirectory(getRoot());
			createDirectory(getModsFolder());

			if (useAsWorkingDirectory)
				Sys.setCwd(getRoot());

			return FileSystem.exists(getRoot()) && FileSystem.exists(getModsFolder());
		}
		catch (e:Dynamic)
		{
			trace('Sonic3Storage: could not create ' + getModsFolder() + ' -> ' + e
				+ ' (is the storage permission granted?)');
			return false;
		}
		#else
		return true;
		#end
	}

	/**
	 * Copies every asset whose id starts with "mods/" from the APK into the
	 * mods folder. Files that already exist are skipped, so it is safe to call
	 * on every launch.
	 *
	 * This only finds something if the mods are embedded in the APK
	 * (for example with <assets path="mods" ... /> in project.xml).
	 *
	 * @return how many files were copied.
	 */
	public static function copyBundledMods():Int
	{
		#if (android && sys)
		var copied:Int = 0;

		if (!ensureFolders())
			return 0;

		for (id in Assets.list())
		{
			if (!StringTools.startsWith(id, 'mods/'))
				continue;

			var target:String = getRoot() + id;

			try
			{
				if (FileSystem.exists(target))
					continue;

				createDirectory(Path.directory(target));
				File.saveBytes(target, Assets.getBytes(id));
				copied++;
			}
			catch (e:Dynamic)
			{
				trace('Sonic3Storage: failed to copy ' + id + ' -> ' + e);
			}
		}

		trace('Sonic3Storage: copied ' + copied + ' file(s) into ' + getModsFolder());
		return copied;
		#else
		return 0;
		#end
	}

	/** True when the mods folder is missing or has nothing inside it. */
	public static function isModsFolderEmpty():Bool
	{
		#if sys
		try
		{
			var mods:String = getModsFolder();
			return !FileSystem.exists(mods) || FileSystem.readDirectory(mods).length == 0;
		}
		catch (e:Dynamic)
		{
			return true;
		}
		#else
		return false;
		#end
	}

	/** Creates a directory and all of its missing parents. */
	static function createDirectory(path:String):Void
	{
		#if sys
		var clean:String = path;

		while (clean.length > 1 && StringTools.endsWith(clean, '/'))
			clean = clean.substr(0, clean.length - 1);

		if (clean == '' || FileSystem.exists(clean))
			return;

		var parent:String = Path.directory(clean);

		if (parent != '' && parent != clean && !FileSystem.exists(parent))
			createDirectory(parent);

		FileSystem.createDirectory(clean);
		#end
	}
}
