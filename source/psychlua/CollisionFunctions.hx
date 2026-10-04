package psychlua;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

class CollisionFunctions
{
	private static var collisions:Map<String, CollisionData> = new Map<String, CollisionData>();

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

		funk.addLocalCallback('setCollisionSize', function(tag:String, width:Float, height:Float)
		{
			return setSize(tag, width, height);
		});

		funk.addLocalCallback('setCollisionType', function(tag:String, collisionType:String)
		{
			return setType(tag, collisionType);
		});

		funk.addLocalCallback('setCollisionVisible', function(tag:String, visible:Bool)
		{
			return setVisible(tag, visible);
		});

		funk.addLocalCallback('setCollisionDebugColor', function(tag:String, color:String)
		{
			return setDebugColor(tag, color);
		});

		funk.addLocalCallback('bindCollisionObject', function(collisionTag:String, objectTag:String)
		{
			return bindObject(collisionTag, objectTag);
		});

		funk.addLocalCallback('unbindCollisionObject', function(collisionTag:String)
		{
			return unbindObject(collisionTag);
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

		funk.addLocalCallback('isSolidAt', function(collisionTag:String, x:Float, y:Float)
		{
			return isSolidAt(collisionTag, x, y);
		});

		funk.addLocalCallback('isOnGround', function(objectTag:String, ?collisionTag:String = '')
		{
			return isOnGround(objectTag, collisionTag);
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

		funk.addLocalCallback('getGroundAngleAt', function(collisionTag:String, x:Float)
		{
			return getGroundAngleAt(collisionTag, x);
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

		if(width <= 0 || height <= 0)
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
		sprite.alpha = visible ? 0.35 : 0;
		sprite.scrollFactor.set(0, 0);

		if(PlayState.instance != null)
			PlayState.instance.add(sprite);

		data.debugSprite = sprite;

		collisions.set(tag, data);

		return true;
	}

	public static function createSpriteCollision(tag:String, spriteTag:String, collisionType:String = 'solid'):Bool
	{
		removeCollision(tag);

		var object:Dynamic = getLuaObject(spriteTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
		{
			trace('CollisionFunctions: Sprite "' + spriteTag + '" was not found.');
			return false;
		}

		var sprite:FlxSprite = cast object;

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

	public static function createCollisionMask(
		tag:String,
		image:String,
		x:Float,
		y:Float,
		collisionType:String = 'floor',
		color:String = 'FFFFFF',
		tolerance:Int = 20,
		debug:Bool = false
	):Bool
	{
		removeCollision(tag);

		if(image == null || image.length == 0)
		{
			trace('CollisionFunctions: Collision image path is empty.');
			return false;
		}

		var graphic:Dynamic = null;

		try
		{
			graphic = Paths.image(image);
		}
		catch(e:Dynamic)
		{
			trace('CollisionFunctions: Failed to load collision image "' + image + '".');
			return false;
		}

		if(graphic == null)
		{
			trace('CollisionFunctions: Collision image "' + image + '" was not found.');
			return false;
		}

		var bitmap:BitmapData = null;

		try
		{
			bitmap = graphic.bitmap;
		}
		catch(e:Dynamic)
		{
			bitmap = null;
		}

		if(bitmap == null)
		{
			trace('CollisionFunctions: Collision image "' + image + '" has no bitmap.');
			return false;
		}

		if(bitmap.width <= 0 || bitmap.height <= 0)
		{
			trace('CollisionFunctions: Collision image "' + image + '" has an invalid size.');
			return false;
		}

		var data:CollisionData = new CollisionData(tag);

		data.kind = 'mask';
		data.x = x;
		data.y = y;
		data.width = bitmap.width;
		data.height = bitmap.height;
		data.collisionType = normalizeType(collisionType);
		data.maskImage = image;
		data.maskColor = parseColor(color);
		data.maskTolerance = tolerance;

		if(data.maskTolerance < 0)
			data.maskTolerance = 0;

		data.maskSolid = [];
		data.columns = [];

		var targetRed:Int = (data.maskColor >> 16) & 0xFF;
		var targetGreen:Int = (data.maskColor >> 8) & 0xFF;
		var targetBlue:Int = data.maskColor & 0xFF;

		var pixelY:Int;
		var pixelX:Int;

		for(pixelY in 0...bitmap.height)
		{
			var row:Array<Bool> = [];

			for(pixelX in 0...bitmap.width)
			{
				var pixel:UInt = bitmap.getPixel32(pixelX, pixelY);
				var alpha:Int = Std.int((pixel >> 24) & 0xFF);

				if(alpha <= 0)
				{
					row.push(false);
					continue;
				}

				var red:Int = Std.int((pixel >> 16) & 0xFF);
				var green:Int = Std.int((pixel >> 8) & 0xFF);
				var blue:Int = Std.int(pixel & 0xFF);

				var matchesColor:Bool =
					Math.abs(red - targetRed) <= data.maskTolerance &&
					Math.abs(green - targetGreen) <= data.maskTolerance &&
					Math.abs(blue - targetBlue) <= data.maskTolerance;

				row.push(matchesColor);
			}

			data.maskSolid.push(row);
		}

		for(pixelX in 0...bitmap.width)
		{
			var column:Array<Float> = [];

			for(pixelY in 0...bitmap.height)
			{
				if(pixelY >= data.maskSolid.length)
					continue;

				if(pixelX >= data.maskSolid[pixelY].length)
					continue;

				if(data.maskSolid[pixelY][pixelX])
				{
					var isTop:Bool =
						pixelY == 0 ||
						!data.maskSolid[pixelY - 1][pixelX];

					if(isTop)
						column.push(data.y + pixelY);
				}
			}

			data.columns.push(column);
		}

		if(debug)
		{
			var debugSprite:FlxSprite = new FlxSprite(x, y);
			debugSprite.loadGraphic(graphic);
			debugSprite.alpha = 0.35;
			debugSprite.scrollFactor.set(0, 0);

			if(PlayState.instance != null)
				PlayState.instance.add(debugSprite);

			data.debugSprite = debugSprite;
			data.visible = true;
		}

		collisions.set(tag, data);

		trace(
			'CollisionFunctions: Loaded mask "' +
			tag +
			'" (' +
			bitmap.width +
			'x' +
			bitmap.height +
			').'
		);

		return true;
	}

	public static function addPoint(tag:String, x:Float, y:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null || data.kind != 'surface')
			return false;

		data.points.push(new CollisionPoint(x, y));
		sortPoints(data);

		return true;
	}

	public static function clearPoints(tag:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		data.points = [];

		return true;
	}

	public static function setPosition(tag:String, x:Float, y:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		var offsetX:Float = x - data.x;
		var offsetY:Float = y - data.y;

		data.x = x;
		data.y = y;

		if(data.kind == 'surface')
		{
			for(point in data.points)
			{
				point.x += offsetX;
				point.y += offsetY;
			}
		}

		if(data.debugSprite != null)
			data.debugSprite.setPosition(x, y);

		return true;
	}

	public static function setSize(tag:String, width:Float, height:Float):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		data.width = width;
		data.height = height;

		if(data.debugSprite != null)
		{
			data.debugSprite.setGraphicSize(Std.int(width), Std.int(height));
			data.debugSprite.updateHitbox();
		}

		return true;
	}

	public static function setType(tag:String, collisionType:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		data.collisionType = normalizeType(collisionType);

		return true;
	}

	public static function setVisible(tag:String, visible:Bool):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		data.visible = visible;

		if(data.debugSprite != null)
			data.debugSprite.alpha = visible ? 0.35 : 0;

		return true;
	}

	public static function setDebugColor(tag:String, color:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		data.debugColor = parseColor(color);

		if(data.debugSprite != null)
			data.debugSprite.color = data.debugColor;

		return true;
	}

	public static function bindObject(collisionTag:String, objectTag:String):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return false;

		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		data.objectTag = objectTag;

		updateDataFromObject(data);

		return true;
	}

	public static function unbindObject(collisionTag:String):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return false;

		data.objectTag = '';

		return true;
	}

	public static function updateCollision(tag:String):Bool
	{
		var data:CollisionData = collisions.get(tag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		return true;
	}

	public static function updateAll():Void
	{
		for(data in collisions)
			updateDataFromObject(data);
	}

	private static function updateDataFromObject(data:CollisionData):Void
	{
		if(data.objectTag == null || data.objectTag.length == 0)
			return;

		var object:Dynamic = getLuaObject(data.objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return;

		var sprite:FlxSprite = cast object;

		data.x = sprite.x;
		data.y = sprite.y;

		if(data.kind == 'sprite')
		{
			data.width = sprite.width;
			data.height = sprite.height;
		}

		if(data.debugSprite != null)
			data.debugSprite.setPosition(data.x, data.y);
	}

	public static function isTouchingObject(objectTag:String, collisionTag:String):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		if(data.kind == 'surface' || data.kind == 'mask')
			return isOnGround(objectTag, collisionTag);

		return rectanglesOverlap(
			sprite.x,
			sprite.y,
			sprite.width,
			sprite.height,
			data.x,
			data.y,
			data.width,
			data.height
		);
	}

	public static function isSolidAt(collisionTag:String, worldX:Float, worldY:Float):Bool
	{
		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		if(data.kind == 'mask')
			return isMaskSolidAt(data, worldX, worldY);

		if(data.kind == 'surface')
		{
			var surfaceY:Float = getSurfaceY(data, worldX);

			if(Math.isNaN(surfaceY))
				return false;

			return worldY >= surfaceY;
		}

		return worldX >= data.x &&
			worldX < data.x + data.width &&
			worldY >= data.y &&
			worldY < data.y + data.height;
	}

	public static function isOnGround(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getGroundCollision(sprite, collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		var leftX:Float = sprite.x + 2;
		var centerX:Float = sprite.x + sprite.width * 0.5;
		var rightX:Float = sprite.x + sprite.width - 2;
		var bottom:Float = sprite.y + sprite.height;

		var leftGround:Float = getSurfaceYForObject(data, leftX, bottom);
		var centerGround:Float = getSurfaceYForObject(data, centerX, bottom);
		var rightGround:Float = getSurfaceYForObject(data, rightX, bottom);

		return isGroundDistanceValid(bottom, leftGround) ||
			isGroundDistanceValid(bottom, centerGround) ||
			isGroundDistanceValid(bottom, rightGround);
	}

	public static function getGroundY(objectTag:String, collisionTag:String = ''):Float
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return Math.NaN;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getGroundCollision(sprite, collisionTag);

		if(data == null)
			return Math.NaN;

		updateDataFromObject(data);

		var bottom:Float = sprite.y + sprite.height;

		var leftX:Float = sprite.x + 2;
		var centerX:Float = sprite.x + sprite.width * 0.5;
		var rightX:Float = sprite.x + sprite.width - 2;

		var leftGround:Float = getSurfaceYForObject(data, leftX, bottom);
		var centerGround:Float = getSurfaceYForObject(data, centerX, bottom);
		var rightGround:Float = getSurfaceYForObject(data, rightX, bottom);

		var best:Float = nearestGround(bottom, leftGround, centerGround, rightGround);

		if(Math.isNaN(best))
			return Math.NaN;

		return best;
	}

	public static function getGroundYAt(collisionTag:String, x:Float, referenceY:Float = 0):Float
	{
		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return Math.NaN;

		updateDataFromObject(data);

		if(data.kind == 'surface')
			return getSurfaceY(data, x);

		if(data.kind == 'mask')
			return getMaskGroundY(data, x, referenceY);

		return data.y;
	}

	public static function getGroundAngle(objectTag:String, collisionTag:String = ''):Float
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return 0;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getGroundCollision(sprite, collisionTag);

		if(data == null)
			return 0;

		updateDataFromObject(data);

		var centerX:Float = sprite.x + sprite.width * 0.5;

		return getGroundAngleAtData(data, centerX);
	}

	public static function getGroundAngleAt(collisionTag:String, x:Float):Float
	{
		var data:CollisionData = collisions.get(collisionTag);

		if(data == null)
			return 0;

		updateDataFromObject(data);

		return getGroundAngleAtData(data, x);
	}

	public static function getGroundDistance(objectTag:String, collisionTag:String = ''):Float
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return Math.NaN;

		var sprite:FlxSprite = cast object;

		var groundY:Float = getGroundY(objectTag, collisionTag);

		if(Math.isNaN(groundY))
			return Math.NaN;

		return groundY - (sprite.y + sprite.height);
	}

	public static function snapToGround(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var groundY:Float = getGroundY(objectTag, collisionTag);

		if(Math.isNaN(groundY))
			return false;

		sprite.y = groundY - sprite.height;

		return true;
	}

	public static function resolveGround(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getGroundCollision(sprite, collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		var bottom:Float = sprite.y + sprite.height;

		var leftX:Float = sprite.x + 2;
		var centerX:Float = sprite.x + sprite.width * 0.5;
		var rightX:Float = sprite.x + sprite.width - 2;

		var leftGround:Float = getSurfaceYForObject(data, leftX, bottom);
		var centerGround:Float = getSurfaceYForObject(data, centerX, bottom);
		var rightGround:Float = getSurfaceYForObject(data, rightX, bottom);

		var groundY:Float = nearestGround(bottom, leftGround, centerGround, rightGround);

		if(Math.isNaN(groundY))
			return false;

		if(bottom >= groundY - 8 && bottom <= groundY + 32)
		{
			sprite.y = groundY - sprite.height;
			return true;
		}

		return false;
	}

	public static function resolveWalls(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getSolidCollision(sprite, collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		if(data.kind == 'mask')
		{
			var leftX:Float = sprite.x;
			var rightX:Float = sprite.x + sprite.width;

			var topY:Float = sprite.y + 4;
			var bottomY:Float = sprite.y + sprite.height - 4;

			var leftHit:Bool = maskVerticalHit(data, leftX, topY, bottomY);
			var rightHit:Bool = maskVerticalHit(data, rightX, topY, bottomY);

			if(leftHit)
			{
				var rightEdge:Float = findMaskRightEdge(data, leftX, topY, bottomY);
				sprite.x = rightEdge + 0.01;
				return true;
			}

			if(rightHit)
			{
				var leftEdge:Float = findMaskLeftEdge(data, rightX, topY, bottomY);
				sprite.x = leftEdge - sprite.width - 0.01;
				return true;
			}

			return false;
		}

		if(data.kind == 'surface')
			return false;

		if(!rectanglesOverlap(
			sprite.x,
			sprite.y,
			sprite.width,
			sprite.height,
			data.x,
			data.y,
			data.width,
			data.height
		))
			return false;

		var playerCenter:Float = sprite.x + sprite.width * 0.5;
		var collisionCenter:Float = data.x + data.width * 0.5;

		if(playerCenter < collisionCenter)
			sprite.x = data.x - sprite.width;
		else
			sprite.x = data.x + data.width;

		return true;
	}

	public static function resolveCeiling(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getSolidCollision(sprite, collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		if(data.kind == 'mask')
		{
			var leftX:Float = sprite.x + 2;
			var centerX:Float = sprite.x + sprite.width * 0.5;
			var rightX:Float = sprite.x + sprite.width - 2;
			var topY:Float = sprite.y;

			if(isSolidAt(data.tag, leftX, topY) ||
				isSolidAt(data.tag, centerX, topY) ||
				isSolidAt(data.tag, rightX, topY))
			{
				var ceilingY:Float = getMaskCeilingY(data, centerX, topY);

				if(!Math.isNaN(ceilingY))
				{
					sprite.y = ceilingY;
					return true;
				}
			}

			return false;
		}

		if(data.kind == 'surface')
			return false;

		if(!rectanglesOverlap(
			sprite.x,
			sprite.y,
			sprite.width,
			sprite.height,
			data.x,
			data.y,
			data.width,
			data.height
		))
			return false;

		if(sprite.y < data.y)
		{
			sprite.y = data.y - sprite.height;
			return true;
		}

		return false;
	}

	public static function resolveCollision(objectTag:String, collisionTag:String = ''):Bool
	{
		var result:Bool = false;

		if(resolveGround(objectTag, collisionTag))
			result = true;

		if(resolveWalls(objectTag, collisionTag))
			result = true;

		if(resolveCeiling(objectTag, collisionTag))
			result = true;

		return result;
	}

	public static function getWallCollision(objectTag:String, collisionTag:String = ''):Int
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return 0;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getSolidCollision(sprite, collisionTag);

		if(data == null)
			return 0;

		updateDataFromObject(data);

		if(data.kind == 'mask')
		{
			var topY:Float = sprite.y + 4;
			var bottomY:Float = sprite.y + sprite.height - 4;

			if(maskVerticalHit(data, sprite.x, topY, bottomY))
				return -1;

			if(maskVerticalHit(data, sprite.x + sprite.width, topY, bottomY))
				return 1;

			return 0;
		}

		if(data.kind == 'surface')
			return 0;

		if(!rectanglesOverlap(
			sprite.x,
			sprite.y,
			sprite.width,
			sprite.height,
			data.x,
			data.y,
			data.width,
			data.height
		))
			return 0;

		var playerCenter:Float = sprite.x + sprite.width * 0.5;
		var collisionCenter:Float = data.x + data.width * 0.5;

		return playerCenter < collisionCenter ? -1 : 1;
	}

	public static function isTouchingWall(objectTag:String, collisionTag:String = ''):Bool
	{
		return getWallCollision(objectTag, collisionTag) != 0;
	}

	public static function isTouchingCeiling(objectTag:String, collisionTag:String = ''):Bool
	{
		var object:Dynamic = getLuaObject(objectTag);

		if(object == null || !Std.isOfType(object, FlxSprite))
			return false;

		var sprite:FlxSprite = cast object;

		var data:CollisionData = getSolidCollision(sprite, collisionTag);

		if(data == null)
			return false;

		updateDataFromObject(data);

		if(data.kind == 'mask')
		{
			var y:Float = sprite.y;

			return isSolidAt(data.tag, sprite.x + 2, y) ||
				isSolidAt(data.tag, sprite.x + sprite.width * 0.5, y) ||
				isSolidAt(data.tag, sprite.x + sprite.width - 2, y);
		}

		if(data.kind == 'surface')
			return false;

		if(!rectanglesOverlap(
			sprite.x,
			sprite.y,
			sprite.width,
			sprite.height,
			data.x,
			data.y,
			data.width,
			data.height
		))
			return false;

		return sprite.y < data.y;
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

		if(data == null)
			return false;

		if(data.debugSprite != null)
		{
			data.debugSprite.kill();
			data.debugSprite.destroy();
			data.debugSprite = null;
		}

		collisions.remove(tag);

		return true;
	}

	public static function clearAll():Void
	{
		var tags:Array<String> = [];

		for(tag in collisions.keys())
			tags.push(tag);

		for(tag in tags)
			removeCollision(tag);
	}

	private static function getGroundCollision(sprite:FlxSprite, requestedTag:String):CollisionData
	{
		if(requestedTag != null && requestedTag.length > 0)
			return collisions.get(requestedTag);

		var best:CollisionData = null;
		var bestDistance:Float = Math.POSITIVE_INFINITY;

		for(data in collisions)
		{
			if(data.collisionType != 'floor' &&
				data.collisionType != 'ground' &&
				data.collisionType != 'solid')
				continue;

			var centerX:Float = sprite.x + sprite.width * 0.5;
			var bottom:Float = sprite.y + sprite.height;

			var groundY:Float = getSurfaceYForObject(data, centerX, bottom);

			if(Math.isNaN(groundY))
				continue;

			var distance:Float = Math.abs(bottom - groundY);

			if(distance < bestDistance)
			{
				bestDistance = distance;
				best = data;
			}
		}

		return best;
	}

	private static function getSolidCollision(sprite:FlxSprite, requestedTag:String):CollisionData
	{
		if(requestedTag != null && requestedTag.length > 0)
			return collisions.get(requestedTag);

		for(data in collisions)
		{
			if(data.collisionType != 'solid' &&
				data.collisionType != 'wall' &&
				data.collisionType != 'ceiling' &&
				data.collisionType != 'floor' &&
				data.collisionType != 'ground')
				continue;

			if(data.kind == 'mask')
			{
				if(maskObjectTouches(data, sprite))
					return data;

				continue;
			}

			if(data.kind == 'surface')
				continue;

			if(rectanglesOverlap(
				sprite.x,
				sprite.y,
				sprite.width,
				sprite.height,
				data.x,
				data.y,
				data.width,
				data.height
			))
				return data;
		}

		return null;
	}

	private static function getSurfaceYForObject(data:CollisionData, x:Float, referenceY:Float):Float
	{
		if(data.kind == 'surface')
			return getSurfaceY(data, x);

		if(data.kind == 'mask')
			return getMaskGroundY(data, x, referenceY);

		return data.y;
	}

	private static function getSurfaceY(data:CollisionData, x:Float):Float
	{
		if(data.points == null || data.points.length < 2)
			return Math.NaN;

		var i:Int;

		for(i in 0...data.points.length - 1)
		{
			var p1:CollisionPoint = data.points[i];
			var p2:CollisionPoint = data.points[i + 1];

			if(x >= p1.x && x <= p2.x)
			{
				var dx:Float = p2.x - p1.x;

				if(dx == 0)
					return Math.min(p1.y, p2.y);

				var percent:Float = (x - p1.x) / dx;

				return p1.y + (p2.y - p1.y) * percent;
			}
		}

		return Math.NaN;
	}

	private static function getMaskGroundY(data:CollisionData, worldX:Float, referenceY:Float):Float
	{
		if(data.maskSolid == null || data.maskSolid.length == 0)
			return Math.NaN;

		var localX:Int = Std.int(Math.floor(worldX - data.x));

		if(localX < 0 || localX >= Std.int(data.width))
			return Math.NaN;

		var startY:Int = 0;

		if(referenceY > 0)
			startY = Std.int(Math.max(0, Math.floor(referenceY - data.y - 32)));

		var endY:Int = data.maskSolid.length - 1;

		if(endY < startY)
			return Math.NaN;

		var best:Float = Math.NaN;
		var bestDistance:Float = Math.POSITIVE_INFINITY;

		var pixelY:Int;

		for(pixelY in startY...endY + 1)
		{
			if(pixelY < 0 || pixelY >= data.maskSolid.length)
				continue;

			var row:Array<Bool> = data.maskSolid[pixelY];

			if(row == null || localX < 0 || localX >= row.length)
				continue;

			if(!row[localX])
				continue;

			var isTop:Bool =
				pixelY == 0 ||
				pixelY - 1 < 0 ||
				localX >= data.maskSolid[pixelY - 1].length ||
				!data.maskSolid[pixelY - 1][localX];

			if(!isTop)
				continue;

			var worldY:Float = data.y + pixelY;

			if(referenceY <= 0)
				return worldY;

			var distance:Float = Math.abs(worldY - referenceY);

			if(worldY >= referenceY - 16 && distance < bestDistance)
			{
				bestDistance = distance;
				best = worldY;
			}
		}

		return best;
	}

	private static function getMaskCeilingY(data:CollisionData, worldX:Float, referenceY:Float):Float
	{
		if(data.maskSolid == null || data.maskSolid.length == 0)
			return Math.NaN;

		var localX:Int = Std.int(Math.floor(worldX - data.x));

		if(localX < 0 || localX >= Std.int(data.width))
			return Math.NaN;

		var startY:Int = Std.int(Math.max(0, Math.floor(referenceY - data.y - 16)));
		var endY:Int = Std.int(Math.min(
			data.maskSolid.length - 1,
			Math.floor(referenceY - data.y + 16)
		));

		if(endY < startY)
			return Math.NaN;

		var solidStart:Int = -1;
		var solidEnd:Int = -1;

		var pixelY:Int;

		for(pixelY in startY...endY + 1)
		{
			if(pixelY < 0 || pixelY >= data.maskSolid.length)
				continue;

			if(localX >= data.maskSolid[pixelY].length)
				continue;

			if(data.maskSolid[pixelY][localX])
			{
				if(solidStart < 0)
					solidStart = pixelY;

				solidEnd = pixelY;
			}
			else if(solidStart >= 0)
			{
				break;
			}
		}

		if(solidStart < 0 || solidEnd < 0)
			return Math.NaN;

		return data.y + solidEnd + 1;
	}

	private static function getGroundAngleAtData(data:CollisionData, x:Float):Float
	{
		if(data.kind == 'surface')
		{
			if(data.points == null || data.points.length < 2)
				return 0;

			var i:Int;

			for(i in 0...data.points.length - 1)
			{
				var p1:CollisionPoint = data.points[i];
				var p2:CollisionPoint = data.points[i + 1];

				if(x >= p1.x && x <= p2.x)
				{
					var dx:Float = p2.x - p1.x;
					var dy:Float = p2.y - p1.y;

					if(dx == 0)
						return dy < 0 ? -90 : 90;

					return Math.atan2(dy, dx) * 180 / Math.PI;
				}
			}

			return 0;
		}

		if(data.kind == 'mask')
		{
			var sampleDistance:Float = 4;

			var leftY:Float = getMaskGroundY(data, x - sampleDistance, 0);
			var rightY:Float = getMaskGroundY(data, x + sampleDistance, 0);

			if(Math.isNaN(leftY) || Math.isNaN(rightY))
				return 0;

			return Math.atan2(
				rightY - leftY,
				sampleDistance * 2
			) * 180 / Math.PI;
		}

		return 0;
	}

	private static function isMaskSolidAt(data:CollisionData, worldX:Float, worldY:Float):Bool
	{
		if(data.maskSolid == null || data.maskSolid.length == 0)
			return false;

		var localX:Int = Std.int(Math.floor(worldX - data.x));
		var localY:Int = Std.int(Math.floor(worldY - data.y));

		if(localX < 0 || localX >= Std.int(data.width))
			return false;

		if(localY < 0 || localY >= Std.int(data.height))
			return false;

		if(localY >= data.maskSolid.length)
			return false;

		if(localX >= data.maskSolid[localY].length)
			return false;

		return data.maskSolid[localY][localX];
	}

	private static function maskVerticalHit(data:CollisionData, worldX:Float, topY:Float, bottomY:Float):Bool
	{
		var start:Int = Std.int(Math.floor(topY));
		var end:Int = Std.int(Math.ceil(bottomY));

		if(end < start)
			return false;

		var y:Int;

		for(y in start...end + 1)
		{
			if(isMaskSolidAt(data, worldX, y))
				return true;
		}

		return false;
	}

	private static function findMaskLeftEdge(data:CollisionData, worldX:Float, topY:Float, bottomY:Float):Float
	{
		var x:Int = Std.int(Math.floor(worldX));

		var i:Int;

		for(i in 0...64)
		{
			var testX:Int = x - i;

			if(!maskVerticalHit(data, testX, topY, bottomY))
				return testX + 1;
		}

		return worldX;
	}

	private static function findMaskRightEdge(data:CollisionData, worldX:Float, topY:Float, bottomY:Float):Float
	{
		var x:Int = Std.int(Math.floor(worldX));

		var i:Int;

		for(i in 0...64)
		{
			var testX:Int = x + i;

			if(!maskVerticalHit(data, testX, topY, bottomY))
				return testX - 1;
		}

		return worldX;
	}

	private static function maskObjectTouches(data:CollisionData, sprite:FlxSprite):Bool
	{
		var left:Float = sprite.x;
		var right:Float = sprite.x + sprite.width;
		var top:Float = sprite.y;
		var bottom:Float = sprite.y + sprite.height;

		if(maskVerticalHit(data, left, top, bottom))
			return true;

		if(maskVerticalHit(data, right, top, bottom))
			return true;

		var centerX:Float = sprite.x + sprite.width * 0.5;

		if(isSolidAt(data.tag, centerX, bottom))
			return true;

		if(isSolidAt(data.tag, centerX, top))
			return true;

		return false;
	}

	private static function isGroundDistanceValid(bottom:Float, groundY:Float):Bool
	{
		if(Math.isNaN(groundY))
			return false;

		return bottom >= groundY - 8 &&
			bottom <= groundY + 8;
	}

	private static function nearestGround(referenceY:Float, a:Float, b:Float, c:Float):Float
	{
		var best:Float = Math.NaN;
		var bestDistance:Float = Math.POSITIVE_INFINITY;

		var values:Array<Float> = [a, b, c];

		for(value in values)
		{
			if(Math.isNaN(value))
				continue;

			var distance:Float = Math.abs(referenceY - value);

			if(distance < bestDistance)
			{
				bestDistance = distance;
				best = value;
			}
		}

		return best;
	}

	private static function rectanglesOverlap(
		x1:Float,
		y1:Float,
		w1:Float,
		h1:Float,
		x2:Float,
		y2:Float,
		w2:Float,
		h2:Float
	):Bool
	{
		return x1 < x2 + w2 &&
			x1 + w1 > x2 &&
			y1 < y2 + h2 &&
			y1 + h1 > y2;
	}

	private static function parseColor(value:String):FlxColor
	{
		var color:String = value;

		if(color == null || color.length == 0)
			return FlxColor.WHITE;

		if(color.charAt(0) == '#')
			color = color.substr(1);

		if(color.length == 6)
			color = 'FF' + color;

		if(color.length != 8)
			return FlxColor.WHITE;

		var parsed:Null<Int> = Std.parseInt('0x' + color);

		if(parsed == null)
			return FlxColor.WHITE;

		return cast parsed;
	}

	private static function normalizeType(collisionType:String):String
	{
		if(collisionType == null || collisionType.length == 0)
			return 'solid';

		return collisionType.toLowerCase();
	}

	private static function sortPoints(data:CollisionData):Void
	{
		data.points.sort(function(a:CollisionPoint, b:CollisionPoint):Int
		{
			if(a.x < b.x)
				return -1;

			if(a.x > b.x)
				return 1;

			return 0;
		});
	}

	private static function getLuaObject(tag:String):Dynamic
	{
		if(PlayState.instance == null)
			return null;

		if(tag == null || tag.length == 0)
			return null;

		return PlayState.instance.getLuaObject(tag);
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

	public var objectTag:String = '';

	public var points:Array<CollisionPoint> = [];
	public var columns:Array<Array<Float>> = [];
	public var maskSolid:Array<Array<Bool>> = [];

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
