package backend;

#if sys
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.media.Sound;
import sys.FileSystem;
import sys.io.File;

class FS
{

	public static inline function exists(path:String):Bool
		return FileSystem.exists(PlatformUtil.toFileSystemPath(path));

	public static inline function isDirectory(path:String):Bool
		return FileSystem.isDirectory(PlatformUtil.toFileSystemPath(path));

	public static inline function readDirectory(path:String):Array<String>
		return FileSystem.readDirectory(PlatformUtil.toFileSystemPath(path));

	public static inline function getContent(path:String):String
		return File.getContent(PlatformUtil.toFileSystemPath(path));

	public static inline function getBytes(path:String):Bytes
		return File.getBytes(PlatformUtil.toFileSystemPath(path));

	public static inline function loadBitmap(path:String):BitmapData
		return BitmapData.fromFile(PlatformUtil.toFileSystemPath(path));

	public static inline function loadSound(path:String):Sound
		return Sound.fromFile(PlatformUtil.toFileSystemPath(path));

	public static inline function saveContent(path:String, content:String):Void
		File.saveContent(PlatformUtil.toWritablePath(path), content);

	public static inline function saveBytes(path:String, bytes:Bytes):Void
		File.saveBytes(PlatformUtil.toWritablePath(path), bytes);

	public static function createDirectory(path:String):Void
	{
		var target:String = PlatformUtil.toWritablePath(path);

		if (FileSystem.exists(target))
			return;

		var parts:Array<String> = target.split('/');
		var current:String = '';

		for (part in parts)
		{
			if (part.length == 0)
			{
				current += '/';
				continue;
			}

			current += (current.length == 0 || StringTools.endsWith(current, '/') ? '' : '/') + part;

			if (StringTools.endsWith(part, ':'))
				continue;

			if (!FileSystem.exists(current))
				FileSystem.createDirectory(current);
		}
	}
}
#else
class FS {}
#end
