using Uno;
using Uno.IO;
using Uno.Time;
using Uno.UX;
using Uno.Threading;
using Uno.Collections;
using Fuse.Scripting;
using Uno.Permissions;

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

			// TODO: fix request camera implementation
			if defined(ANDROID)
			{
				AddMember(new NativePromise<PlatformPermission, string>("requrestCamera", RequestCamera, PermissionConverter));	
			}
			else
			{
				AddMember(new NativePromise<string, string>("requrestCamera", RequestCamera));
			}
		}

		extern(!ANDROID) static Future<string> RequestCamera(object[] args)
		{
			return new Promise<string>("Camera permission not needed");
		}

		extern(ANDROID) static Future<PlatformPermission> RequestCamera(object[] args)
		{
			return Permissions.Request(Permissions.Android.CAMERA);
		}

		static string PermissionConverter(Fuse.Scripting.Context context, PlatformPermission permission)
		{
			return permission.Name;
		}
	}
}
