using Uno;
using Uno.IO;
using Uno.Time;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Scripting;
using Uno.Permissions;
using Fuse.Controls;

namespace BarcodeScanner
{
	[UXGlobalModule]
	public class PermissionsModule : NativeModule
	{
		static readonly PermissionsModule _instance;
		
		public PermissionsModule()
		{
			if (_instance != null)
				return;

			Resource.SetGlobalKey(_instance = this, "BarcodeScanner/Permissions");

			AddMember(new NativePromise<PlatformPermission, string>("requrestCamera", RequestCamera, PermissionConverter));
		}

		static Future<PlatformPermission> RequestCamera(object[] args)
		{
			if defined(Android)
			{
				return Permissions.Request(Permissions.Android.CAMERA);
			}
			else
				return new Promise<PlatformPermission>().RejectWithMessage("Platform not supported");
		}

		static string PermissionConverter(Fuse.Scripting.Context context, PlatformPermission permission)
		{
			return permission.Name;
		}
	}
}
