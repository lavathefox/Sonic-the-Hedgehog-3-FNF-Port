package modcharts;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.math.FlxMath;

private typedef ModchartTween =
{
    var id:String;
    var target:Dynamic;
    var property:String;
    var from:Float;
    var to:Float;
    var duration:Float;
    var delay:Float;
    var elapsed:Float;
    var ease:String;
    var onComplete:Void->Void;
}

private typedef ModchartEvent =
{
    var id:String;
    var time:Float;
    var callback:Void->Void;
}

class ModchartManager extends FlxBasic
{
    public var songTime(default, null):Float = 0;
    public var playbackRate:Float = 1;
    public var running:Bool = true;
    public var useExternalClock:Bool = false;
    public var onBeat:Int->Void;
    public var onStep:Int->Void;
    public var onSection:Int->Void;
    public var lastBeat(default, null):Int = -1;
    public var lastStep(default, null):Int = -1;
    public var lastSection(default, null):Int = -1;

    var tweens:Array<ModchartTween> = [];
    var events:Array<ModchartEvent> = [];
    var objects:Map<String, Dynamic> = new Map();
    var nextId:Int = 0;

    public function new()
    {
        super();
    }

    public function register(name:String, object:Dynamic):Void
    {
        if (name != null && name.length > 0 && object != null)
            objects.set(name, object);
    }

    public function unregister(name:String):Void
    {
        objects.remove(name);
    }

    public function getObject(name:String):Dynamic
    {
        return objects.get(name);
    }

    public function setProperty(target:Dynamic, path:String, value:Dynamic):Bool
    {
        var location = resolveProperty(target, path);
        if (location == null) return false;
        Reflect.setProperty(location.owner, location.field, value);
        return true;
    }

    public function getProperty(target:Dynamic, path:String):Dynamic
    {
        var location = resolveProperty(target, path);
        return location == null ? null : Reflect.getProperty(location.owner, location.field);
    }

    public function tween(id:String, target:Dynamic, property:String, to:Float, duration:Float, ease:String = "linear", delay:Float = 0, onComplete:Void->Void = null):Bool
    {
        if (target == null || property == null || property.length == 0 || Math.isNaN(to)) return false;
        var value:Dynamic = getProperty(target, property);
        if (value == null || !Std.isOfType(value, Float) && !Std.isOfType(value, Int)) return false;
        var from:Float = cast value;
        if (id == null || id.length == 0) id = "tween_" + nextId++;
        cancelTween(id);
        if (duration <= 0 && delay <= 0)
        {
            setProperty(target, property, to);
            if (onComplete != null) onComplete();
            return true;
        }
        tweens.push({id: id, target: target, property: property, from: from, to: to,
            duration: Math.max(0, duration), delay: Math.max(0, delay), elapsed: 0,
            ease: ease == null ? "linear" : ease.toLowerCase(), onComplete: onComplete});
        return true;
    }

    public function tweenObject(id:String, objectName:String, property:String, to:Float, duration:Float, ease:String = "linear", delay:Float = 0, onComplete:Void->Void = null):Bool
    {
        return tween(id, getObject(objectName), property, to, duration, ease, delay, onComplete);
    }

    public function cancelTween(id:String):Bool
    {
        var removed = false;
        var i = tweens.length;
        while (i-- > 0)
        {
            if (tweens[i].id == id)
            {
                tweens.splice(i, 1);
                removed = true;
            }
        }
        return removed;
    }

    public function cancelTweensOf(target:Dynamic):Void
    {
        var i = tweens.length;
        while (i-- > 0)
            if (tweens[i].target == target) tweens.splice(i, 1);
    }

    public function schedule(id:String, time:Float, callback:Void->Void):Void
    {
        if (callback == null || Math.isNaN(time)) return;
        if (id == null || id.length == 0) id = "event_" + nextId++;
        cancelEvent(id);
        events.push({id: id, time: Math.max(0, time), callback: callback});
    }

    public function scheduleBeat(id:String, beat:Int, bpm:Float, callback:Void->Void):Void
    {
        if (bpm > 0) schedule(id, beat * 60 / bpm, callback);
    }

    public function scheduleStep(id:String, step:Int, bpm:Float, callback:Void->Void):Void
    {
        if (bpm > 0) schedule(id, step * 15 / bpm, callback);
    }

    public function cancelEvent(id:String):Bool
    {
        var removed = false;
        var i = events.length;
        while (i-- > 0)
        {
            if (events[i].id == id)
            {
                events.splice(i, 1);
                removed = true;
            }
        }
        return removed;
    }

    public function notifyBeat(beat:Int):Void
    {
        if (beat != lastBeat)
        {
            lastBeat = beat;
            if (onBeat != null) onBeat(beat);
        }
    }

    public function notifyStep(step:Int):Void
    {
        if (step != lastStep)
        {
            lastStep = step;
            if (onStep != null) onStep(step);
        }
    }

    public function notifySection(section:Int):Void
    {
        if (section != lastSection)
        {
            lastSection = section;
            if (onSection != null) onSection(section);
        }
    }

    public function seek(seconds:Float, fireEvents:Bool = false):Void
    {
        songTime = Math.max(0, seconds);
        if (fireEvents) runDueEvents();
    }

    public function tick(elapsed:Float):Void
    {
        if (!running || elapsed <= 0 || Math.isNaN(elapsed)) return;
        var delta = elapsed * Math.max(0, playbackRate);
        songTime += delta;
        advanceTweens(delta);
        runDueEvents();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (!useExternalClock) tick(elapsed);
    }

    function advanceTweens(delta:Float):Void
    {
        var snapshot = tweens.copy();
        for (item in snapshot)
        {
            if (tweens.indexOf(item) < 0) continue;
            item.elapsed += delta;
            if (item.elapsed < item.delay) continue;
            var progress = item.duration <= 0 ? 1.0 : Math.min(1.0, (item.elapsed - item.delay) / item.duration);
            var value = item.from + (item.to - item.from) * easeValue(progress, item.ease);
            setProperty(item.target, item.property, value);
            if (progress >= 1)
            {
                tweens.remove(item);
                if (item.onComplete != null) item.onComplete();
            }
        }
    }

    function runDueEvents():Void
    {
        var due = [];
        for (item in events)
            if (item.time <= songTime) due.push(item);
        due.sort(function(a, b) return a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
        for (item in due)
        {
            if (events.remove(item)) item.callback();
        }
    }

    public function clear():Void
    {
        tweens = [];
        events = [];
        objects = new Map();
        songTime = 0;
        lastBeat = -1;
        lastStep = -1;
        lastSection = -1;
    }

    override public function destroy():Void
    {
        clear();
        onBeat = null;
        onStep = null;
        onSection = null;
        super.destroy();
    }

    static function resolveProperty(target:Dynamic, path:String):Null<{owner:Dynamic, field:String}>
    {
        if (target == null || path == null || path.length == 0) return null;
        var parts = path.split(".");
        var owner:Dynamic = target;
        for (i in 0...parts.length - 1)
        {
            owner = Reflect.getProperty(owner, parts[i]);
            if (owner == null) return null;
        }
        var field = parts[parts.length - 1];
        return field.length == 0 ? null : {owner: owner, field: field};
    }

    static function easeValue(t:Float, mode:String):Float
    {
        switch (mode)
        {
            case "quadin": return t * t;
            case "quadout": return t * (2 - t);
            case "quadinout": return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
            case "cubein": return t * t * t;
            case "cubeout": return 1 - Math.pow(1 - t, 3);
            case "cubeinout": return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
            case "sinein": return 1 - Math.cos(t * Math.PI / 2);
            case "sineout": return Math.sin(t * Math.PI / 2);
            case "sineinout": return -(Math.cos(Math.PI * t) - 1) / 2;
            default: return t;
        }
    }
}
