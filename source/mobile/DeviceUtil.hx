package mobile;

#if android
import lime.system.JNI;
#end

/**
 * Android-only device features (vibration and keep screen on), done through
 * project/DeviceHelper.java. On other platforms every function does nothing.
 *
 * If the Java file is not part of the build, the calls fail once, print a
 * message and are skipped from then on, so the game never crashes because of it.
 */
class DeviceUtil
{
	#if android
	static inline var HELPER:String = 'me/funkin/sonic3/DeviceHelper';

	static var vibrateMethod:Dynamic = null;
	static var keepScreenMethod:Dynamic = null;
	static var brightnessMethod:Dynamic = null;
	static var unavailable:Bool = false;
	#end

	/** Vibrates for the given time in milliseconds. */
	public static function vibrate(milliseconds:Int):Void
	{
		#if android
		if (unavailable || milliseconds <= 0)
			return;

		try
		{
			if (vibrateMethod == null)
				vibrateMethod = JNI.createStaticMethod(HELPER, 'vibrate', '(I)V');

			vibrateMethod(milliseconds);
		}
		catch (e:Dynamic)
		{
			unavailable = true;
			trace('DeviceUtil: vibration is not available -> ' + e);
		}
		#end
	}

	/** One short pulse, with the strength chosen in the VIBRATION option. */
	public static function tap():Void
	{
		#if android
		vibrate(AndroidOptions.vibrationMs());
		#end
	}

	/** Sets the screen brightness from 0 to 1. A negative value gives control back to the phone (automatic). */
	public static function setBrightness(value:Float):Void
	{
		#if android
		if (unavailable)
			return;

		try
		{
			if (brightnessMethod == null)
				brightnessMethod = JNI.createStaticMethod(HELPER, 'setBrightness', '(F)V');

			brightnessMethod(value);
		}
		catch (e:Dynamic)
		{
			unavailable = true;
			trace('DeviceUtil: brightness is not available -> ' + e);
		}
		#end
	}

	/** Stops the screen from turning off while the game is open. */
	public static function setKeepScreenOn(value:Bool):Void
	{
		#if android
		if (unavailable)
			return;

		try
		{
			if (keepScreenMethod == null)
				keepScreenMethod = JNI.createStaticMethod(HELPER, 'setKeepScreenOn', '(Z)V');

			keepScreenMethod(value);
		}
		catch (e:Dynamic)
		{
			unavailable = true;
			trace('DeviceUtil: keep screen on is not available -> ' + e);
		}
		#end
	}
}
