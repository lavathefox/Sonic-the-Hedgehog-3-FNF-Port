package options;

/**
 * Maps a character to its image in images/hud/letershud.
 *
 * File names must be safe for URLs: on the HTML5 target a '#' in a file name is read as a
 * URL fragment, so the asset cannot be loaded. That is why '#' is stored as "hash.png".
 */
class LetterPath
{
	static final names:Map<String, String> = [
		':' => 'colon2',
		'#' => 'hash',
		'/' => 'slash',
		'\u00C9' => '\u00E9', // É -> é.png (the file name is lowercase)
		'\u00CA' => '\u00EA' // Ê -> ê.png (the file name is lowercase)
	];

	public static function get(char:String):String
	{
		var upper:String = char.toUpperCase();
		var name:String = names.exists(upper) ? names.get(upper) : upper;

		return 'hud/letershud/' + name;
	}
}
