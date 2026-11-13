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

class Sonic3Storage
{
	public static inline var FOLDER_NAME:String = '.Sonic3Funkin';

	public static function getRoot():String
	{
		#if android
		return '/storage/emulated/0/' + FOLDER_NAME + '/';
		#elseif ios
        return haxe.io.Path.addTrailingSlash(lime.system.System.documentsDirectory);
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

	static final TEXT_EXTENSIONS:Array<String> = ['json', 'xml', 'txt', 'lua', 'hx', 'hxc', 'frag', 'vert', 'csv'];

	static function isTextFile(id:String):Bool
	{
		return TEXT_EXTENSIONS.contains(Path.extension(id).toLowerCase());
	}

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
			if (!StringTools.startsWith(id, 'mods/') && id != 'modsList.txt')
				continue;

			listed++;
			var target:String = getRoot() + id;

			try
			{
				if (!overwrite && FileSystem.exists(target) && FileSystem.stat(target).size > 0)
					continue;

				var bytes = Assets.getBytes(id);

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

		#if MODS_ALLOWED
		Paths.clearDirectoryCache();
		#end

		trace('Sonic3Storage: copied ' + copied + ' of ' + listed + ' bundled file(s) into ' + getModsFolder());
		return copied;
		#else
		return 0;
		#end
	}

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

	public static inline var BUNDLE_REVISION:Int = 3;
	
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
