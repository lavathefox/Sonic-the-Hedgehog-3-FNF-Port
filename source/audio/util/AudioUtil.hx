package audio.util;

import haxe.ds.StringMap;

class AudioUtil
{
    public static inline var DEFAULT_SAMPLE_RATE:Int = 44100;
    public static inline var DEFAULT_BPM:Float = 120.0;
    public static inline var MIN_DECIBELS:Float = -80.0;
    public static inline var MAX_PAN:Float = 1.0;

    public static function clamp(value:Float, min:Float = 0, max:Float = 1):Float
    {
        if (Math.isNaN(value)) return min;
        if (min > max)
        {
            var oldMin = min;
            min = max;
            max = oldMin;
        }
        return Math.max(min, Math.min(max, value));
    }

    public static inline function clampVolume(value:Float):Float
    {
        return clamp(value);
    }

    public static inline function clampPan(value:Float):Float
    {
        return clamp(value, -MAX_PAN, MAX_PAN);
    }

    public static function percentToVolume(percent:Float):Float
    {
        return clamp(percent / 100);
    }

    public static function volumeToPercent(volume:Float):Float
    {
        return clampVolume(volume) * 100;
    }

    public static function decibelsToVolume(db:Float):Float
    {
        if (Math.isNaN(db)) return 0;
        if (db <= MIN_DECIBELS) return 0;
        if (db >= 0) return 1;
        return Math.pow(10, db / 20);
    }

    public static function volumeToDecibels(volume:Float):Float
    {
        var value = clampVolume(volume);
        return value <= 0 ? MIN_DECIBELS : Math.max(MIN_DECIBELS, 20 * Math.log(value) / Math.log(10));
    }

    public static function combineVolumes(master:Float, category:Float, source:Float = 1):Float
    {
        return clampVolume(master) * clampVolume(category) * clampVolume(source);
    }

    public static function linearToPerceptual(volume:Float, exponent:Float = 2):Float
    {
        var safeExponent = exponent > 0 && !Math.isNaN(exponent) ? exponent : 2;
        return Math.pow(clampVolume(volume), safeExponent);
    }

    public static function perceptualToLinear(volume:Float, exponent:Float = 2):Float
    {
        var safeExponent = exponent > 0 && !Math.isNaN(exponent) ? exponent : 2;
        return Math.pow(clampVolume(volume), 1 / safeExponent);
    }

    public static function lerp(from:Float, to:Float, ratio:Float):Float
    {
        return from + (to - from) * clamp(ratio);
    }

    public static function smoothStep(ratio:Float):Float
    {
        var t = clamp(ratio);
        return t * t * (3 - 2 * t);
    }

    public static function smootherStep(ratio:Float):Float
    {
        var t = clamp(ratio);
        return t * t * t * (t * (t * 6 - 15) + 10);
    }

    public static function fadeVolume(from:Float, to:Float, elapsed:Float, duration:Float, easing:String = "linear"):Float
    {
        if (duration <= 0 || Math.isNaN(duration)) return clampVolume(to);
        var t = clamp(elapsed / duration);
        switch (easing == null ? "linear" : easing.toLowerCase())
        {
            case "smooth", "smoothstep": t = smoothStep(t);
            case "smoother", "smootherstep": t = smootherStep(t);
            case "easein", "ease-in": t *= t;
            case "easeout", "ease-out": t = 1 - (1 - t) * (1 - t);
            case "easeinout", "ease-in-out": t = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
            default:
        }
        return clampVolume(lerp(from, to, t));
    }

    public static function crossfadeVolumes(progress:Float, equalPower:Bool = true):Array<Float>
    {
        var t = clamp(progress);
        if (equalPower)
            return [Math.cos(t * Math.PI * 0.5), Math.sin(t * Math.PI * 0.5)];
        return [1 - t, t];
    }

    public static function stereoGains(pan:Float):Array<Float>
    {
        var angle = (clampPan(pan) + 1) * Math.PI * 0.25;
        return [Math.cos(angle), Math.sin(angle)];
    }

    public static function millisecondsToSeconds(milliseconds:Float):Float
    {
        return milliseconds / 1000;
    }

    public static function secondsToMilliseconds(seconds:Float):Float
    {
        return seconds * 1000;
    }

    public static function secondsToSamples(seconds:Float, sampleRate:Int = DEFAULT_SAMPLE_RATE):Int
    {
        if (sampleRate <= 0 || seconds <= 0 || Math.isNaN(seconds)) return 0;
        return Std.int(Math.floor(seconds * sampleRate + 0.5));
    }

    public static function samplesToSeconds(samples:Int, sampleRate:Int = DEFAULT_SAMPLE_RATE):Float
    {
        return sampleRate <= 0 ? 0 : samples / sampleRate;
    }

    public static function millisecondsToSamples(milliseconds:Float, sampleRate:Int = DEFAULT_SAMPLE_RATE):Int
    {
        return secondsToSamples(millisecondsToSeconds(milliseconds), sampleRate);
    }

    public static function samplesToMilliseconds(samples:Int, sampleRate:Int = DEFAULT_SAMPLE_RATE):Float
    {
        return secondsToMilliseconds(samplesToSeconds(samples, sampleRate));
    }

    public static function beatsToSeconds(beats:Float, bpm:Float = DEFAULT_BPM):Float
    {
        return bpm <= 0 || Math.isNaN(bpm) ? 0 : beats * 60 / bpm;
    }

    public static function secondsToBeats(seconds:Float, bpm:Float = DEFAULT_BPM):Float
    {
        return bpm <= 0 || Math.isNaN(bpm) ? 0 : seconds * bpm / 60;
    }

    public static function beatDurationMilliseconds(bpm:Float = DEFAULT_BPM):Float
    {
        return beatsToSeconds(1, bpm) * 1000;
    }

    public static function stepDurationMilliseconds(bpm:Float = DEFAULT_BPM, stepsPerBeat:Int = 4):Float
    {
        return stepsPerBeat <= 0 ? 0 : beatDurationMilliseconds(bpm) / stepsPerBeat;
    }

    public static function formatTime(seconds:Float, showMilliseconds:Bool = false):String
    {
        var safe = Math.isNaN(seconds) || seconds < 0 ? 0 : seconds;
        var totalMilliseconds = Std.int(Math.floor(safe * 1000));
        var totalSeconds = Std.int(Math.floor(totalMilliseconds / 1000));
        var hours = Std.int(Math.floor(totalSeconds / 3600));
        var minutes = Std.int(Math.floor((totalSeconds % 3600) / 60));
        var secs = totalSeconds % 60;
        var output = hours > 0
            ? hours + ":" + pad(minutes, 2) + ":" + pad(secs, 2)
            : minutes + ":" + pad(secs, 2);
        if (showMilliseconds) output += "." + pad(totalMilliseconds % 1000, 3);
        return output;
    }

    public static function normalizedPosition(position:Float, duration:Float):Float
    {
        if (duration <= 0 || Math.isNaN(duration)) return 0;
        return clamp(position / duration);
    }

    public static function remainingTime(position:Float, duration:Float):Float
    {
        if (Math.isNaN(duration) || duration <= 0) return 0;
        return Math.max(0, duration - Math.max(0, position));
    }

    public static function safePlaybackRate(rate:Float, min:Float = 0.1, max:Float = 4):Float
    {
        return clamp(rate, min, max);
    }

    public static function isValidSampleRate(sampleRate:Int):Bool
    {
        return sampleRate >= 8000 && sampleRate <= 384000;
    }

    public static function isValidBpm(bpm:Float):Bool
    {
        return !Math.isNaN(bpm) && bpm > 0 && bpm <= 1000;
    }

    public static function normalizeChannelName(name:String, fallback:String = "default"):String
    {
        if (name == null) return fallback;
        var trimmed = StringTools.trim(name);
        return trimmed.length == 0 ? fallback : trimmed;
    }

    static function pad(value:Int, digits:Int):String
    {
        var result = Std.string(value);
        while (result.length < digits) result = "0" + result;
        return result;
    }
}
