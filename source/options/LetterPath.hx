package options;

class LetterPath
{
	static final names:Map<String, String> = [
		':' => 'colon2',
		'#' => 'hash',
		'/' => 'slash',
		'\u00C9' => '\u00E9',
		'\u00CA' => '\u00EA' 
	];

	public static function get(char:String):String
	{
		var upper:String = char.toUpperCase();
		var name:String = names.exists(upper) ? names.get(upper) : upper;

		return 'hud/letershud/' + name;
	}
}
