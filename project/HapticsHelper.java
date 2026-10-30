package me.funkin.sonic3;

import android.app.Activity;
import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Log;
import android.view.View;

import org.haxe.extension.Extension;

public class HapticsHelper
{
	private static final String TAG = "HapticsHelper";
	private static Vibrator vibrator;

	@SuppressWarnings("deprecation")
	private static Vibrator getVibrator()
	{
		if (vibrator != null)
			return vibrator;

		Activity activity = Extension.mainActivity;
		if (activity == null)
			return null;

		Vibrator found = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
		if (found != null && found.hasVibrator())
			vibrator = found;

		return vibrator;
	}

	private static int clampAmplitude(int amplitude)
	{
		return Math.max(1, Math.min(255, amplitude));
	}

	private static long[] parseLongs(String text)
	{
		String[] parts = text.split(",");
		long[] values = new long[parts.length];
		for (int i = 0; i < parts.length; i++)
			values[i] = Math.max(0, Long.parseLong(parts[i].trim()));
		return values;
	}

	private static int[] parseInts(String text, int length)
	{
		String[] parts = text.split(",");
		int[] values = new int[length];
		for (int i = 0; i < length; i++)
			values[i] = i < parts.length ? Math.max(0, Math.min(255, Integer.parseInt(parts[i].trim()))) : 0;
		return values;
	}

	public static boolean hasVibrator()
	{
		return getVibrator() != null;
	}

	public static boolean hasAmplitudeControl()
	{
		Vibrator target = getVibrator();
		return target != null && Build.VERSION.SDK_INT >= 26 && target.hasAmplitudeControl();
	}

	@SuppressWarnings("deprecation")
	public static void vibrate(int milliseconds, int amplitude)
	{
		Vibrator target = getVibrator();
		if (target == null || milliseconds <= 0)
			return;

		try
		{
			if (Build.VERSION.SDK_INT >= 26)
			{
				int value = target.hasAmplitudeControl() ? clampAmplitude(amplitude) : VibrationEffect.DEFAULT_AMPLITUDE;
				target.vibrate(VibrationEffect.createOneShot(milliseconds, value));
			}
			else
				target.vibrate(milliseconds);
		}
		catch (Throwable t)
		{
			Log.e(TAG, "Could not vibrate", t);
		}
	}

	@SuppressWarnings("deprecation")
	public static void pattern(String timings, String amplitudes)
	{
		Vibrator target = getVibrator();
		if (target == null || timings == null || timings.isEmpty())
			return;

		try
		{
			long[] parsedTimings = parseLongs(timings);

			if (Build.VERSION.SDK_INT >= 26)
			{
				if (target.hasAmplitudeControl() && amplitudes != null && !amplitudes.isEmpty())
					target.vibrate(VibrationEffect.createWaveform(parsedTimings, parseInts(amplitudes, parsedTimings.length), -1));
				else
					target.vibrate(VibrationEffect.createWaveform(parsedTimings, -1));
			}
			else
				target.vibrate(parsedTimings, -1);
		}
		catch (Throwable t)
		{
			Log.e(TAG, "Could not play pattern", t);
		}
	}

	public static boolean playEffect(int style)
	{
		Vibrator target = getVibrator();
		if (target == null || Build.VERSION.SDK_INT < 29)
			return false;

		int effect;
		switch (style)
		{
			case 0:
				effect = VibrationEffect.EFFECT_TICK;
				break;
			case 2:
				effect = VibrationEffect.EFFECT_HEAVY_CLICK;
				break;
			case 3:
				effect = VibrationEffect.EFFECT_DOUBLE_CLICK;
				break;
			default:
				effect = VibrationEffect.EFFECT_CLICK;
				break;
		}

		try
		{
			target.vibrate(VibrationEffect.createPredefined(effect));
			return true;
		}
		catch (Throwable t)
		{
			Log.e(TAG, "Could not play effect", t);
			return false;
		}
	}

	public static void performFeedback(final int constant)
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
					View view = activity.getWindow().getDecorView();
					if (view != null)
						view.performHapticFeedback(constant);
				}
				catch (Throwable t)
				{
					Log.e(TAG, "Could not perform feedback", t);
				}
			}
		});
	}

	public static void cancel()
	{
		Vibrator target = getVibrator();
		if (target == null)
			return;

		try
		{
			target.cancel();
		}
		catch (Throwable t)
		{
			Log.e(TAG, "Could not cancel", t);
		}
	}
}
