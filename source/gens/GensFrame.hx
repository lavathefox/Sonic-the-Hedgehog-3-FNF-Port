package gens;

import flixel.FlxG;
import haxe.Timer;
import haxe.io.Bytes;
import haxe.io.Path;
import lime.app.Application;
import lime.ui.FileDialog;
import lime.ui.FileDialogType;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.StageDisplayState;
import openfl.events.Event;
import openfl.events.KeyboardEvent;
import openfl.events.MouseEvent;
import openfl.geom.Rectangle;
import openfl.text.TextField;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import openfl.ui.Keyboard;
import states.GensIdleState;
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
	var historyItem:MenuItem;
	var slotItems:Array<MenuItem>;
	var slot:Int = 0;

	var busy:Bool = false;
	var dialogClosed:Bool = false;
	var pendingPath:String = null;
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

	function buildMenus():Void
	{
		var needRom:Void->Bool = function() return romLoaded;
		var never:Void->Bool = function() return false;

		soundEnable = MenuItem.check("&Enable", !FlxG.sound.muted, function(v:Bool)
		{
			FlxG.sound.muted = !v;
			msg(v ? "SOUND ENABLED" : "SOUND DISABLED");
		});

		historyItem = MenuItem.sub("ROM &History", [], function() return loadHistory().length > 0);
		rebuildHistory();

		slotItems = MenuItem.radios(["&0", "&1", "&2", "&3", "&4", "&5", "&6", "&7", "&8", "&9"], 0, function(i:Int)
		{
			slot = i;
			msg("STATE " + i + " SELECTED");
		});

		var rates = ["11025", "22050", "44100"];
		var rateItems = MenuItem.radios(["11025 Hz", "22050 Hz", "44100 Hz"], 2, function(i:Int)
		{
			msg("SOUND RATE: " + rates[i] + " HZ");
		});

		var countries = ["AUTO DETECTION", "JAPAN (NTSC)", "USA (NTSC)", "EUROPE (PAL)", "JAPAN (PAL)"];
		var countryItems = MenuItem.radios(["&Auto Detection", "&Japan (NTSC)", "&USA (NTSC)", "&Europe (PAL)", "Japan (&PAL)"], 0, function(i:Int)
		{
			msg("COUNTRY: " + countries[i]);
		});

		var sramSizes = ["NONE", "8 KB", "16 KB", "32 KB", "64 KB"];
		var sramItems = MenuItem.radios(["&None", "&8 Kb", "&16 Kb", "&32 Kb", "&64 Kb"], 0, function(i:Int)
		{
			msg("SRAM SIZE: " + sramSizes[i]);
		});

		var chip = function(label:String):MenuItem
		{
			var name = StringTools.replace(label.split("&").join(""), " Enable", "").toUpperCase();
			return MenuItem.check(label, true, function(v:Bool)
			{
				msg(name + (v ? " ENABLED" : " DISABLED"));
			});
		};

		var info = function(label:String, title:String):MenuItem
		{
			return MenuItem.normal(label, null, function()
			{
				Application.current.window.alert("This option is not available in this build.", title);
			});
		};

		var file:Array<MenuItem> = [
			MenuItem.normal("&Open ROM...", "Ctrl+O", openRomDialog),
			MenuItem.normal("&Boot CD", "Ctrl+B", null, never),
			historyItem,
			MenuItem.normal("&Close ROM", "Ctrl+C", closeRom, needRom),
			MenuItem.sep(),
			MenuItem.normal("&Game Genie", null, function()
			{
				Application.current.window.alert("Game Genie is not available in this build.", "Game Genie");
			}, needRom),
			MenuItem.sep(),
			MenuItem.normal("&Load State...", "Ctrl+F8", loadState, needRom),
			MenuItem.normal("&Save State as...", "Ctrl+F5", saveState, needRom),
			MenuItem.normal("Quick Lo&ad", "F8", loadState, needRom),
			MenuItem.normal("Quick Sa&ve", "F5", saveState, needRom),
			MenuItem.sub("Change S&tate", slotItems, "F6/F7", needRom),
			MenuItem.sep(),
			MenuItem.normal("E&xit", null, exitApp)
		];

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
			chip("&YM2612 Enable"),
			chip("&PSG Enable"),
			chip("&DAC Enable"),
			chip("PC&M Enable"),
			chip("P&WM Enable"),
			chip("CDD&A Enable")
		];

		var options:Array<MenuItem> = [
			info("&General Options...", "General Options"),
			info("&Joypads...", "Joypads"),
			info("&Directories...", "Directories"),
			info("&Bios/Misc Files...", "Bios/Misc Files"),
			MenuItem.sep(),
			MenuItem.sub("Current &Country", countryItems),
			MenuItem.sub("Sega CD SRAM &Size", sramItems)
		];

		headers = [
			MenuItem.sub("&File", file),
			MenuItem.sub("&Sound", sound),
			MenuItem.sub("&Options", options)
		];
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
		if (busy) return;
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
		if (busy) return;
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
		if (busy) return;

		if (panels.length > 0)
		{
			menuKey(e);
			return;
		}

		var k = e.keyCode;

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

		if (k == Keyboard.F5) saveState();
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
			FlxG.scaleMode = new GensScaleMode();
			FlxG.mouse.visible = true;
			FlxG.mouse.useSystemCursor = true;
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

		var vis = barVisible();
		if (vis != lastVis)
		{
			layout();
			Lib.current.stage.dispatchEvent(new Event(Event.RESIZE));
		}

		if (restoreKeys && panels.length == 0)
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

	function saveState():Void
	{
		if (romLoaded) msg("STATE " + slot + " SAVED");
	}

	function loadState():Void
	{
		if (romLoaded) msg("STATE " + slot + " LOADED");
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
		try
		{
			FlxG.save.flush();
		}
		catch (e:Dynamic) {}
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
