package backend;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSubState;
import flixel.FlxCamera;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

import objects.Note;
import objects.Character;
import states.PlayState;

enum Countdown
{
    THREE;
    TWO;
    ONE;
    GO;
    START;
}

class BaseStage extends FlxBasic
{
    private var game(get, never):Dynamic;
    public var onPlayState(get, never):Bool;
    public var stageReady(default, null):Bool = false;
    public var stageDestroyed(default, null):Bool = false;

    public var paused(get, never):Bool;
    public var songName(get, never):String;
    public var isStoryMode(get, never):Bool;
    public var seenCutscene(get, never):Bool;
    public var inCutscene(get, set):Bool;
    public var canPause(get, set):Bool;
    public var members(get, never):Array<FlxBasic>;

    public var boyfriend(get, never):Character;
    public var dad(get, never):Character;
    public var gf(get, never):Character;
    public var boyfriendGroup(get, never):FlxSpriteGroup;
    public var dadGroup(get, never):FlxSpriteGroup;
    public var gfGroup(get, never):FlxSpriteGroup;

    public var unspawnNotes(get, never):Array<Note>;
    public var camGame(get, never):FlxCamera;
    public var camHUD(get, never):FlxCamera;
    public var camOther(get, never):FlxCamera;
    public var defaultCamZoom(get, set):Float;
    public var camFollow(get, never):FlxObject;

    public var curBeat:Int = 0;
    public var curDecBeat:Float = 0;
    public var curStep:Int = 0;
    public var curDecStep:Float = 0;
    public var curSection:Int = 0;

    private var ownedTweens:Array<FlxTween> = [];
    private var ownedTimers:Array<FlxTimer> = [];
    private var ownedObjects:Array<FlxBasic> = [];

    public function new()
    {
        super();
        if (!onPlayState)
        {
            FlxG.log.error('BaseStage must be created inside PlayState.');
            active = false;
            return;
        }

        if (PlayState.instance.stages == null)
        {
            FlxG.log.error('PlayState stage collection is unavailable.');
            active = false;
            return;
        }

        PlayState.instance.stages.push(this);
        stageReady = true;
        create();
    }

    public function create():Void {}
    public function createPost():Void {}
    public function countdownTick(count:Countdown, num:Int):Void {}
    public function startSong():Void {}
    public function beatHit():Void {}
    public function stepHit():Void {}
    public function sectionHit():Void {}
    public function closeSubState():Void {}
    public function openSubState(SubState:FlxSubState):Void {}

    public function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float):Void {}
    public function eventPushed(event:EventNote):Void {}
    public function eventPushedUnique(event:EventNote):Void {}
    public function goodNoteHit(note:Note):Void {}
    public function opponentNoteHit(note:Note):Void {}
    public function noteMiss(note:Note):Void {}
    public function noteMissPress(direction:Int):Void {}

    public function add(object:FlxBasic):FlxBasic
    {
        if (!onPlayState || object == null || stageDestroyed) return object;
        FlxG.state.add(object);
        return object;
    }

    public function remove(object:FlxBasic, splice:Bool = false):FlxBasic
    {
        if (!onPlayState || object == null) return object;
        FlxG.state.remove(object, splice);
        ownedObjects.remove(object);
        return object;
    }

    public function insert(position:Int, object:FlxBasic):FlxBasic
    {
        if (!onPlayState || object == null || stageDestroyed) return object;
        var list = members;
        if (list == null) return add(object);
        var index = position;
        if (index < 0) index = list.length;
        if (index > list.length) index = list.length;
        FlxG.state.insert(index, object);
        return object;
    }

    public function addOwned(object:FlxBasic):FlxBasic
    {
        if (object == null || !onPlayState || stageDestroyed) return object;
        add(object);
        if (ownedObjects.indexOf(object) < 0) ownedObjects.push(object);
        return object;
    }

    public function addBehindGF(obj:FlxBasic):FlxBasic return insert(indexBefore(gfGroup), obj);
    public function addBehindBF(obj:FlxBasic):FlxBasic return insert(indexBefore(boyfriendGroup), obj);
    public function addBehindDad(obj:FlxBasic):FlxBasic return insert(indexBefore(dadGroup), obj);

    private function indexBefore(object:FlxBasic):Int
    {
        if (members == null || object == null) return -1;
        return members.indexOf(object);
    }

    public function setDefaultGF(name:String):Void
    {
        if (!onPlayState || name == null || name.length == 0 || PlayState.SONG == null) return;
        if (PlayState.SONG.gfVersion == null || PlayState.SONG.gfVersion.length == 0)
            PlayState.SONG.gfVersion = name;
    }

    public function getStageObject(name:String):Dynamic
    {
        if (!onPlayState || name == null || name.length == 0 || game.variables == null) return null;
        return game.variables.get(name);
    }

    public function hasStageObject(name:String):Bool return getStageObject(name) != null;

    public function setStageObject(name:String, value:Dynamic):Void
    {
        if (!onPlayState || name == null || name.length == 0 || game.variables == null) return;
        game.variables.set(name, value);
    }

    public function removeStageObject(name:String):Bool
    {
        if (!onPlayState || name == null || game.variables == null) return false;
        return game.variables.remove(name);
    }

    public function setStartCallback(myfn:Void->Void):Void
    {
        if (onPlayState) PlayState.instance.startCallback = myfn;
    }

    public function setEndCallback(myfn:Void->Void):Void
    {
        if (onPlayState) PlayState.instance.endCallback = myfn;
    }

    public function trackTween(tween:FlxTween):FlxTween
    {
        if (tween != null && ownedTweens.indexOf(tween) < 0) ownedTweens.push(tween);
        return tween;
    }

    public function trackTimer(timer:FlxTimer):FlxTimer
    {
        if (timer != null && ownedTimers.indexOf(timer) < 0) ownedTimers.push(timer);
        return timer;
    }

    public function cancelStageActions():Void
    {
        for (tween in ownedTweens) if (tween != null) tween.cancel();
        for (timer in ownedTimers) if (timer != null) timer.cancel();
        ownedTweens.resize(0);
        ownedTimers.resize(0);
    }

    public function setCameraZoom(value:Float):Void
    {
        if (onPlayState && value > 0) defaultCamZoom = value;
    }

    public function setCameraFollow(x:Float, y:Float):Void
    {
        if (camFollow != null) camFollow.setPosition(x, y);
    }

    public function startCountdown():Bool return onPlayState ? PlayState.instance.startCountdown() : false;
    public function endSong():Bool return onPlayState ? PlayState.instance.endSong() : false;
    public function moveCameraSection():Void if (onPlayState) PlayState.instance.moveCameraSection();
    public function moveCamera(isDad:Bool):Void if (onPlayState) PlayState.instance.moveCamera(isDad);

    override public function destroy():Void
    {
        if (stageDestroyed) return;
        stageDestroyed = true;
        stageReady = false;
        cancelStageActions();

        if (onPlayState)
        {
            for (object in ownedObjects)
            {
                if (object != null)
                {
                    FlxG.state.remove(object, true);
                    object.destroy();
                }
            }
            if (PlayState.instance.stages != null)
                PlayState.instance.stages.remove(this);
        }
        ownedObjects.resize(0);
        super.destroy();
    }

    inline private function get_game():Dynamic return onPlayState ? PlayState.instance : null;
    inline private function get_onPlayState():Bool return PlayState.instance != null && Std.isOfType(FlxG.state, PlayState);
    inline private function get_paused():Bool return onPlayState ? game.paused : false;
    inline private function get_songName():String return onPlayState ? game.songName : '';
    inline private function get_isStoryMode():Bool return PlayState.isStoryMode;
    inline private function get_seenCutscene():Bool return PlayState.seenCutscene;
    inline private function get_inCutscene():Bool return onPlayState ? game.inCutscene : false;
    inline private function set_inCutscene(value:Bool):Bool { if (onPlayState) game.inCutscene = value; return value; }
    inline private function get_canPause():Bool return onPlayState ? game.canPause : false;
    inline private function set_canPause(value:Bool):Bool { if (onPlayState) game.canPause = value; return value; }
    inline private function get_members():Array<FlxBasic> return onPlayState ? game.members : null;
    inline private function get_boyfriend():Character return onPlayState ? game.boyfriend : null;
    inline private function get_dad():Character return onPlayState ? game.dad : null;
    inline private function get_gf():Character return onPlayState ? game.gf : null;
    inline private function get_boyfriendGroup():FlxSpriteGroup return onPlayState ? game.boyfriendGroup : null;
    inline private function get_dadGroup():FlxSpriteGroup return onPlayState ? game.dadGroup : null;
    inline private function get_gfGroup():FlxSpriteGroup return onPlayState ? game.gfGroup : null;
    inline private function get_unspawnNotes():Array<Note> return onPlayState ? cast game.unspawnNotes : [];
    inline private function get_camGame():FlxCamera return onPlayState ? game.camGame : null;
    inline private function get_camHUD():FlxCamera return onPlayState ? game.camHUD : null;
    inline private function get_camOther():FlxCamera return onPlayState ? game.camOther : null;
    inline private function get_defaultCamZoom():Float return onPlayState ? game.defaultCamZoom : 1;
    inline private function set_defaultCamZoom(value:Float):Float { if (onPlayState) game.defaultCamZoom = value; return value; }
    inline private function get_camFollow():FlxObject return onPlayState ? game.camFollow : null;
}
