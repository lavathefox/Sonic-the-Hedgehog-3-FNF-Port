package backend.web;

import openfl.utils.Assets;

typedef WebFileStat =
{
	var size:Int;
	var atime:Date;
	var mtime:Date;
	var ctime:Date;
}

class FileSystem
{
	static var assetIds:Array<String> = null;
	static var virtualDirs:Map<String, Bool> = new Map();
	public static function normalize(path:String):String
	{
		if (path == null) return '';
		var p:String = StringTools.replace(path, '\\', '/');
		while (p.indexOf('//') != -1) p = StringTools.replace(p, '//', '/');
		while (StringTools.startsWith(p, './')) p = p.substr(2);
		if (p == '.') p = '';
		while (p.length > 0 && StringTools.endsWith(p, '/')) p = p.substr(0, p.length - 1);
		return p;
	}

	static function ids():Array<String>
	{
		if (assetIds == null)
		{
			try { assetIds = Assets.list(); } catch (e:Dynamic) { assetIds = []; }
			if (assetIds == null) assetIds = [];
		}
		return assetIds;
	}

	public static function refreshAssetList():Void
	{
		assetIds = null;
	}

	static function hasChildren(p:String):Bool
	{
		var prefix:String = p + '/';
		for (id in ids())
			if (StringTools.startsWith(id, prefix)) return true;
		for (id in File.virtualKeys())
			if (StringTools.startsWith(id, prefix)) return true;
		for (d in virtualDirs.keys())
			if (StringTools.startsWith(d, prefix)) return true;
		return false;
	}

	public static function exists(path:String):Bool
	{
		var p:String = normalize(path);
		if (p == '') return true;
		if (File.hasVirtual(p)) return true;
		if (virtualDirs.exists(p)) return true;
		try { if (Assets.exists(p)) return true; } catch (e:Dynamic) {}
		return hasChildren(p);
	}

	public static function isDirectory(path:String):Bool
	{
		var p:String = normalize(path);
		if (p == '') return true;
		if (File.hasVirtual(p)) return false;
		if (virtualDirs.exists(p)) return true;
		try { if (Assets.exists(p)) return false; } catch (e:Dynamic) {}
		return hasChildren(p);
	}

	public static function readDirectory(path:String):Array<String>
	{
		var p:String = normalize(path);
		var prefix:String = (p == '') ? '' : p + '/';
		var found:Map<String, Bool> = new Map();

		function consider(id:String):Void
		{
			if (prefix != '' && !StringTools.startsWith(id, prefix)) return;
			var rest:String = id.substr(prefix.length);
			if (rest.length == 0) return;
			var slash:Int = rest.indexOf('/');
			found.set(slash == -1 ? rest : rest.substr(0, slash), true);
		}

		for (id in ids()) consider(id);
		for (id in File.virtualKeys()) consider(id);
		for (d in virtualDirs.keys()) consider(d);

		var result:Array<String> = [for (k in found.keys()) k];
		result.sort(function(a:String, b:String):Int return a < b ? -1 : (a > b ? 1 : 0));
		return result;
	}

	public static function createDirectory(path:String):Void
	{
		var p:String = normalize(path);
		if (p == '') return;
		var current:String = '';
		for (part in p.split('/'))
		{
			current = (current == '') ? part : current + '/' + part;
			virtualDirs.set(current, true);
		}
	}

	public static function deleteDirectory(path:String):Void
	{
		virtualDirs.remove(normalize(path));
	}

	public static function deleteFile(path:String):Void
	{
		File.deleteVirtual(normalize(path));
	}

	public static function rename(path:String, newPath:String):Void
	{
		var from:String = normalize(path);
		var to:String = normalize(newPath);
		if (!File.hasVirtual(from))
			throw 'FileSystem.rename: only files created at runtime can be renamed in the browser: ' + path;
		File.saveBytes(to, File.getBytes(from));
		File.deleteVirtual(from);
	}

	public static function stat(path:String):WebFileStat
	{
		var p:String = normalize(path);
		if (!exists(p))
			throw 'FileSystem.stat: no such file or directory: ' + path;

		var size:Int = 0;
		if (File.hasVirtual(p))
			size = File.getBytes(p).length;
		else
		{
			try
			{
				var b = Assets.getBytes(p);
				if (b != null) size = b.length;
			}
			catch (e:Dynamic) {}
		}

		var now:Date = Date.now();
		return {size: size, atime: now, mtime: now, ctime: now};
	}

	public static function fullPath(path:String):String
	{
		return normalize(path);
	}

	public static function absolutePath(path:String):String
	{
		return normalize(path);
	}
}
