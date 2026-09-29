package options;

class GameplayMapOption extends Option
{
	var gameplayVariable:String;

	public function new(name:String, description:String, variable:String, type:OptionType = BOOL)
	{
		gameplayVariable = variable;
		super(name, description, 'gameplaySettings', type);
	}

	override function getValue():Dynamic
	{
		return ClientPrefs.data.gameplaySettings.get(gameplayVariable);
	}

	override function setValue(value:Dynamic)
	{
		ClientPrefs.data.gameplaySettings.set(gameplayVariable, value);
	}
}
