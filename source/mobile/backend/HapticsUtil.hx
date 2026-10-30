package mobile.backend;

import haxe.Timer;
import mobile.AndroidOptions;

#if android
import lime.system.JNI;
#elseif ios
import lime.ui.Haptic;
#end

enum abstract HapticEffect(Int) to Int
{
	var TICK = 0;
	var CLICK = 1;
	var HEAVY_CLICK = 2;
	var DOUBLE_CLICK = 3;
}

enum abstract HapticFeedback(Int) to Int
{
	var LONG_PRESS = 0;
	var VIRTUAL_KEY = 1;
	var KEYBOARD_TAP = 3;
	var CLOCK_TICK = 4;
	var CONFIRM = 16;
	var REJECT = 17;
}

class HapticsUtil
{
	public static var enabled:Bool = true;
	public static var minInterval:Float = 0.025;

	static var lastPulse:Float = -1;

	#if android
	static inline var HELPER:String = 'me/funkin/sonic3/HapticsHelper';

	static var methods:Map<String, Dynamic> = new Map();
	static var unavailable:Bool = false;
	static var vibratorCache:Null<Bool> = null;
	#end

	public static function isSupported():Bool
	{
		#if android
		if (vibratorCache == null)
			vibratorCache = call('hasVibrator', '()Z', []) == true;
		return vibratorCache;
		#elseif ios
		return true;
		#else
		return false;
		#end
	}

	public static function optionScale():Float
	{
		var strongest:Int = 0;
		for (ms in AndroidOptions.VIBRATION_MS)
		{
			if (ms > strongest)
				strongest = ms;
		}

		return strongest <= 0 ? 0 : AndroidOptions.vibrationMs() / strongest;
	}

	public static function isActive():Bool
	{
		return enabled && optionScale() > 0 && isSupported();
	}

	public static function vibrate(milliseconds:Int, strength:Float = 1, force:Bool = false):Void
	{
		if (milliseconds <= 0 || !consumePulse(force))
			return;

		rawVibrate(milliseconds, toAmplitude(strength));
	}

	public static function pattern(steps:Array<Int>, ?strengths:Array<Float>, force:Bool = false):Void
	{
		if (steps == null || steps.length == 0 || !consumePulse(force))
			return;

		rawPattern(steps, strengths);
	}

	public static function play(effect:HapticEffect, force:Bool = false):Void
	{
		if (!consumePulse(force))
			return;

		#if android
		if (optionScale() >= 1 && call('playEffect', '(I)Z', [effect]) == true)
			return;
		#end

		switch (effect)
		{
			case TICK:
				rawVibrate(10, toAmplitude(0.5));
			case CLICK:
				rawVibrate(20, toAmplitude(0.8));
			case HEAVY_CLICK:
				rawVibrate(40, toAmplitude(1));
			case DOUBLE_CLICK:
				rawPattern([18, 70, 18], [0.8, 0.8]);
		}
	}

	public static function feedback(type:HapticFeedback):Void
	{
		if (!enabled || optionScale() <= 0)
			return;

		#if android
		call('performFeedback', '(I)V', [type]);
		#elseif ios
		Haptic.vibrate(0, 15);
		#end
	}

	public static function cancel():Void
	{
		#if android
		call('cancel', '()V', []);
		#end
	}

	public static function tap():Void
	{
		var milliseconds:Int = AndroidOptions.vibrationMs();
		if (milliseconds <= 0 || !consumePulse(false))
			return;

		rawVibrate(milliseconds, 255);
	}

	public static inline function light():Void
	{
		play(TICK);
	}

	public static inline function medium():Void
	{
		play(CLICK);
	}

	public static inline function heavy():Void
	{
		play(HEAVY_CLICK);
	}

	public static function success():Void
	{
		pattern([20, 60, 35], [0.6, 1]);
	}

	public static function warning():Void
	{
		pattern([40, 80, 40], [0.8, 0.8]);
	}

	public static function error():Void
	{
		pattern([60, 50, 60, 50, 90], [1, 1, 1]);
	}

	public static inline function noteHit():Void
	{
		play(TICK);
	}

	public static function miss():Void
	{
		vibrate(45, 0.9);
	}

	static function consumePulse(force:Bool):Bool
	{
		if (!enabled || optionScale() <= 0)
			return false;

		var now:Float = Timer.stamp();
		if (!force && lastPulse >= 0 && now - lastPulse < minInterval)
			return false;

		lastPulse = now;
		return true;
	}

	static function toAmplitude(strength:Float):Int
	{
		var value:Float = Math.max(0, Math.min(1, strength)) * optionScale();
		return Std.int(Math.max(1, Math.min(255, Math.round(value * 255))));
	}

	static function rawVibrate(milliseconds:Int, amplitude:Int):Void
	{
		#if android
		call('vibrate', '(II)V', [milliseconds, amplitude]);
		#elseif ios
		Haptic.vibrate(0, milliseconds);
		#end
	}

	static function rawPattern(steps:Array<Int>, ?strengths:Array<Float>):Void
	{
		#if android
		var timings:Array<Int> = [0];
		var amplitudes:Array<Int> = [0];

		for (i in 0...steps.length)
		{
			var isPulse:Bool = i % 2 == 0;
			var pulseIndex:Int = i >> 1;
			var strength:Float = (strengths != null && pulseIndex < strengths.length) ? strengths[pulseIndex] : 1;

			timings.push(Std.int(Math.max(0, steps[i])));
			amplitudes.push(isPulse ? toAmplitude(strength) : 0);
		}

		call('pattern', '(Ljava/lang/String;Ljava/lang/String;)V', [timings.join(','), amplitudes.join(',')]);
		#elseif ios
		var total:Int = 0;
		for (i in 0...steps.length)
		{
			if (i % 2 == 0)
				total += steps[i];
		}

		if (total > 0)
			Haptic.vibrate(0, total);
		#end
	}

	#if android
	static function call(name:String, signature:String, args:Array<Dynamic>):Dynamic
	{
		if (unavailable)
			return null;

		try
		{
			var method:Dynamic = methods.get(name);
			if (method == null)
			{
				method = JNI.createStaticMethod(HELPER, name, signature);
				methods.set(name, method);
			}

			return Reflect.callMethod(null, method, args);
		}
		catch (e:Dynamic)
		{
			unavailable = true;
			return null;
		}
	}
	#end
}
