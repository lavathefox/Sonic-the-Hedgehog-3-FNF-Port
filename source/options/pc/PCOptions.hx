package options.pc;

#if PC_OPTIONS
import flixel.FlxG;

import api.OptionsAPI;
import api.SonicAPI;
import backend.ClientPrefs;

class PCOptions
{
	public static final WINDOW_SCALE_NAMES:Array<String> = ['100', '125', '150', '200'];
	static final WINDOW_SCALES:Array<Float> = [1.0, 1.25, 1.5, 2.0];

	public static final FPS_LIMIT_NAMES:Array<String> = ['30', '60', '120', '144', '240'];
	static final FPS_LIMITS:Array<Int> = [30, 60, 120, 144, 240];

	public static final VOLUME_NAMES:Array<String> = ['0', '25', '50', '75', '100'];
	static final VOLUMES:Array<Float> = [0, 0.25, 0.5, 0.75, 1];

	public static var fullscreen:Bool = false;
	public static var windowScale:Int = 0;
	public static var showMouse:Bool = true;
	public static var pauseOnFocusLoss:Bool = true;

	static var hooked:Bool = false;
	static var ready:Bool = false;

	public static function init():Void
	{
		if (hooked)
			return;

		hooked = true;

		FlxG.signals.postStateSwitch.add(onStateSwitch);
	}

	public static function ensureLoaded():Void
	{
		if (!ready)
			tryLoadAndApply();
	}

	static function onStateSwitch():Void
	{
		ensureLoaded();

		applyMouse();
		applyAutoPause();
	}

	static function tryLoadAndApply():Void
	{
		var save = FlxG.save;

		if (save == null || !save.isBound || save.data == null)
			return;

		ready = true;
		readSaved(save.data);
		registerApi();
		apply();
	}

	static function readBool(obj:Dynamic, name:String, fallback:Bool):Bool
	{
		var value:Dynamic = Reflect.field(obj, name);
		return value == null ? fallback : value == true;
	}

	static function readSaved(data:Dynamic):Void
	{
		var saved:Dynamic = Reflect.field(data, 'pcOptions');

		fullscreen = readBool(saved == null ? {} : saved, 'fullscreen', FlxG.fullscreen);
		showMouse = readBool(saved == null ? {} : saved, 'showMouse', true);
		pauseOnFocusLoss = readBool(saved == null ? {} : saved, 'pauseOnFocusLoss', FlxG.autoPause);

		var scale:Dynamic = saved == null ? null : Reflect.field(saved, 'windowScale');
		windowScale = clampIndex(scale == null ? 0 : Std.int(scale), WINDOW_SCALES.length);
	}

	public static function save():Void
	{
		var store = FlxG.save;

		if (store == null || !store.isBound || store.data == null)
			return;

		Reflect.setField(store.data, 'pcOptions', {
			fullscreen: fullscreen,
			windowScale: windowScale,
			showMouse: showMouse,
			pauseOnFocusLoss: pauseOnFocusLoss
		});

		store.flush();
	}
  
	public static function apply():Void
	{
		if (FlxG.game == null)
			return;

		applyFullscreen();
		applyWindowSize();
		applyMouse();
		applyAutoPause();
		applyFramerate();
	}

	public static function applyFullscreen():Void
	{
		if (FlxG.game != null && FlxG.fullscreen != fullscreen)
			FlxG.fullscreen = fullscreen;
	}

	public static function applyWindowSize():Void
	{
		if (FlxG.game == null || FlxG.fullscreen)
			return;

		var scale:Float = WINDOW_SCALES[clampIndex(windowScale, WINDOW_SCALES.length)];
		var window = openfl.Lib.application.window;

		if (window != null)
			window.resize(Std.int(SonicAPI.DESIGN_WIDTH * scale), Std.int(SonicAPI.DESIGN_HEIGHT * scale));
	}

	public static function applyMouse():Void
	{
		if (FlxG.game != null && FlxG.mouse != null)
			FlxG.mouse.visible = showMouse;
	}

	public static function applyAutoPause():Void
	{
		if (FlxG.game != null)
			FlxG.autoPause = pauseOnFocusLoss;
	}

	public static function applyFramerate():Void
	{
		if (FlxG.game == null)
			return;

		var target:Int = ClientPrefs.data.framerate;

		if (target > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = target;
			FlxG.drawFramerate = target;
		}
		else
		{
			FlxG.drawFramerate = target;
			FlxG.updateFramerate = target;
		}
	}

	public static function setFullscreen(value:Bool):Void
	{
		fullscreen = value;
		applyFullscreen();

		if (!value)
			applyWindowSize();

		changed('pc.fullscreen', value);
	}

	public static function setWindowScale(index:Int):Void
	{
		windowScale = clampIndex(index, WINDOW_SCALES.length);
		applyWindowSize();
		changed('pc.windowScale', Std.int(WINDOW_SCALES[windowScale] * 100));
	}

	public static function setShowMouse(value:Bool):Void
	{
		showMouse = value;
		applyMouse();
		changed('pc.showMouse', value);
	}

	public static function setPauseOnFocusLoss(value:Bool):Void
	{
		pauseOnFocusLoss = value;
		applyAutoPause();
		changed('pc.pauseOnFocusLoss', value);
	}

	public static function setShowFps(value:Bool):Void
	{
		ClientPrefs.data.showFPS = value;

		if (Main.fpsVar != null)
			Main.fpsVar.visible = value;

		changed('pc.showFps', value);
	}

	public static function fpsLimitIndex():Int
	{
		return closestIndex(ClientPrefs.data.framerate);
	}

	public static function setFpsLimitIndex(index:Int):Void
	{
		ClientPrefs.data.framerate = FPS_LIMITS[clampIndex(index, FPS_LIMITS.length)];
		applyFramerate();
		changed('pc.fpsLimit', ClientPrefs.data.framerate);
	}

	public static function volumeIndex():Int
	{
		var best:Int = 0;

		for (i in 0...VOLUMES.length)
		{
			if (Math.abs(VOLUMES[i] - FlxG.sound.volume) < Math.abs(VOLUMES[best] - FlxG.sound.volume))
				best = i;
		}

		return best;
	}

	public static function setVolumeIndex(index:Int):Void
	{
		FlxG.sound.volume = VOLUMES[clampIndex(index, VOLUMES.length)];
		changed('pc.volume', Std.int(FlxG.sound.volume * 100));
	}

	public static function reset():Void
	{
		var defaults:backend.ClientPrefs.SaveVariables = {};

		fullscreen = false;
		windowScale = 0;
		showMouse = true;
		pauseOnFocusLoss = true;
		ClientPrefs.data.framerate = defaults.framerate;
		ClientPrefs.data.showFPS = defaults.showFPS;

		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;

		FlxG.sound.volume = 1;

		apply();
		save();
		OptionsAPI.notifyChanged('pc.reset', true);
	}

	static function changed(id:String, value:Dynamic):Void
	{
		save();
		OptionsAPI.notifyChanged(id, value);
	}

	static function clampIndex(index:Int, length:Int):Int
	{
		return index < 0 ? 0 : (index >= length ? length - 1 : index);
	}

	static function closestIndex(framerate:Int):Int
	{
		var best:Int = 0;

		for (i in 0...FPS_LIMITS.length)
		{
			if (Math.abs(FPS_LIMITS[i] - framerate) < Math.abs(FPS_LIMITS[best] - framerate))
				best = i;
		}

		return best;
	}

	static function registerApi():Void
	{
		OptionsAPI.register('pc.fullscreen', function():Dynamic return fullscreen, function(v:Dynamic) setFullscreen(v == true));
		OptionsAPI.register('pc.showMouse', function():Dynamic return showMouse, function(v:Dynamic) setShowMouse(v == true));
		OptionsAPI.register('pc.pauseOnFocusLoss', function():Dynamic return pauseOnFocusLoss, function(v:Dynamic) setPauseOnFocusLoss(v == true));
		OptionsAPI.register('pc.showFps', function():Dynamic return ClientPrefs.data.showFPS, function(v:Dynamic) setShowFps(v == true));

		OptionsAPI.register('pc.windowScale', function():Dynamic return Std.int(WINDOW_SCALES[windowScale] * 100), function(v:Dynamic)
		{
			var percent:Float = Std.parseFloat(Std.string(v));
			var best:Int = 0;

			for (i in 0...WINDOW_SCALES.length)
			{
				if (Math.abs(WINDOW_SCALES[i] * 100 - percent) < Math.abs(WINDOW_SCALES[best] * 100 - percent))
					best = i;
			}

			setWindowScale(best);
		});

		OptionsAPI.register('pc.fpsLimit', function():Dynamic return ClientPrefs.data.framerate, function(v:Dynamic)
		{
			setFpsLimitIndex(closestIndex(Std.int(Std.parseFloat(Std.string(v)))));
		});

		OptionsAPI.register('pc.volume', function():Dynamic return Std.int(FlxG.sound.volume * 100), function(v:Dynamic)
		{
			var wanted:Float = Std.parseFloat(Std.string(v)) / 100;
			var best:Int = 0;

			for (i in 0...VOLUMES.length)
			{
				if (Math.abs(VOLUMES[i] - wanted) < Math.abs(VOLUMES[best] - wanted))
					best = i;
			}

			setVolumeIndex(best);
		});
	}
}
#end
