package states;

import backend.Mods;
import backend.Mods.ModsList;
import backend.ClientPrefs;
import backend.Paths;
import backend.Language;
import backend.Controls;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.text.FlxText.FlxTextAlign;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import openfl.display.BitmapData;
import options.ModSettingsSubState;
import sys.FileSystem;
import sys.io.File;

class ModsMenuState extends MusicBeatState
{
    var modsList:ModsList;
    var selected:Int = 0;
    var startMod:String;
    var items:Array<AirModEntry> = [];
    var rows:FlxTypedGroup<AirModRow>;
    var bg:FlxSprite;
    var listPanel:FlxSprite;
    var detailPanel:FlxSprite;
    var icon:FlxSprite;
    var title:FlxText;
    var description:FlxText;
    var status:FlxText;
    var help:FlxText;
    var counter:FlxText;
    var emptyText:FlxText;
    var actions:Array<AirMenuButton> = [];
    var restartRequired:Bool = false;
    var leaving:Bool = false;
    var scrollTop:Int = 0;
    var visibleRows:Int = 7;
    var rowHeight:Float = 59;
    var panelX:Float = 0;
    var panelY:Float = 0;
    var panelW:Float = 0;
    var panelH:Float = 0;
    var focusedAction:Int = -1;

    public function new(?startMod:String)
    {
        this.startMod = startMod;
        super();
    }

    override function create()
    {
        persistentUpdate = false;
        FlxG.mouse.visible = true;
        modsList = Mods.parseList();
        Mods.loadTopMod();

        bg = new FlxSprite().makeGraphic(1, 1, 0xFF101829);
        bg.scale.set(FlxG.width, FlxG.height);
        bg.updateHitbox();
        bg.scrollFactor.set();
        add(bg);

        var heading = new FlxText(0, 14, FlxG.width, 'MOD MANAGER', 34);
        heading.setFormat(Paths.font('vcr.ttf'), 34, FlxColor.WHITE, CENTER);
        add(heading);

        panelX = 18;
        panelY = 75;
        panelW = Math.min(360, FlxG.width * 0.39);
        panelH = FlxG.height - 150;
        listPanel = panel(panelX, panelY, panelW, panelH, 0xFF1D2940);
        detailPanel = panel(panelX + panelW + 16, panelY, FlxG.width - panelX * 2 - panelW - 16, panelH, 0xFF1D2940);

        var listHeading = new FlxText(panelX + 15, panelY + 10, panelW - 30, 'INSTALLED MODS', 21);
        listHeading.setFormat(Paths.font('vcr.ttf'), 21, FlxColor.WHITE);
        add(listHeading);
        counter = new FlxText(panelX + 15, panelY + 42, panelW - 30, '', 15);
        counter.setFormat(Paths.font('vcr.ttf'), 15, 0xFFADC1DC);
        add(counter);

        rows = new FlxTypedGroup<AirModRow>();
        add(rows);

        for (folder in modsList.all)
        {
            var entry = new AirModEntry(folder, !modsList.disabled.contains(folder));
            items.push(entry);
        }
        if (startMod != null)
        {
            for (i in 0...items.length)
                if (items[i].folder == startMod) selected = i;
        }

        var rightX = detailPanel.x + 18;
        var rightW = detailPanel.width - 36;
        icon = new FlxSprite(rightX, panelY + 18);
        icon.makeGraphic(96, 96, 0xFF334765);
        add(icon);

        title = new FlxText(rightX + 110, panelY + 22, rightW - 110, '', 27);
        title.setFormat(Paths.font('vcr.ttf'), 27, FlxColor.WHITE);
        add(title);

        status = new FlxText(rightX + 110, panelY + 75, rightW - 110, '', 17);
        status.setFormat(Paths.font('vcr.ttf'), 17, FlxColor.WHITE);
        add(status);

        description = new FlxText(rightX, panelY + 132, rightW, '', 19);
        description.setFormat(Paths.font('vcr.ttf'), 19, 0xFFD4E0F2);
        add(description);

        var actionY = panelY + panelH - 125;
        var gap:Float = 8;
        var actionW:Float = (rightW - gap * 2) / 3;
        actions.push(new AirMenuButton(rightX, actionY, actionW, 44, 'ENABLE', function() toggleSelected()));
        actions.push(new AirMenuButton(rightX + actionW + gap, actionY, actionW, 44, 'MOVE UP', function() moveSelected(-1)));
        actions.push(new AirMenuButton(rightX + (actionW + gap) * 2, actionY, actionW, 44, 'MOVE DOWN', function() moveSelected(1)));
        actions.push(new AirMenuButton(rightX, actionY + 52, actionW, 44, 'SETTINGS', function() openSettings()));
        actions.push(new AirMenuButton(rightX + actionW + gap, actionY + 52, actionW, 44, 'ENABLE ALL', function() setAll(true)));
        actions.push(new AirMenuButton(rightX + (actionW + gap) * 2, actionY + 52, actionW, 44, 'DISABLE ALL', function() setAll(false)));
        for (action in actions) add(action);

        help = new FlxText(18, FlxG.height - 62, FlxG.width - 36, 'UP/DOWN: SELECT   ENTER: TOGGLE   LEFT/RIGHT: PRIORITY   ESC: BACK   R: RELOAD', 15);
        help.setFormat(Paths.font('vcr.ttf'), 15, 0xFFB9CBE4, CENTER);
        add(help);

        emptyText = new FlxText(panelX + 10, panelY + 140, panelW - 20, 'NO MODS INSTALLED', 22);
        emptyText.setFormat(Paths.font('vcr.ttf'), 22, FlxColor.WHITE, CENTER);
        add(emptyText);

        refresh();
        super.create();
    }

    function panel(x:Float, y:Float, w:Float, h:Float, color:FlxColor):FlxSprite
    {
        var s = new FlxSprite(x, y).makeGraphic(1, 1, color);
        s.scale.set(w, h);
        s.updateHitbox();
        add(s);
        return s;
    }

    function refresh():Void
    {
        if (selected >= items.length) selected = items.length - 1;
        if (selected < 0) selected = 0;
        if (selected < scrollTop) scrollTop = selected;
        if (selected >= scrollTop + visibleRows) scrollTop = selected - visibleRows + 1;
        if (scrollTop < 0) scrollTop = 0;

        rows.clear();
        var max = Std.int(Math.min(items.length, scrollTop + visibleRows));
        for (i in scrollTop...max)
        {
            var row = new AirModRow(panelX + 10, panelY + 73 + (i - scrollTop) * rowHeight, panelW - 20, rowHeight - 5, items[i], i == selected);
            row.index = i;
            rows.add(row);
        }

        emptyText.visible = items.length == 0;
        counter.text = items.length + ' MODS  /  ' + countEnabled() + ' ENABLED';
        var has = items.length > 0;
        icon.visible = title.visible = status.visible = description.visible = has;
        for (action in actions) action.visible = has;
        if (!has) return;

        var current = items[selected];
        title.text = current.name;
        status.text = current.enabled ? 'ENABLED' : 'DISABLED';
        status.color = current.enabled ? 0xFF79EFAB : 0xFFFF8A8A;
        description.text = current.desc + (current.mustRestart ? '\n\nChanges to this mod require a restart.' : '');
        bg.color = current.bgColor;
        actions[0].label.text = current.enabled ? 'DISABLE' : 'ENABLE';
        actions[1].active = selected > 0;
        actions[2].active = selected < items.length - 1;
        actions[3].active = current.settings != null && current.settings.length > 0;
        actions[4].active = countEnabled() < items.length;
        actions[5].active = countEnabled() > 0;
        actions[0].active = true;
        icon.makeGraphic(96, 96, 0xFF334765);
        var path = current.iconPath;
        if (path != null)
        {
            try
            {
                var bmp = BitmapData.fromFile(path);
                if (bmp != null) icon.loadGraphic(bmp, true, 150, 150);
            }
            catch (e:Dynamic) {}
        }
        icon.setGraphicSize(96, 96);
        icon.updateHitbox();
    }

    function countEnabled():Int
    {
        var n = 0;
        for (item in items) if (item.enabled) n++;
        return n;
    }

    function toggleSelected():Void
    {
        if (items.length == 0) return;
        var entry = items[selected];
        entry.enabled = !entry.enabled;
        if (entry.mustRestart) restartRequired = true;
        syncLists();
        refresh();
    }

    function setAll(value:Bool):Void
    {
        for (entry in items)
        {
            if (entry.enabled != value && entry.mustRestart) restartRequired = true;
            entry.enabled = value;
        }
        syncLists();
        refresh();
    }

    function moveSelected(direction:Int):Void
    {
        if (items.length < 2) return;
        var destination = selected + direction;
        if (destination < 0 || destination >= items.length) return;
        var moved = items[selected];
        var other = items[destination];
        if (moved.mustRestart || other.mustRestart) restartRequired = true;
        items[selected] = other;
        items[destination] = moved;
        selected = destination;
        syncLists();
        refresh();
    }

    function syncLists():Void
    {
        modsList.all = [];
        modsList.enabled = [];
        modsList.disabled = [];
        for (entry in items)
        {
            modsList.all.push(entry.folder);
            if (entry.enabled) modsList.enabled.push(entry.folder);
            else modsList.disabled.push(entry.folder);
        }
        saveList();
    }

    function saveList():Void
    {
        var lines:Array<String> = [];
        for (entry in items) lines.push(entry.folder + '|' + (entry.enabled ? '1' : '0'));
        try
        {
            File.saveContent('modsList.txt', lines.join('\n'));
            Mods.parseList();
            Mods.loadTopMod();
            Paths.clearDirectoryCache();
        }
        catch (e:Dynamic) {}
    }

    function openSettings():Void
    {
        if (items.length == 0) return;
        var entry = items[selected];
        if (entry.settings != null && entry.settings.length > 0)
            openSubState(new ModSettingsSubState(entry.settings, entry.folder, entry.name));
    }

    function reload():Void
    {
        saveList();
        var folder = items.length > 0 ? items[selected].folder : null;
        MusicBeatState.switchState(new ModsMenuState(folder));
    }

    function exitMenu():Void
    {
        if (leaving) return;
        leaving = true;
        saveList();
        FlxG.mouse.visible = false;
        FlxG.autoPause = ClientPrefs.data.autoPause;
        if (restartRequired)
        {
            TitleState.initialized = false;
            TitleState.closedState = false;
            FlxG.resetGame();
        }
        else MusicBeatState.switchState(new MainMenuState());
    }

    override function update(elapsed:Float)
    {
        if (leaving) return;
        if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
        {
            exitMenu();
            return;
        }
        if (FlxG.keys.justPressed.R) reload();
        if (items.length > 0)
        {
            if (controls.UI_DOWN_P) { selected = (selected + 1) % items.length; refresh(); }
            if (controls.UI_UP_P) { selected = (selected - 1 + items.length) % items.length; refresh(); }
            if (controls.UI_LEFT_P) moveSelected(-1);
            if (controls.UI_RIGHT_P) moveSelected(1);
            if (controls.ACCEPT) toggleSelected();
            if (FlxG.mouse.wheel != 0)
            {
                selected = Std.int(FlxMath.bound(selected - FlxG.mouse.wheel, 0, items.length - 1));
                refresh();
            }
            if (FlxG.mouse.justPressed)
            {
                for (row in rows.members)
                    if (row != null && FlxG.mouse.overlaps(row))
                    {
                        if (selected == row.index) toggleSelected();
                        else { selected = row.index; refresh(); }
                        break;
                    }
            }
        }
        super.update(elapsed);
    }
}

class AirModEntry
{
    public var folder:String;
    public var name:String;
    public var desc:String;
    public var enabled:Bool;
    public var mustRestart:Bool = false;
    public var bgColor:FlxColor = 0xFF283C5A;
    public var settings:Array<Dynamic> = null;
    public var iconPath:String = null;

    public function new(folder:String, enabled:Bool)
    {
        this.folder = folder;
        this.name = folder;
        this.desc = 'No description provided.';
        this.enabled = enabled;
        var pack:Dynamic = Mods.getPack(folder);
        if (pack != null)
        {
            if (pack.name != null) name = Std.string(pack.name);
            if (pack.description != null) desc = Std.string(pack.description);
            if (pack.restart == true) mustRestart = true;
            if (pack.color != null)
            {
                try bgColor = FlxColor.fromRGB(pack.color[0], pack.color[1], pack.color[2]);
                catch (e:Dynamic) {}
            }
        }
        var p = Paths.mods(folder + '/pack.png');
        if (!FileSystem.exists(p)) p = Paths.mods(folder + '/pack-pixel.png');
        if (FileSystem.exists(p)) iconPath = p;
        var settingsPath = Paths.mods(folder + '/data/settings.json');
        if (FileSystem.exists(settingsPath))
        {
            try settings = tjson.TJSON.parse(File.getContent(settingsPath));
            catch (e:Dynamic) {}
        }
    }
}

class AirModRow extends FlxSpriteGroup
{
    public var index:Int = 0;
    public function new(x:Float, y:Float, w:Float, h:Float, item:AirModEntry, selected:Bool)
    {
        super(x, y);
        var bg = new FlxSprite().makeGraphic(1, 1, selected ? 0xFF42699A : 0xFF293750);
        bg.scale.set(w, h);
        bg.updateHitbox();
        add(bg);
        var text = new FlxText(12, 8, w - 24, item.name, 18);
        text.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE);
        add(text);
        var status = new FlxText(12, 32, w - 24, item.enabled ? 'ON' : 'OFF', 13);
        status.setFormat(Paths.font('vcr.ttf'), 13, item.enabled ? 0xFF79EFAB : 0xFFFF8A8A);
        add(status);
    }
}

class AirMenuButton extends FlxSpriteGroup
{
    public var label:FlxText;
    public var active:Bool = true;
    var callback:Void->Void;
    var bg:FlxSprite;

    public function new(x:Float, y:Float, w:Float, h:Float, text:String, callback:Void->Void)
    {
        super(x, y);
        this.callback = callback;
        bg = new FlxSprite().makeGraphic(1, 1, 0xFF3E5D84);
        bg.scale.set(w, h);
        bg.updateHitbox();
        add(bg);
        label = new FlxText(3, 10, w - 6, text, 14);
        label.setFormat(Paths.font('vcr.ttf'), 14, FlxColor.WHITE, CENTER);
        add(label);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        alpha = active ? 1 : 0.35;
        if (active && visible && FlxG.mouse.overlaps(this))
        {
            bg.color = 0xFF608BC0;
            if (FlxG.mouse.justPressed && callback != null) callback();
        }
        else bg.color = 0xFF3E5D84;
    }
}
