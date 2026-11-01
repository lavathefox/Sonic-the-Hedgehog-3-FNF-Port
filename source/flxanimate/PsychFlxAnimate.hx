package flxanimate;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;
import haxe.Json;
import haxe.io.Path;
import StringTools;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class PsychFlxAnimate extends OriginalFlxAnimate
{
    public var lastLoadError(default, null):String = "";
    public var atlasLoaded(default, null):Bool = false;
    public var animationPaused(default, null):Bool = false;
    public var playbackSpeed(default, null):Float = 1;
    public var atlasFormat(default, null):String = "";
    public var atlasSource(default, null):String = "";

    var destroyedEx:Bool = false;

    public function loadAtlasEx(img:FlxGraphicAsset, ?pathOrStr:String, ?myJson:Dynamic):Void
    {
        if (!tryLoadAtlasEx(img, pathOrStr, myJson))
            throw new haxe.Exception(lastLoadError);
    }

    public function tryLoadAtlasEx(img:FlxGraphicAsset, ?pathOrStr:String, ?myJson:Dynamic):Bool
    {
        lastLoadError = "";
        atlasLoaded = false;
        atlasFormat = "";
        atlasSource = "";

        if (destroyedEx)
            return failLoad("Cannot load an atlas after destroy().");

        if (img == null)
            return failLoad("The atlas image is null.");

        if (pathOrStr == null || StringTools.trim(pathOrStr).length == 0)
            return failLoad("Atlas data or its file path is empty.");

        if (myJson == null)
            return failLoad("Animation metadata (AnimAtlas) is missing.");

        try
        {
            var animationData:AnimAtlas = parseAnimationData(myJson);
            if (animationData == null)
                return failLoad("Animation metadata could not be parsed.");

            var rawAtlas:String = readTextOrFile(pathOrStr);
            var format:String = detectFormat(pathOrStr, rawAtlas);
            var frameData:Dynamic;

            if (format == "xml")
                frameData = Xml.parse(rawAtlas);
            else
                frameData = Json.parse(rawAtlas);

            anim._loadAtlas(animationData);

            if (format == "xml")
                frames = FlxAnimateFrames.fromSparrow(cast frameData, img);
            else
                frames = FlxAnimateFrames.fromSpriteMap(cast frameData, img);

            if (anim.curInstance != null && anim.curInstance.symbol != null)
                origin = anim.curInstance.symbol.transformationPoint;

            atlasLoaded = true;
            animationPaused = false;
            playbackSpeed = 1;
            atlasFormat = format;
            atlasSource = pathOrStr;
            return true;
        }
        catch (e:Dynamic)
        {
            return failLoad(Std.string(e));
        }
    }

    public function loadAtlasFromText(img:FlxGraphicAsset, atlasText:String, animationJson:String):Void
    {
        loadAtlasEx(img, atlasText, animationJson);
    }

    public function loadAtlasFromFiles(img:FlxGraphicAsset, atlasPath:String, animationPath:String):Void
    {
        loadAtlasEx(img, atlasPath, animationPath);
    }

    public function hasAnimationInstance():Bool
    {
        return !destroyedEx && anim != null && anim.curInstance != null && anim.curSymbol != null;
    }

    public function isAnimationPlaying():Bool
    {
        return hasAnimationInstance() && !animationPaused;
    }

    public function pauseAnimation():Void
    {
        if (!hasAnimationInstance() || animationPaused)
            return;

        anim.pause();
        animationPaused = true;
    }

    public function resumeAnimation():Void
    {
        if (!hasAnimationInstance() || !animationPaused)
            return;

        anim.play();
        animationPaused = false;
    }

    public function toggleAnimationPause():Bool
    {
        if (!hasAnimationInstance())
            return false;

        if (animationPaused)
            resumeAnimation();
        else
            pauseAnimation();

        return animationPaused;
    }

    public function restartAnimation():Void
    {
        if (!hasAnimationInstance())
            return;

        anim.play();
        animationPaused = false;
    }

    public function setPlaybackSpeed(value:Float):Float
    {
        if (Math.isNaN(value) || !Math.isFinite(value))
            return playbackSpeed;

        playbackSpeed = Math.max(0, value);
        if (playbackSpeed == 0)
            pauseAnimation();
        else if (animationPaused)
            resumeAnimation();

        return playbackSpeed;
    }

    public function getAtlasInfo():Dynamic
    {
        return {
            loaded: atlasLoaded,
            format: atlasFormat,
            source: atlasSource,
            paused: animationPaused,
            playbackSpeed: playbackSpeed,
            hasInstance: hasAnimationInstance(),
            error: lastLoadError
        };
    }

    override function draw():Void
    {
        if (!hasAnimationInstance())
            return;

        super.draw();
    }

    override function destroy():Void
    {
        if (destroyedEx)
            return;

        destroyedEx = true;
        atlasLoaded = false;
        animationPaused = false;
        atlasSource = "";
        atlasFormat = "";
        super.destroy();
    }

    function failLoad(message:String):Bool
    {
        lastLoadError = message;
        return false;
    }

    static function parseAnimationData(value:Dynamic):AnimAtlas
    {
        if (Std.isOfType(value, String))
            return cast Json.parse(readTextOrFile(cast value));

        return cast value;
    }

    static function readTextOrFile(value:String):String
    {
        if (value == null)
            throw new haxe.Exception("Missing text or path.");

        var trimmed = StringTools.trim(value);
        if (trimmed.length == 0)
            throw new haxe.Exception("Empty text or path.");

        #if sys
        if (FileSystem.exists(trimmed) && !FileSystem.isDirectory(trimmed))
            return removeBOM(File.getContent(trimmed));
        #end

        return removeBOM(value);
    }

    static function detectFormat(source:String, content:String):String
    {
        var extension = Path.extension(StringTools.trim(source)).toLowerCase();
        if (extension == "xml")
            return "xml";
        if (extension == "json")
            return "json";

        var trimmed = StringTools.ltrim(content);
        if (StringTools.startsWith(trimmed, "<"))
            return "xml";
        if (StringTools.startsWith(trimmed, "{") || StringTools.startsWith(trimmed, "["))
            return "json";

        throw new haxe.Exception("Unrecognized atlas format; expected XML or JSON.");
    }

    static function removeBOM(value:String):String
    {
        if (value == null || value.length == 0)
            return "";

        if (value.charCodeAt(0) == 0xFEFF)
            return value.substr(1);

        if (StringTools.startsWith(value, "\xEF\xBB\xBF"))
            return value.substr(3);

        return value;
    }
}
