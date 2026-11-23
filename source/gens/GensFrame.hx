package gens;

import flixel.FlxG;
import flixel.FlxSprite;
import backend.Conductor;
import backend.Difficulty;
import backend.Mods;
import backend.Song;
import backend.WeekData;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.system.scaleModes.BaseScaleMode;
import flixel.system.scaleModes.FillScaleMode;
import flixel.system.scaleModes.RatioScaleMode;
import haxe.Json;
import haxe.Timer;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Application;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.PNGEncoderOptions;
import openfl.display.Sprite;
import openfl.display.StageDisplayState;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.filters.ColorMatrixFilter;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import states.GensIdleState;
import states.LoadingState;
import states.PlayState;
import save.Save;
import states.Sonic3TitleStateV2;
import sys.FileSystem;
import sys.io.File;

typedef Palette =
{
	var bar:Int;
	var barLine:Int;
	var panel:Int;
	var border:Int;
	var sep:Int;
	var hl:Int;
	var hlText:Int;
	var text:Int;
	var dis:Int;
}

typedef DRow =
{
	var kind:Int;
	var label:String;
	@:optional var value:Dynamic;
	@:optional var def:Dynamic;
	@:optional var dir:Bool;
	@:optional var min:Int;
	@:optional var max:Int;
	@:optional var step:Int;
	@:optional var apply:Dynamic->Void;
}

class GensFrame extends Sprite
{
	public static inline var ROM_FILE:String = "Sonic The Hedgehog 3 (W) [!].md";
	public static final ROM_EXTS:Array<String> = ["md", "bin", "gen", "smd"];

	public static var instance(default, null):GensFrame;
	public static var romLoaded(default, null):Bool = false;
	public static var barHeight(get, never):Int;

	static inline var CLASSIC:Bool = false;
	static inline var BAR_H:Int = 20;
	static inline var ROW_H:Int = 22;
	static inline var SEP_H:Int = 7;
	static inline var PAD:Int = 3;
	static inline var GUTTER:Int = 32;
	static inline var RIGHT:Int = 28;
	static inline var KEY_GAP:Int = 30;
	static inline var FONT:String = "_sans";
	static inline var SIZE:Int = 12;

	static final PAD_NAMES:Array<String> = ["Up", "Down", "Left", "Right", "Start", "B", "A", "C", "Mode", "X", "Y", "Z"];
	static final PAD_BIND:Array<String> = ["ui_up", "ui_down", "ui_left", "ui_right", "accept", "back"];
	static final PAD_DEF:Array<Int> = [38, 40, 37, 39, 13, 8, 65, 68, 16, 81, 87, 69];

	static final DIR_NAMES:Array<String> = ["Savestates", "SRAM Backups", "BRAM Backups", "WAV Dumping", "GYM Dumping", "Screenshots"];
	static final DIR_DEF:Array<String> = ["States", "saves", "saves", "Dumps", "Dumps", "Screenshots"];

	static final BIOS_NAMES:Array<String> = [
		"Genesis BIOS", "USA CD BIOS", "Europe CD BIOS", "Japan CD BIOS", "32X 68000 BIOS", "32X Master SH2 BIOS", "32X Slave SH2 BIOS"
	];

	static final WIN10:Palette = {
		bar: 0xFFFFFF,
		barLine: 0xE0E0E0,
		panel: 0xF2F2F2,
		border: 0xCCCCCC,
		sep: 0xD7D7D7,
		hl: 0x91C9F7,
		hlText: 0x000000,
		text: 0x000000,
		dis: 0x7F7F7F
	};

	static final CLASSIC_PAL:Palette = {
		bar: 0xD4D0C8,
		barLine: 0x808080,
		panel: 0xD4D0C8,
		border: 0x404040,
		sep: 0x808080,
		hl: 0x0A246A,
		hlText: 0xFFFFFF,
		text: 0x000000,
		dis: 0x808080
	};

	static var baseFps:Int = 0;

	var pal:Palette = CLASSIC ? CLASSIC_PAL : WIN10;

	var headers:Array<MenuItem> = [];
	var headLabels:Array<TextField> = [];
	var headX:Array<Float> = [];
	var headW:Array<Float> = [];
	var activeHeader:Int = -1;
	var hotHeader:Int = -1;

	var panels:Array<Panel> = [];
	var barSprite:Sprite;
	var panelLayer:Sprite;
	var osd:TextField;
	var osdShadow:TextField;
	var osdLeft:Float = 0;
	var lastTime:Float = 0;

	var soundEnable:MenuItem;
	var fullItem:MenuItem;
	var historyItem:MenuItem;
	var slotItems:Array<MenuItem>;
	var slot:Int = 0;

	var dlg:GDialog;
	var paused:Bool = false;
	var busy:Bool = false;
	var dialogClosed:Bool = false;
	var pendingPath:String = null;
	var pendingSaveAs:String = null;
	var pendingLoadFrom:String = null;
	var pendingMusic:Dynamic = null;
	var pendingPlay:Dynamic = null;
	var oldPlay:PlayState = null;
	var playWait:Int = 0;
	var musicWait:Int = 0;
	var keysLocked:Bool = false;
	var restoreKeys:Bool = false;
	var configured:Bool = false;
	var lastVis:Bool = true;
	var curTitle:String = "Gens - Idle";

	static function get_barHeight():Int
		return (instance != null && instance.barVisible()) ? BAR_H : 0;

	public static function init():Void
	{
		if (instance != null) return;
		instance = new GensFrame();
		Lib.current.addChild(instance);
	}

	public static function message(s:String):Void
	{
		if (instance != null) instance.showMsg(s);
	}

	static function cfg(key:String, def:Dynamic):Dynamic
	{
		var v:Dynamic = null;
		try
		{
			v = Reflect.field(FlxG.save.data, "gens_" + key);
		}
		catch (e:Dynamic) {}
		return v == null ? def : v;
	}

	static function setCfg(key:String, v:Dynamic):Void
	{
		try
		{
			Reflect.setField(FlxG.save.data, "gens_" + key, v);
		}
		catch (e:Dynamic) {}
	}

	static function flushCfg():Void
	{
		try
		{
			FlxG.save.flush();
		}
		catch (e:Dynamic) {}
	}

	static function dirOf(i:Int):String
	{
		var s:String = Std.string(cfg("dir_" + i, DIR_DEF[i]));
		if (s == null || s == "" || s == "null") s = DIR_DEF[i];
		var abs = s.charAt(0) == "/" || s.charAt(1) == ":";
		return abs ? s : Path.join([Sys.getCwd(), s]);
	}

	static function bindIndex(a:Array<FlxKey>):Int
		return a.length > 1 ? 1 : 0;

	static function bindGet(id:String, def:Int):Int
	{
		try
		{
			var a = ClientPrefs.keyBinds.get(id);
			if (a != null && a.length > 0)
			{
				var v:Int = a[bindIndex(a)];
				if (v > 0) return v;
			}
		}
		catch (e:Dynamic) {}
		return def;
	}

	static function bindSet(id:String, code:Int):Void
	{
		try
		{
			var a = ClientPrefs.keyBinds.get(id);
			if (a != null && a.length > 0) a[bindIndex(a)] = code;
		}
		catch (e:Dynamic) {}
	}

	function new()
	{
		super();
		mouseEnabled = false;

		ensureRomCopy();

		osdShadow = mkTF("", true, 16);
		osdShadow.textColor = 0x000000;
		addChild(osdShadow);
		osd = mkTF("", true, 16);
		osd.textColor = 0xFFFFFF;
		addChild(osd);

		barSprite = new Sprite();
		addChild(barSprite);
		panelLayer = new Sprite();
		addChild(panelLayer);

		buildMenus();
		buildBar();

		var st = Lib.current.stage;
		st.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
		st.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
		st.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		st.addEventListener(Event.RESIZE, onResize);
		addEventListener(Event.ENTER_FRAME, onFrame);

		Application.current.window.onDropFile.add(function(path:String)
		{
			pendingPath = path;
		});

		lastTime = Timer.stamp();
		layout();
	}

	function barVisible():Bool
		return Lib.current.stage.displayState == StageDisplayState.NORMAL;

	function mkTF(s:String, bold:Bool = false, size:Int = SIZE):TextField
	{
		var t = new TextField();
		t.defaultTextFormat = new TextFormat(FONT, size, 0x000000, bold);
		t.selectable = false;
		t.mouseEnabled = false;
		t.autoSize = TextFieldAutoSize.LEFT;
		t.text = s;
		return t;
	}

	static function scaleFor(stretch:Bool):BaseScaleMode
	{
		if (stretch) return new FrameFillMode();
		return new FrameRatioMode();
	}

	static function plain(label:String):String
		return StringTools.replace(label, "&", "").toUpperCase();

	static function keyed(m:MenuItem, k:String):MenuItem
	{
		m.key = k;
		return m;
	}

		function flag(label:String, key:String, def:Bool, ?onChange:Bool->Void, ?enabled:Void->Bool):MenuItem
	{
		var name = plain(label);
		return MenuItem.check(label, cfg(key, def) == true, function(v:Bool)
		{
			setCfg(key, v);
			flushCfg();
			if (onChange != null) onChange(v);
			msg(name + (v ? " ON" : " OFF"));
		}, enabled);
	}

		function choice(labels:Array<String>, key:String, def:Int, onSelect:Int->Void):Array<MenuItem>
	{
		return MenuItem.radios(labels, Std.int(cfg(key, def)), function(i:Int)
		{
			setCfg(key, i);
			flushCfg();
			onSelect(i);
		});
	}

	function buildMenus():Void
	{
		var needRom:Void->Bool = function() return romLoaded;
		var never:Void->Bool = function() return false;

		soundEnable = MenuItem.check("&Enable", !FlxG.sound.muted, function(v:Bool)
		{
			FlxG.sound.muted = !v;
			msg(v ? "SOUND ENABLED" : "SOUND DISABLED");
		});

		historyItem = MenuItem.sub("ROM &History", [], null, function() return loadHistory().length > 0);
		rebuildHistory();

		slotItems = MenuItem.radios(["&0", "&1", "&2", "&3", "&4", "&5", "&6", "&7", "&8", "&9"], 0, function(i:Int)
		{
			slot = i;
			msg("STATE " + i + " SELECTED");
		});

		var file:Array<MenuItem> = [
			MenuItem.normal("&Open ROM...", "Ctrl+O", openRomDialog),
			MenuItem.normal("&Boot CD", "Ctrl+B", null, never),
			MenuItem.normal("&Netplay", null, null, never),
			historyItem,
			MenuItem.normal("&Close ROM", "Ctrl+C", closeRom, needRom),
			MenuItem.sep(),
			MenuItem.normal("&Game Genie", null, function()
			{
				Application.current.window.alert("Game Genie is not available in this build.", "Game Genie");
			}, needRom),
			MenuItem.sep(),
			MenuItem.normal("&Load State...", "Ctrl+F8", loadStateAs, needRom),
			MenuItem.normal("&Save State as...", "Ctrl+F5", saveStateAs, needRom),
			MenuItem.normal("Quick Lo&ad", "F8", loadState, needRom),
			MenuItem.normal("Quick Sa&ve", "F5", saveState, needRom),
			MenuItem.sub("Change S&tate", slotItems, "F6/F7", needRom),
			MenuItem.sep(),
			MenuItem.normal("E&xit", null, exitApp)
		];

		fullItem = keyed(MenuItem.check("&Full Screen", FlxG.fullscreen, function(v:Bool)
		{
			FlxG.fullscreen = v;
		}), "Alt+Enter");

		var renders = [
			"&Normal", "&Double", "&Interpolated", "&Scanline", "50% Scanline", "25% Scanline", "Interpolated Scanline", "Interpolated 50% Scanline",
			"Interpolated 25% Scanline", "2xSAI (Kreed)"
		];
		var renderItems = choice(renders, "render", 0, function(i:Int)
		{
			var smooth = (i == 2 || i == 6 || i == 7 || i == 8);
			FlxSprite.defaultAntialiasing = smooth;
			ClientPrefs.data.antialiasing = smooth;
			msg("RENDER: " + plain(renders[i]));
		});

		var skipLabels = ["&Auto", "&0", "&1", "&2", "&3", "&4", "&5", "&6", "&7", "&8"];
		var skipItems = choice(skipLabels, "frameskip", 0, function(i:Int)
		{
			msg("FRAME SKIP: " + (i == 0 ? "AUTO" : Std.string(i - 1)));
		});

		var graphics:Array<MenuItem> = [
			fullItem,
			flag("&VSync", "vsync", false),
			flag("S&tretch", "stretch", false, function(v:Bool)
			{
				FlxG.scaleMode = scaleFor(v);
			}),
			MenuItem.sep(),
			MenuItem.sub("&Render", renderItems),
			MenuItem.sub("Frame S&kip", skipItems),
			MenuItem.sep(),
			MenuItem.normal("&Color Adjust...", null, openColorAdjust),
			flag("Sprite &Limit", "spritelimit", true),
			MenuItem.sep(),
			keyed(MenuItem.normal("Screen S&hot", null, takeShot, needRom), "Shift+Backspace")
		];

		var debugItems:Array<MenuItem> = [
			MenuItem.check("&68000", false, function(v:Bool)
			{
				msg("68000 DEBUG " + (v ? "ON" : "OFF"));
			}),
			MenuItem.check("&Z80", false, function(v:Bool)
			{
				msg("Z80 DEBUG " + (v ? "ON" : "OFF"));
			}),
			MenuItem.check("&VDP (FPS counter)", Main.fpsVar != null && Main.fpsVar.visible, function(v:Bool)
			{
				Main.setFPSVisible(v);
				msg("VDP DEBUG " + (v ? "ON" : "OFF"));
			})
		];

		var cpu:Array<MenuItem> = [
			MenuItem.sub("&Debug", debugItems, null, needRom),
			MenuItem.sep(),
			keyed(MenuItem.normal("&Hard Reset", null, hardReset, needRom), "Tab"),
			keyed(MenuItem.normal("&Pause", null, togglePause, needRom), "Pause")
		];

		var rates = ["11025", "22050", "44100"];
		var rateItems = choice(["11025 Hz", "22050 Hz", "44100 Hz"], "rate", 2, function(i:Int)
		{
			msg("SOUND RATE: " + rates[i] + " HZ");
		});

		var chip = function(label:String, ?apply:Bool->Void):MenuItem
		{
			var name = StringTools.replace(plain(label), " ENABLE", "");
			return MenuItem.check(label, true, function(v:Bool)
			{
				if (apply != null) apply(v);
				msg(name + (v ? " ENABLED" : " DISABLED"));
			});
		};

		var sound:Array<MenuItem> = [
			soundEnable,
			MenuItem.sub("&Rate", rateItems),
			MenuItem.check("S&tereo", true, function(v:Bool)
			{
				msg(v ? "STEREO ENABLED" : "MONO ENABLED");
			}),
			MenuItem.sep(),
			chip("&Z80 Enable"),
			MenuItem.sep(),
			chip("&YM2612 Enable", function(v:Bool)
			{
				FlxG.sound.defaultMusicGroup.volume = v ? 1 : 0;
			}),
			chip("&PSG Enable", function(v:Bool)
			{
				FlxG.sound.defaultSoundGroup.volume = v ? 1 : 0;
			}),
			chip("&DAC Enable"),
			chip("PC&M Enable"),
			chip("P&WM Enable"),
			chip("CDD&A Enable")
		];

		var countries = ["AUTO DETECTION", "JAPAN (NTSC)", "USA (NTSC)", "EUROPE (PAL)", "JAPAN (PAL)"];
		var countryItems = choice(["&Auto Detection", "&Japan (NTSC)", "&USA (NTSC)", "&Europe (PAL)", "Japan (&PAL)"], "country", 0, function(i:Int)
		{
			applyCountry(i);
			msg("COUNTRY: " + countries[i] + (i >= 3 ? " - 50 FPS" : ""));
		});

		var sramSizes = ["NONE", "8 KB", "16 KB", "32 KB", "64 KB"];
		var sramItems = choice(["&None", "&8 Kb", "&16 Kb", "&32 Kb", "&64 Kb"], "sram", 0, function(i:Int)
		{
			msg("SRAM SIZE: " + sramSizes[i]);
		});

		var options:Array<MenuItem> = [
			MenuItem.normal("&General Options...", null, openGeneral),
			MenuItem.normal("&Joypads...", null, openJoypads),
			MenuItem.normal("&Directories...", null, openDirectories),
			MenuItem.normal("&Bios/Misc Files...", null, openBios),
			MenuItem.sep(),
			MenuItem.sub("Current &Country", countryItems),
			MenuItem.sub("Sega CD SRAM &Size", sramItems)
		];

		var help:Array<MenuItem> = [MenuItem.normal("&About...", null, openAbout)];

		headers = [
			MenuItem.sub("&File", file),
			MenuItem.sub("&Graphics", graphics),
			MenuItem.sub("&CPU", cpu),
			MenuItem.sub("&Sound", sound),
			MenuItem.sub("&Options", options),
			MenuItem.sub("&Help", help)
		];
	}

	function applyAll():Void
	{
		FlxG.autoPause = cfg("autopause", FlxG.autoPause) == true;
		applyCountry(Std.int(cfg("country", 0)));
		applyColor();
	}

		function applyCountry(i:Int):Void
	{
		var pal = (i == 3 || i == 4);
		var f:Int;
		if (pal)
		{
			if (baseFps == 0) baseFps = FlxG.updateFramerate;
			f = 50;
		}
		else
		{
			if (baseFps == 0) return;
			f = baseFps;
			baseFps = 0;
		}
		if (f > FlxG.drawFramerate)
		{
			FlxG.drawFramerate = f;
			FlxG.updateFramerate = f;
		}
		else
		{
			FlxG.updateFramerate = f;
			FlxG.drawFramerate = f;
		}
	}

		function applyColor():Void
	{
		if (FlxG.game == null) return;
		var con:Int = Std.int(cfg("contrast", 100));
		var bri:Int = Std.int(cfg("brightness", 0));
		var gray:Bool = cfg("gray", false) == true;
		var inv:Bool = cfg("inverse", false) == true;

		if (con == 100 && bri == 0 && !gray && !inv)
		{
			FlxG.game.filters = [];
			return;
		}

		var k:Float = con / 100.0;
		var off:Float = 255.0 * (0.5 - 0.5 * k) + bri * 2.55;
		var s:Float = inv ? -k : k;
		var o:Float = inv ? 255.0 - off : off;

		var m:Array<Float> = [];
		for (i in 0...3)
		{
			var r:Array<Float> = gray ? [0.299, 0.587, 0.114] : [i == 0 ? 1.0 : 0.0, i == 1 ? 1.0 : 0.0, i == 2 ? 1.0 : 0.0];
			m.push(r[0] * s);
			m.push(r[1] * s);
			m.push(r[2] * s);
			m.push(0.0);
			m.push(o);
		}
		m.push(0.0);
		m.push(0.0);
		m.push(0.0);
		m.push(1.0);
		m.push(0.0);
		FlxG.game.filters = [new ColorMatrixFilter(m)];
	}

	function toggleFull():Void
	{
		FlxG.fullscreen = !FlxG.fullscreen;
		fullItem.checked = FlxG.fullscreen;
	}

	function hardReset():Void
	{
		if (!romLoaded) return;
		closeAll();
		resumeGame();
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		msg("HARD RESET");
		FlxG.switchState(new Sonic3TitleStateV2());
	}

	function togglePause():Void
	{
		if (!romLoaded) return;
		closeAll();
		paused = !paused;
		if (FlxG.state != null) FlxG.state.active = !paused;
		if (paused)
			FlxG.sound.pause();
		else
			FlxG.sound.resume();
		msg(paused ? "PAUSED" : "RESUMED");
	}

	function resumeGame():Void
	{
		if (!paused) return;
		paused = false;
		if (FlxG.state != null) FlxG.state.active = true;
		FlxG.sound.resume();
	}

	function takeShot():Void
	{
		if (!romLoaded)
		{
			msg("NO ROM LOADED");
			return;
		}
		closeAll();
		try
		{
			var st = Lib.current.stage;
			var bh = barHeight;

			var vBar = barSprite.visible;
			barSprite.visible = false;
			panelLayer.visible = false;
			osd.visible = false;
			osdShadow.visible = false;
			var full = new BitmapData(st.stageWidth, st.stageHeight, false, 0x000000);
			full.draw(st);
			barSprite.visible = vBar;
			panelLayer.visible = true;
			osd.visible = true;
			osdShadow.visible = true;

			var shot = new BitmapData(st.stageWidth, Std.int(Math.max(1, st.stageHeight - bh)), false, 0x000000);
			shot.copyPixels(full, new Rectangle(0, bh, shot.width, shot.height), new Point(0, 0));
			full.dispose();

			var dir = dirOf(5);
			if (!FileSystem.exists(dir)) FileSystem.createDirectory(dir);
			var n = 0;
			var path:String;
			do
			{
				path = Path.join([dir, "Sonic3_" + StringTools.lpad(Std.string(n), "0", 4) + ".png"]);
				n++;
			}
			while (FileSystem.exists(path));

			File.saveBytes(path, shot.encode(shot.rect, new PNGEncoderOptions()));
			shot.dispose();
			msg("SCREENSHOT: " + Path.withoutDirectory(path).toUpperCase());
		}
		catch (e:Dynamic)
		{
			msg("SCREENSHOT FAILED");
		}
	}

	static function rHead(s:String):DRow
		return {kind: 0, label: s};

	static function rInfo(s:String):DRow
		return {kind: 7, label: s};

	static function rCheck(s:String, v:Bool, d:Bool, a:Bool->Void):DRow
		return {
			kind: 1,
			label: s,
			value: v,
			def: d,
			apply: function(x:Dynamic)
			{
				a(x == true);
			}
		};

	static function rKey(s:String, v:Int, d:Int, a:Int->Void):DRow
		return {
			kind: 2,
			label: s,
			value: v,
			def: d,
			apply: function(x:Dynamic)
			{
				a(Std.int(x));
			}
		};

	static function rPath(s:String, v:String, d:String, isDir:Bool, a:String->Void):DRow
		return {
			kind: 3,
			label: s,
			value: v,
			def: d,
			dir: isDir,
			apply: function(x:Dynamic)
			{
				a(Std.string(x));
			}
		};

	static function rStep(s:String, v:Int, d:Int, mn:Int, mx:Int, st:Int, a:Int->Void):DRow
		return {
			kind: 4,
			label: s,
			value: v,
			def: d,
			min: mn,
			max: mx,
			step: st,
			apply: function(x:Dynamic)
			{
				a(Std.int(x));
			}
		};

	function openDialog(title:String, rows:Array<DRow>, w:Int, single:Bool = false, ?afterOk:Void->Void):Void
	{
		if (dlg != null) return;
		closeAll();
		if (!keysLocked)
		{
			keysLocked = true;
			FlxG.keys.enabled = false;
		}
		restoreKeys = false;

		dlg = new GDialog(title, rows, w, single);
		dlg.onDone = function(ok:Bool)
		{
			dlg = null;
			restoreKeys = true;
			if (ok)
			{
				flushCfg();
				if (afterOk != null) afterOk();
			}
		};
		addChild(dlg);
	}

	function openGeneral():Void
	{
		openDialog("General Options", [
			rHead("Display"),
			rCheck("Show FPS counter", ClientPrefs.data.showFPS == true, false, function(v:Bool)
			{
				ClientPrefs.data.showFPS = v;
				Main.refreshFPSVisibility();
			}),
			rCheck("Show OSD messages", cfg("osd", true) == true, true, function(v:Bool)
			{
				setCfg("osd", v);
			}),
			rCheck("Fast Blur", cfg("fastblur", false) == true, false, function(v:Bool)
			{
				setCfg("fastblur", v);
			}),
			rHead("Emulation"),
			rCheck("Pause when the window loses focus", FlxG.autoPause, true, function(v:Bool)
			{
				FlxG.autoPause = v;
				setCfg("autopause", v);
			}),
			rCheck("Auto Fix Checksum", cfg("fixsum", true) == true, true, function(v:Bool)
			{
				setCfg("fixsum", v);
			}),
			rCheck("Perfect Synchro", cfg("perfectsync", false) == true, false, function(v:Bool)
			{
				setCfg("perfectsync", v);
			})
		], 360);
	}

	function openJoypads():Void
	{
		var rows:Array<DRow> = [rHead("Player 1")];
		for (i in 0...PAD_NAMES.length)
		{
			var idx = i;
			var n = PAD_NAMES[i];
			var linked = idx < PAD_BIND.length;
			var cur = linked ? bindGet(PAD_BIND[idx], PAD_DEF[idx]) : Std.int(cfg("pad_" + n, PAD_DEF[idx]));
			rows.push(rKey(linked ? n : n + "   (not used in game)", cur, PAD_DEF[idx], function(v:Int)
			{
				if (linked)
					bindSet(PAD_BIND[idx], v);
				else
					setCfg("pad_" + n, v);
			}));
		}
		openDialog("Joypads", rows, 360, false, function()
		{
			try
			{
				ClientPrefs.saveSettings();
			}
			catch (e:Dynamic) {}
		});
	}

	function openDirectories():Void
	{
		var rows:Array<DRow> = [rHead("Directories")];
		for (i in 0...DIR_NAMES.length)
		{
			var idx = i;
			rows.push(rPath(DIR_NAMES[i], Std.string(cfg("dir_" + i, DIR_DEF[i])), DIR_DEF[i], true, function(v:String)
			{
				setCfg("dir_" + idx, v);
			}));
		}
		openDialog("Directories", rows, 520);
	}

	function openBios():Void
	{
		var rows:Array<DRow> = [rHead("Bios Files")];
		for (i in 0...BIOS_NAMES.length)
		{
			var idx = i;
			rows.push(rPath(BIOS_NAMES[i], Std.string(cfg("bios_" + i, "")), "", false, function(v:String)
			{
				setCfg("bios_" + idx, v);
			}));
		}
		openDialog("Bios/Misc Files", rows, 520);
	}

	function openColorAdjust():Void
	{
		openDialog("Color Adjust", [
			rStep("Contrast", Std.int(cfg("contrast", 100)), 100, 0, 200, 5, function(v:Int)
			{
				setCfg("contrast", v);
			}),
			rStep("Brightness", Std.int(cfg("brightness", 0)), 0, -100, 100, 5, function(v:Int)
			{
				setCfg("brightness", v);
			}),
			rCheck("Grayscale", cfg("gray", false) == true, false, function(v:Bool)
			{
				setCfg("gray", v);
			}),
			rCheck("Inverse Colors", cfg("inverse", false) == true, false, function(v:Bool)
			{
				setCfg("inverse", v);
			})
		], 340, false, applyColor);
	}

	function openAbout():Void
	{
		openDialog("About", [
			rHead("Gens - Sonic the Hedgehog 3 (FNF Port)"),
			rInfo("Gens-style launcher for the FNF port."),
			rInfo("Menu layout based on the Gens emulator."),
			rInfo("Not affiliated with SEGA.")
		], 340, true);
	}

	function buildBar():Void
	{
		var x:Float = 0;
		for (h in headers)
		{
			var t = mkTF(h.text);
			t.x = Math.round(x + 8 - 2);
			t.y = Math.round((BAR_H - t.textHeight) / 2 - 2);
			barSprite.addChild(t);
			headLabels.push(t);
			var w = Math.ceil(t.textWidth) + 16;
			headX.push(x);
			headW.push(w);
			x += w;
		}
	}

	function paintBar():Void
	{
		var g = barSprite.graphics;
		g.clear();
		var sw = Lib.current.stage.stageWidth;
		g.lineStyle();
		g.beginFill(pal.bar);
		g.drawRect(0, 0, sw, BAR_H);
		g.endFill();
		g.lineStyle(1, pal.barLine);
		g.moveTo(0, BAR_H - 0.5);
		g.lineTo(sw, BAR_H - 0.5);

		for (i in 0...headers.length)
		{
			var lit = (i == activeHeader || i == hotHeader);
			if (lit)
			{
				g.lineStyle();
				g.beginFill(pal.hl);
				g.drawRect(headX[i], 0, headW[i], BAR_H - 1);
				g.endFill();
			}
			var col = lit ? pal.hlText : pal.text;
			headLabels[i].textColor = col;
			underline(g, headLabels[i], headers[i].mnemonicIndex, col);
		}
	}

	function underline(g:openfl.display.Graphics, tf:TextField, index:Int, col:Int):Void
	{
		if (index < 0) return;
		var r:Rectangle = null;
		try
		{
			r = tf.getCharBoundaries(index);
		}
		catch (e:Dynamic) {}
		if (r == null) return;
		var y = Math.round(tf.y + r.y + r.height) - 1;
		g.lineStyle(1, col);
		g.moveTo(tf.x + r.x, y + 0.5);
		g.lineTo(tf.x + r.x + r.width, y + 0.5);
	}

	function layout():Void
	{
		var vis = barVisible();
		lastVis = vis;
		barSprite.visible = vis;
		if (!vis) closeAll();
		paintBar();
		var sh = Lib.current.stage.stageHeight;
		osd.x = 10;
		osd.y = sh - 38;
		osdShadow.x = osd.x + 1;
		osdShadow.y = osd.y + 1;
		if (Main.fpsVar != null) Main.fpsVar.y = (vis ? BAR_H : 0) + 3;
	}

	function onResize(_:Event):Void
	{
		layout();
	}

	function pushPanel(items:Array<MenuItem>, x:Float, y:Float, level:Int, parent:Panel):Panel
	{
		var p = new Panel();
		p.items = items;
		p.level = level;
		p.sprite = new Sprite();

		var maxL:Float = 0;
		var maxK:Float = 0;
		for (it in items)
		{
			if (it.isSep())
			{
				p.labels.push(null);
				p.keys.push(null);
				continue;
			}
			var l = mkTF(it.text);
			var k:TextField = it.key != null ? mkTF(it.key) : null;
			p.labels.push(l);
			p.keys.push(k);
			p.sprite.addChild(l);
			if (k != null) p.sprite.addChild(k);
			if (l.textWidth > maxL) maxL = l.textWidth;
			if (k != null && k.textWidth > maxK) maxK = k.textWidth;
		}

		p.w = Math.ceil(Math.max(130, GUTTER + maxL + (maxK > 0 ? KEY_GAP + maxK : 0) + RIGHT));

		var cy:Float = PAD;
		for (it in items)
		{
			var h:Float = it.isSep() ? SEP_H : ROW_H;
			p.tops.push(cy);
			p.heights.push(h);
			cy += h;
		}
		p.h = cy + PAD;

		var sw = Lib.current.stage.stageWidth;
		var sh = Lib.current.stage.stageHeight;
		if (x + p.w > sw) x = parent != null ? parent.sprite.x - p.w + 3 : sw - p.w;
		if (x < 0) x = 0;
		if (y + p.h > sh) y = Math.max(0, sh - p.h);
		p.sprite.x = Math.round(x);
		p.sprite.y = Math.round(y);

		for (n in 0...items.length)
		{
			if (items[n].isSep()) continue;
			var l = p.labels[n];
			l.x = GUTTER - 2;
			l.y = Math.round(p.tops[n] + (ROW_H - l.textHeight) / 2 - 2);
			var k = p.keys[n];
			if (k != null)
			{
				k.x = Math.round(p.w - RIGHT - k.textWidth - 2);
				k.y = l.y;
			}
		}

		panelLayer.addChild(p.sprite);
		panels.push(p);
		paintPanel(p);
		return p;
	}

	function paintPanel(p:Panel):Void
	{
		var g = p.sprite.graphics;
		g.clear();
		g.lineStyle(1, pal.border);
		g.beginFill(pal.panel);
		g.drawRect(0.5, 0.5, p.w - 1, p.h - 1);
		g.endFill();

		for (n in 0...p.items.length)
		{
			var it = p.items[n];
			var top = p.tops[n];
			var h = p.heights[n];
			var cy = top + h / 2;

			if (it.isSep())
			{
				g.lineStyle(1, pal.sep);
				g.moveTo(GUTTER - 4, Math.round(cy) + 0.5);
				g.lineTo(p.w - 4, Math.round(cy) + 0.5);
				continue;
			}

			var sel = (n == p.sel);
			var en = it.isEnabled();
			if (sel)
			{
				g.lineStyle();
				g.beginFill(pal.hl);
				g.drawRect(3, top, p.w - 6, h);
				g.endFill();
			}

			var col = !en ? pal.dis : (sel ? pal.hlText : pal.text);
			p.labels[n].textColor = col;
			if (p.keys[n] != null) p.keys[n].textColor = col;
			underline(g, p.labels[n], it.mnemonicIndex, col);

			if (it.isCheck() && it.checked)
			{
				g.lineStyle(2, col);
				g.moveTo(9, cy);
				g.lineTo(12, cy + 3);
				g.lineTo(18, cy - 4);
			}
			else if (it.isRadio() && it.checked)
			{
				g.lineStyle();
				g.beginFill(col);
				g.drawCircle(14, cy, 3);
				g.endFill();
			}

			if (it.isSub())
			{
				var ax = p.w - 14;
				g.lineStyle();
				g.beginFill(col);
				g.moveTo(ax, cy - 4);
				g.lineTo(ax + 4, cy);
				g.lineTo(ax, cy + 4);
				g.lineTo(ax, cy - 4);
				g.endFill();
			}
		}
	}

	function truncatePanels(count:Int):Void
	{
		while (panels.length > count)
		{
			var p = panels.pop();
			if (p.sprite.parent != null) p.sprite.parent.removeChild(p.sprite);
		}
	}

	function openHeader(i:Int, selectFirst:Bool = false):Void
	{
		truncatePanels(0);
		refreshChecks();
		if (!keysLocked)
		{
			keysLocked = true;
			restoreKeys = false;
			FlxG.keys.enabled = false;
		}
		activeHeader = i;
		var p = pushPanel(headers[i].children, headX[i], BAR_H - 1, 0, null);
		if (selectFirst)
		{
			p.sel = nextSel(p, -1, 1);
			paintPanel(p);
		}
		paintBar();
	}

	function openSub(p:Panel, selectFirst:Bool):Void
	{
		if (p.sel < 0) return;
		var it = p.items[p.sel];
		if (!it.isSub() || it.children == null || it.children.length == 0) return;
		truncatePanels(p.level + 1);
		var np = pushPanel(it.children, p.sprite.x + p.w - 3, p.sprite.y + p.tops[p.sel] - PAD, p.level + 1, p);
		if (selectFirst)
		{
			np.sel = nextSel(np, -1, 1);
			paintPanel(np);
		}
	}

	function closeAll():Void
	{
		truncatePanels(0);
		if (activeHeader >= 0)
		{
			activeHeader = -1;
			paintBar();
		}
		if (keysLocked) restoreKeys = true;
	}

	function refreshChecks():Void
	{
		soundEnable.checked = !FlxG.sound.muted;
		fullItem.checked = FlxG.fullscreen;
		refreshSlotLabels();
	}

	function refreshSlotLabels():Void
	{
		for (i in 0...slotItems.length)
			slotItems[i].text = i + (stateExists(i) ? "  (saved)" : "");
	}

	function nextSel(p:Panel, from:Int, dir:Int):Int
	{
		var n = p.items.length;
		if (n == 0) return -1;
		if (from < 0 && dir < 0) from = 0;
		var i = from;
		for (_ in 0...n)
		{
			i = (i + dir + n) % n;
			if (!p.items[i].isSep()) return i;
		}
		return -1;
	}

	function headerAt(mx:Float, my:Float):Int
	{
		if (!barVisible() || my < 0 || my >= BAR_H) return -1;
		for (i in 0...headX.length)
			if (mx >= headX[i] && mx < headX[i] + headW[i]) return i;
		return -1;
	}

	function panelAt(mx:Float, my:Float):Int
	{
		var i = panels.length - 1;
		while (i >= 0)
		{
			var p = panels[i];
			if (mx >= p.sprite.x && mx < p.sprite.x + p.w && my >= p.sprite.y && my < p.sprite.y + p.h) return i;
			i--;
		}
		return -1;
	}

	function itemAt(p:Panel, mx:Float, my:Float):Int
	{
		var ly = my - p.sprite.y;
		for (n in 0...p.items.length)
			if (!p.items[n].isSep() && ly >= p.tops[n] && ly < p.tops[n] + p.heights[n]) return n;
		return -1;
	}

	function activateItem(p:Panel, n:Int, fromKey:Bool):Void
	{
		var it = p.items[n];
		if (it.isSep() || !it.isEnabled()) return;

		if (it.isSub())
		{
			if (p.sel != n)
			{
				truncatePanels(p.level + 1);
				p.sel = n;
				paintPanel(p);
			}
			if (panels.length == p.level + 1) openSub(p, fromKey);
			return;
		}

		closeAll();
		it.trigger();
	}

	function onMouseMove(e:MouseEvent):Void
	{
		if (busy || dlg != null) return;
		var mx = e.stageX;
		var my = e.stageY;

		var h = headerAt(mx, my);
		if (h != hotHeader)
		{
			hotHeader = h;
			paintBar();
		}

		if (panels.length == 0) return;

		if (h >= 0 && h != activeHeader)
		{
			openHeader(h);
			return;
		}

		var pi = panelAt(mx, my);
		if (pi < 0) return;
		var p = panels[pi];
		var n = itemAt(p, mx, my);
		if (n < 0 || p.sel == n) return;

		truncatePanels(pi + 1);
		p.sel = n;
		paintPanel(p);
		var it = p.items[n];
		if (it.isSub() && it.isEnabled()) openSub(p, false);
	}

	function onMouseDown(e:MouseEvent):Void
	{
		if (busy || dlg != null) return;
		var mx = e.stageX;
		var my = e.stageY;

		var h = headerAt(mx, my);
		if (h >= 0)
		{
			if (h == activeHeader)
				closeAll();
			else
				openHeader(h);
			return;
		}

		if (panels.length == 0) return;

		var pi = panelAt(mx, my);
		if (pi >= 0)
		{
			var n = itemAt(panels[pi], mx, my);
			if (n >= 0) activateItem(panels[pi], n, false);
			return;
		}

		closeAll();
	}

	static function keyChar(e:KeyboardEvent):String
	{
		var c = e.charCode;
		if (c > 32 && c < 127) return String.fromCharCode(c).toLowerCase();
		var k = e.keyCode;
		if ((k >= 48 && k <= 57) || (k >= 65 && k <= 90)) return String.fromCharCode(k).toLowerCase();
		return "";
	}

	function onKeyDown(e:KeyboardEvent):Void
	{
		if (busy || dlg != null) return;

		if (panels.length > 0)
		{
			menuKey(e);
			return;
		}

		var k = e.keyCode;

		if (e.altKey && !e.ctrlKey && k == Keyboard.ENTER)
		{
			toggleFull();
			return;
		}

		if (e.altKey && !e.ctrlKey && barVisible())
		{
			var ch = keyChar(e);
			for (i in 0...headers.length)
				if (ch != "" && headers[i].mnemonic == ch)
				{
					openHeader(i, true);
					return;
				}
			return;
		}

		if (e.ctrlKey && k == Keyboard.O)
		{
			openRomDialog();
			return;
		}
		if (e.ctrlKey && k == Keyboard.C)
		{
			closeRom();
			return;
		}
		if (!romLoaded) return;

		if (e.ctrlKey && k == Keyboard.F5) saveStateAs();
		else if (e.ctrlKey && k == Keyboard.F8) loadStateAs();
		else if (e.shiftKey && k == Keyboard.BACKSPACE) takeShot();
		else if (k == Keyboard.TAB) hardReset();
		else if (k == 19) togglePause();
		else if (k == Keyboard.F5) saveState();
		else if (k == Keyboard.F8) loadState();
		else if (k == Keyboard.F6) changeSlot(-1);
		else if (k == Keyboard.F7) changeSlot(1);
	}

	function menuKey(e:KeyboardEvent):Void
	{
		var p = panels[panels.length - 1];
		var k = e.keyCode;

		if (k == Keyboard.ESCAPE)
		{
			if (panels.length > 1)
				truncatePanels(panels.length - 1);
			else
				closeAll();
		}
		else if (k == Keyboard.UP)
		{
			p.sel = nextSel(p, p.sel, -1);
			paintPanel(p);
		}
		else if (k == Keyboard.DOWN)
		{
			p.sel = nextSel(p, p.sel, 1);
			paintPanel(p);
		}
		else if (k == Keyboard.RIGHT)
		{
			var it = p.sel >= 0 ? p.items[p.sel] : null;
			if (it != null && it.isSub() && it.isEnabled())
				openSub(p, true);
			else if (panels.length == 1)
				openHeader((activeHeader + 1) % headers.length, true);
		}
		else if (k == Keyboard.LEFT)
		{
			if (panels.length > 1)
				truncatePanels(panels.length - 1);
			else
				openHeader((activeHeader - 1 + headers.length) % headers.length, true);
		}
		else if (k == Keyboard.ENTER || k == Keyboard.SPACE)
		{
			if (p.sel >= 0) activateItem(p, p.sel, true);
		}
		else
		{
			var ch = keyChar(e);
			if (ch == "") return;
			var matches:Array<Int> = [];
			for (n in 0...p.items.length)
				if (!p.items[n].isSep() && p.items[n].mnemonic == ch) matches.push(n);
			if (matches.length == 0) return;
			var pick = matches[0];
			for (m in matches)
				if (m > p.sel)
				{
					pick = m;
					break;
				}
			if (matches.length == 1)
				activateItem(p, pick, true);
			else
			{
				p.sel = pick;
				paintPanel(p);
			}
		}
	}

	function onFrame(_:Event):Void
	{
		var now = Timer.stamp();
		var dt = now - lastTime;
		lastTime = now;

		if (!configured && FlxG.state != null)
		{
			configured = true;
			FlxG.scaleMode = scaleFor(cfg("stretch", false) == true);
			FlxG.mouse.visible = true;
			FlxG.mouse.useSystemCursor = true;
			applyAll();
			setTitle(curTitle);
		}

		if (dialogClosed)
		{
			dialogClosed = false;
			busy = false;
		}

		if (pendingPath != null)
		{
			var p = pendingPath;
			pendingPath = null;
			loadRom(p);
		}

		if (pendingSaveAs != null)
		{
			var p = pendingSaveAs;
			pendingSaveAs = null;
			if (Path.extension(p) == "") p += ".gs" + slot;
			msg(writeState(p) ? "STATE SAVED: " + Path.withoutDirectory(p).toUpperCase() : "STATE SAVE FAILED");
		}

		if (pendingLoadFrom != null)
		{
			var p = pendingLoadFrom;
			pendingLoadFrom = null;
			loadStateFile(p, Path.withoutDirectory(p).toUpperCase());
		}

		if (pendingPlay != null)
		{
			var pi = PlayState.instance;
			if (--playWait <= 0)
				pendingPlay = null;
			else if (pi != null && pi != oldPlay && Std.isOfType(FlxG.state, PlayState) && !pi.startingSong)
			{
				applyPlayStats(pi, pendingPlay);
				pendingPlay = null;
				oldPlay = null;
			}
		}

		if (pendingMusic != null && --musicWait <= 0)
		{
			restoreMusic(pendingMusic);
			pendingMusic = null;
		}

		var vis = barVisible();
		if (vis != lastVis)
		{
			layout();
			Lib.current.stage.dispatchEvent(new Event(Event.RESIZE));
		}

		if (restoreKeys && panels.length == 0 && dlg == null)
		{
			restoreKeys = false;
			keysLocked = false;
			FlxG.keys.enabled = true;
			FlxG.keys.reset();
		}

		if (osdLeft > 0)
		{
			osdLeft -= dt;
			if (osdLeft <= 0)
			{
				osd.text = "";
				osdShadow.text = "";
			}
			else if (osdLeft < 0.5)
			{
				osd.alpha = osdLeft / 0.5;
				osdShadow.alpha = osd.alpha;
			}
		}
	}

	function msg(s:String):Void
		showMsg(s);

	function showMsg(s:String):Void
	{
		if (cfg("osd", true) == false) return;
		osd.text = s;
		osdShadow.text = s;
		osd.alpha = 1;
		osdShadow.alpha = 1;
		osdLeft = 2.5;
	}

	function setTitle(s:String):Void
	{
		curTitle = s;
		Application.current.window.title = s;
	}

	function exitApp():Void
	{
		Main.shutdownSystems();
		Sys.exit(0);
	}

	static inline var STATE_VERSION:Int = 1;

	static function stateName():String
		return Path.withoutExtension(ROM_FILE);

	static function stateFile(n:Int):String
		return Path.join([dirOf(0), stateName() + ".gs" + n]);

	static function stateExists(n:Int):Bool
	{
		try
		{
			return FileSystem.exists(stateFile(n));
		}
		catch (e:Dynamic) {}
		return false;
	}

	function buildState():String
	{
		var cls:String = FlxG.state != null ? Type.getClassName(Type.getClass(FlxG.state)) : null;
		var music:Dynamic = null;
		if (FlxG.sound.music != null && FlxG.sound.music.playing)
			music = {time: FlxG.sound.music.time, volume: FlxG.sound.music.volume};

		var play:Dynamic = null;
		var pi = PlayState.instance;
		if (Std.isOfType(FlxG.state, PlayState) && pi != null && !pi.isDead && !pi.endingSong && PlayState.SONG != null)
		{
			var ratings:Array<Int> = [];
			for (r in pi.ratingsData) ratings.push(r.hits);
			var pos:Float = Conductor.songPosition;
			if (pos < 0) pos = 0;
			play = {
				song: Song.loadedSongName,
				diffPath: Difficulty.getFilePath(),
				diffList: Difficulty.list.copy(),
				mod: Mods.currentModDirectory,
				story: PlayState.isStoryMode,
				week: PlayState.storyWeek,
				playlist: PlayState.storyPlaylist.copy(),
				difficulty: PlayState.storyDifficulty,
				campaignScore: PlayState.campaignScore,
				campaignMisses: PlayState.campaignMisses,
				deaths: PlayState.deathCounter,
				position: pos,
				score: pi.songScore,
				hits: pi.songHits,
				misses: pi.songMisses,
				combo: pi.combo,
				health: pi.health,
				played: pi.totalPlayed,
				notesHit: pi.totalNotesHit,
				ratings: ratings
			};
		}

		var body:Dynamic = {
			version: STATE_VERSION,
			play: play,
			rom: ROM_FILE,
			time: Date.now().toString(),
			stateClass: cls,
			slot: Save.currentSlot,
			progress: Json.parse(Json.stringify(Save.data)),
			music: music
		};
		var payload = Json.stringify(body);
		return Json.stringify({checksum: Sha256.encode(payload), payload: payload});
	}

	function writeState(path:String):Bool
	{
		try
		{
			var dir = Path.directory(path);
			if (dir != "" && !FileSystem.exists(dir)) FileSystem.createDirectory(dir);
			var tmp = path + ".tmp";
			File.saveContent(tmp, buildState());
			if (readState(tmp) == null)
			{
				FileSystem.deleteFile(tmp);
				return false;
			}
			if (FileSystem.exists(path)) FileSystem.deleteFile(path);
			FileSystem.rename(tmp, path);
			return true;
		}
		catch (e:Dynamic) {}
		return false;
	}

	static function readState(path:String):Dynamic
	{
		try
		{
			if (!FileSystem.exists(path) || FileSystem.isDirectory(path)) return null;
			var env:Dynamic = Json.parse(File.getContent(path));
			if (env == null || !Std.isOfType(env.payload, String) || !Std.isOfType(env.checksum, String)) return null;
			var payload:String = env.payload;
			if (Sha256.encode(payload) != env.checksum) return null;
			var body:Dynamic = Json.parse(payload);
			if (body == null || body.version != STATE_VERSION) return null;
			return body;
		}
		catch (e:Dynamic) {}
		return null;
	}

	function applyState(body:Dynamic):Bool
	{
		try
		{
			var want:Int = body.slot == null ? -1 : Std.int(body.slot);
			if (want >= 0 && want != Save.currentSlot) Save.changeSlot(want, true);
			Save.clear();
			var prog:Dynamic = body.progress;
			if (prog != null)
				for (k in Reflect.fields(prog))
					Save.set(k, Reflect.field(prog, k));
			Main.flushProgress();
		}
		catch (e:Dynamic)
		{
			return false;
		}

		if (body.play != null && restorePlay(body.play))
		{
			resumeGame();
			pendingMusic = null;
			return true;
		}

		var next:FlxState = null;
		var name:String = body.stateClass == null ? "" : Std.string(body.stateClass);
		var unsafe = name == "" || name.indexOf("PlayState") >= 0 || name.indexOf("Charting") >= 0 || name.indexOf("Loading") >= 0;
		if (!unsafe)
		{
			var cls:Class<Dynamic> = Type.resolveClass(name);
			if (cls != null)
			{
				try
				{
					next = cast Type.createInstance(cls, []);
				}
				catch (e:Dynamic)
				{
					next = null;
				}
			}
		}
		if (next == null) next = new Sonic3TitleStateV2();

		resumeGame();
		pendingMusic = body.music;
		musicWait = 3;
		FlxG.switchState(next);
		return true;
	}

	function restorePlay(p:Dynamic):Bool
	{
		try
		{
			var song:String = Std.string(p.song);
			Mods.currentModDirectory = Std.string(p.mod);
			PlayState.isStoryMode = p.story == true;
			PlayState.storyWeek = Std.int(p.week);
			PlayState.storyPlaylist = p.playlist;
			PlayState.storyDifficulty = Std.int(p.difficulty);
			PlayState.campaignScore = Std.int(p.campaignScore);
			PlayState.campaignMisses = Std.int(p.campaignMisses);
			PlayState.deathCounter = Std.int(p.deaths);
			PlayState.changedDifficulty = false;
			PlayState.chartingMode = false;
			PlayState.seenCutscene = true;
			if (p.diffList != null) Difficulty.list = p.diffList;
			if (PlayState.isStoryMode) WeekData.reloadWeekFiles(true);
			Song.loadFromJson(song + Std.string(p.diffPath), song);
			var pos:Float = p.position;
			PlayState.startOnTime = pos > 0 ? pos : 0;
			oldPlay = PlayState.instance;
			pendingPlay = p;
			playWait = 3600;
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			LoadingState.prepareToSong();
			LoadingState.loadAndSwitchState(new PlayState(), false, false);
			return true;
		}
		catch (e:Dynamic)
		{
			pendingPlay = null;
		}
		return false;
	}

	function applyPlayStats(pi:PlayState, p:Dynamic):Void
	{
		try
		{
			pi.songScore = Std.int(p.score);
			pi.songHits = Std.int(p.hits);
			pi.songMisses = Std.int(p.misses);
			pi.combo = Std.int(p.combo);
			pi.totalPlayed = Std.int(p.played);
			pi.totalNotesHit = p.notesHit;
			var rs:Array<Dynamic> = p.ratings;
			if (rs != null)
				for (i in 0...rs.length)
					if (i < pi.ratingsData.length) pi.ratingsData[i].hits = Std.int(rs[i]);
			pi.health = p.health;
			pi.RecalculateRating(false, false);
		}
		catch (e:Dynamic) {}
	}

	function restoreMusic(m:Dynamic):Void
	{
		try
		{
			if (FlxG.sound.music == null) return;
			if (m.time != null && m.time < FlxG.sound.music.length) FlxG.sound.music.time = m.time;
		}
		catch (e:Dynamic) {}
	}

	function loadStateFile(path:String, label:String):Void
	{
		if (!romLoaded) return;
		if (!FileSystem.exists(path))
		{
			msg("STATE NOT FOUND");
			return;
		}
		var body = readState(path);
		if (body == null)
		{
			msg("STATE IS CORRUPT");
			return;
		}
		msg(applyState(body) ? "STATE LOADED: " + label : "STATE LOAD FAILED");
	}

	function saveState():Void
	{
		if (!romLoaded) return;
		msg(writeState(stateFile(slot)) ? "STATE " + slot + " SAVED" : "STATE " + slot + " SAVE FAILED");
		refreshSlotLabels();
	}

	function loadState():Void
	{
		if (!romLoaded) return;
		var f = stateFile(slot);
		if (!FileSystem.exists(f))
		{
			msg("STATE " + slot + " NOT FOUND");
			return;
		}
		loadStateFile(f, "STATE " + slot);
	}

	function saveStateAs():Void
	{
		if (!romLoaded || busy) return;
		busy = true;
		closeAll();
		try
		{
			if (!FileSystem.exists(dirOf(0))) FileSystem.createDirectory(dirOf(0));
		}
		catch (e:Dynamic) {}
		var fd = new FileDialog();
		fd.onSelect.add(function(path:String)
		{
			pendingSaveAs = path;
			dialogClosed = true;
		});
		fd.onCancel.add(function()
		{
			dialogClosed = true;
		});
		fd.browse(FileDialogType.SAVE, "gs0;gs1;gs2;gs3;gs4;gs5;gs6;gs7;gs8;gs9", stateFile(slot), "Save State as");
	}

	function loadStateAs():Void
	{
		if (!romLoaded || busy) return;
		busy = true;
		closeAll();
		var fd = new FileDialog();
		fd.onSelect.add(function(path:String)
		{
			pendingLoadFrom = path;
			dialogClosed = true;
		});
		fd.onCancel.add(function()
		{
			dialogClosed = true;
		});
		fd.browse(FileDialogType.OPEN, "gs0;gs1;gs2;gs3;gs4;gs5;gs6;gs7;gs8;gs9", stateFile(slot), "Load State");
	}

	function changeSlot(d:Int):Void
	{
		slot = (slot + d + 10) % 10;
		slotItems[slot].select();
		msg("STATE " + slot + " SELECTED");
	}

	function openRomDialog():Void
	{
		if (busy) return;
		busy = true;
		closeAll();

		var fd = new FileDialog();
		fd.onSelect.add(function(path:String)
		{
			pendingPath = path;
			dialogClosed = true;
		});
		fd.onCancel.add(function()
		{
			dialogClosed = true;
		});
		fd.browse(FileDialogType.OPEN, ROM_EXTS.join(";"), startDir(), "Open ROM");
	}

	function loadRom(path:String):Void
	{
		if (path == null) return;
		var name = Path.withoutDirectory(path);
		var ext = Path.extension(path).toLowerCase();

		if (!ROM_EXTS.contains(ext) || !isGameRom(path))
		{
			msg("INVALID ROM: " + name.toUpperCase());
			return;
		}

		closeAll();
		resumeGame();
		romLoaded = true;
		addHistory(path);
		setTitle("Gens - " + Path.withoutExtension(name));
		msg(Path.withoutExtension(name).toUpperCase());
		FlxG.switchState(new Sonic3TitleStateV2());
	}

	function closeRom():Void
	{
		if (!romLoaded) return;
		closeAll();
		resumeGame();
		romLoaded = false;
		if (FlxG.sound.music != null) FlxG.sound.music.stop();
		setTitle("Gens - Idle");
		msg("ROM CLOSED");
		FlxG.switchState(new GensIdleState());
	}

	function loadHistory():Array<String>
	{
		var h:Dynamic = FlxG.save.data.gensRomHistory;
		if (h != null && Std.isOfType(h, Array)) return cast h;
		return [];
	}

	function addHistory(path:String):Void
	{
		var h = loadHistory().copy();
		h.remove(path);
		h.unshift(path);
		while (h.length > 9) h.pop();
		FlxG.save.data.gensRomHistory = h;
		flushCfg();
		rebuildHistory();
	}

	function rebuildHistory():Void
	{
		var h = loadHistory();
		var kids:Array<MenuItem> = [];
		for (i in 0...h.length)
		{
			var path = h[i];
			var m = MenuItem.normal("&" + (i + 1) + " " + Path.withoutDirectory(path), null, function() loadRom(path));
			kids.push(m);
		}
		if (kids.length == 0) kids.push(MenuItem.normal("(Empty)", null, null, function() return false));
		historyItem.children = kids;
	}

	static function startDir():String
	{
		try
		{
			return Path.directory(Sys.programPath());
		}
		catch (e:Dynamic) {}
		return null;
	}

	static function ensureRomCopy():Void
	{
		try
		{
			var exe = Sys.programPath();
			var rom = Path.join([Path.directory(exe), ROM_FILE]);
			if (!FileSystem.exists(rom) || FileSystem.stat(rom).size != FileSystem.stat(exe).size)
				File.copy(exe, rom);
		}
		catch (e:Dynamic) {}
	}

	static function isGameRom(path:String):Bool
	{
		try
		{
			var exe = Sys.programPath();
			if (!FileSystem.exists(path) || !FileSystem.exists(exe)) return false;
			if (FileSystem.stat(path).size != FileSystem.stat(exe).size) return false;
			return sameHead(path, exe, 65536);
		}
		catch (e:Dynamic) {}
		return false;
	}

	static function sameHead(a:String, b:String, n:Int):Bool
	{
		var fa = File.read(a, true);
		var fb = File.read(b, true);
		var ba = Bytes.alloc(n);
		var bb = Bytes.alloc(n);
		var la = fa.readBytes(ba, 0, n);
		var lb = fb.readBytes(bb, 0, n);
		fa.close();
		fb.close();
		return la == lb && ba.compare(bb) == 0;
	}
}

private class Panel
{
	public var items:Array<MenuItem>;
	public var level:Int;
	public var sprite:Sprite;
	public var w:Float;
	public var h:Float;
	public var tops:Array<Float> = [];
	public var heights:Array<Float> = [];
	public var labels:Array<TextField> = [];
	public var keys:Array<TextField> = [];
	public var sel:Int = -1;

	public function new() {}
}

private class GDialog extends Sprite
{
	static inline var TITLE:Int = 24;
	static inline var BTN_W:Int = 80;
	static inline var BTN_H:Int = 24;

	public var onDone:Bool->Void;

	var rows:Array<DRow>;
	var single:Bool;
	var w:Int;
	var h:Int = 0;
	var px:Int = 0;
	var py:Int = 0;
	var tops:Array<Int> = [];
	var heights:Array<Int> = [];
	var labels:Array<TextField> = [];
	var vals:Array<TextField> = [];
	var titleTf:TextField;
	var btnTf:Array<TextField> = [];
	var capture:Int = -1;
	var hasDefaults:Bool = false;
	var finished:Bool = false;

	public function new(title:String, rows:Array<DRow>, w:Int, single:Bool)
	{
		super();
		this.rows = rows;
		this.w = w;
		this.single = single;

		var y = TITLE + 8;
		for (r in rows)
		{
			var rh = r.kind == 0 ? 28 : 24;
			tops.push(y);
			heights.push(rh);
			y += rh;
			if (r.def != null) hasDefaults = true;
		}
		h = y + 12 + BTN_H + 12;

		titleTf = mk(title, true, 0xFFFFFF);
		addChild(titleTf);

		for (r in rows)
		{
			var l = mk(r.label, r.kind == 0, 0x000000);
			addChild(l);
			labels.push(l);

			var v = mk("", false, 0x000000);
			if (r.kind == 3)
			{
				v.autoSize = TextFieldAutoSize.NONE;
				v.wordWrap = false;
				v.height = 18;
			}
			addChild(v);
			vals.push(v);
		}

		for (s in ["OK", "Cancel", "Defaults"])
		{
			var t = mk(s, false, 0x000000);
			addChild(t);
			btnTf.push(t);
		}

		mouseEnabled = true;
		addEventListener(MouseEvent.MOUSE_DOWN, onDown);
		addEventListener(Event.ADDED_TO_STAGE, onAdded);
	}

	static function mk(s:String, bold:Bool, color:Int):TextField
	{
		var t = new TextField();
		t.defaultTextFormat = new TextFormat("_sans", 12, color, bold);
		t.selectable = false;
		t.mouseEnabled = false;
		t.autoSize = TextFieldAutoSize.LEFT;
		t.text = s;
		return t;
	}

	static function keyName(code:Int):String
	{
		var fk:FlxKey = code;
		var s:String = null;
		try
		{
			s = fk.toString();
		}
		catch (e:Dynamic) {}
		return (s == null || s == "") ? "Key " + code : s;
	}

	function onAdded(_:Event):Void
	{
		removeEventListener(Event.ADDED_TO_STAGE, onAdded);
		var st = stage;
		px = Std.int((st.stageWidth - w) / 2);
		py = Std.int(Math.max(24, (st.stageHeight - h) / 2));
		st.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
		paint();
	}

	function btnX(i:Int):Int
	{
		if (single) return px + Std.int((w - BTN_W) / 2);
		return switch (i)
		{
			case 0: px + w - 16 - BTN_W * 2 - 8;
			case 1: px + w - 16 - BTN_W;
			default: px + 16;
		}
	}

	function btnY():Int
		return py + h - 12 - BTN_H;

	function btnShown(i:Int):Bool
	{
		if (single) return i == 0;
		if (i == 2) return hasDefaults;
		return true;
	}

	function paint():Void
	{
		var st = Lib.current.stage;
		var g = graphics;
		g.clear();

		g.lineStyle();
		g.beginFill(0x000000, 0.30);
		g.drawRect(0, 0, st.stageWidth, st.stageHeight);
		g.endFill();

		g.lineStyle(1, 0x404040);
		g.beginFill(0xF0F0F0);
		g.drawRect(px + 0.5, py + 0.5, w - 1, h - 1);
		g.endFill();

		g.lineStyle();
		g.beginFill(0x0A246A);
		g.drawRect(px + 1, py + 1, w - 2, TITLE - 1);
		g.endFill();
		titleTf.x = px + 8;
		titleTf.y = py + 3;

		for (i in 0...rows.length)
		{
			var r = rows[i];
			var top = py + tops[i];
			var l = labels[i];
			var v = vals[i];

			switch (r.kind)
			{
				case 0:
					l.x = px + 14;
					l.y = top + 4;
					g.lineStyle(1, 0xA0A0A0);
					g.moveTo(px + 14, top + 23.5);
					g.lineTo(px + w - 14, top + 23.5);

				case 1:
					g.lineStyle(1, 0x404040);
					g.beginFill(0xFFFFFF);
					g.drawRect(px + 16.5, top + 5.5, 12, 12);
					g.endFill();
					if (r.value == true)
					{
						g.lineStyle(2, 0x000000);
						g.moveTo(px + 19, top + 11);
						g.lineTo(px + 22, top + 14);
						g.lineTo(px + 27, top + 8);
					}
					l.x = px + 38;
					l.y = top + 3;

				case 2:
					var bx = px + w - 16 - 130;
					g.lineStyle(1, 0x404040);
					g.beginFill(capture == i ? 0x91C9F7 : 0xFFFFFF);
					g.drawRect(bx + 0.5, top + 2.5, 130, 18);
					g.endFill();
					v.text = capture == i ? "Press a key..." : keyName(Std.int(r.value));
					v.x = bx + 6;
					v.y = top + 3;
					l.x = px + 16;
					l.y = top + 3;

				case 3:
					var bx = px + 160;
					var bw = w - 160 - 16;
					g.lineStyle(1, 0x404040);
					g.beginFill(0xFFFFFF);
					g.drawRect(bx + 0.5, top + 2.5, bw, 18);
					g.endFill();
					var s = Std.string(r.value);
					v.text = (s == null || s == "" || s == "null") ? "(none)" : s;
					v.x = bx + 4;
					v.y = top + 3;
					v.width = bw - 8;
					v.height = 16;
					l.x = px + 16;
					l.y = top + 3;

				case 4:
					var mx0 = px + w - 110;
					var px0 = px + w - 34;
					g.lineStyle(1, 0x404040);
					g.beginFill(0xE1E1E1);
					g.drawRect(mx0 + 0.5, top + 2.5, 18, 18);
					g.drawRect(px0 + 0.5, top + 2.5, 18, 18);
					g.endFill();
					g.lineStyle(1, 0x000000);
					g.moveTo(mx0 + 5, top + 11.5);
					g.lineTo(mx0 + 14, top + 11.5);
					g.moveTo(px0 + 5, top + 11.5);
					g.lineTo(px0 + 14, top + 11.5);
					g.moveTo(px0 + 9.5, top + 7);
					g.lineTo(px0 + 9.5, top + 16);
					v.text = Std.string(r.value);
					v.x = mx0 + 26 + Math.max(0, 28 - v.textWidth) / 2;
					v.y = top + 3;
					l.x = px + 16;
					l.y = top + 3;

				default:
					l.x = px + 16;
					l.y = top + 2;
			}
		}

		for (i in 0...3)
		{
			var t = btnTf[i];
			t.visible = btnShown(i);
			if (!t.visible) continue;
			var bx = btnX(i);
			var by = btnY();
			g.lineStyle(1, 0x404040);
			g.beginFill(i == 0 ? 0xDCEBFA : 0xE1E1E1);
			g.drawRect(bx + 0.5, by + 0.5, BTN_W - 1, BTN_H - 1);
			g.endFill();
			t.x = bx + (BTN_W - t.textWidth) / 2 - 2;
			t.y = by + (BTN_H - t.textHeight) / 2 - 2;
		}
	}

	function onDown(e:MouseEvent):Void
	{
		e.stopPropagation();
		var mx = e.stageX;
		var my = e.stageY;

		for (i in 0...3)
		{
			if (!btnShown(i)) continue;
			if (mx >= btnX(i) && mx < btnX(i) + BTN_W && my >= btnY() && my < btnY() + BTN_H)
			{
				if (i == 0) finish(true);
				else if (i == 1) finish(false);
				else resetDefaults();
				return;
			}
		}

		for (i in 0...rows.length)
		{
			var top = py + tops[i];
			if (my < top || my >= top + heights[i] || mx < px || mx >= px + w) continue;
			rowClick(i, mx);
			return;
		}
	}

	function rowClick(i:Int, mx:Float):Void
	{
		var r = rows[i];
		switch (r.kind)
		{
			case 1:
				r.value = !(r.value == true);
			case 2:
				capture = i;
			case 3:
				browse(i);
			case 4:
				var v:Int = Std.int(r.value);
				var st:Int = r.step == null ? 1 : r.step;
				if (mx >= px + w - 110 && mx < px + w - 92) v -= st;
				else if (mx >= px + w - 34 && mx < px + w - 16) v += st;
				var lo:Int = r.min == null ? 0 : r.min;
				var hi:Int = r.max == null ? 100 : r.max;
				if (v < lo) v = lo;
				if (v > hi) v = hi;
				r.value = v;
			default:
		}
		paint();
	}

	function browse(i:Int):Void
	{
		var r = rows[i];
		var fd = new FileDialog();
		fd.onSelect.add(function(p:String)
		{
			r.value = p;
			paint();
		});
		fd.browse(r.dir == true ? FileDialogType.OPEN_DIRECTORY : FileDialogType.OPEN, null, null, r.label);
	}

	function resetDefaults():Void
	{
		capture = -1;
		for (r in rows)
			if (r.def != null) r.value = r.def;
		paint();
	}

	function onKey(e:KeyboardEvent):Void
	{
		e.stopImmediatePropagation();

		if (capture >= 0)
		{
			if (e.keyCode != Keyboard.ESCAPE) rows[capture].value = e.keyCode;
			capture = -1;
			paint();
			return;
		}

		if (e.keyCode == Keyboard.ESCAPE)
			finish(false);
		else if (e.keyCode == Keyboard.ENTER)
			finish(true);
	}

	function finish(ok:Bool):Void
	{
		if (finished) return;
		finished = true;

		if (ok)
		{
			for (r in rows)
			{
				if (r.apply == null || r.value == null) continue;
				try
				{
					r.apply(r.value);
				}
				catch (e:Dynamic) {}
			}
		}

		if (stage != null) stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
		if (parent != null) parent.removeChild(this);
		if (onDone != null) onDone(ok);
	}
}

private class FrameRatioMode extends RatioScaleMode
{
	override public function onMeasure(Width:Int, Height:Int):Void
	{
		var bar = GensFrame.barHeight;
		super.onMeasure(Width, Std.int(Math.max(1, Height - bar)));
		offset.y += bar;
		if (FlxG.game != null) FlxG.game.y = offset.y;
	}
}

private class FrameFillMode extends FillScaleMode
{
	override public function onMeasure(Width:Int, Height:Int):Void
	{
		var bar = GensFrame.barHeight;
		super.onMeasure(Width, Std.int(Math.max(1, Height - bar)));
		offset.y += bar;
		if (FlxG.game != null) FlxG.game.y = offset.y;
	}
}
