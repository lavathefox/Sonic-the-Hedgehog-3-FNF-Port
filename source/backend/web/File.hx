package backend.web;

import haxe.crypto.Base64;
import haxe.io.Bytes;
import js.Browser;
import openfl.utils.Assets;

class File
{
	static inline var PREFIX:String = 'sonic3fnf_vfs:';
	static var memory:Map<String, Bytes> = new Map();

	static function storage():js.html.Storage
	{
		try
		{
			return Browser.getLocalStorage();
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	public static function hasVirtual(path:String):Bool
	{
		var p:String = FileSystem.normalize(path);
		if (memory.exists(p)) return true;
		var ls = storage();
		if (ls != null)
		{
			try
			{
				return ls.getItem(PREFIX + p) != null;
			}
			catch (e:Dynamic) {}
		}
		return false;
	}

	public static function virtualKeys():Array<String>
	{
		var keys:Array<String> = [for (k in memory.keys()) k];
		var ls = storage();
		if (ls != null)
		{
			try
			{
				for (i in 0...ls.length)
				{
					var k:String = ls.key(i);
					if (k != null && StringTools.startsWith(k, PREFIX))
					{
						var name:String = k.substr(PREFIX.length);
						if (keys.indexOf(name) == -1) keys.push(name);
					}
				}
			}
			catch (e:Dynamic) {}
		}
		return keys;
	}

	static function readVirtual(p:String):Bytes
	{
		if (memory.exists(p)) return memory.get(p);
		var ls = storage();
		if (ls != null)
		{
			try
			{
				var item:String = ls.getItem(PREFIX + p);
				if (item != null)
				{
					var bytes:Bytes = Base64.decode(item);
					memory.set(p, bytes);
					return bytes;
				}
			}
			catch (e:Dynamic) {}
		}
		return null;
	}

	public static function deleteVirtual(path:String):Void
	{
		var p:String = FileSystem.normalize(path);
		memory.remove(p);
		var ls = storage();
		if (ls != null)
		{
			try
			{
				ls.removeItem(PREFIX + p);
			}
			catch (e:Dynamic) {}
		}
	}

	public static function getBytes(path:String):Bytes
	{
		var p:String = FileSystem.normalize(path);

		var v:Bytes = readVirtual(p);
		if (v != null) return v;

		if (Assets.exists(p))
		{
			var b:Bytes = cast Assets.getBytes(p);
			if (b != null) return b;
		}

		throw 'File.getBytes: file not found (or not loaded yet): ' + path;
	}

	public static function getContent(path:String):String
	{
		var p:String = FileSystem.normalize(path);

		var v:Bytes = readVirtual(p);
		if (v != null) return v.toString();

		if (Assets.exists(p))
		{
			var text:String = Assets.getText(p);
			if (text != null) return text;
		}

		throw 'File.getContent: file not found (or not loaded yet): ' + path;
	}

	public static function saveBytes(path:String, bytes:Bytes):Void
	{
		var p:String = FileSystem.normalize(path);
		memory.set(p, bytes);

		var ls = storage();
		if (ls != null)
		{
			try
			{
				ls.setItem(PREFIX + p, Base64.encode(bytes));
			}
			catch (e:Dynamic) {} // quota exceeded / private mode: keep it in memory only
		}
	}

	public static function saveContent(path:String, content:String):Void
	{
		saveBytes(path, Bytes.ofString(content == null ? '' : content));
	}

	public static function copy(srcPath:String, dstPath:String):Void
	{
		saveBytes(dstPath, getBytes(srcPath));
	}
}
