package me.funkin.sonic3;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.WindowManager;

import org.haxe.extension.Extension;

/**
 * Small helper called from Haxe through JNI (see mobile/DeviceUtil.hx).
 * Needs the VIBRATE permission, which Project.xml already declares.
 */
public class DeviceHelper
{
	/** Vibrates once for the given time in milliseconds. */
	@SuppressWarnings("deprecation")
	public static void vibrate(int milliseconds)
	{
		if (milliseconds <= 0)
			return;

		try
		{
			Activity activity = Extension.mainActivity;

			if (activity == null)
				return;

			Vibrator vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);

			if (vibrator == null || !vibrator.hasVibrator())
				return;

			if (Build.VERSION.SDK_INT >= 26)
				vibrator.vibrate(VibrationEffect.createOneShot(milliseconds, VibrationEffect.DEFAULT_AMPLITUDE));
			else
				vibrator.vibrate(milliseconds);
		}
		catch (Throwable t)
		{
			android.util.Log.e("DeviceHelper", "Could not vibrate", t);
		}
	}

	/** Keeps the screen on (true) or lets it turn off normally (false). */
	public static void setKeepScreenOn(final boolean keepOn)
	{
		final Activity activity = Extension.mainActivity;

		if (activity == null)
			return;

		activity.runOnUiThread(new Runnable()
		{
			@Override
			public void run()
			{
				try
				{
					if (keepOn)
						activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
					else
						activity.getWindow().clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
				}
				catch (Throwable t)
				{
					android.util.Log.e("DeviceHelper", "Could not change keep screen on", t);
				}
			}
		});
	}
}
