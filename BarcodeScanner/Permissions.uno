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
			AddMember(new NativePromise<string, string>("requrestCamera", RequestCamera));
		}

		extern(ANDROID) class CameraPermissionRequest : Promise<string>
		{
			public CameraPermissionRequest()
			{
				Permissions
					.Request(Permissions.Android.CAMERA)
					.Then(OnResolve, Reject);
			}

			void OnResolve(PlatformPermission permission)
			{
				Resolve(permission.Name);
			}
		}

		static Future<string> RequestCamera(object[] args)
		{
			if defined(ANDROID)
			{
				return new CameraPermissionRequest();
			}
			else
			{
				return new Promise<string>("Camera permission not needed");
			}
		}
	}
}
