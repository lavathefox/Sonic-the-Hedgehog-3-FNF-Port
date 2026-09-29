package options;

class PreferencesSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('preferences_menu', 'Preferences');
		rpcTitle = 'Preferences Menu';

		var option:Option = new Option('Downscroll',
			'If checked, notes go Down instead of Up.',
			'downScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Middlescroll',
			'If checked, your notes get centered.',
			'middleScroll',
			BOOL);
		addOption(option);

		var option:Option = new Option('Ghost Tapping',
			"If checked, you won't get misses from pressing keys while there are no notes able to be hit.",
			'ghostTapping',
			BOOL);
		addOption(option);

		var option:Option = new Option('Camera Zooms',
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			BOOL);
		addOption(option);

		var option:Option = new Option('Flashing Lights',
			"Uncheck this if you're sensitive to flashing lights.",
			'flashing',
			BOOL);
		addOption(option);

		super();
	}
}
