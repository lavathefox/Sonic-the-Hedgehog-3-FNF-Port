package mobile;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;

class HitBox extends FlxSprite
{
	public var controlName:String;
	public var debugColor(default, set):Int;
	public var inputEnabled:Bool = true;
	public var debugVisible(default, set):Bool = false;
	public var useTouchInput:Bool = true;
	public var useMouseInput:Bool = false;
	public var allowMultipleTouches:Bool = true;
	public var pressed(default, null):Bool = false;
	public var justPressed(default, null):Bool = false;
	public var justReleased(default, null):Bool = false;
	public var touchCount(default, null):Int = 0;
	public var marginLeft:Float = 0;
	public var marginRight:Float = 0;
	public var marginTop:Float = 0;
	public var marginBottom:Float = 0;
	public var onPress:HitBox->Void;
	public var onRelease:HitBox->Void;

	private var areaWidth:Float = 1;
	private var areaHeight:Float = 1;
	private var pointerIds:Array<Int> = [];

	private var drawnWidth:Int = -1;
	private var drawnHeight:Int = -1;
	private var drawnColor:Int = 0;

	public function new(x:Float, y:Float, width:Float, height:Float, ?controlName:String = "control", ?color:Int = 0x55FF0000)
	{
		super(x, y);
		this.controlName = controlName == null ? "control" : controlName;
		debugColor = color;
		scrollFactor.set(0, 0);
		antialiasing = false;
		setBounds(x, y, width, height);
		visible = false;
	}

	public function setBounds(x:Float, y:Float, width:Float, height:Float):Void
	{
		setPosition(x, y);
		areaWidth = Math.max(1, width);
		areaHeight = Math.max(1, height);
		redrawDebug();
		visible = debugVisible;
	}

	public function setMargins(left:Float = 0, top:Float = 0, right:Float = 0, bottom:Float = 0):Void
	{
		marginLeft = left;
		marginTop = top;
		marginRight = right;
		marginBottom = bottom;
	}

	public function containsPoint(pointX:Float, pointY:Float):Bool
	{
		return pointX >= x - marginLeft && pointX <= x + areaWidth + marginRight
			&& pointY >= y - marginTop && pointY <= y + areaHeight + marginBottom;
	}

	public function containsScreenPoint(pointX:Float, pointY:Float, ?camera:FlxCamera):Bool
	{
		var cam = camera == null ? FlxG.camera : camera;
		if (cam == null)
			return containsPoint(pointX, pointY);

		var zoom = cam.zoom;
		if (zoom <= 0)
			return false;

		var localX = (pointX - cam.x - cam.width * 0.5) / zoom + cam.width * 0.5;
		var localY = (pointY - cam.y - cam.height * 0.5) / zoom + cam.height * 0.5;
		return containsPoint(localX, localY);
	}

	public function resetInput():Void
	{
		pressed = false;
		justPressed = false;
		justReleased = false;
		touchCount = 0;
		pointerIds.resize(0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var wasPressed = pressed;
		touchCount = 0;
		pointerIds.resize(0);

		if (inputEnabled && active && exists)
		{
			var cam:FlxCamera = (cameras != null && cameras.length > 0) ? cameras[0] : FlxG.camera;

			#if FLX_TOUCH
			if (useTouchInput && FlxG.touches != null)
			{
				for (touch in FlxG.touches.list)
				{
					if (!touch.pressed)
						continue;

					var point:FlxPoint = touch.getScreenPosition(cam);
					if (point == null)
						continue;

					var inside:Bool = containsPoint(point.x, point.y);
					point.put();

					if (!inside)
						continue;

					touchCount++;
					pointerIds.push(touch.touchPointID);

					if (!allowMultipleTouches)
						break;
				}
			}
			#end

			#if FLX_MOUSE
			if (useMouseInput && FlxG.mouse.pressed)
			{
				var mousePoint = FlxG.mouse.getScreenPosition(cam);
				if (containsPoint(mousePoint.x, mousePoint.y))
				{
					touchCount++;
					pointerIds.push(-1);
				}
				mousePoint.put();
			}
			#end
		}

		pressed = touchCount > 0;
		justPressed = pressed && !wasPressed;
		justReleased = !pressed && wasPressed;

		if (justPressed && onPress != null)
			onPress(this);

		if (justReleased && onRelease != null)
			onRelease(this);
	}

	public function hasPointer(id:Int):Bool
	{
		return pointerIds.indexOf(id) != -1;
	}

	private function redrawDebug():Void
	{
		if (!debugVisible)
			return;

		var w:Int = Std.int(Math.ceil(areaWidth));
		var h:Int = Std.int(Math.ceil(areaHeight));

		if (w == drawnWidth && h == drawnHeight && debugColor == drawnColor)
			return;

		makeGraphic(w, h, debugColor, true);
		drawnWidth = w;
		drawnHeight = h;
		drawnColor = debugColor;
	}

	private function set_debugColor(value:Int):Int
	{
		debugColor = value;
		redrawDebug();
		return value;
	}

	private function set_debugVisible(value:Bool):Bool
	{
		debugVisible = value;
		visible = value;
		redrawDebug();
		return value;
	}

	override public function destroy():Void
	{
		resetInput();
		onPress = null;
		onRelease = null;
		super.destroy();
	}
}
