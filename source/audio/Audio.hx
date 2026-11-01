package audio;

import flixel.FlxG;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxSoundAsset;

class Audio
{
    public static var initialized(default, null):Bool = false;
    public static var masterVolume(default, null):Float = 1;
    public static var musicVolume(default, null):Float = 1;
    public static var soundVolume(default, null):Float = 1;
    public static var muted(default, null):Bool = false;
    public static var currentMusic(default, null):String = "";

    static var channels:Map<String, FlxSound> = new Map();
    static var channelVolumes:Map<String, Float> = new Map();
    static var fades:Array<AudioFade> = [];
    static var musicBaseVolume:Float = 1;
    static var musicFadeVolume:Float = 1;
    static var musicPaused:Bool = false;
    static var nextId:Int = 0;

    public static function initialize():Void
    {
        if (initialized) return;
        initialized = true;
        applyVolumes();
    }

    public static function playMusic(asset:FlxSoundAsset, ?name:String, volume:Float = 1, looped:Bool = true, fadeIn:Float = 0):Void
    {
        initialize();
        cancelFade("music");
        musicBaseVolume = clamp(volume);
        musicFadeVolume = fadeIn > 0 ? 0 : 1;
        musicPaused = false;
        currentMusic = name == null ? "" : name;
        FlxG.sound.playMusic(asset, 0, looped);
        applyMusicVolume();
        if (fadeIn > 0) fadeMusicTo(1, fadeIn);
    }

    public static function stopMusic(fadeOut:Float = 0):Void
    {
        if (FlxG.sound.music == null) return;
        if (fadeOut > 0)
        {
            fadeMusicTo(0, fadeOut, true);
            return;
        }
        cancelFade("music");
        FlxG.sound.music.stop();
        currentMusic = "";
        musicPaused = false;
        musicFadeVolume = 1;
    }

    public static function pauseMusic():Void
    {
        if (FlxG.sound.music == null || musicPaused) return;
        FlxG.sound.music.pause();
        musicPaused = true;
    }

    public static function resumeMusic():Void
    {
        if (FlxG.sound.music == null || !musicPaused) return;
        FlxG.sound.music.resume();
        musicPaused = false;
    }

    public static function toggleMusicPause():Bool
    {
        if (musicPaused) resumeMusic();
        else pauseMusic();
        return musicPaused;
    }

    public static function playSound(asset:FlxSoundAsset, volume:Float = 1, ?channel:String, looped:Bool = false):FlxSound
    {
        initialize();
        if (channel == null || channel.length == 0)
        {
            nextId++;
            channel = "sfx_" + nextId;
        }
        stopSound(channel);
        var sound = new FlxSound();
        sound.loadEmbedded(asset, looped);
        FlxG.sound.list.add(sound);
        channels.set(channel, sound);
        channelVolumes.set(channel, clamp(volume));
        sound.volume = effectiveSoundVolume(channel);
        sound.play();
        return sound;
    }

    public static function stopSound(channel:String):Void
    {
        if (!channels.exists(channel)) return;
        cancelFade(channel);
        var sound = channels.get(channel);
        channels.remove(channel);
        channelVolumes.remove(channel);
        if (sound != null)
        {
            sound.stop();
            FlxG.sound.list.remove(sound, true);
        }
    }

    public static function pauseSound(channel:String):Void
    {
        var sound = channels.get(channel);
        if (sound != null) sound.pause();
    }

    public static function resumeSound(channel:String):Void
    {
        var sound = channels.get(channel);
        if (sound != null) sound.resume();
    }

    public static function getSound(channel:String):FlxSound
    {
        return channels.get(channel);
    }

    public static function isSoundPlaying(channel:String):Bool
    {
        var sound = channels.get(channel);
        return sound != null && sound.playing;
    }

    public static function isMusicPlaying():Bool
    {
        return FlxG.sound.music != null && FlxG.sound.music.playing;
    }

    public static function setMasterVolume(value:Float):Void
    {
        masterVolume = clamp(value);
        applyVolumes();
    }

    public static function setMusicVolume(value:Float):Void
    {
        musicVolume = clamp(value);
        applyMusicVolume();
    }

    public static function setSoundVolume(value:Float):Void
    {
        soundVolume = clamp(value);
        applySoundVolumes();
    }

    public static function setChannelVolume(channel:String, value:Float):Void
    {
        if (!channels.exists(channel)) return;
        channelVolumes.set(channel, clamp(value));
        var sound = channels.get(channel);
        if (sound != null) sound.volume = effectiveSoundVolume(channel);
    }

    public static function setMuted(value:Bool):Void
    {
        muted = value;
        applyVolumes();
    }

    public static function toggleMute():Bool
    {
        setMuted(!muted);
        return muted;
    }

    public static function fadeMusicTo(value:Float, duration:Float, stopWhenDone:Bool = false):Void
    {
        if (FlxG.sound.music == null) return;
        addFade("music", musicFadeVolume, clamp(value), duration, stopWhenDone);
    }

    public static function fadeSoundTo(channel:String, value:Float, duration:Float, stopWhenDone:Bool = false):Void
    {
        if (!channels.exists(channel)) return;
        addFade(channel, channelVolumes.get(channel), clamp(value), duration, stopWhenDone);
    }

    public static function update(elapsed:Float):Void
    {
        if (!initialized || elapsed <= 0) return;
        var completed:Array<AudioFade> = [];
        for (fade in fades)
        {
            fade.elapsed = Math.min(fade.duration, fade.elapsed + elapsed);
            var ratio = fade.duration <= 0 ? 1 : fade.elapsed / fade.duration;
            var volume = fade.start + (fade.target - fade.start) * ratio;
            if (fade.channel == "music")
            {
                musicFadeVolume = volume;
                applyMusicVolume();
            }
            else
                setChannelVolume(fade.channel, volume);
            if (ratio >= 1) completed.push(fade);
        }
        for (fade in completed)
        {
            fades.remove(fade);
            if (fade.stopWhenDone)
            {
                if (fade.channel == "music") stopMusic();
                else stopSound(fade.channel);
            }
        }
    }

    public static function stopAllSounds():Void
    {
        var names = [for (name in channels.keys()) name];
        for (name in names) stopSound(name);
    }

    public static function stopAll():Void
    {
        stopMusic();
        stopAllSounds();
    }

    public static function dispose():Void
    {
        stopAll();
        fades = [];
        initialized = false;
    }

    static function addFade(channel:String, start:Float, target:Float, duration:Float, stopWhenDone:Bool):Void
    {
        cancelFade(channel);
        if (duration <= 0)
        {
            if (channel == "music")
            {
                musicFadeVolume = target;
                applyMusicVolume();
                if (stopWhenDone) stopMusic();
            }
            else
            {
                setChannelVolume(channel, target);
                if (stopWhenDone) stopSound(channel);
            }
            return;
        }
        fades.push(new AudioFade(channel, start, target, duration, stopWhenDone));
    }

    static function cancelFade(channel:String):Void
    {
        fades = fades.filter(function(fade) return fade.channel != channel);
    }

    static function applyVolumes():Void
    {
        applyMusicVolume();
        applySoundVolumes();
    }

    static function applyMusicVolume():Void
    {
        if (FlxG.sound.music != null)
            FlxG.sound.music.volume = (muted ? 0 : masterVolume * musicVolume * musicBaseVolume * musicFadeVolume);
    }

    static function applySoundVolumes():Void
    {
        for (name in channels.keys())
        {
            var sound = channels.get(name);
            if (sound != null) sound.volume = effectiveSoundVolume(name);
        }
    }

    static function effectiveSoundVolume(channel:String):Float
    {
        var value = channelVolumes.exists(channel) ? channelVolumes.get(channel) : 1;
        return muted ? 0 : masterVolume * soundVolume * value;
    }

    static function clamp(value:Float):Float
    {
        if (Math.isNaN(value)) return 0;
        return Math.max(0, Math.min(1, value));
    }
}

private class AudioFade
{
    public var channel:String;
    public var start:Float;
    public var target:Float;
    public var duration:Float;
    public var elapsed:Float = 0;
    public var stopWhenDone:Bool;

    public function new(channel:String, start:Float, target:Float, duration:Float, stopWhenDone:Bool)
    {
        this.channel = channel;
        this.start = start;
        this.target = target;
        this.duration = duration;
        this.stopWhenDone = stopWhenDone;
    }
}
