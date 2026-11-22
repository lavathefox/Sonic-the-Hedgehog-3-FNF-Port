package gens;

enum ItemKind
{
	Normal;
	Check;
	Radio;
	Sep;
	Sub;
}

class MenuItem
{
	public var kind:ItemKind;
	public var text:String;
	public var mnemonic:String = "";
	public var mnemonicIndex:Int = -1;
	public var key:String;
	public var checked:Bool = false;
	public var enabledFn:Void->Bool;
	public var action:Void->Void;
	public var onToggle:Bool->Void;
	public var children:Array<MenuItem>;
	public var group:Array<MenuItem>;

	public function new(kind:ItemKind, label:String)
	{
		this.kind = kind;
		var i = label.indexOf("&");
		if (i >= 0)
		{
			text = label.substr(0, i) + label.substr(i + 1);
			mnemonicIndex = i;
			mnemonic = text.charAt(i).toLowerCase();
		}
		else
			text = label;
	}

	public function isSep():Bool
		return kind == ItemKind.Sep;

	public function isSub():Bool
		return kind == ItemKind.Sub;

	public function isCheck():Bool
		return kind == ItemKind.Check;

	public function isRadio():Bool
		return kind == ItemKind.Radio;

	public function isEnabled():Bool
		return enabledFn == null || enabledFn();

	public function select():Void
	{
		if (group == null) return;
		for (m in group) m.checked = (m == this);
	}

	public function trigger():Void
	{
		switch (kind)
		{
			case ItemKind.Check:
				checked = !checked;
				if (onToggle != null) onToggle(checked);
			case ItemKind.Radio:
				select();
				if (action != null) action();
			case ItemKind.Normal:
				if (action != null) action();
			default:
		}
	}

	public static function normal(label:String, ?key:String, ?action:Void->Void, ?enabled:Void->Bool):MenuItem
	{
		var m = new MenuItem(ItemKind.Normal, label);
		m.key = key;
		m.action = action;
		m.enabledFn = enabled;
		return m;
	}

	public static function check(label:String, checked:Bool, ?onToggle:Bool->Void, ?enabled:Void->Bool):MenuItem
	{
		var m = new MenuItem(ItemKind.Check, label);
		m.checked = checked;
		m.onToggle = onToggle;
		m.enabledFn = enabled;
		return m;
	}

	public static function radios(labels:Array<String>, selected:Int, onSelect:Int->Void):Array<MenuItem>
	{
		var items:Array<MenuItem> = [];
		for (i in 0...labels.length)
		{
			var idx = i;
			var m = new MenuItem(ItemKind.Radio, labels[i]);
			m.checked = (i == selected);
			m.action = function() onSelect(idx);
			items.push(m);
		}
		for (m in items) m.group = items;
		return items;
	}

	public static function sep():MenuItem
		return new MenuItem(ItemKind.Sep, "");

	public static function sub(label:String, children:Array<MenuItem>, ?key:String, ?enabled:Void->Bool):MenuItem
	{
		var m = new MenuItem(ItemKind.Sub, label);
		m.children = children;
		m.key = key;
		m.enabledFn = enabled;
		return m;
	}
}
