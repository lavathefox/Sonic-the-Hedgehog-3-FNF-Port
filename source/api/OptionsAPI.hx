package api;

import haxe.Json;

class OptionsAPI
{
	static var getters:Map<String, Void->Dynamic> = new Map();
	static var setters:Map<String, Dynamic->Void> = new Map();
	static var listeners:Array<String->Dynamic->Void> = [];

	public static function register(id:String, getter:Void->Dynamic, setter:Dynamic->Void):Void
	{
		getters.set(id, getter);
		setters.set(id, setter);
	}

	public static function unregister(id:String):Void
	{
		getters.remove(id);
		setters.remove(id);
	}

	public static function has(id:String):Bool
	{
		return getters.exists(id);
	}

	public static function list():Array<String>
	{
		var ids:Array<String> = [for (id in getters.keys()) id];
		ids.sort(function(a:String, b:String):Int return a < b ? -1 : (a > b ? 1 : 0));
		return ids;
	}

	public static function get(id:String, ?fallback:Dynamic):Dynamic
	{
		var getter:Void->Dynamic = getters.get(id);
		return getter == null ? fallback : getter();
	}

	public static function set(id:String, value:Dynamic):Bool
	{
		var setter:Dynamic->Void = setters.get(id);

		if (setter == null)
			return false;

		try
		{
			setter(value);
		}
		catch (e:Dynamic)
		{
			trace('OptionsAPI: could not set ' + id + ' -> ' + e);
			return false;
		}

		return true;
	}

	public static function notifyChanged(id:String, value:Dynamic):Void
	{
		for (listener in listeners.copy())
			listener(id, value);
	}

	public static function addListener(listener:String->Dynamic->Void):Void
	{
		if (listeners.indexOf(listener) == -1)
			listeners.push(listener);
	}

	public static function removeListener(listener:String->Dynamic->Void):Void
	{
		listeners.remove(listener);
	}

	public static function snapshot():Dynamic
	{
		var result:Dynamic = {};

		for (id in list())
			Reflect.setField(result, id, get(id));

		return result;
	}

	public static function toJson(pretty:Bool = false):String
	{
		return Json.stringify(snapshot(), null, pretty ? '  ' : null);
	}
}
