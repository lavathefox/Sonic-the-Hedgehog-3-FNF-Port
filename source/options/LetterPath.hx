package options;

class LetterPath
{
	public static function get(char:String):String
	{
		if (char == null || char.length == 0)
			return 'hud/letershud/';

		var name:String;

		switch (char.charCodeAt(0))
		{
			case 58: // ':'
				name = 'colon2';

			case 35: // '#'
				name = 'hash';

			case 47: // '/'
				name = 'slash';

			case 0xC9, 0xE9: // E with acute, e with acute
				name = 'e_acute';

			case 0xCA, 0xEA: // E with circumflex, e with circumflex
				name = 'e_circ';

			default:
				name = char.toUpperCase();
		}

		return 'hud/letershud/' + name;
	}
}
