package options.pc;

#if PC_OPTIONS
import backend.ClientPrefs;

class SonicPCOptionsSubstate extends options.SonicMobileOptionsSubstate
{
	override function getTitle():String
	{
		return tr('PC OPTIONS', 'OPCOES DE PC', 'OPCIONES DE PC');
	}

	override function loadOptions():Void
	{
		PCOptions.ensureLoaded();
	}

	override function applyOptions():Void {}

	override function buildEntries():Void
	{
		entries = [
			boolEntry(tr('FULLSCREEN', 'TELA CHEIA', 'PANTALLA COMPLETA'),
				function() return PCOptions.fullscreen,
				PCOptions.setFullscreen),

			listEntry(tr('WINDOW SIZE', 'TAMANHO JANELA', 'TAMANO VENTANA'), PCOptions.WINDOW_SCALE_NAMES,
				function() return PCOptions.windowScale,
				PCOptions.setWindowScale),

			listEntry(tr('FPS LIMIT', 'LIMITE DE FPS', 'LIMITE DE FPS'), PCOptions.FPS_LIMIT_NAMES,
				PCOptions.fpsLimitIndex,
				PCOptions.setFpsLimitIndex),

			boolEntry(tr('SHOW FPS', 'MOSTRAR FPS', 'MOSTRAR FPS'),
				function() return ClientPrefs.data.showFPS,
				PCOptions.setShowFps),

			boolEntry(tr('MOUSE CURSOR', 'CURSOR DO MOUSE', 'CURSOR DEL MOUSE'),
				function() return PCOptions.showMouse,
				PCOptions.setShowMouse),

			boolEntry(tr('PAUSE ON FOCUS LOSS', 'PAUSAR SEM FOCO', 'PAUSAR SIN FOCO'),
				function() return PCOptions.pauseOnFocusLoss,
				PCOptions.setPauseOnFocusLoss),

			listEntry(tr('MASTER VOLUME', 'VOLUME GERAL', 'VOLUMEN GENERAL'), PCOptions.VOLUME_NAMES,
				PCOptions.volumeIndex,
				PCOptions.setVolumeIndex),

			{
				label: tr('RESET OPTIONS', 'REINICIAR OPCOES', 'REINICIAR OPCIONES'),
				getValue: function():String return 'DEFAULT',
				change: function(direction:Int):Void
				{
					PCOptions.reset();
					refreshAllRows = true;
				}
			}
		];
	}
}
#end
