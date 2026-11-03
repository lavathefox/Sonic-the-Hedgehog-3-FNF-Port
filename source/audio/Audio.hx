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
    public static var maxSoundChannels:Int = 24;
    public static var autoCleanup:Bool = true;
    public static var lastError(default, null):String = "";

    static var channels:Map<String, FlxSound> = new Map();
    static var channelVolumes:Map<String, Float> = new Map();
    static var channelPaused:Map<String, Bool> = new Map();
    static var channelLooped:Map<String, Bool> = new Map();
    static var channelOrder:Array<String> = [];
    static var fades:Array<AudioFade> = [];
    static var musicBaseVolume:Float = 1;
    static var musicFadeVolume:Float = 1;
    static var musicPaused:Bool = false;
    static var allPaused:Bool = false;
    static var nextId:Int = 0;
    static var outgoingMusic:FlxSound;
    static var outgoingFade:AudioFade;

    public static function initialize():Void
    {
        if (initialized) return;
        initialized = true;
        lastError = "";
        applyVolumes();
    }

    public static function playMusic(asset:FlxSoundAsset, ?name:String, volume:Float = 1, looped:Bool = true, fadeIn:Float = 0):Void
    {
        initialize();
        clearOutgoingMusic();
        cancelFade("music");
        musicBaseVolume = clamp(volume);
        musicFadeVolume = fadeIn > 0 ? 0 : 1;
        musicPaused = false;
        allPaused = false;
        currentMusic = name == null ? "" : name;
        FlxG.sound.playMusic(asset, 0, looped);
        applyMusicVolume();
        if (fadeIn > 0) fadeMusicTo(1, fadeIn);
    }

    public static function crossfadeMusic(asset:FlxSoundAsset, ?name:String, duration:Float = 1, volume:Float = 1, looped:Bool = true):Void
    {
        initialize();
        if (duration <= 0 || FlxG.sound.music == null)
        {
            playMusic(asset, name, volume, looped);
            return;
        }
        clearOutgoingMusic();
        cancelFade("music");
        outgoingMusic = FlxG.sound.music;
        var outgoingVolume = outgoingMusic.volume;
        outgoingFade = new AudioFade("__outgoing_music", outgoingVolume, 0, duration, true);
        musicBaseVolume = clamp(volume);
        musicFadeVolume = 0;
        musicPaused = false;
        allPaused = false;
        currentMusic = name == null ? "" : name;
        FlxG.sound.music = null;
        FlxG.sound.playMusic(asset, 0, looped);
        applyMusicVolume();
        fadeMusicTo(1, duration);
    }

    public static function stopMusic(fadeOut:Float = 0):Void
    {
        if (FlxG.sound.music == null)
        {
            clearOutgoingMusic();
            currentMusic = "";
            return;
        }
        if (fadeOut > 0)
        {
            fadeMusicTo(0, fadeOut, true);
            return;
        }
        cancelFade("music");
        FlxG.sound.music.stop();
        clearOutgoingMusic();
        currentMusic = "";
        musicPaused = false;
        musicFadeVolume = 1;
    }

    public static function pauseMusic():Void
    {
        if (FlxG.sound.music == null || musicPaused) return;
        FlxG.sound.music.pause();
        if (outgoingMusic != null) outgoingMusic.pause();
        musicPaused = true;
    }

    public static function resumeMusic():Void
    {
        if (FlxG.sound.music == null || !musicPaused) return;
        FlxG.sound.music.resume();
        if (outgoingMusic != null) outgoingMusic.resume();
        musicPaused = false;
    }

    public static function toggleMusicPause():Bool
    {
        if (musicPaused) resumeMusic(); else pauseMusic();
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
        cleanupFinishedSounds();
        if (maxSoundChannels > 0)
        {
            while (channelOrder.length >= maxSoundChannels)
                stopSound(channelOrder[0]);
        }
        var sound = new FlxSound();
        sound.loadEmbedded(asset, looped);
        FlxG.sound.list.add(sound);
        channels.set(channel, sound);
        channelVolumes.set(channel, clamp(volume));
        channelPaused.set(channel, false);
        channelLooped.set(channel, looped);
        channelOrder.push(channel);
        sound.volume = effectiveSoundVolume(channel);
        sound.play();
        return sound;
    }

    public static function stopSound(channel:String):Void
    {
        if (channel == null || !channels.exists(channel)) return;
        cancelFade(channel);
        var sound = channels.get(channel);
        channels.remove(channel);
        channelVolumes.remove(channel);
        channelPaused.remove(channel);
        channelLooped.remove(channel);
        channelOrder.remove(channel);
        if (sound != null)
        {
            sound.stop();
            FlxG.sound.list.remove(sound, true);
        }
    }

    public static function pauseSound(channel:String):Void
    {
        var sound = channels.get(channel);
        if (sound != null && sound.playing)
        {
            sound.pause();
            channelPaused.set(channel, true);
        }
    }

    public static function resumeSound(channel:String):Void
    {
        var sound = channels.get(channel);
        if (sound != null && channelPaused.exists(channel) && channelPaused.get(channel))
        {
            sound.resume();
            channelPaused.set(channel, false);
        }
    }

    public static function pauseAll():Void
    {
        if (allPaused) return;
        allPaused = true;
        pauseMusic();
        for (name in channelOrder.copy()) pauseSound(name);
    }

    public static function resumeAll():Void
    {
        if (!allPaused) return;
        allPaused = false;
        resumeMusic();
        for (name in channelOrder.copy()) resumeSound(name);
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

    public static function isMusicPaused():Bool
    {
        return musicPaused;
    }

    public static function getActiveSoundCount():Int
    {
        cleanupFinishedSounds();
        return channelOrder.length;
    }

    public static function getChannelNames():Array<String>
    {
        cleanupFinishedSounds();
        return channelOrder.copy();
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

    public static function getChannelVolume(channel:String):Float
    {
        return channelVolumes.exists(channel) ? channelVolumes.get(channel) : 0;
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
        addFade(channel, getChannelVolume(channel), clamp(value), duration, stopWhenDone);
    }

    public static function update(elapsed:Float):Void
    {
        if (!initialized || Math.isNaN(elapsed) || elapsed <= 0) return;
        if (autoCleanup) cleanupFinishedSounds();
        if (allPaused) return;
        var completed:Array<AudioFade> = [];
        for (fade in fades)
        {
            if (fade.channel == "music" && musicPaused) continue;
            if (fade.channel != "music" && channelPaused.exists(fade.channel) && channelPaused.get(fade.channel)) continue;
            fade.elapsed = Math.min(fade.duration, fade.elapsed + elapsed);
            var ratio = fade.duration <= 0 ? 1 : fade.elapsed / fade.duration;
            var value = fade.start + (fade.target - fade.start) * ratio;
            if (fade.channel == "music")
            {
                musicFadeVolume = value;
                applyMusicVolume();
            }
            else setChannelVolume(fade.channel, value);
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
        if (outgoingMusic != null && outgoingFade != null && !musicPaused)
        {
            outgoingFade.elapsed = Math.min(outgoingFade.duration, outgoingFade.elapsed + elapsed);
            var ratio = outgoingFade.duration <= 0 ? 1 : outgoingFade.elapsed / outgoingFade.duration;
            outgoingMusic.volume = outgoingFade.start * (1 - ratio);
            if (ratio >= 1) clearOutgoingMusic();
        }
    }

    public static function cleanupFinishedSounds():Void
    {
        var expired:Array<String> = [];
        for (name in channelOrder)
        {
            var sound = channels.get(name);
            if (sound == null || (!sound.playing && !(channelPaused.exists(name) && channelPaused.get(name))))
                expired.push(name);
        }
        for (name in expired) stopSound(name);
    }

    public static function stopAllSounds():Void
    {
        for (name in channelOrder.copy()) stopSound(name);
    }

    public static function stopAll():Void
    {
        stopMusic();
        stopAllSounds();
        allPaused = false;
    }

    public static function dispose():Void
    {
        stopAll();
        fades = [];
        initialized = false;
    }

    static function clearOutgoingMusic():Void
    {
        if (outgoingMusic != null)
        {
            outgoingMusic.stop();
            FlxG.sound.list.remove(outgoingMusic, true);
            outgoingMusic = null;
        }
        outgoingFade = null;
    }

    static function addFade(channel:String, start:Float, target:Float, duration:Float, stopWhenDone:Bool):Void
    {
        cancelFade(channel);
        if (duration <= 0 || Math.isNaN(duration))
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
            FlxG.sound.music.volume = muted ? 0 : clamp(masterVolume * musicVolume * musicBaseVolume * musicFadeVolume);
        if (outgoingMusic != null && muted) outgoingMusic.volume = 0;
    }

    static function applySoundVolumes():Void
    {
        for (name in channelOrder)
        {
            var sound = channels.get(name);
            if (sound != null) sound.volume = effectiveSoundVolume(name);
        }
    }

    static function effectiveSoundVolume(channel:String):Float
    {
        var value = channelVolumes.exists(channel) ? channelVolumes.get(channel) : 1;
        return muted ? 0 : clamp(masterVolume * soundVolume * value);
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
