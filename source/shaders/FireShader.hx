package shaders;

import flixel.system.FlxAssets.FlxShader;

@:glFragmentSource('
#pragma header

uniform float uTime;
uniform float uIntensity;
uniform float uSpeed;
uniform float uScale;
uniform float uOpacity;
uniform float uDistortion;
uniform vec3 uFireColor;
uniform vec3 uHotColor;

float fireHash(vec2 p)
{
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float fireNoise(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = fireHash(i);
    float b = fireHash(i + vec2(1.0, 0.0));
    float c = fireHash(i + vec2(0.0, 1.0));
    float d = fireHash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fireFbm(vec2 p)
{
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++)
    {
        value += amplitude * fireNoise(p);
        p = p * 2.03 + vec2(13.1, 7.7);
        amplitude *= 0.5;
    }
    return value;
}

void main()
{
    vec2 uv = openfl_TextureCoordv;
    vec4 original = flixel_texture2D(bitmap, uv);

    float time = uTime * uSpeed;
    vec2 field = vec2(uv.x * uScale, (1.0 - uv.y) * uScale);
    field.x += sin(field.y * 2.0 + time * 1.4) * 0.18;
    field.y += time * 1.8;

    float turbulence = fireFbm(field + vec2(0.0, time * 0.3));
    float detail = fireFbm(field * 1.8 - vec2(time * 0.5, 0.0));

    float base = pow(clamp(1.0 - uv.y, 0.0, 1.0), 0.65);
    float flame = base * (0.75 + turbulence * 0.7);
    flame -= uv.y * (0.45 + detail * 0.25);
    flame += (turbulence - 0.5) * 0.35;
    flame = smoothstep(0.12, 0.8, flame) * clamp(uIntensity, 0.0, 3.0);

    float hot = smoothstep(0.55, 1.15, flame);
    vec3 fireColor = mix(uFireColor, uHotColor, hot);
    float alpha = clamp(flame * uOpacity, 0.0, 1.0);

    vec2 distortedUv = clamp(
        uv + vec2((turbulence - 0.5) * uDistortion * alpha, 0.0),
        vec2(0.0),
        vec2(1.0)
    );
    vec4 background = flixel_texture2D(bitmap, distortedUv);

    vec3 result = mix(background.rgb, fireColor, alpha);
    gl_FragColor = vec4(result, original.a);
}
')
class FireShader extends FlxShader
{
    public var time(default, set):Float = 0;
    public var intensity(default, set):Float = 1;
    public var speed(default, set):Float = 1;
    public var fireScale(default, set):Float = 5;
    public var opacity(default, set):Float = 0.85;
    public var distortion(default, set):Float = 0.012;

    public function new()
    {
        super();
        uTime.value = [0.0];
        uIntensity.value = [1.0];
        uSpeed.value = [1.0];
        uScale.value = [5.0];
        uOpacity.value = [0.85];
        uDistortion.value = [0.012];
        uFireColor.value = [1.0, 0.18, 0.015];
        uHotColor.value = [1.0, 0.9, 0.3];
    }

    public function update(elapsed:Float):Void
    {
        if (elapsed > 0 && !Math.isNaN(elapsed))
            time += elapsed;
    }

    public function reset():Void
    {
        time = 0;
    }

    public function setFireColor(red:Float, green:Float, blue:Float):Void
    {
        uFireColor.value = [clamp01(red), clamp01(green), clamp01(blue)];
    }

    public function setHotColor(red:Float, green:Float, blue:Float):Void
    {
        uHotColor.value = [clamp01(red), clamp01(green), clamp01(blue)];
    }

    function set_time(value:Float):Float
    {
        time = value;
        uTime.value = [value];
        return value;
    }

    function set_intensity(value:Float):Float
    {
        intensity = Math.max(0, Math.min(3, value));
        uIntensity.value = [intensity];
        return intensity;
    }

    function set_speed(value:Float):Float
    {
        speed = Math.max(0, value);
        uSpeed.value = [speed];
        return speed;
    }

    function set_fireScale(value:Float):Float
    {
        fireScale = Math.max(0.1, value);
        uScale.value = [fireScale];
        return fireScale;
    }

    function set_opacity(value:Float):Float
    {
        opacity = clamp01(value);
        uOpacity.value = [opacity];
        return opacity;
    }

    function set_distortion(value:Float):Float
    {
        distortion = Math.max(0, Math.min(0.2, value));
        uDistortion.value = [distortion];
        return distortion;
    }

    private static function clamp01(value:Float):Float
    {
        return Math.max(0, Math.min(1, value));
    }
}
