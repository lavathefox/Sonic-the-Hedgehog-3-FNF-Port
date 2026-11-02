package psychlua;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

typedef CRect =
{
	var x:Float;
	var y:Float;
	var w:Float;
	var h:Float;
}

class CollisionFunctions
{
	private static var collisions:Map<String, CollisionData> = new Map<String, CollisionData>();
	private static var sensors:Map<String, ObjectSensors> = new Map<String, ObjectSensors>();
	private static var maskCache:Map<String, MaskCache> = new Map<String, MaskCache>();
	private static var defaultSensors:ObjectSensors = new ObjectSensors();

	private static var lastHitX:Float = Math.NaN;
	private static var lastHitY:Float = Math.NaN;

	public static function implement(funk:FunkinLua):Void
	{
		funk.addLocalCallback('createCollisionBox', function(tag:String, x:Float, y:Float, width:Float, height:Float, ?collisionType:String = 'solid')
		{
			return createBox(tag, x, y, width, height, collisionType);
		});

		funk.addLocalCallback('createCollisionGraphic', function(tag:String, x:Float, y:Float, width:Int, height:Int, ?color:String = 'FF0000', ?collisionType:String = 'solid', ?visible:Bool = false)
		{
			return createGraphic(tag, x, y, width, height, color, collisionType, visible);
		});

		funk.addLocalCallback('createCollisionSprite', function(tag:String, spriteTag:String, ?collisionType:String = 'solid')
		{
			return createSpriteCollision(tag, spriteTag, collisionType);
		});

		funk.addLocalCallback('createCollisionMask', function(tag:String, image:String, x:Float, y:Float, ?collisionType:String = 'floor', ?color:String = 'FFFFFF', ?tolerance:Int = 20, ?debug:Bool = false)
		{
			return createCollisionMask(tag, image, x, y, collisionType, color, tolerance, debug);
		});

		funk.addLocalCallback('createCollisionSurface', function(tag:String, ?collisionType:String = 'floor')
		{
			return createSurface(tag, collisionType);
		});

		funk.addLocalCallback('addCollisionPoint', function(tag:String, x:Float, y:Float)
		{
			return addPoint(tag, x, y);
		});

		funk.addLocalCallback('clearCollisionPoints', function(tag:String)
		{
			return clearPoints(tag);
		});

		funk.addLocalCallback('setCollisionPosition', function(tag:String, x:Float, y:Float)
		{
			return setPosition(tag, x, y);
		});

		funk.addLocalCallback('moveCollision', function(tag:String, dx:Float, dy:Float)
		{
			return moveCollision(tag, dx, dy);
		});

		funk.addLocalCallback('setCollisionSize', function(tag:String, width:Float, height:Float)
		{
			return setSize(tag, width, height);
		});

		funk.addLocalCallback('setCollisionType', function(tag:String, collisionType:String)
		{
			return setType(tag, collisionType);
		});

		funk.addLocalCallback('getCollisionType', function(tag:String)
		{
			var data:CollisionData = collisions.get(tag);
			return data == null ? '' : data.collisionType;
		});

		funk.addLocalCallback('setCollisionVisible', function(tag:String, visible:Bool)
		{
			return setVisible(tag, visible);
		});

		funk.addLocalCallback('setCollisionDebugColor', function(tag:String, color:String)
		{
			return setDebugColor(tag, color);
		});

		funk.addLocalCallback('setCollisionEnabled', function(tag:String, enabled:Bool)
		{
			return setEnabled(tag, enabled);
		});

		funk.addLocalCallback('isCollisionEnabled', function(tag:String)
		{
			var data:CollisionData = collisions.get(tag);
			return data != null && data.enabled;
		});

		funk.addLocalCallback('collisionExists', function(tag:String)
		{
			return collisions.exists(tag);
		});

		funk.addLocalCallback('bindCollisionObject', function(collisionTag:String, objectTag:String)
		{
			return bindObject(collisionTag, objectTag);
		});

		funk.addLocalCallback('unbindCollisionObject', function(collisionTag:String)
		{
			return unbindObject(collisionTag);
		});

		funk.addLocalCallback('setCollisionHitbox', function(objectTag:String, offsetX:Float, offsetY:Float, width:Float, height:Float)
		{
			return setHitbox(objectTag, offsetX, offsetY, width, height);
		});

		funk.addLocalCallback('setCollisionSteps', function(objectTag:String, climb:Int, drop:Int, ?stepHeight:Float = 16, ?tolerance:Float = 8)
		{
			return setSteps(objectTag, climb, drop, stepHeight, tolerance);
		});

		funk.addLocalCallback('resetCollisionObject', function(objectTag:String)
		{
			sensors.remove(objectTag);
			return true;
		});

		funk.addLocalCallback('updateCollision', function(tag:String)
		{
			return updateCollision(tag);
		});

		funk.addLocalCallback('updateAllCollisions', function()
		{
			updateAll();
			return true;
		});

		funk.addLocalCallback('isTouchingCollision', function(objectTag:String, collisionTag:String)
		{
			return isTouchingObject(objectTag, collisionTag);
		});

		funk.addLocalCallback('getTouchingCollision', function(objectTag:String)
		{
			return getTouchingCollision(objectTag);
		});

		funk.addLocalCallback('isSolidAt', function(collisionTag:String, x:Float, y:Float)
		{
			return isSolidAt(collisionTag, x, y);
		});

		funk.addLocalCallback('isOnGround', function(objectTag:String, ?collisionTag:String = '')
		{
			return isOnGround(objectTag, collisionTag);
		});

		funk.addLocalCallback('getGroundCollisionTag', function(objectTag:String)
		{
			return getGroundCollisionTag(objectTag);
		});

		funk.addLocalCallback('getGroundY', function(objectTag:String, ?collisionTag:String = '')
		{
			return getGroundY(objectTag, collisionTag);
		});

		funk.addLocalCallback('getGroundYAt', function(collisionTag:String, x:Float, ?referenceY:Float = 0)
		{
			return getGroundYAt(collisionTag, x, referenceY);
		});

		funk.addLocalCallback('getGroundAngle', function(objectTag:String, ?collisionTag:String = '')
		{
			return getGroundAngle(objectTag, collisionTag);
		});

		funk.addLocalCallback('getGroundAngleAt', function(collisionTag:String, x:Float, ?referenceY:Float = 0)
		{
			return getGroundAngleAt(collisionTag, x, referenceY);
		});

		funk.addLocalCallback('isOnSlope', function(objectTag:String, ?minAngle:Float = 5, ?collisionTag:String = '')
		{
			return Math.abs(getGroundAngle(objectTag, collisionTag)) >= minAngle;
		});

		funk.addLocalCallback('getGroundDistance', function(objectTag:String, ?collisionTag:String = '')
		{
			return getGroundDistance(objectTag, collisionTag);
		});

		funk.addLocalCallback('snapToGround', function(objectTag:String, ?collisionTag:String = '')
		{
			return snapToGround(objectTag, collisionTag);
		});

		funk.addLocalCallback('resolveGroundCollision', function(objectTag:String, ?collisionTag:String = '')
		{
			return resolveGround(objectTag, collisionTag);
		});

		funk.addLocalCallback('resolveWallCollision', function(objectTag:String, ?collisionTag:String = '')
		{
			return resolveWalls(objectTag, collisionTag);
		});

		funk.addLocalCallback('resolveCeilingCollision', function(objectTag:String, ?collisionTag:String = '')
		{
			return resolveCeiling(objectTag, collisionTag);
		});

		funk.addLocalCallback('resolveCollision', function(objectTag:String, ?collisionTag:String = '')
		{
			return resolveCollision(objectTag, collisionTag);
		});

		funk.addLocalCallback('isTouchingWall', function(objectTag:String, ?collisionTag:String = '')
		{
			return isTouchingWall(objectTag, collisionTag);
		});

		funk.addLocalCallback('isTouchingCeiling', function(objectTag:String, ?collisionTag:String = '')
		{
			return isTouchingCeiling(objectTag, collisionTag);
		});

		funk.addLocalCallback('getWallCollision', function(objectTag:String, ?collisionTag:String = '')
		{
			return getWallCollision(objectTag, collisionTag);
		});

		funk.addLocalCallback('raycastCollision', function(collisionTag:String, x1:Float, y1:Float, x2:Float, y2:Float)
		{
			return raycast(collisionTag, x1, y1, x2, y2);
		});

		funk.addLocalCallback('getRaycastX', function()
		{
			return lastHitX;
		});

		funk.addLocalCallback('getRaycastY', function()
		{
			return lastHitY;
		});

		funk.addLocalCallback('getCollisionX', function(tag:String)
		{
			return getX(tag);
		});

		funk.addLocalCallback('getCollisionY', function(tag:String)
		{
			return getY(tag);
		});

		funk.addLocalCallback('getCollisionWidth', function(tag:String)
		{
			return getWidth(tag);
		});

		funk.addLocalCallback('getCollisionHeight', function(tag:String)
		{
			return getHeight(tag);
		});

		funk.addLocalCallback('removeCollision', function(tag:String)
		{
			return removeCollision(tag);
		});

		funk.addLocalCallback('clearCollisions', function()
		{
			clearAll();
			return true;
		});

		funk.addLocalCallback('clearCollisionMaskCache', function()
		{
			clearMaskCache();
			return true;
		});
	}

	public static function createBox(tag:String, x:Float, y:Float, width:Float, height:Float, collisionType:String = 'solid'):Bool
	{
		removeCollision(tag);

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'box';
		data.x = x;
		data.y = y;
		data.width = width;
		data.height = height;
		data.collisionType = normalizeType(collisionType);

		collisions.set(tag, data);

		return true;
	}

	public static function createGraphic(tag:String, x:Float, y:Float, width:Int, height:Int, color:String = 'FF0000', collisionType:String = 'solid', visible:Bool = false):Bool
	{
		removeCollision(tag);

		if (width <= 0 || height <= 0)
		{
			trace('CollisionFunctions: Invalid collision graphic size for "' + tag + '".');
			return false;
		}

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'box';
		data.x = x;
		data.y = y;
		data.width = width;
		data.height = height;
		data.collisionType = normalizeType(collisionType);
		data.visible = visible;
		data.debugColor = parseColor(color);

		var sprite:FlxSprite = new FlxSprite(x, y);
		sprite.makeGraphic(width, height, data.debugColor);
		sprite.alpha = 0.35;
		sprite.visible = visible;

		if (PlayState.instance != null)
			PlayState.instance.add(sprite);

		data.debugSprite = sprite;

		collisions.set(tag, data);

		return true;
	}

	public static function createSpriteCollision(tag:String, spriteTag:String, collisionType:String = 'solid'):Bool
	{
		removeCollision(tag);

		var sprite:FlxSprite = getSprite(spriteTag);

		if (sprite == null)
		{
			trace('CollisionFunctions: Sprite "' + spriteTag + '" was not found.');
			return false;
		}

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'sprite';
		data.objectTag = spriteTag;
		data.collisionType = normalizeType(collisionType);
		data.x = sprite.x;
		data.y = sprite.y;
		data.width = sprite.width;
		data.height = sprite.height;

		collisions.set(tag, data);

		return true;
	}

	public static function createSurface(tag:String, collisionType:String = 'floor'):Bool
	{
		removeCollision(tag);

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'surface';
		data.collisionType = normalizeType(collisionType);

		collisions.set(tag, data);

		return true;
	}

	public static function createCollisionMask(tag:String, image:String, x:Float, y:Float, collisionType:String = 'floor', color:String = 'FFFFFF', tolerance:Int = 20, debug:Bool = false):Bool
	{
		removeCollision(tag);

		if (image == null || image.length == 0)
		{
			trace('CollisionFunctions: Collision image path is empty.');
			return false;
		}

		var graphic:Dynamic = loadMaskGraphic(image);

		if (graphic == null)
		{
			trace('CollisionFunctions: Collision image "' + image + '" was not found.');
			return false;
		}

		var bitmap:BitmapData = null;

		try
		{
			bitmap = graphic.bitmap;
		}
		catch (e:Dynamic)
		{
			bitmap = null;
		}

		if (bitmap == null || bitmap.width <= 0 || bitmap.height <= 0)
		{
			trace('CollisionFunctions: Collision image "' + image + '" has no usable bitmap.');
			return false;
		}

		if (tolerance < 0)
			tolerance = 0;

		var maskColor:FlxColor = parseColor(color);
		var colorInt:Int = maskColor;
		var cacheKey:String = image + '|' + Std.string(colorInt) + '|' + Std.string(tolerance);

		var cached:MaskCache = maskCache.get(cacheKey);

		if (cached == null)
		{
			cached = buildMask(bitmap, colorInt, tolerance);

			if (cached == null)
			{
				trace('CollisionFunctions: Failed to read pixels of "' + image + '". If the image is cached on GPU, disable GPU caching for it.');
				return false;
			}

			maskCache.set(cacheKey, cached);
		}

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'mask';
		data.x = x;
		data.y = y;
		data.width = cached.width;
		data.height = cached.height;
		data.collisionType = normalizeType(collisionType);
		data.maskImage = image;
		data.maskColor = maskColor;
		data.maskTolerance = tolerance;
		data.maskBits = cached.bits;
		data.maskW = cached.width;
		data.maskH = cached.height;
		data.maskStride = cached.stride;

		if (debug)
		{
			var debugSprite:FlxSprite = new FlxSprite(x, y);
			debugSprite.loadGraphic(graphic);
			debugSprite.alpha = 0.35;

			if (PlayState.instance != null)
				PlayState.instance.add(debugSprite);

			data.debugSprite = debugSprite;
			data.visible = true;
		}

		collisions.set(tag, data);

		trace('CollisionFunctions: Loaded mask "' + tag + '" (' + cached.width + 'x' + cached.height + ').');

		return true;
	}

	private static function loadMaskGraphic(image:String):Dynamic
	{
		try
		{
			return Paths.image(image, null, false);
		}
		catch (e:Dynamic)
		{
		}

		try
		{
			return Paths.image(image);
		}
		catch (e:Dynamic)
		{
		}

		return null;
	}

	private static function buildMask(bitmap:BitmapData, colorInt:Int, tolerance:Int):MaskCache
	{
		var w:Int = bitmap.width;
		var h:Int = bitmap.height;
		var stride:Int = (w + 7) >> 3;
		var bits:Bytes = Bytes.alloc(stride * h);

		var targetRed:Int = (colorInt >> 16) & 0xFF;
		var targetGreen:Int = (colorInt >> 8) & 0xFF;
		var targetBlue:Int = colorInt & 0xFF;

		var chunk:Int = 16;
		var startY:Int = 0;

		try
		{
			while (startY < h)
			{
				var rows:Int = Std.int(Math.min(chunk, h - startY));
				var pixels = bitmap.getPixels(new Rectangle(0, startY, w, rows));
				var i:Int = 0;

				for (ry in 0...rows)
				{
					var rowBase:Int = (startY + ry) * stride;

					for (px in 0...w)
					{
						var a:Int = pixels[i];
						var r:Int = pixels[i + 1];
						var g:Int = pixels[i + 2];
						var b:Int = pixels[i + 3];
						i += 4;

						if (a > 0
							&& Math.abs(r - targetRed) <= tolerance
							&& Math.abs(g - targetGreen) <= tolerance
							&& Math.abs(b - targetBlue) <= tolerance)
						{
							var index:Int = rowBase + (px >> 3);
							bits.set(index, bits.get(index) | (0x80 >> (px & 7)));
						}
					}
				}

				startY += rows;
			}
		}
		catch (e:Dynamic)
		{
			trace('CollisionFunctions: ' + Std.string(e));
			return null;
		}

		return new MaskCache(bits, w, h, stride);
	}

	public static function clearMaskCache():Void
	{
		maskCache = new Map<String, MaskCache>();
	}

	public static function addPoint(tag:String, x:Float, y:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null || data.kind != 'surface')
			return false;

		data.points.push(new CollisionPoint(x, y));
		sortPoints(data);

		return true;
	}

	public static function clearPoints(tag:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.points = [];

		return true;
	}

	public static function setPosition(tag:String, x:Float, y:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		var offsetX:Float = x - data.x;
		var offsetY:Float = y - data.y;

		data.x = x;
		data.y = y;

		if (data.kind == 'surface')
		{
			for (point in data.points)
			{
				point.x += offsetX;
				point.y += offsetY;
			}
		}

		if (data.debugSprite != null)
			data.debugSprite.setPosition(x, y);

		return true;
	}

	public static function moveCollision(tag:String, dx:Float, dy:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		return setPosition(tag, data.x + dx, data.y + dy);
	}

	public static function setSize(tag:String, width:Float, height:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.width = width;
		data.height = height;

		if (data.debugSprite != null && data.kind != 'mask')
		{
			data.debugSprite.setGraphicSize(Std.int(width), Std.int(height));
			data.debugSprite.updateHitbox();
		}

		return true;
	}

	public static function setType(tag:String, collisionType:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.collisionType = normalizeType(collisionType);

		return true;
	}

	public static function setVisible(tag:String, visible:Bool):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.visible = visible;

		if (data.debugSprite != null)
			data.debugSprite.visible = visible;

		return true;
	}

	public static function setDebugColor(tag:String, color:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.debugColor = parseColor(color);

		if (data.debugSprite != null)
			data.debugSprite.color = data.debugColor;

		return true;
	}

	public static function setEnabled(tag:String, enabled:Bool):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		data.enabled = enabled;

		return true;
	}

	public static function bindObject(collisionTag:String, objectTag:String):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if (data == null)
			return false;

		if (getSprite(objectTag) == null)
			return false;

		data.objectTag = objectTag;

		updateDataFromObject(data);

		return true;
	}

	public static function unbindObject(collisionTag:String):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if (data == null)
			return false;

		data.objectTag = '';

		return true;
	}

	public static function setHitbox(objectTag:String, offsetX:Float, offsetY:Float, width:Float, height:Float):Bool
	{
		if (objectTag == null || objectTag.length == 0)
			return false;

		var s:ObjectSensors = getOrCreateSensors(objectTag);

		s.hitOffX = offsetX;
		s.hitOffY = offsetY;
		s.hitW = width;
		s.hitH = height;

		return true;
	}

	public static function setSteps(objectTag:String, climb:Int, drop:Int, stepHeight:Float = 16, tolerance:Float = 8):Bool
	{
		if (objectTag == null || objectTag.length == 0)
			return false;

		var s:ObjectSensors = getOrCreateSensors(objectTag);

		s.climb = climb < 0 ? 0 : climb;
		s.drop = drop < 0 ? 0 : drop;
		s.stepHeight = stepHeight < 0 ? 0 : stepHeight;
		s.tolerance = tolerance < 0 ? 0 : tolerance;

		return true;
	}

	public static function updateCollision(tag:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		updateDataFromObject(data);

		return true;
	}

	public static function updateAll():Void
	{
		for (data in collisions)
			updateDataFromObject(data);
	}

	private static function updateDataFromObject(data:CollisionData):Void
	{
		if (data.objectTag == null || data.objectTag.length == 0)
			return;

		var sprite:FlxSprite = getSprite(data.objectTag);

		if (sprite == null)
			return;

		data.x = sprite.x;
		data.y = sprite.y;

		if (data.kind == 'sprite')
		{
			data.width = sprite.width;
			data.height = sprite.height;
		}

		if (data.debugSprite != null)
			data.debugSprite.setPosition(data.x, data.y);
	}

	public static function isTouchingObject(objectTag:String, collisionTag:String):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var data:CollisionData = collisions.get(collisionTag);

		if (data == null || !data.enabled)
			return false;

		var s:ObjectSensors = getSensors(objectTag);

		return touchesData(data, getRect(sprite, s), s);
	}

	public static function getTouchingCollision(objectTag:String):String
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return '';

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		for (data in collisions)
		{
			if (!data.enabled)
				continue;

			if (touchesData(data, r, s))
				return data.tag;
		}

		return '';
	}

	private static function touchesData(data:CollisionData, r:CRect, s:ObjectSensors):Bool
	{
		updateDataFromObject(data);

		if (data.kind == 'surface')
			return !Math.isNaN(bestGroundY(data, r, s)) && isNear(r, bestGroundY(data, r, s), s);

		if (data.kind == 'mask')
		{
			if (maskObjectTouches(data, r))
				return true;

			var g:Float = bestGroundY(data, r, s);

			return !Math.isNaN(g) && isNear(r, g, s);
		}

		return rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height);
	}

	public static function isSolidAt(collisionTag:String, worldX:Float, worldY:Float):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if (data == null)
			return false;

		updateDataFromObject(data);

		return solidAtData(data, worldX, worldY);
	}

	public static function isOnGround(objectTag:String, collisionTag:String = ''):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getGroundCollision(r, s, collisionTag);

		if (data == null)
			return false;

		var g:Float = bestGroundY(data, r, s);

		return !Math.isNaN(g) && isNear(r, g, s);
	}

	public static function getGroundCollisionTag(objectTag:String):String
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return '';

		var s:ObjectSensors = getSensors(objectTag);
		var data:CollisionData = getGroundCollision(getRect(sprite, s), s, '');

		return data == null ? '' : data.tag;
	}

	public static function getGroundY(objectTag:String, collisionTag:String = ''):Float
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return Math.NaN;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getGroundCollision(r, s, collisionTag);

		if (data == null)
			return Math.NaN;

		return bestGroundY(data, r, s);
	}

	public static function getGroundYAt(collisionTag:String, x:Float, referenceY:Float = 0):Float
	{
		var data:CollisionData = collisions.get(collisionTag);

		if (data == null || !data.enabled)
			return Math.NaN;

		updateDataFromObject(data);

		if (data.kind == 'surface')
			return getSurfaceY(data, x);

		if (data.kind == 'mask')
		{
			if (referenceY > 0)
				return maskFindGround(data, x, referenceY, 32, 32);

			return maskFirstSolid(data, x);
		}

		return data.y;
	}

	public static function getGroundAngle(objectTag:String, collisionTag:String = ''):Float
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return 0;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getGroundCollision(r, s, collisionTag);

		if (data == null)
			return 0;

		var g:Float = bestGroundY(data, r, s);

		return getGroundAngleAtData(data, r.x + r.w * 0.5, Math.isNaN(g) ? 0 : g);
	}

	public static function getGroundAngleAt(collisionTag:String, x:Float, referenceY:Float = 0):Float
	{
		var data:CollisionData = collisions.get(collisionTag);

		if (data == null || !data.enabled)
			return 0;

		updateDataFromObject(data);

		return getGroundAngleAtData(data, x, referenceY);
	}

	public static function getGroundDistance(objectTag:String, collisionTag:String = ''):Float
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return Math.NaN;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var g:Float = getGroundY(objectTag, collisionTag);

		if (Math.isNaN(g))
			return Math.NaN;

		return g - (r.y + r.h);
	}

	public static function snapToGround(objectTag:String, collisionTag:String = ''):Bool
	{
		return resolveGround(objectTag, collisionTag);
	}

	public static function resolveGround(objectTag:String, collisionTag:String = ''):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getGroundCollision(r, s, collisionTag);

		if (data == null)
			return false;

		var g:Float = bestGroundY(data, r, s);

		if (Math.isNaN(g))
			return false;

		sprite.y = g - r.h - s.hitOffY;

		return true;
	}

	public static function resolveWalls(objectTag:String, collisionTag:String = ''):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getSolidCollision(r, collisionTag);

		if (data == null)
			return false;

		updateDataFromObject(data);

		if (data.kind == 'mask')
		{
			var topY:Float = r.y + s.wallInset;
			var bottomY:Float = Math.max(topY, r.y + r.h - s.stepHeight);

			var leftX:Float = r.x;
			var rightX:Float = r.x + r.w - 1;

			if (maskColumnHit(data, leftX, topY, bottomY))
			{
				var n:Int = 1;

				while (n < 64 && maskColumnHit(data, leftX + n, topY, bottomY))
					n++;

				sprite.x += n;
				return true;
			}

			if (maskColumnHit(data, rightX, topY, bottomY))
			{
				var m:Int = 1;

				while (m < 64 && maskColumnHit(data, rightX - m, topY, bottomY))
					m++;

				sprite.x -= m;
				return true;
			}

			return false;
		}

		if (data.kind == 'surface')
			return false;

		if (!rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height))
			return false;

		var playerCenter:Float = r.x + r.w * 0.5;
		var collisionCenter:Float = data.x + data.width * 0.5;

		if (playerCenter < collisionCenter)
			sprite.x = data.x - r.w - s.hitOffX;
		else
			sprite.x = data.x + data.width - s.hitOffX;

		return true;
	}

	public static function resolveCeiling(objectTag:String, collisionTag:String = ''):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getSolidCollision(r, collisionTag);

		if (data == null)
			return false;

		updateDataFromObject(data);

		if (data.kind == 'mask')
		{
			var xs:Array<Float> = [r.x + 2, r.x + r.w * 0.5, r.x + r.w - 3];

			for (sx in xs)
			{
				if (isMaskSolidAt(data, sx, r.y))
				{
					var ceilingY:Float = maskCeilingY(data, sx, r.y, 32);

					if (!Math.isNaN(ceilingY))
					{
						sprite.y = ceilingY - s.hitOffY;
						return true;
					}
				}
			}

			return false;
		}

		if (data.kind == 'surface')
			return false;

		if (!rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height))
			return false;

		if (r.y + r.h * 0.5 > data.y + data.height * 0.5)
		{
			sprite.y = data.y + data.height - s.hitOffY;
			return true;
		}

		return false;
	}

	public static function resolveCollision(objectTag:String, collisionTag:String = ''):Bool
	{
		var result:Bool = false;

		if (resolveWalls(objectTag, collisionTag))
			result = true;

		if (resolveCeiling(objectTag, collisionTag))
			result = true;

		if (resolveGround(objectTag, collisionTag))
			result = true;

		return result;
	}

	public static function getWallCollision(objectTag:String, collisionTag:String = ''):Int
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return 0;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getSolidCollision(r, collisionTag);

		if (data == null)
			return 0;

		updateDataFromObject(data);

		if (data.kind == 'mask')
		{
			var topY:Float = r.y + s.wallInset;
			var bottomY:Float = Math.max(topY, r.y + r.h - s.stepHeight);

			if (maskColumnHit(data, r.x, topY, bottomY))
				return -1;

			if (maskColumnHit(data, r.x + r.w - 1, topY, bottomY))
				return 1;

			return 0;
		}

		if (data.kind == 'surface')
			return 0;

		if (!rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height))
			return 0;

		return (r.x + r.w * 0.5) < (data.x + data.width * 0.5) ? -1 : 1;
	}

	public static function isTouchingWall(objectTag:String, collisionTag:String = ''):Bool
	{
		return getWallCollision(objectTag, collisionTag) != 0;
	}

	public static function isTouchingCeiling(objectTag:String, collisionTag:String = ''):Bool
	{
		var sprite:FlxSprite = getSprite(objectTag);

		if (sprite == null)
			return false;

		var s:ObjectSensors = getSensors(objectTag);
		var r:CRect = getRect(sprite, s);

		var data:CollisionData = getSolidCollision(r, collisionTag);

		if (data == null)
			return false;

		updateDataFromObject(data);

		if (data.kind == 'mask')
		{
			return isMaskSolidAt(data, r.x + 2, r.y)
				|| isMaskSolidAt(data, r.x + r.w * 0.5, r.y)
				|| isMaskSolidAt(data, r.x + r.w - 3, r.y);
		}

		if (data.kind == 'surface')
			return false;

		if (!rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height))
			return false;

		return r.y + r.h * 0.5 > data.y + data.height * 0.5;
	}

	public static function raycast(tag:String, x1:Float, y1:Float, x2:Float, y2:Float):Float
	{
		lastHitX = Math.NaN;
		lastHitY = Math.NaN;

		var data:CollisionData = collisions.get(tag);

		if (data == null || !data.enabled)
			return -1;

		updateDataFromObject(data);

		var dx:Float = x2 - x1;
		var dy:Float = y2 - y1;
		var dist:Float = Math.sqrt(dx * dx + dy * dy);

		if (dist <= 0)
		{
			if (solidAtData(data, x1, y1))
			{
				lastHitX = x1;
				lastHitY = y1;
				return 0;
			}

			return -1;
		}

		var steps:Int = Std.int(Math.ceil(dist));

		for (i in 0...steps + 1)
		{
			var t:Float = i / steps;
			var px:Float = x1 + dx * t;
			var py:Float = y1 + dy * t;

			if (solidAtData(data, px, py))
			{
				lastHitX = px;
				lastHitY = py;
				return dist * t;
			}
		}

		return -1;
	}

	public static function getX(tag:String):Float
	{
		var data:CollisionData = collisions.get(tag);
		return data == null ? 0 : data.x;
	}

	public static function getY(tag:String):Float
	{
		var data:CollisionData = collisions.get(tag);
		return data == null ? 0 : data.y;
	}

	public static function getWidth(tag:String):Float
	{
		var data:CollisionData = collisions.get(tag);
		return data == null ? 0 : data.width;
	}

	public static function getHeight(tag:String):Float
	{
		var data:CollisionData = collisions.get(tag);
		return data == null ? 0 : data.height;
	}

	public static function removeCollision(tag:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if (data == null)
			return false;

		if (data.debugSprite != null)
		{
			if (PlayState.instance != null)
				PlayState.instance.remove(data.debugSprite, true);

			data.debugSprite.kill();
			data.debugSprite.destroy();
			data.debugSprite = null;
		}

		data.maskBits = null;

		collisions.remove(tag);

		return true;
	}

	public static function clearAll():Void
	{
		var tags:Array<String> = [];

		for (tag in collisions.keys())
			tags.push(tag);

		for (tag in tags)
			removeCollision(tag);

		sensors = new Map<String, ObjectSensors>();
		lastHitX = Math.NaN;
		lastHitY = Math.NaN;
	}

	private static function getSensors(tag:String):ObjectSensors
	{
		var s:ObjectSensors = sensors.get(tag);
		return s == null ? defaultSensors : s;
	}

	private static function getOrCreateSensors(tag:String):ObjectSensors
	{
		var s:ObjectSensors = sensors.get(tag);

		if (s == null)
		{
			s = new ObjectSensors();
			sensors.set(tag, s);
		}

		return s;
	}

	private static function getRect(sprite:FlxSprite, s:ObjectSensors):CRect
	{
		return {
			x: sprite.x + s.hitOffX,
			y: sprite.y + s.hitOffY,
			w: s.hitW > 0 ? s.hitW : sprite.width,
			h: s.hitH > 0 ? s.hitH : sprite.height
		};
	}

	private static function isNear(r:CRect, groundY:Float, s:ObjectSensors):Bool
	{
		var bottom:Float = r.y + r.h;
		return bottom >= groundY - s.tolerance && bottom <= groundY + s.tolerance;
	}

	private static function blocksSides(data:CollisionData):Bool
	{
		return data.collisionType != 'platform' && data.collisionType != 'trigger';
	}

	private static function canBeGround(data:CollisionData):Bool
	{
		return data.collisionType == 'floor'
			|| data.collisionType == 'ground'
			|| data.collisionType == 'solid'
			|| data.collisionType == 'platform';
	}

	private static function groundFor(data:CollisionData, x:Float, bottom:Float, s:ObjectSensors):Float
	{
		var climb:Int = data.collisionType == 'platform' ? 0 : s.climb;
		var result:Float = Math.NaN;

		switch (data.kind)
		{
			case 'surface':
				result = getSurfaceY(data, x);

			case 'mask':
				result = maskFindGround(data, x, bottom, climb, s.drop);

			default:
				if (x >= data.x && x < data.x + data.width)
					result = data.y;
		}

		if (Math.isNaN(result))
			return Math.NaN;

		if (result < bottom - climb || result > bottom + s.drop)
			return Math.NaN;

		return result;
	}

	private static function bestGroundY(data:CollisionData, r:CRect, s:ObjectSensors):Float
	{
		updateDataFromObject(data);

		var bottom:Float = r.y + r.h;

		var a:Float = groundFor(data, r.x + s.sensorInset, bottom, s);
		var b:Float = groundFor(data, r.x + r.w * 0.5, bottom, s);
		var c:Float = groundFor(data, r.x + r.w - s.sensorInset - 1, bottom, s);

		return nearestGround(bottom, a, b, c);
	}

	private static function getGroundCollision(r:CRect, s:ObjectSensors, requestedTag:String):CollisionData
	{
		if (requestedTag != null && requestedTag.length > 0)
		{
			var requested:CollisionData = collisions.get(requestedTag);
			return (requested != null && requested.enabled) ? requested : null;
		}

		var best:CollisionData = null;
		var bestDistance:Float = Math.POSITIVE_INFINITY;
		var bottom:Float = r.y + r.h;

		for (data in collisions)
		{
			if (!data.enabled || !canBeGround(data))
				continue;

			var g:Float = bestGroundY(data, r, s);

			if (Math.isNaN(g))
				continue;

			var distance:Float = Math.abs(bottom - g);

			if (distance < bestDistance)
			{
				bestDistance = distance;
				best = data;
			}
		}

		return best;
	}

	private static function getSolidCollision(r:CRect, requestedTag:String):CollisionData
	{
		if (requestedTag != null && requestedTag.length > 0)
		{
			var requested:CollisionData = collisions.get(requestedTag);
			return (requested != null && requested.enabled) ? requested : null;
		}

		for (data in collisions)
		{
			if (!data.enabled || !blocksSides(data))
				continue;

			updateDataFromObject(data);

			if (data.kind == 'mask')
			{
				if (maskObjectTouches(data, r))
					return data;

				continue;
			}

			if (data.kind == 'surface')
				continue;

			if (rectanglesOverlap(r.x, r.y, r.w, r.h, data.x, data.y, data.width, data.height))
				return data;
		}

		return null;
	}

	private static function solidAtData(data:CollisionData, wx:Float, wy:Float):Bool
	{
		if (!data.enabled)
			return false;

		switch (data.kind)
		{
			case 'mask':
				return isMaskSolidAt(data, wx, wy);

			case 'surface':
				{
					var sy:Float = getSurfaceY(data, wx);

					if (Math.isNaN(sy))
						return false;

					return wy >= sy;
				}

			default:
				return wx >= data.x && wx < data.x + data.width && wy >= data.y && wy < data.y + data.height;
		}
	}

	private static function getSurfaceY(data:CollisionData, x:Float):Float
	{
		if (data.points == null || data.points.length < 2)
			return Math.NaN;

		for (i in 0...data.points.length - 1)
		{
			var p1:CollisionPoint = data.points[i];
			var p2:CollisionPoint = data.points[i + 1];

			if (x >= p1.x && x <= p2.x)
			{
				var dx:Float = p2.x - p1.x;

				if (dx == 0)
					return Math.min(p1.y, p2.y);

				return p1.y + (p2.y - p1.y) * ((x - p1.x) / dx);
			}
		}

		return Math.NaN;
	}

	private static inline function maskBit(data:CollisionData, lx:Int, ly:Int):Bool
	{
		return (data.maskBits.get(ly * data.maskStride + (lx >> 3)) & (0x80 >> (lx & 7))) != 0;
	}

	private static function isMaskSolidAt(data:CollisionData, worldX:Float, worldY:Float):Bool
	{
		if (data.maskBits == null)
			return false;

		var lx:Int = Std.int(Math.floor(worldX - data.x));
		var ly:Int = Std.int(Math.floor(worldY - data.y));

		if (lx < 0 || ly < 0 || lx >= data.maskW || ly >= data.maskH)
			return false;

		return maskBit(data, lx, ly);
	}

	private static function maskFindGround(data:CollisionData, worldX:Float, referenceY:Float, climb:Int, drop:Int):Float
	{
		if (data.maskBits == null)
			return Math.NaN;

		var lx:Int = Std.int(Math.floor(worldX - data.x));

		if (lx < 0 || lx >= data.maskW)
			return Math.NaN;

		var ly:Int = Std.int(Math.floor(referenceY - data.y));

		if (ly >= data.maskH)
			return Math.NaN;

		if (ly < 0)
		{
			if (-ly > drop)
				return Math.NaN;

			ly = 0;
		}

		if (maskBit(data, lx, ly))
		{
			var n:Int = 0;

			while (ly > 0 && n < climb && maskBit(data, lx, ly - 1))
			{
				ly--;
				n++;
			}

			if (ly > 0 && maskBit(data, lx, ly - 1))
				return Math.NaN;

			return data.y + ly;
		}

		var steps:Int = 0;

		while (ly < data.maskH - 1 && steps < drop)
		{
			ly++;
			steps++;

			if (maskBit(data, lx, ly))
				return data.y + ly;
		}

		return Math.NaN;
	}

	private static function maskFirstSolid(data:CollisionData, worldX:Float):Float
	{
		if (data.maskBits == null)
			return Math.NaN;

		var lx:Int = Std.int(Math.floor(worldX - data.x));

		if (lx < 0 || lx >= data.maskW)
			return Math.NaN;

		for (ly in 0...data.maskH)
		{
			if (maskBit(data, lx, ly))
				return data.y + ly;
		}

		return Math.NaN;
	}

	private static function maskCeilingY(data:CollisionData, worldX:Float, referenceY:Float, limit:Int):Float
	{
		if (data.maskBits == null)
			return Math.NaN;

		var lx:Int = Std.int(Math.floor(worldX - data.x));
		var ly:Int = Std.int(Math.floor(referenceY - data.y));

		if (lx < 0 || lx >= data.maskW || ly < 0 || ly >= data.maskH)
			return Math.NaN;

		if (!maskBit(data, lx, ly))
			return Math.NaN;

		var n:Int = 0;

		while (ly + 1 < data.maskH && n < limit && maskBit(data, lx, ly + 1))
		{
			ly++;
			n++;
		}

		if (n >= limit)
			return Math.NaN;

		return data.y + ly + 1;
	}

	private static function maskColumnHit(data:CollisionData, worldX:Float, topY:Float, bottomY:Float):Bool
	{
		var start:Int = Std.int(Math.floor(topY));
		var end:Int = Std.int(Math.ceil(bottomY));

		for (y in start...end + 1)
		{
			if (isMaskSolidAt(data, worldX, y))
				return true;
		}

		return false;
	}

	private static function maskObjectTouches(data:CollisionData, r:CRect):Bool
	{
		var top:Float = r.y;
		var bottom:Float = r.y + r.h - 1;

		if (maskColumnHit(data, r.x, top, bottom))
			return true;

		if (maskColumnHit(data, r.x + r.w - 1, top, bottom))
			return true;

		var centerX:Float = r.x + r.w * 0.5;

		return isMaskSolidAt(data, centerX, bottom) || isMaskSolidAt(data, centerX, top);
	}

	private static function getGroundAngleAtData(data:CollisionData, x:Float, referenceY:Float):Float
	{
		if (data.kind == 'surface')
		{
			if (data.points == null || data.points.length < 2)
				return 0;

			for (i in 0...data.points.length - 1)
			{
				var p1:CollisionPoint = data.points[i];
				var p2:CollisionPoint = data.points[i + 1];

				if (x >= p1.x && x <= p2.x)
				{
					var dx:Float = p2.x - p1.x;
					var dy:Float = p2.y - p1.y;

					if (dx == 0)
						return dy < 0 ? -90 : 90;

					return Math.atan2(dy, dx) * 180 / Math.PI;
				}
			}

			return 0;
		}

		if (data.kind == 'mask')
		{
			var sample:Float = 4;
			var leftY:Float;
			var rightY:Float;

			if (referenceY > 0)
			{
				leftY = maskFindGround(data, x - sample, referenceY, 24, 24);
				rightY = maskFindGround(data, x + sample, referenceY, 24, 24);
			}
			else
			{
				leftY = maskFirstSolid(data, x - sample);
				rightY = maskFirstSolid(data, x + sample);
			}

			if (Math.isNaN(leftY) || Math.isNaN(rightY))
				return 0;

			return Math.atan2(rightY - leftY, sample * 2) * 180 / Math.PI;
		}

		return 0;
	}

	private static function nearestGround(referenceY:Float, a:Float, b:Float, c:Float):Float
	{
		var best:Float = Math.NaN;
		var bestDistance:Float = Math.POSITIVE_INFINITY;

		var values:Array<Float> = [a, b, c];

		for (value in values)
		{
			if (Math.isNaN(value))
				continue;

			var distance:Float = Math.abs(referenceY - value);

			if (distance < bestDistance)
			{
				bestDistance = distance;
				best = value;
			}
		}

		return best;
	}

	private static function rectanglesOverlap(x1:Float, y1:Float, w1:Float, h1:Float, x2:Float, y2:Float, w2:Float, h2:Float):Bool
	{
		return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
	}

	private static function parseColor(value:String):FlxColor
	{
		var color:String = value;

		if (color == null || color.length == 0)
			return FlxColor.WHITE;

		if (color.charAt(0) == '#')
			color = color.substr(1);

		if (color.length == 6)
			color = 'FF' + color;

		if (color.length != 8)
			return FlxColor.WHITE;

		var parsed:Null<Int> = Std.parseInt('0x' + color);

		if (parsed == null)
			return FlxColor.WHITE;

		return cast parsed;
	}

	private static function normalizeType(collisionType:String):String
	{
		if (collisionType == null || collisionType.length == 0)
			return 'solid';

		return collisionType.toLowerCase();
	}

	private static function sortPoints(data:CollisionData):Void
	{
		data.points.sort(function(a:CollisionPoint, b:CollisionPoint):Int
		{
			if (a.x < b.x)
				return -1;

			if (a.x > b.x)
				return 1;

			return 0;
		});
	}

	private static function getLuaObject(tag:String):Dynamic
	{
		var game:PlayState = PlayState.instance;

		if (game == null || tag == null || tag.length == 0)
			return null;

		var object:Dynamic = game.getLuaObject(tag);

		if (object != null)
			return object;

		switch (tag)
		{
			case 'boyfriend':
				return game.boyfriend;
			case 'dad':
				return game.dad;
			case 'gf':
				return game.gf;
		}

		if (game.variables.exists(tag))
			return game.variables.get(tag);

		return null;
	}

	private static function getSprite(tag:String):FlxSprite
	{
		var object:Dynamic = getLuaObject(tag);

		if (object == null || !Std.isOfType(object, FlxSprite))
			return null;

		return cast object;
	}
}

class CollisionData
{
	public var tag:String;

	public var kind:String = 'box';

	public var x:Float = 0;
	public var y:Float = 0;

	public var width:Float = 0;
	public var height:Float = 0;

	public var collisionType:String = 'solid';
	public var enabled:Bool = true;

	public var objectTag:String = '';

	public var points:Array<CollisionPoint> = [];

	public var maskBits:Bytes = null;
	public var maskW:Int = 0;
	public var maskH:Int = 0;
	public var maskStride:Int = 0;

	public var maskImage:String = '';
	public var maskColor:FlxColor = FlxColor.WHITE;
	public var maskTolerance:Int = 20;

	public var debugSprite:FlxSprite = null;
	public var debugColor:FlxColor = FlxColor.RED;

	public var visible:Bool = false;

	public function new(tag:String)
	{
		this.tag = tag;
	}
}

class CollisionPoint
{
	public var x:Float;
	public var y:Float;

	public function new(x:Float, y:Float)
	{
		this.x = x;
		this.y = y;
	}
}

class MaskCache
{
	public var bits:Bytes;
	public var width:Int;
	public var height:Int;
	public var stride:Int;

	public function new(bits:Bytes, width:Int, height:Int, stride:Int)
	{
		this.bits = bits;
		this.width = width;
		this.height = height;
		this.stride = stride;
	}
}

class ObjectSensors
{
	public var hitOffX:Float = 0;
	public var hitOffY:Float = 0;
	public var hitW:Float = 0;
	public var hitH:Float = 0;

	public var climb:Int = 24;
	public var drop:Int = 12;
	public var stepHeight:Float = 16;
	public var tolerance:Float = 8;

	public var wallInset:Float = 4;
	public var sensorInset:Float = 2;

	public function new()
	{
	}
}
