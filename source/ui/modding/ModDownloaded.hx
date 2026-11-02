package ui.modding;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class ModDownloaded extends FlxState
{
    public static var modName:String = "Unknown Mod";
    public static var modAuthor:String = "Unknown Author";
    public static var modVersion:String = "1.0.0";
    public static var modDescription:String = "Mod ready to play.";
    public static var modIcon:String = "";
    public static var onPlay:Void->Void;
    public static var onBack:Void->Void;
    public static var onOpenFolder:Void->Void;
    public static var allowPlay:Bool = true;
    public static var allowOpenFolder:Bool = false;

    public var selected(default, null):Int = 0;
    public var closing(default, null):Bool = false;

    var background:FlxSprite;
    var panel:FlxSprite;
    var iconSprite:FlxSprite;
    var header:FlxText;
    var nameLabel:FlxText;
    var authorLabel:FlxText;
    var versionLabel:FlxText;
    var descriptionLabel:FlxText;
    var options:Array<FlxText> = [];
    var actions:Array<Int> = [];
    var inputDelay:Float = 0.15;
    var lastTouch:Bool = false;

    public function new()
    {
        super();
    }

    override public function create():Void
    {
        super.create();
        FlxG.camera.bgColor = 0xFF080D20;

        background = new FlxSprite();
        background.makeGraphic(FlxG.width, FlxG.height, 0xFF101C43);
        add(background);

        var panelWidth:Int = Std.int(Math.min(FlxG.width - 32, 760));
        var panelHeight:Int = Std.int(Math.min(FlxG.height - 24, 550));
        panel = new FlxSprite((FlxG.width - panelWidth) * 0.5, (FlxG.height - panelHeight) * 0.5);
        panel.makeGraphic(panelWidth, panelHeight, 0xFF182A58);
        add(panel);

        var left:Float = panel.x + 20;
        var top:Float = panel.y + 15;
        var innerWidth:Int = panelWidth - 40;

        header = makeLabel("MOD DOWNLOADED!", left, top, innerWidth, 30, 0xFF74F6C4);
        header.alignment = FlxTextAlign.CENTER;

        iconSprite = new FlxSprite(left, top + 60);
        var loaded:Bool = false;
        if (modIcon != null && modIcon.length > 0)
        {
            try
            {
                if (openfl.utils.Assets.exists(modIcon))
                {
                    iconSprite.loadGraphic(modIcon);
                    loaded = true;
                }
            }
            catch (error:Dynamic) {}
        }
        if (!loaded)
            iconSprite.makeGraphic(92, 92, 0xFF3573D5);
        iconSprite.setGraphicSize(92, 92);
        iconSprite.updateHitbox();
        add(iconSprite);

        var textX:Float = left + 108;
        var textWidth:Int = Std.int(Math.max(100, innerWidth - 108));
        nameLabel = makeLabel(modName, textX, top + 57, textWidth, 26, FlxColor.WHITE);
        authorLabel = makeLabel("By " + modAuthor, textX, top + 93, textWidth, 17, 0xFFB5C9ED);
        versionLabel = makeLabel("Version " + modVersion, textX, top + 119, textWidth, 16, 0xFF89DBF3);

        descriptionLabel = makeLabel(modDescription, left, top + 175, innerWidth, 19, 0xFFE0E7FA);
        descriptionLabel.wordWrap = true;

        actions = [];
        if (allowPlay) actions.push(0);
        if (allowOpenFolder) actions.push(1);
        actions.push(2);

        var spacing:Float = Math.min(56, Math.max(37, (panelHeight - 310) / actions.length));
        var optionStart:Float = panel.y + panelHeight - 28 - actions.length * spacing;
        for (i in 0...actions.length)
        {
            var label:String = switch (actions[i])
            {
                case 0: "PLAY MOD";
                case 1: "OPEN MOD FOLDER";
                default: "BACK";
            };
            var item = makeLabel(label, left, optionStart + i * spacing, innerWidth, 23, FlxColor.WHITE);
            item.alignment = FlxTextAlign.CENTER;
            options.push(item);
        }
        selected = 0;
        refreshSelection();
        FlxTween.tween(panel, {alpha: 1}, 0.25, {ease: FlxEase.quadOut});
    }

    function makeLabel(value:String, x:Float, y:Float, width:Int, size:Int, color:FlxColor):FlxText
    {
        var label = new FlxText(x, y, width, value, size);
        label.color = color;
        label.scrollFactor.set(0, 0);
        add(label);
        return label;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (closing) return;
        if (inputDelay > 0)
        {
            inputDelay -= elapsed;
            return;
        }

        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.LEFT)
            changeSelection(-1);
        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.RIGHT)
            changeSelection(1);
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            confirm();
        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            back();

        #if FLX_TOUCH
        var anyTouch:Bool = false;
        for (touch in FlxG.touches.list)
        {
            if (!touch.pressed) continue;
            anyTouch = true;
            if (!lastTouch)
            {
                for (i in 0...options.length)
                {
                    var option = options[i];
                    if (touch.screenX >= option.x && touch.screenX <= option.x + option.width
                        && touch.screenY >= option.y - 8 && touch.screenY <= option.y + option.height + 8)
                    {
                        selected = i;
                        refreshSelection();
                        confirm();
                        break;
                    }
                }
            }
            break;
        }
        lastTouch = anyTouch;
        #end
    }

    public function changeSelection(amount:Int):Void
    {
        if (closing || options.length == 0) return;
        selected = (selected + amount + options.length) % options.length;
        refreshSelection();
    }

    function refreshSelection():Void
    {
        for (i in 0...options.length)
        {
            options[i].color = i == selected ? 0xFFFFD34E : FlxColor.WHITE;
            options[i].scale.set(i == selected ? 1.06 : 1, i == selected ? 1.06 : 1);
        }
    }

    public function confirm():Void
    {
        if (closing || selected < 0 || selected >= actions.length) return;
        switch (actions[selected])
        {
            case 0:
                closing = true;
                if (onPlay != null) onPlay();
            case 1:
                if (onOpenFolder != null) onOpenFolder();
            case 2:
                back();
        }
    }

    public function back():Void
    {
        if (closing) return;
        closing = true;
        if (onBack != null) onBack();
    }

    override public function destroy():Void
    {
        options = [];
        actions = [];
        super.destroy();
    }
}
