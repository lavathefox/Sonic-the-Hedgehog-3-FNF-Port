package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import backend.Mods;
import backend.Sonic3Storage;

#if mobile
import haxe.io.Path;
import lime.system.System;
#end

class PermissionState extends FlxState
{
    static inline var POLL_INTERVAL:Float = 0.35;
    static inline var REQUEST_COOLDOWN:Float = 1.5;
    static inline var FINISH_DELAY:Float = 0.3;
    static inline var MAX_PATH_CHARS:Int = 140;

    public static var allowSkip:Bool = true;
    public static var enableAnimations:Bool = true;
    public static var accentColor:FlxColor = 0xFF278AFF;
    public static var backgroundColor:FlxColor = 0xFF080F25;
    public static var onPermissionResult:Bool->Void;

    var background:FlxSprite;
    var overlay:FlxSprite;
    var panel:FlxSprite;
    var accentLine:FlxSprite;
    var titleText:FlxText;
    var bodyText:FlxText;
    var pathText:FlxText;
    var statusText:FlxText;
    var hintText:FlxText;
    var grantButton:FlxSprite;
    var grantLabel:FlxText;
    var skipButton:FlxSprite;
    var skipLabel:FlxText;
    var buttons:Array<FlxSprite> = [];
    var tweens:Array<FlxTween> = [];

    var selected:Int = 0;
    var requested:Bool = false;
    var finishing:Bool = false;
    var finished:Bool = false;
    var grantedAccess:Bool = false;
    var pollTimer:Float = 0;
    var grantCooldown:Float = 0;
    var finishTimer:Float = 0;
    var animationTime:Float = 0;
    var uiScale:Float = 1;
    var entranceTime:Float = 0;
    var grantBaseY:Float = 0;
    var skipBaseY:Float = 0;
    var previousMouseVisible:Bool = false;
    var previousAutoPause:Bool = true;

    override public function create():Void
    {
        super.create();

        previousMouseVisible = FlxG.mouse.visible;
        previousAutoPause = FlxG.autoPause;
        FlxG.autoPause = false;

        #if mobile
        FlxG.mouse.visible = false;
        #else
        FlxG.mouse.visible = true;
        #end

        FlxG.camera.bgColor = backgroundColor;
        buildInterface();
        animateEntrance();

        if (hasStoragePermission())
            beginFinish(true);
        else
            setStatus("Choose an option to continue.", 0xFFAEC5F5);
    }

    function buildInterface():Void
    {
        var w:Float = FlxG.width;
        var h:Float = FlxG.height;
        uiScale = Math.max(0.45, Math.min(w / 959, h / 670));

        background = new FlxSprite();
        background.makeGraphic(Std.int(w), Std.int(h), backgroundColor);
        background.scrollFactor.set();
        add(background);

        var panelW:Float = Math.min(w - 20 * uiScale, 810 * uiScale);
        var panelH:Float = Math.min(h - 16 * uiScale, 620 * uiScale);
        panel = makeRect((w - panelW) * 0.5, (h - panelH) * 0.5, panelW, panelH, 0xFF14234A);
        overlay = makeRect(panel.x + 3 * uiScale, panel.y + 3 * uiScale, panelW - 6 * uiScale, panelH - 6 * uiScale, 0xFF192D59);
        accentLine = makeRect(panel.x, panel.y, panelW, 5 * uiScale, accentColor);

        var inset:Float = 22 * uiScale;
        var contentX:Float = panel.x + inset;
        var contentW:Float = panelW - inset * 2;

        titleText = makeText(contentX, panel.y + 22 * uiScale, contentW,
            "STORAGE ACCESS", fontSize(34), FlxColor.WHITE);

        bodyText = makeText(contentX, panel.y + 83 * uiScale, contentW,
            "External mods need permission to access shared storage.\n"
            + "Allow access in Android settings, then return to the game.\n"
            + "You can also play using private app storage.",
            fontSize(19), 0xFFE0E8FF);

        pathText = makeText(contentX, panel.y + 208 * uiScale, contentW,
            "MODS FOLDER\n" + formatPath(getModsPath()), fontSize(14), 0xFFB7D5FF);

        var buttonW:Float = Math.min(contentW, 490 * uiScale);
        var buttonH:Float = Math.max(36, 60 * uiScale);
        var buttonX:Float = (w - buttonW) * 0.5;
        var firstY:Float = panel.y + panelH - 220 * uiScale;
        var secondY:Float = firstY + 76 * uiScale;

        grantButton = makeRect(buttonX, firstY, buttonW, buttonH, accentColor);
        grantLabel = makeText(buttonX, firstY + 10 * uiScale, buttonW,
            "GRANT ACCESS", fontSize(23), FlxColor.WHITE);
        skipButton = makeRect(buttonX, secondY, buttonW, buttonH, 0xFF485B83);
        skipLabel = makeText(buttonX, secondY + 12 * uiScale, buttonW,
            "CONTINUE WITHOUT ACCESS", fontSize(18), FlxColor.WHITE);

        buttons = [grantButton, skipButton];
        grantBaseY = grantButton.y;
        skipBaseY = skipButton.y;

        statusText = makeText(contentX, panel.y + panelH - 60 * uiScale,
            contentW, "", fontSize(16), 0xFFFFD76D);
        hintText = makeText(contentX, panel.y + panelH - 28 * uiScale,
            contentW, "ENTER: select    ARROWS: change    ESC: skip",
            fontSize(12), 0xFF9FB8E8);

        if (!allowSkip)
        {
            skipButton.visible = false;
            skipLabel.visible = false;
            hintText.text = "ENTER: grant access";
        }

        refreshSelection();
    }

    function makeRect(x:Float, y:Float, w:Float, h:Float, color:FlxColor):FlxSprite
    {
        var item = new FlxSprite(x, y);
        item.makeGraphic(Std.int(Math.max(1, w)), Std.int(Math.max(1, h)), color);
        item.scrollFactor.set();
        add(item);
        return item;
    }

    function makeText(x:Float, y:Float, width:Float, content:String, size:Int, color:FlxColor):FlxText
    {
        var item = new FlxText(x, y, width, content, size);
        item.setFormat(null, size, color, FlxTextAlign.CENTER);
        item.scrollFactor.set();
        add(item);
        return item;
    }

    function fontSize(value:Int):Int
    {
        return Std.int(Math.max(11, Math.round(value * uiScale)));
    }

    function getModsPath():String
    {
        try
        {
            var value = Sonic3Storage.getModsFolder();
            return value == null ? "Unavailable" : value;
        }
        catch (error:Dynamic)
        {
            return "Unavailable";
        }
    }

    function formatPath(value:String):String
    {
        if (value.length <= MAX_PATH_CHARS) return value;
        return value.substr(0, 65) + "\n...\n" + value.substr(value.length - 65);
    }

    function hasStoragePermission():Bool
    {
        try
        {
            return Sonic3Storage.hasPermission();
        }
        catch (error:Dynamic)
        {
            return false;
        }
    }

    function animateEntrance():Void
    {
        if (!enableAnimations) return;

        var items:Array<FlxSprite> = [
            panel, overlay, accentLine, titleText, bodyText, pathText,
            grantButton, grantLabel, skipButton, skipLabel, statusText, hintText
        ];

        for (i in 0...items.length)
        {
            var item = items[i];
            var y:Float = item.y;
            item.y += 18 * uiScale;
            item.alpha = 0;
            tweens.push(FlxTween.tween(item, {y: y, alpha: 1}, 0.38,
                {ease: FlxEase.quadOut, startDelay: i * 0.022}));
        }
    }

    function setStatus(message:String, color:FlxColor):Void
    {
        if (statusText == null) return;
        statusText.text = message;
        statusText.color = color;
    }

    function refreshSelection():Void
    {
        grantLabel.text = (selected == 0 ? "> " : "") + "GRANT ACCESS" + (selected == 0 ? " <" : "");
        skipLabel.text = (selected == 1 ? "> " : "") + "CONTINUE WITHOUT ACCESS" + (selected == 1 ? " <" : "");
        grantButton.color = selected == 0 ? FlxColor.WHITE : 0xFFCADCFF;
        skipButton.color = selected == 1 ? FlxColor.WHITE : 0xFFD3DEFA;
    }

    function tapped(target:FlxSprite):Bool
    {
        if (target == null || !target.visible || !target.exists) return false;

        #if FLX_TOUCH
        for (touch in FlxG.touches.list)
        {
            if (touch != null && touch.justPressed && touch.overlaps(target))
                return true;
        }
        #end

        #if !mobile
        return FlxG.mouse.justPressed && FlxG.mouse.overlaps(target);
        #else
        return false;
        #end
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (finished) return;

        #if mobile
        if (FlxG.mouse.visible) FlxG.mouse.visible = false;
        #end

        animationTime += elapsed;
        entranceTime += elapsed;

        if (finishing)
        {
            finishTimer += elapsed;
            if (finishTimer >= FINISH_DELAY)
            {
                finished = true;
                finish();
            }
            return;
        }

        if (grantCooldown > 0)
            grantCooldown = Math.max(0, grantCooldown - elapsed);

        pollTimer += elapsed;
        if (pollTimer >= POLL_INTERVAL)
        {
            pollTimer = 0;
            if (hasStoragePermission())
            {
                beginFinish(true);
                return;
            }
        }

        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.LEFT)
            changeSelection(-1);
        else if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.RIGHT)
            changeSelection(1);

        if (tapped(grantButton))
        {
            selected = 0;
            refreshSelection();
            onGrantPressed();
        }
        else if (allowSkip && tapped(skipButton))
        {
            selected = 1;
            refreshSelection();
            beginFinish(false);
        }
        else if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
        {
            if (selected == 0) onGrantPressed();
            else if (allowSkip) beginFinish(false);
        }
        else if (allowSkip && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE))
        {
            beginFinish(false);
        }

        if (!finishing && entranceTime > 0.55)
        {
            var pulse:Float = 0.95 + Math.sin(animationTime * 2.5) * 0.05;
            grantButton.alpha = selected == 0 ? 1 : pulse;
            skipButton.alpha = selected == 1 ? 1 : pulse;
        }
    }

    function changeSelection(direction:Int):Void
    {
        if (!allowSkip) return;
        selected = (selected + direction + 2) % 2;
        refreshSelection();
    }

    function onGrantPressed():Void
    {
        if (finishing || grantCooldown > 0) return;

        if (hasStoragePermission())
        {
            beginFinish(true);
            return;
        }

        grantCooldown = REQUEST_COOLDOWN;
        requested = true;
        setStatus("Waiting for Android storage permission...", 0xFFFFD76D);

        try
        {
            Sonic3Storage.requestPermission();
        }
        catch (error:Dynamic)
        {
            requested = false;
            setStatus("Could not open settings. Please try again.", 0xFFFF8F8F);
        }
    }

    function beginFinish(granted:Bool):Void
    {
        if (finishing || finished) return;

        finishing = true;
        grantedAccess = granted;
        finishTimer = 0;

        for (item in [grantButton, grantLabel, skipButton, skipLabel, hintText])
        {
            FlxTween.cancelTweensOf(item);
            item.visible = false;
        }

        FlxTween.cancelTweensOf(statusText);
        statusText.alpha = 1;
        setStatus(granted ? "Preparing mod folders..." : "Using private app storage...",
            0xFFBCEFCB);
    }

    function usePrivateStorage():Void
    {
        #if mobile
        try
        {
            var directory = System.applicationStorageDirectory;
            if (directory != null && directory.length > 0)
                Sys.setCwd(Path.addTrailingSlash(directory));
        }
        catch (error:Dynamic) {}
        #end
    }

    function finish():Void
    {
        var ready:Bool = false;

        if (grantedAccess)
        {
            try
            {
                ready = Sonic3Storage.ensureFolders(true);
                if (ready)
                    Sonic3Storage.syncBundledMods();
            }
            catch (error:Dynamic)
            {
                ready = false;
            }
        }

        if (!ready)
            usePrivateStorage();

        try
        {
            #if (LUA_ALLOWED && cpp)
            Mods.pushGlobalMods();
            #end
            Mods.loadTopMod();
        }
        catch (error:Dynamic) {}

        if (onPermissionResult != null)
        {
            try onPermissionResult(grantedAccess && ready)
            catch (error:Dynamic) {}
        }

        FlxG.switchState(new Sonic3TitleStateV2());
    }

    override public function destroy():Void
    {
        for (tween in tweens)
            if (tween != null) tween.cancel();
        tweens = [];

        FlxG.autoPause = previousAutoPause;
        #if mobile
        FlxG.mouse.visible = false;
        #else
        FlxG.mouse.visible = previousMouseVisible;
        #end

        buttons = [];
        super.destroy();
    }
}
