package mobile;

import mobile.backend.HapticsUtil;

#if android
import lime.system.JNI;
#end

class DeviceUtil
{
	#if android
	static inline var HELPER:String = 'me/funkin/sonic3/DeviceHelper';

	static var methods:Map<String, Dynamic> = new Map();
	static var broken:Map<String, Bool> = new Map();
	#end

	public static function vibrate(milliseconds:Int):Void
	{
		if (milliseconds <= 0)
			return;

		#if (android || ios)
		HapticsUtil.vibrate(milliseconds, 1, true);
		#elseif html5
		try
		{
			js.Browser.navigator.vibrate(milliseconds);
		}
		catch (e:Dynamic) {}
		#end
	}

	public static function tap():Void
	{
		#if (android || ios)
		HapticsUtil.tap();
		#end
	}

	public static function setBrightness(value:Float):Void
	{
		#if android
		callHelper('setBrightness', '(F)V', [value]);
		#end
	}

	public static function setKeepScreenOn(value:Bool):Void
	{
		#if android
		callHelper('setKeepScreenOn', '(Z)V', [value]);
		#end
	}

	#if android
	static function callHelper(name:String, signature:String, args:Array<Dynamic>):Void
	{
		if (broken.exists(name))
			return;

		try
		{
			var method:Dynamic = methods.get(name);

			if (method == null)
			{
				method = JNI.createStaticMethod(HELPER, name, signature);
				methods.set(name, method);
			}

			Reflect.callMethod(null, method, args);
		}
		catch (e:Dynamic)
		{
			broken.set(name, true);
			trace('DeviceUtil: "$name" is not available -> ' + e);
		}
	}
	#end
}
