package audio.waveform;

import flixel.FlxG;
import flixel.sound.FlxSound;
import openfl.media.Sound;
import haxe.io.Bytes;

class WaveformSound
{
    public var sound(default, null):FlxSound;
    public var samples(default, null):Array<Float> = [];
    public var sampleRate(default, null):Int = 44100;
    public var channels(default, null):Int = 1;
    public var duration(get, never):Float;
    public var playing(get, never):Bool;
    public var position(get, set):Float;
    public var volume(get, set):Float;

    public function new(?source:Sound, autoDestroy:Bool = false)
    {
        sound = new FlxSound();
        if (source != null) sound.loadEmbedded(source, false, autoDestroy);
    }

    public function load(source:Sound, looped:Bool = false):WaveformSound
    {
        if (source != null) sound.loadEmbedded(source, looped, false);
        return this;
    }

    public function play(?forceRestart:Bool = false):WaveformSound
    {
        sound.play(forceRestart);
        return this;
    }

    public function pause():WaveformSound
    {
        sound.pause();
        return this;
    }

    public function stop():WaveformSound
    {
        sound.stop();
        return this;
    }

    public function destroy():Void
    {
        sound.destroy();
        samples = [];
    }

    public function attachToFlixel():WaveformSound
    {
        FlxG.sound.list.add(sound);
        return this;
    }

    public function setSamples(data:Array<Float>, rate:Int = 44100, channelCount:Int = 1):WaveformSound
    {
        samples = data == null ? [] : data.copy();
        sampleRate = rate > 0 ? rate : 44100;
        channels = channelCount > 0 ? channelCount : 1;
        return this;
    }

    public function clearSamples():Void
    {
        samples = [];
    }

    public function getPeak(startTime:Float, endTime:Float):Float
    {
        if (samples.length == 0) return 0;
        var a = timeToFrame(startTime);
        var b = timeToFrame(endTime);
        if (b <= a) b = a + 1;
        var peak:Float = 0;
        for (frame in a...b)
        {
            for (channel in 0...channels)
            {
                var idx = frame * channels + channel;
                if (idx >= 0 && idx < samples.length)
                {
                    var value = Math.abs(samples[idx]);
                    if (value > peak) peak = value;
                }
            }
        }
        return Math.min(1, peak);
    }

    public function getRMS(startTime:Float, endTime:Float):Float
    {
        if (samples.length == 0) return 0;
        var a = timeToFrame(startTime);
        var b = timeToFrame(endTime);
        if (b <= a) b = a + 1;
        var sum:Float = 0;
        var count:Int = 0;
        for (frame in a...b)
        {
            for (channel in 0...channels)
            {
                var idx = frame * channels + channel;
                if (idx >= 0 && idx < samples.length)
                {
                    var value = samples[idx];
                    sum += value * value;
                    count++;
                }
            }
        }
        return count == 0 ? 0 : Math.sqrt(sum / count);
    }

    public function getWaveform(pointCount:Int, ?startTime:Float = 0, ?endTime:Float = -1):Array<Float>
    {
        var result:Array<Float> = [];
        if (pointCount <= 0) return result;
        if (endTime < 0) endTime = sampleDuration();
        if (endTime < startTime) endTime = startTime;
        var span = endTime - startTime;
        for (i in 0...pointCount)
        {
            var a = startTime + span * i / pointCount;
            var b = startTime + span * (i + 1) / pointCount;
            result.push(getPeak(a, b));
        }
        return result;
    }

    public function sampleDuration():Float
    {
        return samples.length / (sampleRate * channels);
    }

    private function timeToFrame(time:Float):Int
    {
        var total = Std.int(samples.length / channels);
        var frame = Std.int(Math.floor(Math.max(0, time) * sampleRate));
        return frame < 0 ? 0 : (frame > total ? total : frame);
    }

    private function get_duration():Float
    {
        return sound.length / 1000;
    }

    private function get_playing():Bool
    {
        return sound.playing;
    }

    private function get_position():Float
    {
        return sound.time / 1000;
    }

    private function set_position(seconds:Float):Float
    {
        sound.time = Math.max(0, seconds) * 1000;
        return seconds;
    }

    private function get_volume():Float
    {
        return sound.volume;
    }

    private function set_volume(value:Float):Float
    {
        sound.volume = Math.max(0, Math.min(1, value));
        return sound.volume;
    }
}
