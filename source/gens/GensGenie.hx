package gens;

import flixel.FlxG;
import backend.ClientPrefs;
import states.PlayState;

class GensGenie
{
	public static inline var PREFIX:String = "gens_genie_";

	static final DEFAULTS:Map<String, Dynamic> = [
		"inflives" => false,
		"infrings" => false,
		"ringbonus" => 0,
		"scoremult" => 100,
		"freezetime" => false,
		"cdtime" => false,
		"noblink" => false,
		"hidescore" => false,
		"hidelives" => false,
		"hidehud" => false,
		"hudstyle" => 0,
		"hdebug" => false
	];

	static final STYLES:Array<String> = ["DEFAULT", "SONIC 1/CD", "SONIC 2"];

	static var lastInstance:PlayState = null;
	static var timer:Float = 0;
	static var styleBackup:Dynamic = null;
	static var styleSaved:Bool = false;

	public static function get(id:String, def:Dynamic):Dynamic
	{
		try
		{
			var v:Dynamic = Reflect.field(FlxG.save.data, PREFIX + id);
			if (v != null) return v;
		}
		catch (e:Dynamic) {}
		return def;
	}

	public static function set(id:String, v:Dynamic):Void
	{
		try
		{
			Reflect.setField(FlxG.save.data, PREFIX + id, v);
		}
		catch (e:Dynamic) {}
	}

	static inline function on(id:String):Bool
		return get(id, false) == true;

	static inline function num(id:String, def:Int):Int
		return Std.int(get(id, def));

		public static function activeCount():Int
	{
		var n = 0;
		for (id => def in DEFAULTS)
			if (get(id, def) != def) n++;

		try
		{
			var gs = ClientPrefs.data.gameplaySettings;
			if (gs.get("practice") == true) n++;
			if (gs.get("botplay") == true) n++;
			if (gs.get("instakill") == true) n++;
			if (gs.get("healthgain") != null && gs.get("healthgain") != 1.0) n++;
			if (gs.get("healthloss") != null && gs.get("healthloss") != 1.0) n++;
		}
		catch (e:Dynamic) {}
		return n;
	}

		public static function update(dt:Float):Void
	{
		var pi = PlayState.instance;
		if (pi == null || !Std.isOfType(FlxG.state, PlayState))
		{
			lastInstance = null;
			return;
		}

		timer -= dt;
		if (pi != lastInstance)
		{
			lastInstance = pi;
			timer = 0;
		}
		if (timer > 0) return;
		timer = 0.25;
		push(pi);
	}

		public static function apply():Void
	{
		applyPrefs();
		var pi = PlayState.instance;
		if (pi != null) push(pi);
	}

	static function push(pi:PlayState):Void
	{
		try
		{
			pi.setOnScripts("genieInfLives", on("inflives"));
			pi.setOnScripts("genieInfRings", on("infrings"));
			pi.setOnScripts("genieRingBonus", num("ringbonus", 0));
			pi.setOnScripts("genieScoreMult", num("scoremult", 100));
			pi.setOnScripts("genieFreezeTime", on("freezetime"));
			pi.setOnScripts("genieCDTime", on("cdtime"));
			pi.setOnScripts("genieNoBlink", on("noblink"));
			pi.setOnScripts("genieHideScore", on("hidescore"));
			pi.setOnScripts("genieHideLives", on("hidelives"));
			pi.setOnScripts("genieHideHud", on("hidehud"));
			pi.setOnScripts("genieDebug", on("hdebug"));
		}
		catch (e:Dynamic) {}
	}

	static function applyPrefs():Void
	{
		try
		{
			var s = num("hudstyle", 0);
			if (s < 0 || s >= STYLES.length) s = 0;

			if (s > 0)
			{
				if (!styleSaved)
				{
					styleBackup = Reflect.getProperty(ClientPrefs.data, "sonicHUDStyle");
					styleSaved = true;
				}
				Reflect.setProperty(ClientPrefs.data, "sonicHUDStyle", STYLES[s]);
			}
			else if (styleSaved)
			{
				Reflect.setProperty(ClientPrefs.data, "sonicHUDStyle", styleBackup);
				styleSaved = false;
			}
		}
		catch (e:Dynamic) {}
	}
}
