package debug;

import flixel.FlxG;
import flixel.util.FlxStringUtil;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.text.TextFieldAutoSize;
import openfl.system.System;
import haxe.Timer;

#if cpp
import cpp.vm.Gc;
#end

class FPSCounter extends TextField
{
	public var currentFPS(default, null):Int = 0;
	public var memoryMegas(get, never):Float;
	public var taskTime(default, null):Float = 0;

	@:noCompletion
	private var times:Array<Float> = [];

	private var deltaTimeout:Float = 0;
	private var lastFrameTime:Float = 0;
	private var frameTimeSum:Float = 0;
	private var frameCount:Int = 0;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		multiline = false;
		wordWrap = false;
		autoSize = TextFieldAutoSize.LEFT;

		defaultTextFormat = new TextFormat(
			"_sans",
			#if mobile
			16,
			#else
			14,
			#end
			color
		);

		textColor = color;
		text = "FPS: 0 • Memory: 0 MB • Task: 0 ms";

		lastFrameTime = Timer.stamp() * 1000;
	}

	private override function __enterFrame(deltaTime:Int):Void
	{
		super.__enterFrame(deltaTime);

		final now:Float = Timer.stamp() * 1000;
		final frameDelta:Float = now - lastFrameTime;

		lastFrameTime = now;

		times.push(now);

		while (times.length > 0 && times[0] <= now - 1000)
		{
			times.shift();
		}

		if (frameDelta >= 0 && frameDelta < 1000)
		{
			frameTimeSum += frameDelta;
			frameCount++;
		}

		deltaTimeout += deltaTime;

		if (deltaTimeout < 100)
			return;

		currentFPS = times.length;

		if (frameCount > 0)
			taskTime = frameTimeSum / frameCount;

		updateText();

		frameTimeSum = 0;
		frameCount = 0;
		deltaTimeout = 0;
	}

	public dynamic function updateText():Void
	{
		final memory:Float = memoryMegas;
		final memoryText:String = FlxStringUtil.formatBytes(memory);

		final taskText:String = Std.string(
			Math.round(taskTime * 100) / 100
		);

		text = 'FPS: ${currentFPS} • Memory: ${memoryText} • Task: ${taskText} ms';

		if (currentFPS < FlxG.drawFramerate * 0.5)
		{
			textColor = 0xFFFF4444;
		}
		else
		{
			textColor = 0xFFFFFFFF;
		}
	}

	private function get_memoryMegas():Float
	{
		#if cpp
		return Gc.memInfo64(Gc.MEM_INFO_USAGE);
		#else
		return System.totalMemory;
		#end
	}
}
