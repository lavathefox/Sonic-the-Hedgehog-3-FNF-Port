package mobile;

import flixel.FlxG;
import backend.ClientPrefs;
import backend.MobileControls;
import objects.Hitbox;

/**
 * Settings that only exist on Android: touch cursor, controls opacity and size,
 * left-handed layout, touch lane look, vibration, keep screen on and brightness.
 *
 * The class compiles on every platform, but everything that does something is
 * guarded with "#if android", so it does nothing on PC.
 */
class AndroidOptions
{
	/** Names shown in the menu and the values they mean. Each pair of lists has the same order. */
	public static final OPACITY_NAMES:Array<String> = ['LOW', 'MEDIUM', 'HIGH', 'FULL'];
	public static final OPACITY_VALUES:Array<Float> = [0.4, 0.65, 0.85, 1.0];

	public static final VIBRATION_NAMES:Array<String> = ['OFF', 'LIGHT', 'STRONG'];
	public static final VIBRATION_MS:Array<Int> = [0, 15, 35];

	/** Look of the touch lanes used during songs. The values are the names Hitbox.style understands. */
	public static final LANE_STYLE_NAMES:Array<String> = ['GRADIENT', 'SOLID', 'OUTLINE'];
	public static final LANE_STYLE_VALUES:Array<String> = ['Gradient', 'Solid', 'Outline'];

	public static final LANE_OPACITY_NAMES:Array<String> = ['LOW', 'MEDIUM', 'HIGH', 'MAX'];
	public static final LANE_OPACITY_VALUES:Array<Float> = [0.2, 0.35, 0.55, 0.8];

	/** Scale of the on-screen arrows and A/B buttons (the default layout uses 3). */
	public static final CONTROLS_SIZE_NAMES:Array<String> = ['SMALL', 'MEDIUM', 'LARGE'];
	public static final CONTROLS_SIZE_VALUES:Array<Float> = [2, 3, 4];

	/** Screen brightness while the game is open. A negative value means "let the phone decide". */
	public static final BRIGHTNESS_NAMES:Array<String> = ['AUTO', 'LOW', 'MEDIUM', 'HIGH'];
	public static final BRIGHTNESS_VALUES:Array<Float> = [-1, 0.25, 0.55, 1.0];

	/** Every option saved by the mobile options menu. */
	public static final SAVED_FIELDS:Array<String> = [
		'mobileShowHitbox',
		'mobilePauseButton',
		'mobileTouchCursor',
		'mobileControlsOpacity',
		'mobileVibration',
		'mobileKeepScreenOn',
		'mobileLaneStyle',
		'mobileLaneOpacity',
		'mobileControlsSize',
		'mobileLeftHanded',
		'mobileBrightness'
	];

	// The layout MobileControls starts with. Keep these in sync with its default positions.
	static inline var DEFAULT_CONTROLS_SCALE:Float = 3;
	static inline var ARROWS_X:Float = 80;
	static inline var ARROWS_Y:Float = 500;
	static inline var BUTTON_A_X:Float = 830;
	static inline var BUTTON_A_Y:Float = 500;
	static inline var BUTTON_B_X:Float = 700;
	static inline var BUTTON_B_Y:Float = 560;

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

	/** Gives the touch lanes their style and opacity. They are read when the lanes are created. */
	public static function applyLaneSettings():Void
	{
		Hitbox.style = LANE_STYLE_VALUES[clampIndex(ClientPrefs.data.mobileLaneStyle, LANE_STYLE_VALUES.length)];
		Hitbox.opacity = LANE_OPACITY_VALUES[clampIndex(ClientPrefs.data.mobileLaneOpacity, LANE_OPACITY_VALUES.length)];
	}

	/** Changes whenever a lane option changes, so MobileControls knows when to rebuild the lanes. */
	public static function laneSignature():String
	{
		return Std.string(ClientPrefs.data.mobileLaneStyle) + '|' + Std.string(ClientPrefs.data.mobileLaneOpacity);
	}

	/** Sets the size of the arrows and A/B buttons and which side of the screen they are on. */
	public static function applyControlsLayout():Void
	{
		#if android
		var arrows = MobileControls.arrows;
		var buttonA = MobileControls.buttonA;
		var buttonB = MobileControls.buttonB;

		if (arrows == null || buttonA == null || buttonB == null)
			return;

		var scale:Float = CONTROLS_SIZE_VALUES[clampIndex(ClientPrefs.data.mobileControlsSize, CONTROLS_SIZE_VALUES.length)];
		MobileControls.setScale(scale, scale);

		// The bottom edges stay where they are at the default size, so bigger controls grow upwards.
		var arrowsY:Float = ARROWS_Y + arrows.frameHeight * (DEFAULT_CONTROLS_SCALE - scale);
		var buttonAY:Float = BUTTON_A_Y + buttonA.frameHeight * (DEFAULT_CONTROLS_SCALE - scale);
		var buttonBY:Float = BUTTON_B_Y + buttonB.frameHeight * (DEFAULT_CONTROLS_SCALE - scale);

		var arrowsX:Float;
		var buttonAX:Float;
		var buttonBX:Float;

		if (!ClientPrefs.data.mobileLeftHanded)
		{
			// Arrows keep their left edge; the buttons keep their right edge. Bigger controls grow towards the middle.
			arrowsX = ARROWS_X;
			buttonAX = BUTTON_A_X + buttonA.frameWidth * (DEFAULT_CONTROLS_SCALE - scale);
			buttonBX = BUTTON_B_X + buttonB.frameWidth * (DEFAULT_CONTROLS_SCALE - scale);
		}
		else
		{
			// Mirror image: arrows on the right, buttons on the left.
			arrowsX = FlxG.width - ARROWS_X - arrows.frameWidth * scale;
			buttonAX = FlxG.width - BUTTON_A_X - buttonA.frameWidth * DEFAULT_CONTROLS_SCALE;
			buttonBX = FlxG.width - BUTTON_B_X - buttonB.frameWidth * DEFAULT_CONTROLS_SCALE;
		}

		MobileControls.setPosition(arrowsX, arrowsY, buttonAX, buttonAY, buttonBX, buttonBY);
		#end
	}

	/** Puts the current options into effect. Call it after any of them changes. */
	public static function apply():Void
	{
		#if android
		applyLaneSettings();
		applyControlsLayout();
		MobileControls.setControlsOpacity(OPACITY_VALUES[clampIndex(ClientPrefs.data.mobileControlsOpacity, OPACITY_VALUES.length)]);
		DeviceUtil.setKeepScreenOn(ClientPrefs.data.mobileKeepScreenOn);
		DeviceUtil.setBrightness(BRIGHTNESS_VALUES[clampIndex(ClientPrefs.data.mobileBrightness, BRIGHTNESS_VALUES.length)]);
		MobileControls.applyMobileOptions();
		#end
	}
}
