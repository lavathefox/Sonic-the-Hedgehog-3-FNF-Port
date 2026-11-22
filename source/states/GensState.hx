package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import haxe.io.Path;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;
#if desktop
import lime.app.Application;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
#end
#if sys
import sys.FileSystem;
import sys.io.File;
#end

typedef GensItem =
{
	var label:String;
	@:optional var key:String;
	@:optional var check:Bool;
	@:optional var sep:Bool;
	@:optional var sub:Bool;
	@:optional var enabled:Bool;
	@:optional var needsRom:Bool;
	@:optional var action:Void->Void;
	@:optional var toggle:Bool->Void;
}

typedef GensMenu =
{
	var name:String;
	var items:Array<GensItem>;
}

class GensState extends FlxState
{
	public static inline var ROM_FILE:String = "Sonic The Hedgehog 3 (W) [!].md";
	public static final ROM_EXTS:Array<String> = ["md", "bin", "gen", "smd"];
	public static var romLoaded:Bool = false;

	static inline var GAME_TITLE:String = "Sonic the Hedgehog 3 (FNF Port)";
	static inline var GREY_WITHOUT_ROM:Bool = true;

	static inline var FONT_SIZE:Int = 16;
	static inline var BAR_H:Int = 26;
	static inline var ITEM_H:Int = 24;
	static inline var SEP_H:Int = 9;
	static inline var HEAD_PAD:Int = 10;
	static inline var LEFT_PAD:Int = 30;
	static inline var RIGHT_PAD:Int = 24;
	static inline var KEY_GAP:Int = 36;

	static inline var C_FACE:FlxColor = 0xFFD4D0C8;
	static inline var C_SEL:FlxColor = 0xFF0A246A;
	static inline var C_DARK:FlxColor = 0xFF404040;
	static inline var C_GRAY:FlxColor = 0xFF808080;

	static final CHECK:Array<String> = [
		"......X",
		".....XX",
		"X...XX.",
		"XX.XX..",
		".XXX...",
		"..X...."
	];

	static final ARROW:Array<String> = [
		"X...",
		"XX..",
		"XXX.",
		"XXXX",
		"XXX.",
		"XX..",
		"X..."
	];

	var menus:Array<GensMenu> = [];

	var headTexts:Array<FlxText> = [];
	var headX:Array<Float> = [];
	var headW:Array<Float> = [];
	var barHl:FlxSprite;

	var dropdown:FlxGroup;
	var hl:FlxSprite;
	var openIdx:Int = -1;
	var hoverIdx:Int = -1;
	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelW:Float = 0;
	var panelItems:Array<GensItem> = [];
	var panelTop:Array<Float> = [];
	var panelHeight:Array<Float> = [];
	var panelLabels:Array<FlxText> = [];
	var panelKeys:Array<FlxText> = [];
	var panelChecks:Array<FlxSprite> = [];
	var panelArrows:Array<FlxSprite> = [];

	var msgText:FlxText;
	var msgTimer:Float = 0;

	var busy:Bool = false;
	var booting:Bool = false;
	var dialogClosed:Bool = false;
	var pendingPath:String = null;

	var curTitle:String = "Gens - Idle";
	var titleFixed:Bool = false;

	override function create():Void
	{
		super.create();

		romLoaded = false;
		FlxG.mouse.visible = true;
		#if desktop
		FlxG.mouse.useSystemCursor = true;
		#end

		setTitle("Gens - Idle");
		ensureRomCopy();

		buildMenus();
		buildBar();

		msgText = new FlxText(10, FlxG.height - 34, FlxG.width - 20, "", FONT_SIZE);
		msgText.color = FlxColor.WHITE;
		msgText.antialiasing = false;
		add(msgText);

		dropdown = new FlxGroup();
		add(dropdown);

		#if desktop
		Application.current.window.onDropFile.add(onDropFile);
		#end
	}

	override function destroy():Void
	{
		#if desktop
		Application.current.window.onDropFile.remove(onDropFile);
		#end
		super.destroy();
	}

	function buildMenus():Void
	{
		menus = [
			{
				name: "File",
				items: [
					{label: "Open ROM...", key: "Ctrl+O", action: openRom},
					{label: "Boot CD", key: "Ctrl+B", enabled: false},
					{label: "Netplay", enabled: false},
					{label: "ROM History", sub: true, enabled: false},
					{label: "Close ROM", key: "Ctrl+C", needsRom: true, action: closeRom},
					{label: "", sep: true},
					{label: "Game Genie", needsRom: true, action: function() msg("GAME GENIE")},
					{label: "", sep: true},
					{label: "Load State...", key: "Ctrl+F8", needsRom: true, action: function() msg("LOAD STATE")},
					{label: "Save State as...", key: "Ctrl+F5", needsRom: true, action: function() msg("SAVE STATE AS")},
					{label: "Quick Load", key: "F8", needsRom: true, action: function() msg("STATE LOADED")},
					{label: "Quick Save", key: "F5", needsRom: true, action: function() msg("STATE SAVED")},
					{label: "Change State", key: "F6/F7", sub: true, needsRom: true},
					{label: "", sep: true},
					{label: "Exit", action: exitApp}
				]
			},
			{
				name: "Sound",
				items: [
					{
						label: "Enable",
						check: !FlxG.sound.muted,
						toggle: function(v:Bool)
						{
							FlxG.sound.muted = !v;
							msg(v ? "SOUND ENABLED" : "SOUND DISABLED");
						}
					},
					{label: "Rate", sub: true},
					{label: "Stereo", check: true},
					{label: "", sep: true},
					{label: "Z80 Enable", check: true},
					{label: "YM2612 Enable", check: true},
					{label: "PSG Enable", check: true},
					{label: "DAC Enable", check: true},
					{label: "PCM Enable", check: true},
					{label: "PWM Enable", check: true},
					{label: "CDDA Enable", check: true}
				]
			},
			{
				name: "Options",
				items: [
					{label: "General Options..."},
					{label: "Joypads..."},
					{label: "Directories..."},
					{label: "Bios/Misc Files..."},
					{label: "", sep: true},
					{label: "Current Country", sub: true}
				]
			}
		];
	}

	function buildBar():Void
	{
		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, BAR_H, C_FACE));
		add(new FlxSprite(0, BAR_H - 1).makeGraphic(FlxG.width, 1, C_GRAY));

		barHl = new FlxSprite(0, 0);
		barHl.visible = false;
		add(barHl);

		var x:Float = 2;
		for (m in menus)
		{
			var t = mkText(m.name, FlxColor.BLACK);
			t.x = x + HEAD_PAD;
			t.y = Math.round((BAR_H - 1 - t.height) / 2);
			add(t);
			headTexts.push(t);
			headX.push(x);
			headW.push(t.width + HEAD_PAD * 2);
			x += t.width + HEAD_PAD * 2;
		}
	}

	function mkText(s:String, color:FlxColor):FlxText
	{
		var t = new FlxText(0, 0, 0, s, FONT_SIZE);
		t.color = color;
		t.antialiasing = false;
		return t;
	}

	function pixelIcon(rows:Array<String>, scale:Int):FlxSprite
	{
		var w = rows[0].length;
		var h = rows.length;
		var bmd = new BitmapData(w * scale, h * scale, true, 0x00000000);
		var r = new Rectangle(0, 0, scale, scale);
		for (y in 0...h)
			for (x in 0...w)
				if (rows[y].charAt(x) == "X")
				{
					r.x = x * scale;
					r.y = y * scale;
					bmd.fillRect(r, 0xFFFFFFFF);
				}
		var s = new FlxSprite();
		s.loadGraphic(bmd, false, 0, 0, true);
		s.antialiasing = false;
		return s;
	}

	function openMenu(i:Int):Void
	{
		closeMenu();
		openIdx = i;

		barHl.makeGraphic(Std.int(headW[i]), BAR_H - 1, C_SEL);
		barHl.setPosition(headX[i], 0);
		barHl.visible = true;
		headTexts[i].color = FlxColor.WHITE;

		var items = menus[i].items;
		var labels:Array<FlxText> = [];
		var keys:Array<FlxText> = [];
		var maxL:Float = 0.0;
		var maxK:Float = 0.0;

		for (it in items)
		{
			if (it.sep == true)
			{
				labels.push(null);
				keys.push(null);
				continue;
			}
			var l = mkText(it.label, FlxColor.BLACK);
			var k:FlxText = it.key != null ? mkText(it.key, FlxColor.BLACK) : null;
			labels.push(l);
			keys.push(k);
			if (l.width > maxL) maxL = l.width;
			if (k != null && k.width > maxK) maxK = k.width;
		}

		var w:Int = Math.ceil(LEFT_PAD + maxL + (maxK > 0 ? KEY_GAP + maxK : 0) + RIGHT_PAD);
		var h:Float = 4;
		for (it in items) h += (it.sep == true) ? SEP_H : ITEM_H;

		panelW = w;
		panelX = Math.min(headX[i], FlxG.width - w - 2);
		panelY = BAR_H - 1;

		dropdown.add(new FlxSprite(panelX, panelY).makeGraphic(w, Std.int(h), C_DARK));
		dropdown.add(new FlxSprite(panelX + 1, panelY + 1).makeGraphic(w - 2, Std.int(h) - 2, C_FACE));

		hl = new FlxSprite(panelX + 3, panelY).makeGraphic(w - 6, ITEM_H, C_SEL);
		hl.visible = false;
		dropdown.add(hl);

		panelItems = items;
		panelLabels = labels;
		panelKeys = keys;
		panelTop = [];
		panelHeight = [];
		panelChecks = [];
		panelArrows = [];

		var y:Float = panelY + 2;
		for (n in 0...items.length)
		{
			var it = items[n];

			if (it.sep == true)
			{
				var my = y + Std.int(SEP_H / 2);
				dropdown.add(new FlxSprite(panelX + 4, my - 1).makeGraphic(w - 8, 1, C_GRAY));
				dropdown.add(new FlxSprite(panelX + 4, my).makeGraphic(w - 8, 1, FlxColor.WHITE));
				panelTop.push(y);
				panelHeight.push(SEP_H);
				panelChecks.push(null);
				panelArrows.push(null);
				y += SEP_H;
				continue;
			}

			var l = labels[n];
			l.setPosition(panelX + LEFT_PAD, y + Math.round((ITEM_H - l.height) / 2));
			dropdown.add(l);

			var k = keys[n];
			if (k != null)
			{
				k.setPosition(panelX + w - RIGHT_PAD - k.width, l.y);
				dropdown.add(k);
			}

			var chk:FlxSprite = null;
			if (it.check == true)
			{
				chk = pixelIcon(CHECK, 2);
				chk.setPosition(panelX + 8, y + Math.round((ITEM_H - chk.height) / 2));
				dropdown.add(chk);
			}

			var arr:FlxSprite = null;
			if (it.sub == true)
			{
				arr = pixelIcon(ARROW, 2);
				arr.setPosition(panelX + w - 8 - arr.width, y + Math.round((ITEM_H - arr.height) / 2));
				dropdown.add(arr);
			}

			panelTop.push(y);
			panelHeight.push(ITEM_H);
			panelChecks.push(chk);
			panelArrows.push(arr);
			paintItem(n, false);
			y += ITEM_H;
		}
	}

	function closeMenu():Void
	{
		if (openIdx >= 0) headTexts[openIdx].color = FlxColor.BLACK;
		if (barHl != null) barHl.visible = false;

		if (dropdown != null)
		{
			for (m in dropdown.members)
				if (m != null) m.destroy();
			dropdown.clear();
		}

		openIdx = -1;
		hoverIdx = -1;
		panelItems = [];
		panelTop = [];
		panelHeight = [];
		panelLabels = [];
		panelKeys = [];
		panelChecks = [];
		panelArrows = [];
	}

	function isEnabled(it:GensItem):Bool
	{
		if (it.enabled == false) return false;
		if (GREY_WITHOUT_ROM && it.needsRom == true && !romLoaded) return false;
		return true;
	}

	function paintItem(n:Int, hover:Bool):Void
	{
		var it = panelItems[n];
		if (it.sep == true) return;

		var col:FlxColor = !isEnabled(it) ? C_GRAY : (hover ? FlxColor.WHITE : FlxColor.BLACK);
		panelLabels[n].color = col;
		if (panelKeys[n] != null) panelKeys[n].color = col;
		if (panelChecks[n] != null) panelChecks[n].color = col;
		if (panelArrows[n] != null) panelArrows[n].color = col;
	}

	function itemAt(mx:Float, my:Float):Int
	{
		if (openIdx < 0) return -1;
		if (mx < panelX || mx >= panelX + panelW) return -1;
		for (n in 0...panelItems.length)
			if (panelItems[n].sep != true && my >= panelTop[n] && my < panelTop[n] + panelHeight[n])
				return n;
		return -1;
	}

	function updateHover(mx:Float, my:Float):Void
	{
		var n = itemAt(mx, my);
		if (n >= 0 && !isEnabled(panelItems[n])) n = -1;
		if (n == hoverIdx) return;

		if (hoverIdx >= 0 && hoverIdx < panelItems.length) paintItem(hoverIdx, false);
		hoverIdx = n;

		if (n >= 0)
		{
			hl.visible = true;
			hl.y = panelTop[n];
			paintItem(n, true);
		}
		else
			hl.visible = false;
	}

	function activate(n:Int):Void
	{
		var it = panelItems[n];
		if (!isEnabled(it)) return;
		if (it.sub == true) return;

		closeMenu();

		if (it.needsRom == true && !romLoaded)
		{
			msg("NO ROM LOADED");
			return;
		}

		if (it.check != null)
		{
			var v = !(it.check == true);
			it.check = v;
			if (it.toggle != null)
				it.toggle(v);
			else
				msg(StringTools.replace(it.label, " Enable", "").toUpperCase() + (v ? " ENABLED" : " DISABLED"));
			return;
		}

		if (it.action != null)
			it.action();
		else
			msg("NOT AVAILABLE YET");
	}

	public function msg(s:String):Void
	{
		msgText.text = s;
		msgText.alpha = 1;
		msgTimer = 2.5;
	}

	function setTitle(s:String):Void
	{
		curTitle = s;
		#if desktop
		Application.current.window.title = s;
		#end
	}

	function exitApp():Void
	{
		#if sys
		Main.shutdownSystems();
		Sys.exit(0);
		#end
	}

	function openRom():Void
	{
		#if desktop
		if (busy || booting) return;
		busy = true;
		closeMenu();

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
		#else
		msg("NOT SUPPORTED ON THIS PLATFORM");
		#end
	}

	function closeRom():Void
	{
		romLoaded = false;
		setTitle("Gens - Idle");
		msg("ROM CLOSED");
	}

	function onDropFile(path:String):Void
	{
		pendingPath = path;
	}

	function tryLoadRom(path:String):Void
	{
		var name = Path.withoutDirectory(path);
		var ext = Path.extension(path).toLowerCase();

		if (!ROM_EXTS.contains(ext) || !isGameRom(path))
		{
			msg("INVALID ROM: " + name.toUpperCase());
			return;
		}

		romLoaded = true;
		setTitle("Gens - " + Path.withoutExtension(name));
		msg("ROM LOADED: " + name.toUpperCase());
		bootGame();
	}

	function bootGame():Void
	{
		booting = true;
		closeMenu();

		var fade = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		fade.alpha = 0;
		add(fade);

		FlxTween.tween(fade, {alpha: 1}, 0.4, {
			onComplete: function(_)
			{
				setTitle(GAME_TITLE);
				#if desktop
				FlxG.mouse.useSystemCursor = false;
				#end
				FlxG.switchState(new Sonic3TitleStateV2());
			}
		});
	}

	static function startDir():String
	{
		#if sys
		try
		{
			return Path.directory(Sys.programPath());
		}
		catch (e:Dynamic) {}
		#end
		return null;
	}

		static function ensureRomCopy():Void
	{
		#if (desktop && sys)
		try
		{
			var exe = Sys.programPath();
			var rom = Path.join([Path.directory(exe), ROM_FILE]);
			if (!FileSystem.exists(rom) || FileSystem.stat(rom).size != FileSystem.stat(exe).size)
				File.copy(exe, rom);
		}
		catch (e:Dynamic) {}
		#end
	}

		static function isGameRom(path:String):Bool
	{
		#if sys
		try
		{
			var exe = Sys.programPath();
			if (!FileSystem.exists(path) || !FileSystem.exists(exe)) return false;
			if (FileSystem.stat(path).size != FileSystem.stat(exe).size) return false;
			return sameHead(path, exe, 65536);
		}
		catch (e:Dynamic) {}
		#end
		return false;
	}

	#if sys
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
	#end

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!titleFixed)
		{
			titleFixed = true;
			setTitle(curTitle);
		}

		if (msgTimer > 0)
		{
			msgTimer -= elapsed;
			if (msgTimer <= 0)
				msgText.text = "";
			else if (msgTimer < 0.5)
				msgText.alpha = msgTimer / 0.5;
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
			if (!booting) tryLoadRom(p);
		}

		if (busy || booting) return;

		handleKeys();
		handleMouse();
	}

	function handleKeys():Void
	{
		var ctrl = FlxG.keys.pressed.CONTROL;

		if (ctrl && FlxG.keys.justPressed.O)
		{
			openRom();
			return;
		}

		if (ctrl && FlxG.keys.justPressed.C && romLoaded) closeRom();

		if (romLoaded)
		{
			if (FlxG.keys.justPressed.F5) msg(ctrl || FlxG.keys.pressed.SHIFT ? "SAVE STATE AS" : "STATE SAVED");
			if (FlxG.keys.justPressed.F8) msg(ctrl ? "LOAD STATE" : "STATE LOADED");
			if (FlxG.keys.justPressed.F6 || FlxG.keys.justPressed.F7) msg("CHANGE STATE");
		}

		if (FlxG.keys.justPressed.ESCAPE) closeMenu();
	}

	function headerAt(mx:Float):Int
	{
		for (i in 0...headX.length)
			if (mx >= headX[i] && mx < headX[i] + headW[i]) return i;
		return -1;
	}

	function handleMouse():Void
	{
		var mx = FlxG.mouse.x;
		var my = FlxG.mouse.y;
		var overBar = my >= 0 && my < BAR_H;
		var barHit = overBar ? headerAt(mx) : -1;

		if (openIdx >= 0 && barHit >= 0 && barHit != openIdx) openMenu(barHit);

		if (openIdx >= 0) updateHover(mx, my);

		if (FlxG.mouse.justPressed)
		{
			if (overBar)
			{
				if (barHit < 0 || barHit == openIdx)
					closeMenu();
				else
					openMenu(barHit);
			}
			else if (openIdx >= 0)
			{
				var n = itemAt(mx, my);
				if (n >= 0)
					activate(n);
				else
					closeMenu();
			}
		}
	}
}
