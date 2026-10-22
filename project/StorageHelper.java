package me.funkin.sonic3;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;

import org.haxe.extension.Extension;

/**
 * Small helper called from Haxe through JNI (see Sonic3Storage.hx).
 *
 * - Android 11+ (API 30+): needs "All files access" (MANAGE_EXTERNAL_STORAGE),
 *   which can only be granted by the user on a system settings screen.
 *   requestAllFilesAccess() opens that screen directly.
 * - Android 6-10: shows the normal runtime permission dialog.
 *
 * Reflection and string constants are used for API 30+ members so this file
 * still compiles when the project's compileSdkVersion is lower than 30.
 */
public class StorageHelper
{
	private static final int REQUEST_CODE = 4242;

	/** True when the app is allowed to write to /storage/emulated/0. */
	public static boolean hasAllFilesAccess()
	{
		if (Build.VERSION.SDK_INT >= 30)
		{
			try
			{
				Object result = Environment.class.getMethod("isExternalStorageManager").invoke(null);
				return Boolean.TRUE.equals(result);
			}
			catch (Throwable t)
			{
				return false;
			}
		}

		Activity activity = Extension.mainActivity;

		if (activity == null)
			return false;

		if (Build.VERSION.SDK_INT >= 23)
			return activity.checkSelfPermission("android.permission.WRITE_EXTERNAL_STORAGE") == PackageManager.PERMISSION_GRANTED;

		// Before Android 6 the permission is granted at install time.
		return true;
	}

	/** Opens the system screen / dialog where the user grants storage access. */
	public static void requestAllFilesAccess()
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
					if (Build.VERSION.SDK_INT >= 30)
					{
						openAllFilesAccessScreen(activity);
					}
					else if (Build.VERSION.SDK_INT >= 23)
					{
						activity.requestPermissions(new String[] {
							"android.permission.READ_EXTERNAL_STORAGE",
							"android.permission.WRITE_EXTERNAL_STORAGE"
						}, REQUEST_CODE);
					}
				}
				catch (Throwable t)
				{
					android.util.Log.e("StorageHelper", "Could not request storage access", t);
				}
			}
		});
	}

	private static void openAllFilesAccessScreen(Activity activity)
	{
		try
		{
			// Settings screen for this app only.
			Intent intent = new Intent("android.settings.MANAGE_APP_ALL_FILES_ACCESS_PERMISSION");
			intent.setData(Uri.parse("package:" + activity.getPackageName()));
			activity.startActivity(intent);
		}
		catch (Throwable t)
		{
			// Fallback: the general "All files access" list.
			Intent intent = new Intent("android.settings.MANAGE_ALL_FILES_ACCESS_PERMISSION");
			activity.startActivity(intent);
		}
	}
}
