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

	/** File types that are read as text when their bytes come back empty. */
	static final TEXT_EXTENSIONS:Array<String> = ['json', 'xml', 'txt', 'lua', 'hx', 'hxc', 'frag', 'vert', 'csv'];

	static function isTextFile(id:String):Bool
	{
		return TEXT_EXTENSIONS.contains(Path.extension(id).toLowerCase());
	}

	/**
	 * Copies every asset whose id starts with "mods/" (plus "modsList.txt")
	 * from the APK into the .Sonic3Funkin folder.
	 *
	 * - Existing files are kept, unless they are empty (an empty file in the
	 *   mods folder would hide the real one and break JSON/XML parsing).
	 * - Bundled files that are empty or cannot be read are skipped instead of
	 *   being written as 0-byte files.
	 * - Text files that come back empty as bytes are read again as text.
	 * - A summary is written to .Sonic3Funkin/copy_report.txt after every copy,
	 *   so problems can be read with a file manager.
	 *
	 * This only finds something if the mods are embedded in the APK
	 * (for example with <assets path="mods" ... /> in project.xml).
	 *
	 * @param overwrite Replace files that already exist.
	 * @return how many files were copied.
	 */
	public static function copyBundledMods(overwrite:Bool = false):Int
	{
		#if (android && sys)
		var copied:Int = 0;
		var listed:Int = 0;
		var problems:Array<String> = [];

		if (!ensureFolders())
			return 0;

		for (id in Assets.list())
		{
			// Mods live under "mods/"; "modsList.txt" (enabled mods) sits next to that folder.
			if (!StringTools.startsWith(id, 'mods/') && id != 'modsList.txt')
				continue;

			listed++;
			var target:String = getRoot() + id;

			try
			{
				if (!overwrite && FileSystem.exists(target) && FileSystem.stat(target).size > 0)
					continue;

				var bytes = Assets.getBytes(id);

				// Some text assets come back empty as bytes: read them as text instead.
				if ((bytes == null || bytes.length == 0) && isTextFile(id))
				{
					var text:String = Assets.getText(id);

					if (text != null && text.length > 0)
					{
						createDirectory(Path.directory(target));
						File.saveContent(target, text);
						copied++;
						continue;
					}
				}

				if (bytes == null || bytes.length == 0)
				{
					problems.push('EMPTY  ' + id);
					continue;
				}

				createDirectory(Path.directory(target));
				File.saveBytes(target, bytes);

				var written:Int = FileSystem.stat(target).size;

				if (written != bytes.length)
					problems.push('SIZE   ' + id + ' (expected ' + bytes.length + ', wrote ' + written + ')');

				copied++;
			}
			catch (e:Dynamic)
			{
				problems.push('ERROR  ' + id + ' -> ' + e);
			}
		}

		writeCopyReport(listed, copied, problems);
		trace('Sonic3Storage: copied ' + copied + ' of ' + listed + ' bundled file(s) into ' + getModsFolder());
		return copied;
		#else
		return 0;
		#end
	}

	/** Writes .Sonic3Funkin/copy_report.txt with the result of the last copy. */
	static function writeCopyReport(listed:Int, copied:Int, problems:Array<String>):Void
	{
		#if sys
		try
		{
			var lines:Array<String> = [
				'Sonic3Storage copy report',
				'Bundled files found: ' + listed,
				'Files copied: ' + copied,
				'Problems: ' + problems.length,
				''
			];

			var shown:Int = Std.int(Math.min(problems.length, 200));

			for (i in 0...shown)
				lines.push(problems[i]);

			if (problems.length > shown)
				lines.push('... and ' + (problems.length - shown) + ' more');

			File.saveContent(getRoot() + 'copy_report.txt', lines.join('\n'));
		}
		catch (e:Dynamic) {}
		#end
	}

	/** Raise this number whenever example_mods changes and installed games must receive the new files. */
	public static inline var BUNDLE_REVISION:Int = 3;

	/**
	 * Copies the bundled mods when needed: on the first run, when the mods folder
	 * is empty, or when BUNDLE_REVISION was raised (that case replaces existing files).
	 * Remembers the revision in .Sonic3Funkin/.mods_revision.
	 *
	 * @return how many files were copied.
	 */
	public static function syncBundledMods():Int
	{
		#if (android && sys)
		if (!ensureFolders())
			return 0;

		var marker:String = getRoot() + '.mods_revision';
		var current:Int = -1;

		try
		{
			if (FileSystem.exists(marker))
			{
				var parsed:Null<Int> = Std.parseInt(StringTools.trim(File.getContent(marker)));

				if (parsed != null)
					current = parsed;
			}
		}
		catch (e:Dynamic) {}

		var revisionChanged:Bool = current != BUNDLE_REVISION;

		// Same revision and the mods folder already has files: nothing to do.
		if (!revisionChanged && !isModsFolderEmpty())
			return 0;

		var copied:Int = copyBundledMods(revisionChanged);

		// Only remember the revision when something was really copied,
		// so a build without bundled mods does not block a later one.
		if (copied > 0)
		{
			try
			{
				File.saveContent(marker, Std.string(BUNDLE_REVISION));
			}
			catch (e:Dynamic) {}
		}

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
