package mobile;

import flixel.FlxG;
import backend.ClientPrefs;
import backend.MobileControls;
import objects.Hitbox;

typedef OptionChoice<T> =
{
	var name:String;
	var value:T;
}

class AndroidOptions
{
	static final OPACITY:Array<OptionChoice<Float>> = [
		{name: 'LOW', value: 0.4},
		{name: 'MEDIUM', value: 0.65},
		{name: 'HIGH', value: 0.85},
		{name: 'FULL', value: 1.0}
	];

	static final VIBRATION:Array<OptionChoice<Int>> = [
		{name: 'OFF', value: 0},
		{name: 'LIGHT', value: 15},
		{name: 'STRONG', value: 35}
	];

	static final LANE_STYLE:Array<OptionChoice<String>> = [
		{name: 'GRADIENT', value: 'Gradient'},
		{name: 'SOLID', value: 'Solid'},
		{name: 'OUTLINE', value: 'Outline'}
	];

	static final LANE_OPACITY:Array<OptionChoice<Float>> = [
		{name: 'LOW', value: 0.2},
		{name: 'MEDIUM', value: 0.35},
		{name: 'HIGH', value: 0.55},
		{name: 'MAX', value: 0.8}
	];

	static final CONTROLS_SIZE:Array<OptionChoice<Float>> = [
		{name: 'SMALL', value: 2},
		{name: 'MEDIUM', value: 3},
		{name: 'LARGE', value: 4}
	];

	static final BRIGHTNESS:Array<OptionChoice<Float>> = [
		{name: 'AUTO', value: -1},
		{name: 'LOW', value: 0.25},
		{name: 'MEDIUM', value: 0.55},
		{name: 'HIGH', value: 1.0}
	];

	public static final OPACITY_NAMES:Array<String> = namesOf(OPACITY);
	public static final OPACITY_VALUES:Array<Float> = valuesOf(OPACITY);

	public static final VIBRATION_NAMES:Array<String> = namesOf(VIBRATION);
	public static final VIBRATION_MS:Array<Int> = valuesOf(VIBRATION);

	public static final LANE_STYLE_NAMES:Array<String> = namesOf(LANE_STYLE);
	public static final LANE_STYLE_VALUES:Array<String> = valuesOf(LANE_STYLE);

	public static final LANE_OPACITY_NAMES:Array<String> = namesOf(LANE_OPACITY);
	public static final LANE_OPACITY_VALUES:Array<Float> = valuesOf(LANE_OPACITY);

	public static final CONTROLS_SIZE_NAMES:Array<String> = namesOf(CONTROLS_SIZE);
	public static final CONTROLS_SIZE_VALUES:Array<Float> = valuesOf(CONTROLS_SIZE);

	public static final BRIGHTNESS_NAMES:Array<String> = namesOf(BRIGHTNESS);
	public static final BRIGHTNESS_VALUES:Array<Float> = valuesOf(BRIGHTNESS);

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

	static inline var DEFAULT_CONTROLS_SCALE:Float = 3;
	static inline var ARROWS_X:Float = 80;
	static inline var ARROWS_Y:Float = 500;
	static inline var BUTTON_A_X:Float = 830;
	static inline var BUTTON_A_Y:Float = 500;
	static inline var BUTTON_B_X:Float = 700;
	static inline var BUTTON_B_Y:Float = 560;

	static var loaded:Bool = false;

	static function namesOf<T>(list:Array<OptionChoice<T>>):Array<String>
	{
		return [for (choice in list) choice.name];
	}

	static function valuesOf<T>(list:Array<OptionChoice<T>>):Array<T>
	{
		return [for (choice in list) choice.value];
	}

	public static function clampIndex(value:Int, length:Int):Int
	{
		if (length <= 0 || value < 0)
			return 0;

		if (value >= length)
			return length - 1;

		return value;
	}

	static inline function pick<T>(list:Array<T>, index:Int):T
	{
		return list[clampIndex(index, list.length)];
	}

	public static function vibrationMs():Int
	{
		return pick(VIBRATION_MS, ClientPrefs.data.mobileVibration);
	}

	public static function controlsOpacity():Float
	{
		return pick(OPACITY_VALUES, ClientPrefs.data.mobileControlsOpacity);
	}

	public static function controlsScale():Float
	{
		return pick(CONTROLS_SIZE_VALUES, ClientPrefs.data.mobileControlsSize);
	}

	public static function brightness():Float
	{
		return pick(BRIGHTNESS_VALUES, ClientPrefs.data.mobileBrightness);
	}

	public static function laneStyle():String
	{
		return pick(LANE_STYLE_VALUES, ClientPrefs.data.mobileLaneStyle);
	}

	public static function laneOpacity():Float
	{
		return pick(LANE_OPACITY_VALUES, ClientPrefs.data.mobileLaneOpacity);
	}

	public static function loadSaved():Void
	{
		#if android
		if (loaded)
			return;

		var save = FlxG.save;
		if (save == null || save.data == null || !save.isBound)
			return;

		loaded = true;

		for (key in SAVED_FIELDS)
		{
			if (!Reflect.hasField(save.data, key))
				continue;

			var value:Dynamic = convertSaved(Reflect.field(save.data, key), Reflect.field(ClientPrefs.data, key));
			if (value != null)
				Reflect.setField(ClientPrefs.data, key, value);
		}

		sanitize();
		#end
	}

	static function convertSaved(stored:Dynamic, current:Dynamic):Dynamic
	{
		if (stored == null)
			return null;

		if (Std.isOfType(current, Bool))
			return Std.isOfType(stored, Bool) ? stored : null;

		if (Std.isOfType(current, Int))
			return Std.isOfType(stored, Float) ? Std.int(stored) : null;

		return stored;
	}

	static function sanitize():Void
	{
		var data = ClientPrefs.data;
		data.mobileControlsOpacity = clampIndex(data.mobileControlsOpacity, OPACITY.length);
		data.mobileVibration = clampIndex(data.mobileVibration, VIBRATION.length);
		data.mobileLaneStyle = clampIndex(data.mobileLaneStyle, LANE_STYLE.length);
		data.mobileLaneOpacity = clampIndex(data.mobileLaneOpacity, LANE_OPACITY.length);
		data.mobileControlsSize = clampIndex(data.mobileControlsSize, CONTROLS_SIZE.length);
		data.mobileBrightness = clampIndex(data.mobileBrightness, BRIGHTNESS.length);
	}

	public static function applyLaneSettings():Void
	{
		Hitbox.style = laneStyle();
		Hitbox.opacity = laneOpacity();
	}

	public static function laneSignature():String
	{
		return laneStyle() + '|' + laneOpacity();
	}

	static inline function growth(size:Float, scale:Float):Float
	{
		return size * (DEFAULT_CONTROLS_SCALE - scale);
	}

	public static function applyControlsLayout():Void
	{
		#if android
		var arrows = MobileControls.arrows;
		var buttonA = MobileControls.buttonA;
		var buttonB = MobileControls.buttonB;

		if (arrows == null || buttonA == null || buttonB == null)
			return;

		var scale:Float = controlsScale();
		MobileControls.setScale(scale, scale);

		var arrowsY:Float = ARROWS_Y + growth(arrows.frameHeight, scale);
		var buttonAY:Float = BUTTON_A_Y + growth(buttonA.frameHeight, scale);
		var buttonBY:Float = BUTTON_B_Y + growth(buttonB.frameHeight, scale);

		var arrowsX:Float;
		var buttonAX:Float;
		var buttonBX:Float;

		if (ClientPrefs.data.mobileLeftHanded)
		{
			arrowsX = FlxG.width - ARROWS_X - arrows.frameWidth * scale;
			buttonAX = FlxG.width - BUTTON_A_X - buttonA.frameWidth * DEFAULT_CONTROLS_SCALE;
			buttonBX = FlxG.width - BUTTON_B_X - buttonB.frameWidth * DEFAULT_CONTROLS_SCALE;
		}
		else
		{
			arrowsX = ARROWS_X;
			buttonAX = BUTTON_A_X + growth(buttonA.frameWidth, scale);
			buttonBX = BUTTON_B_X + growth(buttonB.frameWidth, scale);
		}

		MobileControls.setPosition(arrowsX, arrowsY, buttonAX, buttonAY, buttonBX, buttonBY);
		#end
	}

	public static function apply():Void
	{
		#if android
		applyLaneSettings();
		applyControlsLayout();
		MobileControls.setControlsOpacity(controlsOpacity());
		DeviceUtil.setKeepScreenOn(ClientPrefs.data.mobileKeepScreenOn);
		DeviceUtil.setBrightness(brightness());
		MobileControls.applyMobileOptions();
		#end
	}
}
