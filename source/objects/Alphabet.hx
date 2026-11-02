package objects;

import haxe.Json;
import openfl.utils.Assets;
import openfl.utils.AssetType;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import StringTools;

#if (MODS_ALLOWED && sys)
import sys.FileSystem;
import sys.io.File;
#end

enum Alignment
{
    LEFT;
    CENTERED;
    RIGHT;
}

class Alphabet extends FlxSpriteGroup
{
    public var text(default, set):String = "";
    public var bold:Bool = false;
    public var letters:Array<AlphaCharacter> = [];
    public var isMenuItem:Bool = false;
    public var targetY:Int = 0;
    public var changeX:Bool = true;
    public var changeY:Bool = true;
    public var alignment(default, set):Alignment = LEFT;
    public var scaleX(default, set):Float = 1;
    public var scaleY(default, set):Float = 1;
    public var rows:Int = 0;
    public var distancePerItem:FlxPoint = FlxPoint.get(20, 120);
    public var startPosition:FlxPoint = FlxPoint.get();
    public var wrapWidth:Float = 0;
    public var lineHeight:Float = 85;
    public var spaceWidth:Float = 28;
    public var letterSpacing:Float = 2;
    public var menuLerpSpeed:Float = 9.6;
    public var menuVerticalMultiplier:Float = 1.3;
    public var autoWrap:Bool = true;
    public var image(default, set):String = "alphabet";

    public function new(x:Float, y:Float, text:String = "", ?bold:Bool = true)
    {
        super(x, y);
        startPosition.set(x, y);
        this.bold = bold;
        if (AlphaCharacter.allLetters == null)
            AlphaCharacter.loadAlphabetData();
        this.text = text;
    }

    public function setAlignmentFromString(align:String):Void
    {
        switch (StringTools.trim(align == null ? "" : align).toLowerCase())
        {
            case "right": alignment = RIGHT;
            case "center", "centered", "centre": alignment = CENTERED;
            default: alignment = LEFT;
        }
    }

    private function set_alignment(value:Alignment):Alignment
    {
        alignment = value;
        updateAlignment();
        return value;
    }

    private function set_image(value:String):String
    {
        if (value == null || value.length == 0) value = "alphabet";
        if (image == value) return value;
        image = value;
        for (letter in letters)
            letter.image = value;
        rebuild();
        return value;
    }

    private function updateAlignment():Void
    {
        for (letter in letters)
        {
            if (letter == null) continue;
            var amount:Float = switch (alignment)
            {
                case CENTERED: letter.rowWidth * 0.5;
                case RIGHT: letter.rowWidth;
                default: 0;
            };
            letter.alignOffset = amount * scaleX;
            letter.applyOffsets();
        }
    }

    private function set_text(value:String):String
    {
        if (value == null) value = "";
        value = StringTools.replace(value, "\\n", "\n");
        text = value;
        rebuild();
        return value;
    }

    public function rebuild():Void
    {
        clearLetters();
        createLetters(text);
        updateAlignment();
    }

    public function clearLetters():Void
    {
        for (letter in letters)
        {
            if (letter == null) continue;
            remove(letter, true);
            letter.destroy();
        }
        letters = [];
        rows = 0;
    }

    public function setScale(newX:Float, newY:Null<Float> = null):Void
    {
        if (newY == null) newY = newX;
        scaleX = newX;
        scaleY = newY;
    }

    private function set_scaleX(value:Float):Float
    {
        if (!Math.isFinite(value) || value <= 0) return scaleX;
        if (scaleX == value) return value;
        scaleX = value;
        scale.x = value;
        rebuild();
        return value;
    }

    private function set_scaleY(value:Float):Float
    {
        if (!Math.isFinite(value) || value <= 0) return scaleY;
        if (scaleY == value) return value;
        scaleY = value;
        scale.y = value;
        rebuild();
        return value;
    }

    public function softReloadLetters(ratioX:Float = 1, ratioY:Null<Float> = null):Void
    {
        if (ratioY == null) ratioY = ratioX;
        if (!Math.isFinite(ratioX) || !Math.isFinite(ratioY)) return;
        rebuild();
    }

    override public function update(elapsed:Float):Void
    {
        if (isMenuItem)
        {
            var factor:Float = Math.exp(-Math.max(0, elapsed) * Math.max(0, menuLerpSpeed));
            if (changeX) x = FlxMath.lerp(startPosition.x + targetY * distancePerItem.x, x, factor);
            if (changeY) y = FlxMath.lerp(startPosition.y + targetY * menuVerticalMultiplier * distancePerItem.y, y, factor);
        }
        super.update(elapsed);
    }

    public function snapToPosition():Void
    {
        if (!isMenuItem) return;
        if (changeX) x = startPosition.x + targetY * distancePerItem.x;
        if (changeY) y = startPosition.y + targetY * menuVerticalMultiplier * distancePerItem.y;
    }

    private function createLetters(value:String):Void
    {
        if (value == null || value.length == 0) return;
        var xPos:Float = 0;
        var row:Int = 0;
        var rowWidths:Array<Float> = [0];
        var limit:Float = wrapWidth > 0 ? wrapWidth : (autoWrap && !bold ? FlxG.width * 0.65 : 0);

        for (i in 0...value.length)
        {
            var character:String = value.charAt(i);
            if (character == "\r") continue;
            if (character == "\n")
            {
                rowWidths[row] = xPos;
                row++;
                xPos = 0;
                rowWidths.push(0);
                continue;
            }

            if (character == " " || (bold && character == "_"))
            {
                xPos += spaceWidth * scaleX;
                rowWidths[row] = xPos;
                continue;
            }

            var lower:String = character.toLowerCase();
            if (!AlphaCharacter.allLetters.exists(lower))
                lower = "?";

            var letter = new AlphaCharacter();
            letter.parent = this;
            if (letter.image != image) letter.image = image;
            letter.setupAlphaCharacter(xPos, row * lineHeight * scaleY, character, bold);
            var advance:Float = letter.width + (letter.letterOffset[0] + (bold ? 0 : letterSpacing)) * scaleX;

            if (limit > 0 && xPos > 0 && xPos + advance > limit)
            {
                rowWidths[row] = xPos;
                row++;
                xPos = 0;
                rowWidths.push(0);
                letter.setupAlphaCharacter(0, row * lineHeight * scaleY, character, bold);
                advance = letter.width + (letter.letterOffset[0] + (bold ? 0 : letterSpacing)) * scaleX;
            }

            letter.row = row;
            add(letter);
            letters.push(letter);
            xPos += advance;
            rowWidths[row] = xPos;
        }

        rows = row + 1;
        for (letter in letters)
            letter.rowWidth = rowWidths[letter.row] / scaleX;
    }

    override public function destroy():Void
    {
        clearLetters();
        distancePerItem.put();
        startPosition.put();
        super.destroy();
    }
}

typedef Letter = {
    ?anim:Null<String>,
    ?offsets:Array<Float>,
    ?offsetsBold:Array<Float>
}

class AlphaCharacter extends FlxSprite
{
    public static var allLetters:Map<String, Null<Letter>>;
    public static var alphabetDataPath(default, null):String = "";

    public static function loadAlphabetData(request:String = "alphabet"):Void
    {
        allLetters = new Map<String, Null<Letter>>();
        var path:String = Paths.getPath('images/$request.json');
        var fallback:String = Paths.getPath('images/alphabet.json');
        var content:String = null;

        #if (MODS_ALLOWED && sys)
        if (FileSystem.exists(path)) content = File.getContent(path);
        else if (FileSystem.exists(fallback))
        {
            path = fallback;
            content = File.getContent(path);
        }
        #end

        if (content == null)
        {
            if (Assets.exists(path, AssetType.TEXT)) content = Assets.getText(path);
            else if (Assets.exists(fallback, AssetType.TEXT))
            {
                path = fallback;
                content = Assets.getText(path);
            }
        }

        alphabetDataPath = path;
        if (content != null)
        {
            try
            {
                var data:Dynamic = Json.parse(content);
                var allowed:String = Reflect.field(data, "allowed");
                if (allowed != null)
                    for (i in 0...allowed.length)
                    {
                        var c = allowed.charAt(i).toLowerCase();
                        if (c != " ") allLetters.set(c, null);
                    }

                var chars:Dynamic = Reflect.field(data, "characters");
                if (chars != null)
                    for (key in Reflect.fields(chars))
                    {
                        var c = key.toLowerCase().substr(0, 1);
                        var entry:Dynamic = Reflect.field(chars, key);
                        if (allLetters.exists(c) && entry != null)
                            allLetters.set(c, {
                                anim: Reflect.field(entry, "animation"),
                                offsets: Reflect.field(entry, "normal"),
                                offsetsBold: Reflect.field(entry, "bold")
                            });
                    }
            }
            catch (error:Dynamic)
            {
                FlxG.log.error('Alphabet JSON error: ' + Std.string(error));
            }
        }
        else
            FlxG.log.warn('Alphabet JSON not found: ' + path);

        if (!allLetters.exists("?")) allLetters.set("?", {anim: "question"});
    }

    public var parent:Alphabet;
    public var image(default, set):String = "alphabet";
    public var alignOffset:Float = 0;
    public var letterOffset:Array<Float> = [0, 0];
    public var row:Int = 0;
    public var rowWidth:Float = 0;
    public var character:String = "?";
    public var curLetter:Letter = null;
    private var baseOffsetX:Float = 0;
    private var baseOffsetY:Float = 0;
    private var currentBold:Bool = false;

    public function new()
    {
        super();
        frames = Paths.getSparrowAtlas(image);
        antialiasing = ClientPrefs.data.antialiasing;
    }

    public function setupAlphaCharacter(x:Float, y:Float, ?character:String = null, ?bold:Null<Bool> = null):Void
    {
        this.x = x;
        this.y = y;
        if (bold == null) bold = parent != null ? parent.bold : false;
        currentBold = bold;
        scale.set(parent != null ? parent.scaleX : 1, parent != null ? parent.scaleY : 1);

        if (character != null)
        {
            this.character = character;
            var lower:String = character.toLowerCase();
            if (allLetters == null) loadAlphabetData();
            curLetter = allLetters.exists(lower) ? allLetters.get(lower) : allLetters.get("?");
            var prefix:String = curLetter != null && curLetter.anim != null ? curLetter.anim : lower;
            var postfix:String = bold ? " bold" : (isTypeAlphabet(lower) ? (lower == character ? " lowercase" : " uppercase") : " normal");
            playLetter(prefix + postfix);
            if (animation.curAnim == null)
                playLetter("question" + (bold ? " bold" : " normal"));
        }
        updateHitbox();
    }

    private function playLetter(name:String):Void
    {
        animation.addByPrefix(name, name, 24, false);
        animation.play(name, true);
    }

    public static function isTypeAlphabet(c:String):Bool
    {
        if (c == null || c.length == 0) return false;
        var ascii:Int = StringTools.fastCodeAt(c, 0);
        return (ascii >= 65 && ascii <= 90) || (ascii >= 97 && ascii <= 122)
            || (ascii >= 192 && ascii <= 214) || (ascii >= 216 && ascii <= 246)
            || (ascii >= 248 && ascii <= 255);
    }

    private function set_image(value:String):String
    {
        if (value == null || value.length == 0) value = "alphabet";
        if (image == value && frames != null) return value;
        image = value;
        frames = Paths.getSparrowAtlas(value);
        if (parent != null)
            setupAlphaCharacter(x, y, character, currentBold);
        return value;
    }

    public function applyOffsets():Void
    {
        offset.set(baseOffsetX + alignOffset, baseOffsetY);
    }

    public function updateLetterOffset():Void
    {
        letterOffset[0] = 0;
        letterOffset[1] = 0;
        var values:Array<Float> = null;
        if (curLetter != null)
            values = currentBold ? curLetter.offsetsBold : curLetter.offsets;
        if (values != null)
        {
            if (values.length > 0) letterOffset[0] = values[0];
            if (values.length > 1) letterOffset[1] = values[1];
        }
        var baseline:Float = (currentBold ? 70 : 110) * scale.y;
        baseOffsetX = letterOffset[0] * scale.x;
        baseOffsetY = letterOffset[1] * scale.y - (baseline - height);
        applyOffsets();
    }

    override public function updateHitbox():Void
    {
        super.updateHitbox();
        updateLetterOffset();
    }
}
