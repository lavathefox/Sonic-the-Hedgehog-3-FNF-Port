package ui.continue;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.text.FlxTextAlign;
import flixel.util.FlxColor;

class ContinueState extends FlxState
{
    public static var seconds:Int = 10;
    public static var continuesLeft:Int = 3;
    public static var onContinue:Void->Void;
    public static var onGiveUp:Void->Void;
    public static var backgroundColor:FlxColor = 0xFF101040;
    public static var accentColor:FlxColor = 0xFFFFD038;
    public static var titleText:String = "CONTINUE?";
    public static var continueText:String = "YES";
    public static var exitText:String = "NO";

    public var remaining(default, null):Int = 10;
    public var selection(default, null):Int = 0;
    public var finished(default, null):Bool = false;

    private var timer:Float = 0;
    private var title:FlxText;
    private var counter:FlxText;
    private var options:Array<FlxText> = [];
    private var hint:FlxText;
    private var emblem:FlxSprite;
    private var previousTouch:Bool = false;

    override public function create():Void
    {
        super.create();

        FlxG.camera.bgColor = backgroundColor;
        remaining = seconds < 1 ? 1 : seconds;
        selection = 0;
        finished = false;

        var cx:Float = FlxG.width * 0.5;
        var scale:Float = Math.min(FlxG.width / 959, FlxG.height / 670);

        var band:FlxSprite = new FlxSprite(0, FlxG.height * 0.12);
        band.makeGraphic(FlxG.width, Std.int(Math.max(1, FlxG.height * 0.72)), 0xFF182C78);
        add(band);

        emblem = new FlxSprite();
        emblem.makeGraphic(Std.int(Math.max(1, 108 * scale)), Std.int(Math.max(1, 108 * scale)), accentColor);
        emblem.x = cx - emblem.width * 0.5;
        emblem.y = FlxG.height * 0.22;
        add(emblem);

        title = makeText(titleText, FlxG.height * 0.10, Std.int(Math.max(18, 40 * scale)), FlxColor.WHITE);
        counter = makeText(Std.string(remaining), FlxG.height * 0.43, Std.int(Math.max(36, 96 * scale)), accentColor);

        var labels:Array<String> = [continueText, exitText];
        for (i in 0...2)
        {
            var option:FlxText = makeText(labels[i], FlxG.height * (0.66 + i * 0.11), Std.int(Math.max(18, 34 * scale)), FlxColor.WHITE);
            options.push(option);
        }

        hint = makeText("ENTER / TOUCH TO SELECT", FlxG.height * 0.92, Std.int(Math.max(10, 17 * scale)), 0xFFBBBBEE);
        refreshSelection();
    }

    private function makeText(value:String, y:Float, size:Int, color:FlxColor):FlxText
    {
        var item:FlxText = new FlxText(0, y, FlxG.width, value, size);
        item.alignment = FlxTextAlign.CENTER;
        item.color = color;
        item.scrollFactor.set(0, 0);
        add(item);
        return item;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (finished) return;

        timer += elapsed;
        while (timer >= 1 && !finished)
        {
            timer -= 1;
            remaining--;
            if (remaining <= 0)
            {
                remaining = 0;
                finish(false);
            }
            counter.text = Std.string(remaining);
        }

        if (finished) return;

        if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.LEFT)
            setSelection(selection - 1);
        if (FlxG.keys.justPressed.DOWN || FlxG.keys.justPressed.RIGHT)
            setSelection(selection + 1);

        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.SPACE)
            confirm();

        if (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.BACKSPACE)
            finish(false);

        #if FLX_TOUCH
        var touching:Bool = false;
        for (touch in FlxG.touches.list)
        {
            if (!touch.pressed) continue;
            touching = true;
            if (!previousTouch)
            {
                var y:Float = touch.screenY;
                if (y >= FlxG.height * 0.63 && y < FlxG.height * 0.86)
                {
                    selection = y >= FlxG.height * 0.74 ? 1 : 0;
                    refreshSelection();
                    confirm();
                }
                else if (y >= FlxG.height * 0.40)
                    setSelection(selection + 1);
            }
            break;
        }
        previousTouch = touching;
        #end
    }

    public function setSelection(index:Int):Void
    {
        if (finished) return;
        selection = (index % 2 + 2) % 2;
        refreshSelection();
    }

    private function refreshSelection():Void
    {
        for (i in 0...options.length)
        {
            options[i].color = i == selection ? accentColor : FlxColor.WHITE;
            options[i].text = (i == selection ? "> " : "  ") + (i == 0 ? continueText : exitText) + (i == selection ? " <" : "  ");
        }
    }

    public function confirm():Void
    {
        if (!finished) finish(selection == 0 && continuesLeft > 0);
    }

    public function finish(accepted:Bool):Void
    {
        if (finished) return;
        finished = true;
        if (accepted)
        {
            continuesLeft--;
            if (onContinue != null) onContinue();
        }
        else if (onGiveUp != null)
            onGiveUp();
    }

    override public function destroy():Void
    {
        options = [];
        super.destroy();
    }
}
