package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import backend.Mods;
import backend.Sonic3Storage;

class PermissionState extends FlxState
{
    static inline var POLL_INTERVAL:Float = 0.4;
    static inline var REQUEST_COOLDOWN:Float = 1.5;
    static inline var SETUP_DELAY:Float = 0.12;

    var background:FlxSprite;
    var panel:FlxSprite;
    var titleText:FlxText;
    var bodyText:FlxText;
    var statusText:FlxText;
    var hintText:FlxText;
    var grantButton:FlxSprite;
    var grantLabel:FlxText;
    var skipButton:FlxSprite;
    var skipLabel:FlxText;

    var requested:Bool = false;
    var finishing:Bool = false;
    var finished:Bool = false;
    var grantedAccess:Bool = false;
    var pollTimer:Float = 0;
    var grantCooldown:Float = 0;
    var setupTimer:Float = 0;
    var uiScale:Float = 1;

    override public function create():Void
    {
        super.create();
        FlxG.mouse.visible = true;
        buildInterface();
        if (hasStoragePermission())
            beginFinish(true);
    }

    function buildInterface():Void
    {
        var w:Float = FlxG.width;
        var h:Float = FlxG.height;
        uiScale = Math.min(w / 959, h / 670);
        if (uiScale <= 0) uiScale = 1;

        background = new FlxSprite();
        background.makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(8, 14, 34));
        add(background);

        var panelW:Int = Std.int(Math.min(w - 28 * uiScale, 820 * uiScale));
        var panelH:Int = Std.int(Math.min(h - 20 * uiScale, 620 * uiScale));
        panel = new FlxSprite((w - panelW) / 2, (h - panelH) / 2);
        panel.makeGraphic(panelW, panelH, FlxColor.fromRGB(17, 29, 62));
        add(panel);

        var inset:Float = 24 * uiScale;
        var contentX:Float = panel.x + inset;
        var contentW:Float = panelW - inset * 2;
        var titleSize:Int = fontSize(36);
        var bodySize:Int = fontSize(21);
        var smallSize:Int = fontSize(17);

        titleText = new FlxText(contentX, panel.y + 28 * uiScale, contentW, "STORAGE ACCESS", titleSize);
        titleText.setFormat(null, titleSize, FlxColor.WHITE, CENTER);
        add(titleText);

        bodyText = new FlxText(contentX, panel.y + 98 * uiScale, contentW, "", bodySize);
        bodyText.setFormat(null, bodySize, FlxColor.fromRGB(218, 228, 255), CENTER);
        bodyText.text = "Mods folder:\n" + Sonic3Storage.getModsFolder()
            + "\n\nAllow file access to use external mods. Open Android settings, enable access, and return to the game."
            + "\n\nYou can also continue using private app storage.";
        add(bodyText);

        var buttonW:Float = Math.min(contentW, 480 * uiScale);
        var buttonH:Float = 64 * uiScale;
        var buttonX:Float = (w - buttonW) / 2;
        var firstY:Float = panel.y + panelH - 220 * uiScale;
        var secondY:Float = firstY + 78 * uiScale;

        grantButton = makeButton(buttonX, firstY, buttonW, buttonH, FlxColor.fromRGB(24, 116, 240));
        grantLabel = makeLabel(grantButton, "GRANT ACCESS", fontSize(25));
        skipButton = makeButton(buttonX, secondY, buttonW, buttonH, FlxColor.fromRGB(68, 81, 112));
        skipLabel = makeLabel(skipButton, "CONTINUE WITHOUT ACCESS", fontSize(19));

        statusText = new FlxText(contentX, panel.y + panelH - 57 * uiScale, contentW, "", smallSize);
        statusText.setFormat(null, smallSize, FlxColor.YELLOW, CENTER);
        add(statusText);

        hintText = new FlxText(contentX, panel.y + panelH - 27 * uiScale, contentW,
            "ENTER: grant    ESC: continue", fontSize(12));
        hintText.setFormat(null, fontSize(12), FlxColor.fromRGB(158, 177, 213), CENTER);
        add(hintText);
    }

    function fontSize(base:Int):Int
    {
        return Std.int(Math.max(10, Math.round(base * uiScale)));
    }

    function makeButton(x:Float, y:Float, width:Float, height:Float, color:FlxColor):FlxSprite
    {
        var sprite = new FlxSprite(x, y);
        sprite.makeGraphic(Std.int(width), Std.int(height), color);
        add(sprite);
        return sprite;
    }

    function makeLabel(button:FlxSprite, caption:String, size:Int):FlxText
    {
        var label = new FlxText(button.x, button.y + (button.height - size * 1.35) / 2,
            button.width, caption, size);
        label.setFormat(null, size, FlxColor.WHITE, CENTER);
        add(label);
        return label;
    }

    function hasStoragePermission():Bool
    {
        try return Sonic3Storage.hasPermission()
        catch (e:Dynamic) return false;
    }

    function tapped(target:FlxSprite):Bool
    {
        if (target == null || !target.visible) return false;
        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(target)) return true;
        #if FLX_TOUCH
        for (touch in FlxG.touches.list)
            if (touch != null && touch.justPressed && touch.overlaps(target)) return true;
        #end
        return false;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (finished) return;

        if (finishing)
        {
            setupTimer += elapsed;
            if (setupTimer >= SETUP_DELAY)
            {
                finished = true;
                finish();
            }
            return;
        }

        if (grantCooldown > 0) grantCooldown = Math.max(0, grantCooldown - elapsed);

        if (requested)
        {
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
        }

        var grantHover:Bool = FlxG.mouse.overlaps(grantButton);
        var skipHover:Bool = FlxG.mouse.overlaps(skipButton);
        grantButton.alpha = grantHover ? 0.8 : 1;
        skipButton.alpha = skipHover ? 0.8 : 1;

        if (tapped(grantButton) || FlxG.keys.justPressed.ENTER)
            onGrantPressed();
        else if (tapped(skipButton) || FlxG.keys.justPressed.ESCAPE)
            beginFinish(false);
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
        pollTimer = 0;
        statusText.text = "Waiting for Android storage permission...";

        try Sonic3Storage.requestPermission()
        catch (e:Dynamic)
        {
            requested = false;
            statusText.text = "Could not open settings. Try again or continue without access.";
        }
    }

    function beginFinish(granted:Bool):Void
    {
        if (finishing || finished) return;
        finishing = true;
        grantedAccess = granted;
        setupTimer = 0;
        grantButton.visible = false;
        grantLabel.visible = false;
        skipButton.visible = false;
        skipLabel.visible = false;
        hintText.visible = false;
        statusText.text = granted ? "Preparing mod folders..." : "Using private app storage...";
    }

    function finish():Void
    {
        if (grantedAccess)
        {
            var ready:Bool = false;
            try ready = Sonic3Storage.ensureFolders(true)
            catch (e:Dynamic) ready = false;

            if (ready)
            {
                try Sonic3Storage.syncBundledMods() catch (e:Dynamic) {}
                try
                {
                    #if LUA_ALLOWED
                    Mods.pushGlobalMods();
                    #end
                    Mods.loadTopMod();
                }
                catch (e:Dynamic) {}
            }
        }
        FlxG.switchState(new Sonic3TitleStateV2());
    }
}
