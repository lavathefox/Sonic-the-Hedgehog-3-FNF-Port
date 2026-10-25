package mobile;

import flixel.FlxG;
import backend.ClientPrefs;
import backend.MobileControls;

/**
 * Settings that only matter on Android: touch cursor, controls opacity,
 * vibration and "keep screen on".
 *
 * The class compiles on every platform, but everything inside is guarded with
 * "#if android", so it does nothing on PC.
 */
class AndroidOptions
{
	/** Names shown in the menu and the opacity each one means. Same order in both lists. */
	public static final OPACITY_NAMES:Array<String> = ['LOW', 'MEDIUM', 'HIGH', 'FULL'];
	public static final OPACITY_VALUES:Array<Float> = [0.4, 0.65, 0.85, 1.0];

	/** Vibration strength names and how long each pulse lasts (milliseconds). */
	public static final VIBRATION_NAMES:Array<String> = ['OFF', 'LIGHT', 'STRONG'];
	public static final VIBRATION_MS:Array<Int> = [0, 15, 35];

	/** Every option saved by the mobile options menu. */
	public static final SAVED_FIELDS:Array<String> = [
		'mobileShowHitbox',
		'mobilePauseButton',
		'mobileTouchCursor',
		'mobileControlsOpacity',
		'mobileVibration',
		'mobileKeepScreenOn'
	];

	static var loaded:Bool = false;

	/** Keeps a saved number inside a list (0 to length - 1). */
	public static function clampIndex(value:Int, length:Int):Int
	{
		if (value < 0)
			return 0;

		if (value >= length)
			return length - 1;

		return value;
	}

	/** Vibration pulse length for the current setting (0 = vibration off). */
	public static function vibrationMs():Int
	{
		return VIBRATION_MS[clampIndex(ClientPrefs.data.mobileVibration, VIBRATION_MS.length)];
	}

	/**
	 * Copies the saved mobile options into ClientPrefs.data.
	 * This port's title screen does not call ClientPrefs.loadPrefs(), so without this
	 * the options would go back to their defaults every time the game is opened.
	 * Only the mobile options are loaded, so nothing else changes.
	 */
	public static function loadSaved():Void
	{
		#if android
		if (loaded)
			return;

		loaded = true;

		if (FlxG.save == null || FlxG.save.data == null)
			return;

		for (key in SAVED_FIELDS)
		{
			if (Reflect.hasField(FlxG.save.data, key))
				Reflect.setField(ClientPrefs.data, key, Reflect.field(FlxG.save.data, key));
		}
		#end
	}

	/** Puts the current options into effect. Call it after any of them changes. */
	public static function apply():Void
	{
		#if android
		MobileControls.setControlsOpacity(OPACITY_VALUES[clampIndex(ClientPrefs.data.mobileControlsOpacity, OPACITY_VALUES.length)]);
		DeviceUtil.setKeepScreenOn(ClientPrefs.data.mobileKeepScreenOn);
		MobileControls.applyMobileOptions();
		#end
	}
}
