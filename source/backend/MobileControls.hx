package backend;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import mobile.HitBox;
import objects.Hitbox;
import mobile.AndroidOptions;
import mobile.DeviceUtil;
import mobile.TouchCursor;
import mobile.input.TouchInput;

class MobileControls
{
    public static var isAndroid(default, null):Bool = #if android true #else false #end;
    public static var enabled:Bool = true;
    public static var visible:Bool = true;

    public static var upPressed:Bool = false;
    public static var downPressed:Bool = false;
    public static var leftPressed:Bool = false;
    public static var rightPressed:Bool = false;
    public static var aPressed:Bool = false;
    public static var bPressed:Bool = false;
    public static var pausePressed:Bool = false;

    public static var upJustPressed:Bool = false;
    public static var downJustPressed:Bool = false;
    public static var leftJustPressed:Bool = false;
    public static var rightJustPressed:Bool = false;
    public static var aJustPressed:Bool = false;
    public static var bJustPressed:Bool = false;
    public static var pauseJustPressed:Bool = false;

    public static var upJustReleased:Bool = false;
    public static var downJustReleased:Bool = false;
    public static var leftJustReleased:Bool = false;
    public static var rightJustReleased:Bool = false;
    public static var aJustReleased:Bool = false;
    public static var bJustReleased:Bool = false;
    public static var pauseJustReleased:Bool = false;

    public static var arrows:FlxSprite;
    public static var buttonA:FlxSprite;
    public static var buttonB:FlxSprite;
    public static var pauseButton:FlxSprite;
    public static var gameplayHitbox:Hitbox;
    public static var hitboxArrows:HitBox;
    public static var hitboxA:HitBox;
    public static var hitboxB:HitBox;

    static var mobileCamera:FlxCamera;
    static var initialized:Bool = false;
    static var currentState:Dynamic;
    static var arrowX:Float = 80;
    static var arrowY:Float = 500;
    static var buttonAX:Float = 830;
    static var buttonAY:Float = 500;
    static var buttonBX:Float = 700;
    static var buttonBY:Float = 560;
    static var arrowScale:Float = 3;
    static var buttonScale:Float = 3;
    static var controlsOpacity:Float = 1;
    static var fadeTimer:Float = 0;
    static var fadeDuration:Float = 0.45;
    static var laneSignature:String = "";
    static var pauseImageLoaded:Bool = false;
    static var lastArrowsAnimation:String = "";

    static inline var ARROWS_IMAGE:String = "mobileControls/controlsArrows";
    static inline var BUTTON_A_IMAGE:String = "mobileControls/buttomA";
    static inline var BUTTON_B_IMAGE:String = "mobileControls/buttomB";
    static var PAUSE_IMAGES:Array<String> = [
        "mobile/pauseButton", "mobile/pausebutton", "mobile/PauseButton"
    ];

    public static function create():Void
    {
        #if android
        if (initialized)
        {
            ensureCamera();
            ensureGraphics();
            setVisible(visible);
            return;
        }

        AndroidOptions.loadSaved();
        createCamera();
        createGameplayHitbox();
        createArrows();
        createButtons();
        createHitboxes();
        createPauseButton();
        initialized = true;
        clearPressed();
        AndroidOptions.apply();
        TouchInput.initialize();
        TouchCursor.install();
        setVisible(visible);
        #end
    }

    #if android
    static function createCamera():Void
    {
        mobileCamera = new FlxCamera();
        mobileCamera.bgColor.alpha = 0;
        mobileCamera.scroll.set(0, 0);
        mobileCamera.zoom = 1;
        FlxG.cameras.add(mobileCamera, false);
    }

    static function ensureCamera():Void
    {
        if (mobileCamera == null || FlxG.cameras.list.indexOf(mobileCamera) < 0)
            createCamera();

        if (arrows != null) arrows.cameras = [mobileCamera];
        if (buttonA != null) buttonA.cameras = [mobileCamera];
        if (buttonB != null) buttonB.cameras = [mobileCamera];
        if (pauseButton != null) pauseButton.cameras = [mobileCamera];
        if (hitboxArrows != null) hitboxArrows.cameras = [mobileCamera];
        if (hitboxA != null) hitboxA.cameras = [mobileCamera];
        if (hitboxB != null) hitboxB.cameras = [mobileCamera];
        if (gameplayHitbox != null) gameplayHitbox.cameras = [mobileCamera];
    }

    static function protect(graphic:FlxGraphic):Void
    {
        if (graphic != null && graphic.key != null)
            Paths.excludeAsset(graphic.key);
    }

    static function graphicUsable(sprite:FlxSprite):Bool
    {
        return sprite != null && sprite.graphic != null && sprite.graphic.bitmap != null;
    }

    static function ensureGraphics():Void
    {
        if (arrows != null && !graphicUsable(arrows)) loadArrowsGraphic();
        if (buttonA != null && !graphicUsable(buttonA)) loadButtonGraphic(buttonA, BUTTON_A_IMAGE);
        if (buttonB != null && !graphicUsable(buttonB)) loadButtonGraphic(buttonB, BUTTON_B_IMAGE);
        if (pauseButton != null && (!graphicUsable(pauseButton) || !pauseImageLoaded))
            loadPauseGraphic();
    }

    static function createGameplayHitbox():Void
    {
        AndroidOptions.applyLaneSettings();
        Hitbox.invisible = false;
        Hitbox.ignoreTop = 0;
        Hitbox.marginLeft = -50;
        Hitbox.marginRight = -50;
        gameplayHitbox = new Hitbox();
        gameplayHitbox.cameras = [mobileCamera];
        laneSignature = AndroidOptions.laneSignature();
    }

    static function refreshGameplayHitbox():Void
    {
        if (gameplayHitbox != null && laneSignature == AndroidOptions.laneSignature())
            return;
        if (gameplayHitbox != null)
        {
            if (currentState != null && currentState.members.contains(gameplayHitbox))
                currentState.remove(gameplayHitbox, false);
            gameplayHitbox.destroy();
        }
        createGameplayHitbox();
    }

    static function loadArrowsGraphic():Void
    {
        if (arrows == null) return;
        arrows.frames = Paths.getSparrowAtlas(ARROWS_IMAGE);
        protect(arrows.graphic);
        arrows.animation.addByPrefix("idle", "idle", 24, false);
        arrows.animation.addByPrefix("leftClick", "leftClick", 24, false);
        arrows.animation.addByPrefix("downClick", "downClick", 24, false);
        arrows.animation.addByPrefix("rightClick", "rightClick", 24, false);
        arrows.animation.addByPrefix("upClick", "upClick", 24, false);
        lastArrowsAnimation = "";
        playArrowAnimation("idle");
    }

    static function loadButtonGraphic(button:FlxSprite, path:String):Void
    {
        if (button == null) return;
        try
        {
            var graphic = Paths.image(path);
            if (graphic != null)
            {
                button.loadGraphic(graphic);
                protect(graphic);
                button.updateHitbox();
            }
        }
        catch (e:Dynamic) {}
    }

    static function createArrows():Void
    {
        arrows = new FlxSprite(arrowX, arrowY);
        loadArrowsGraphic();
        arrows.antialiasing = false;
        arrows.scale.set(arrowScale, arrowScale);
        arrows.updateHitbox();
        arrows.scrollFactor.set();
        arrows.cameras = [mobileCamera];
    }

    static function createButtons():Void
    {
        buttonA = new FlxSprite(buttonAX, buttonAY);
        buttonB = new FlxSprite(buttonBX, buttonBY);
        loadButtonGraphic(buttonA, BUTTON_A_IMAGE);
        loadButtonGraphic(buttonB, BUTTON_B_IMAGE);
        for (button in [buttonA, buttonB])
        {
            button.antialiasing = false;
            button.scale.set(buttonScale, buttonScale);
            button.updateHitbox();
            button.scrollFactor.set();
            button.cameras = [mobileCamera];
        }
    }

    static function createHitboxes():Void
    {
        hitboxArrows = new HitBox(arrowX, arrowY, arrows.width, arrows.height, "arrows");
        hitboxA = new HitBox(buttonAX, buttonAY, buttonA.width, buttonA.height, "buttonA");
        hitboxB = new HitBox(buttonBX, buttonBY, buttonB.width, buttonB.height, "buttonB");
        hitboxArrows.cameras = [mobileCamera];
        hitboxA.cameras = [mobileCamera];
        hitboxB.cameras = [mobileCamera];
        applyMobileOptions();
    }

    static function drawFallbackPauseIcon():Void
    {
        pauseButton.makeGraphic(56, 56, FlxColor.TRANSPARENT, true);
        FlxSpriteUtil.drawRoundRect(pauseButton, 0, 0, 56, 56, 12, 12, 0xAA000000);
        FlxSpriteUtil.drawRect(pauseButton, 18, 14, 8, 28, FlxColor.WHITE);
        FlxSpriteUtil.drawRect(pauseButton, 32, 14, 8, 28, FlxColor.WHITE);
    }

    static function loadPauseGraphic():Void
    {
        if (pauseButton == null) return;
        pauseImageLoaded = false;
        for (path in PAUSE_IMAGES)
        {
            try
            {
                var graphic = Paths.image(path);
                if (graphic != null && graphic.bitmap != null)
                {
                    pauseButton.loadGraphic(graphic);
                    protect(graphic);
                    pauseImageLoaded = true;
                    break;
                }
            }
            catch (e:Dynamic) {}
        }
        if (!pauseImageLoaded) drawFallbackPauseIcon();
        pauseButton.setGraphicSize(56, 56);
        pauseButton.updateHitbox();
        pauseButton.antialiasing = false;
    }

    static function createPauseButton():Void
    {
        pauseButton = new FlxSprite(FlxG.width - 80, 24);
        loadPauseGraphic();
        pauseButton.scrollFactor.set();
        pauseButton.cameras = [mobileCamera];
    }

    static function vibrateOnPress():Void
    {
        if (AndroidOptions.vibrationMs() <= 0) return;
        var pressed = upJustPressed || downJustPressed || leftJustPressed || rightJustPressed
            || aJustPressed || bJustPressed || pauseJustPressed;
        for (lane in 0...Hitbox.LANES)
            if (Hitbox.justPressed(lane)) pressed = true;
        if (pressed) DeviceUtil.tap();
    }

    static function playArrowAnimation(name:String):Void
    {
        if (arrows == null || arrows.animation == null || lastArrowsAnimation == name)
            return;
        arrows.animation.play(name, true);
        lastArrowsAnimation = name;
    }

    static function updateAnimation():Void
    {
        if (upPressed) playArrowAnimation("upClick");
        else if (downPressed) playArrowAnimation("downClick");
        else if (leftPressed) playArrowAnimation("leftClick");
        else if (rightPressed) playArrowAnimation("rightClick");
        else playArrowAnimation("idle");
    }

    static function inPauseArea(x:Float, y:Float):Bool
    {
        if (pauseButton == null || !pauseButton.visible) return false;
        return x >= pauseButton.x - 12 && x <= pauseButton.x + pauseButton.width + 12
            && y >= pauseButton.y - 12 && y <= pauseButton.y + pauseButton.height + 12;
    }

    static function inArrowArea(x:Float, y:Float):Bool
    {
        if (arrows == null || !arrows.visible) return false;
        return x >= arrows.x - 42 && x <= arrows.x + arrows.width + 42
            && y >= arrows.y && y <= arrows.y + arrows.height;
    }

    static function checkTouch(x:Float, y:Float):Void
    {
        if (inPauseArea(x, y))
        {
            pausePressed = true;
            return;
        }

        if (buttonA != null && buttonA.visible && hitboxA != null && hitboxA.containsPoint(x, y))
        {
            aPressed = true;
            return;
        }

        if (buttonB != null && buttonB.visible && hitboxB != null && hitboxB.containsPoint(x, y))
        {
            bPressed = true;
            return;
        }

        if (inArrowArea(x, y))
        {
            var dx = x - (arrows.x + arrows.width * 0.5);
            var dy = y - (arrows.y + arrows.height * 0.5);
            if (Math.abs(dx) > Math.abs(dy))
            {
                if (dx < 0) leftPressed = true;
                else rightPressed = true;
            }
            else
            {
                if (dy < 0) upPressed = true;
                else downPressed = true;
            }
        }
    }

    static function syncTouchActions():Void
    {
        if (Controls.instance == null) return;
        var values = [
            "ui_up" => upPressed,
            "ui_down" => downPressed,
            "ui_left" => leftPressed,
            "ui_right" => rightPressed,
            "accept" => aPressed,
            "back" => bPressed,
            "pause" => pausePressed
        ];
        for (action => down in values)
            Controls.instance.setTouchAction(action, -100, down);
    }
    #end

    public static function addToState(state:Dynamic):Void
    {
        #if android
        if (!initialized) create();
        if (state == null || !initialized) return;
        ensureCamera();
        ensureGraphics();

        if (currentState != state)
        {
            if (currentState != null) removeFromState(currentState);
            currentState = state;
        }

        var inSong = Std.isOfType(state, states.PlayState);
        if (inSong) refreshGameplayHitbox();

        if (inSong && gameplayHitbox != null && !state.members.contains(gameplayHitbox))
            state.add(gameplayHitbox);

        for (sprite in [arrows, buttonA, buttonB, hitboxArrows, hitboxA, hitboxB])
            if (sprite != null && !state.members.contains(sprite)) state.add(sprite);

        if (inSong && pauseButton != null && !state.members.contains(pauseButton))
            state.add(pauseButton);

        setVisible(visible);
        applyMobileOptions();
        #end
    }

    public static function removeFromState(state:Dynamic):Void
    {
        #if android
        if (state == null) return;
        for (sprite in [gameplayHitbox, arrows, buttonA, buttonB, hitboxArrows, hitboxA, hitboxB, pauseButton])
            if (sprite != null && state.members.contains(sprite)) state.remove(sprite, false);
        if (currentState == state) currentState = null;
        clearPressed();
        #end
    }

    public static function update():Void
    {
        #if android
        if (!initialized) return;
        TouchInput.update();

        var oldUp = upPressed;
        var oldDown = downPressed;
        var oldLeft = leftPressed;
        var oldRight = rightPressed;
        var oldA = aPressed;
        var oldB = bPressed;
        var oldPause = pausePressed;

        upPressed = downPressed = leftPressed = rightPressed = false;
        aPressed = bPressed = pausePressed = false;

        if (enabled && visible)
        {
            for (touch in FlxG.touches.list)
            {
                if (touch == null || !touch.pressed) continue;
                var point = touch.getScreenPosition(mobileCamera);
                checkTouch(point.x, point.y);
            }
        }

        upJustPressed = upPressed && !oldUp;
        downJustPressed = downPressed && !oldDown;
        leftJustPressed = leftPressed && !oldLeft;
        rightJustPressed = rightPressed && !oldRight;
        aJustPressed = aPressed && !oldA;
        bJustPressed = bPressed && !oldB;
        pauseJustPressed = pausePressed && !oldPause;

        upJustReleased = !upPressed && oldUp;
        downJustReleased = !downPressed && oldDown;
        leftJustReleased = !leftPressed && oldLeft;
        rightJustReleased = !rightPressed && oldRight;
        aJustReleased = !aPressed && oldA;
        bJustReleased = !bPressed && oldB;
        pauseJustReleased = !pausePressed && oldPause;

        syncTouchActions();
        if (enabled) vibrateOnPress();
        updateAnimation();

        if (fadeTimer > 0)
        {
            fadeTimer = Math.max(0, fadeTimer - FlxG.elapsed);
            var alpha = FlxEase.quadOut(1 - fadeTimer / fadeDuration);
            setAlpha(alpha);
        }
        #end
    }

    public static function isReservedTouch(touch:Dynamic):Bool
    {
        #if android
        if (touch == null || mobileCamera == null) return false;
        var p = touch.getScreenPosition(mobileCamera);
        return inPauseArea(p.x, p.y)
            || inArrowArea(p.x, p.y)
            || (buttonA != null && buttonA.visible && hitboxA != null && hitboxA.containsPoint(p.x, p.y))
            || (buttonB != null && buttonB.visible && hitboxB != null && hitboxB.containsPoint(p.x, p.y));
        #else
        return false;
        #end
    }

    public static function setVisible(value:Bool):Void
    {
        visible = value;
        #if android
        var showControls = value && !Std.isOfType(currentState, states.PlayState);
        if (arrows != null) arrows.visible = showControls;
        if (buttonA != null) buttonA.visible = showControls;
        if (buttonB != null) buttonB.visible = showControls;
        applyMobileOptions();
        if (!value) clearPressed();
        else fadeIn();
        #end
    }

    public static function fadeIn(duration:Float = 0.45):Void
    {
        #if android
        fadeDuration = Math.max(0.01, duration);
        fadeTimer = fadeDuration;
        setAlpha(0);
        #end
    }

    public static function setAlpha(value:Float):Void
    {
        #if android
        var alpha = Math.max(0, Math.min(1, value)) * controlsOpacity;
        if (arrows != null) arrows.alpha = alpha;
        if (buttonA != null) buttonA.alpha = alpha;
        if (buttonB != null) buttonB.alpha = alpha;
        #end
    }

    public static function setControlsOpacity(value:Float):Void
    {
        controlsOpacity = Math.max(0.1, Math.min(1, value));
        #if android
        if (fadeTimer <= 0) setAlpha(1);
        #end
    }

    public static function applyMobileOptions():Void
    {
        #if android
        var inSong = Std.isOfType(currentState, states.PlayState);
        var showAreas = ClientPrefs.data.mobileShowHitbox && visible;
        for (box in [hitboxArrows, hitboxA, hitboxB])
            if (box != null) box.visible = showAreas && !inSong;
        Hitbox.showIdle = showAreas && inSong;
        if (pauseButton != null)
            pauseButton.visible = ClientPrefs.data.mobilePauseButton && inSong && visible;
        #end
    }

    public static function isAttachedTo(state:Dynamic):Bool
    {
        #if android
        return initialized && currentState == state;
        #else
        return false;
        #end
    }

    public static function setEnabled(value:Bool):Void
    {
        enabled = value;
        if (!value) clearPressed();
    }

    public static function setPosition(
        newArrowX:Float, newArrowY:Float,
        newButtonAX:Float, newButtonAY:Float,
        newButtonBX:Float, newButtonBY:Float
    ):Void
    {
        arrowX = newArrowX;
        arrowY = newArrowY;
        buttonAX = newButtonAX;
        buttonAY = newButtonAY;
        buttonBX = newButtonBX;
        buttonBY = newButtonBY;
        #if android
        if (arrows != null) { arrows.x = arrowX; arrows.y = arrowY; }
        if (buttonA != null) { buttonA.x = buttonAX; buttonA.y = buttonAY; }
        if (buttonB != null) { buttonB.x = buttonBX; buttonB.y = buttonBY; }
        if (hitboxArrows != null) hitboxArrows.setBounds(arrowX, arrowY, arrows.width, arrows.height);
        if (hitboxA != null) hitboxA.setBounds(buttonAX, buttonAY, buttonA.width, buttonA.height);
        if (hitboxB != null) hitboxB.setBounds(buttonBX, buttonBY, buttonB.width, buttonB.height);
        #end
    }

    public static function setScale(newArrowScale:Float, newButtonScale:Float):Void
    {
        arrowScale = newArrowScale;
        buttonScale = newButtonScale;
        #if android
        if (arrows != null)
        {
            arrows.scale.set(arrowScale, arrowScale);
            arrows.updateHitbox();
            if (hitboxArrows != null) hitboxArrows.setBounds(arrows.x, arrows.y, arrows.width, arrows.height);
        }
        for (button in [buttonA, buttonB])
        {
            if (button == null) continue;
            button.scale.set(buttonScale, buttonScale);
            button.updateHitbox();
        }
        if (hitboxA != null) hitboxA.setBounds(buttonA.x, buttonA.y, buttonA.width, buttonA.height);
        if (hitboxB != null) hitboxB.setBounds(buttonB.x, buttonB.y, buttonB.width, buttonB.height);
        #end
    }

    static function clearPressed():Void
    {
        upPressed = downPressed = leftPressed = rightPressed = false;
        aPressed = bPressed = pausePressed = false;
        upJustPressed = downJustPressed = leftJustPressed = rightJustPressed = false;
        aJustPressed = bJustPressed = pauseJustPressed = false;
        upJustReleased = downJustReleased = leftJustReleased = rightJustReleased = false;
        aJustReleased = bJustReleased = pauseJustReleased = false;
        #if android
        syncTouchActions();
        #end
    }

    public static function destroy():Void
    {
        clearPressed();
        #if android
        if (currentState != null) removeFromState(currentState);
        for (sprite in [arrows, buttonA, buttonB, hitboxArrows, hitboxA, hitboxB, gameplayHitbox, pauseButton])
            if (sprite != null) sprite.destroy();
        arrows = null;
        buttonA = null;
        buttonB = null;
        hitboxArrows = null;
        hitboxA = null;
        hitboxB = null;
        gameplayHitbox = null;
        pauseButton = null;
        if (mobileCamera != null)
        {
            FlxG.cameras.remove(mobileCamera, true);
            mobileCamera = null;
        }
        TouchInput.dispose();
        #end
        currentState = null;
        initialized = false;
        enabled = true;
        visible = true;
    }
}
