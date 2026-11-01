package shaders;

import flixel.system.FlxAssets.FlxShader;

class BloomShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header

        uniform float bloomIntensity;
        uniform float bloomThreshold;
        uniform float bloomRadius;
        uniform float bloomSoftness;

        vec3 extractBright(vec3 color)
        {
            float brightness = max(max(color.r, color.g), color.b);
            float factor = smoothstep(bloomThreshold - bloomSoftness, bloomThreshold + bloomSoftness, brightness);
            return color * factor;
        }

        void main()
        {
            vec2 uv = openfl_TextureCoordv;
            vec4 original = flixel_texture2D(bitmap, uv);
            vec2 texel = bloomRadius / openfl_TextureSize;

            vec3 bloom = extractBright(original.rgb) * 0.227027;

            bloom += extractBright(flixel_texture2D(bitmap, uv + vec2(1.384615, 0.0) * texel).rgb) * 0.158216;
            bloom += extractBright(flixel_texture2D(bitmap, uv - vec2(1.384615, 0.0) * texel).rgb) * 0.158216;
            bloom += extractBright(flixel_texture2D(bitmap, uv + vec2(3.230769, 0.0) * texel).rgb) * 0.070270;
            bloom += extractBright(flixel_texture2D(bitmap, uv - vec2(3.230769, 0.0) * texel).rgb) * 0.070270;

            bloom += extractBright(flixel_texture2D(bitmap, uv + vec2(0.0, 1.384615) * texel).rgb) * 0.158216;
            bloom += extractBright(flixel_texture2D(bitmap, uv - vec2(0.0, 1.384615) * texel).rgb) * 0.158216;
            bloom += extractBright(flixel_texture2D(bitmap, uv + vec2(0.0, 3.230769) * texel).rgb) * 0.070270;
            bloom += extractBright(flixel_texture2D(bitmap, uv - vec2(0.0, 3.230769) * texel).rgb) * 0.070270;

            vec3 result = original.rgb + bloom * bloomIntensity;
            gl_FragColor = vec4(clamp(result, 0.0, 1.0), original.a);
        }
    ')

    public function new(intensity:Float = 0.65, threshold:Float = 0.7, radius:Float = 1.5, softness:Float = 0.15)
    {
        super();
        setIntensity(intensity);
        setThreshold(threshold);
        setRadius(radius);
        setSoftness(softness);
    }

    public function setIntensity(value:Float):Void
    {
        bloomIntensity.value = [Math.max(0, value)];
    }

    public function setThreshold(value:Float):Void
    {
        bloomThreshold.value = [clamp(value, 0, 1)];
    }

    public function setRadius(value:Float):Void
    {
        bloomRadius.value = [Math.max(0, value)];
    }

    public function setSoftness(value:Float):Void
    {
        bloomSoftness.value = [Math.max(0.001, value)];
    }

    private static inline function clamp(value:Float, min:Float, max:Float):Float
    {
        return Math.max(min, Math.min(max, value));
    }
}
