using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(!ANDROID) public class BarcodeScanner {}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zxing:1.8.4")]
	[Require("AndroidManifest.Permission", "android.permission.CAMERA")]
	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.zxing.ZXingScannerView",
		"com.google.zxing.Result",
		"me.dm7.barcodescanner.core.IViewFinder",
		"android.content.Context",
		"android.graphics.Rect")]
	extern(ANDROID) public class BarcodeScanner : ViewHandle, IBarcodeScannerView
	{
		class ScanPromise : Promise<string>
		{
			readonly Java.Object _scannerView;
			readonly BarcodeScanner _barcodeScanner;

			public ScanPromise(BarcodeScanner barcodeScanner, Java.Object scannerView)
			{
				_barcodeScanner = barcodeScanner;
				_scannerView = scannerView;

				Permissions.Request(new PlatformPermission[] { Permissions.Android.CAMERA }).Then(DoScan, Reject);
			}

			void DoScan(PlatformPermission[] permission)
			{
				_scannerView.InstallResultHandler(OnGotResult);
				_scannerView.StartCamera();
			}

			void OnGotResult(string code)
			{
				_barcodeScanner._scanningSession = null;
				_scannerView.StopCamera();
				_scannerView.RemoveResultHandler();
				Resolve(code);
			}
		}

		public BarcodeScanner() : this(Create()) { }

		BarcodeScanner(Java.Object scannerView) : base(scannerView)
		{
			_scannerView = scannerView;
		}

		readonly Java.Object _scannerView;

		object _scanningSession = null;

		Future<string> IBarcodeScannerView.Scan()
		{
			if (_scanningSession != null)
				return new Promise<string>().RejectWithMessage("Scanning already in progress");

			var session = new ScanPromise(this, _scannerView);
			_scanningSession = session;
			return session;
		}

		public override void Dispose()
		{
			base.Dispose();
		}

		[Foreign(Language.Java)]
		static Java.Object Create()
		@{
			return new ZXingScannerView(com.apps.barcodescannerexample.BarcodeScannerExample.GetRootActivity());
		@}
	}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zxing:1.8.4")]
	[Require("AndroidManifest.Permission", "android.permission.CAMERA")]
	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.zxing.ZXingScannerView",
		"com.google.zxing.Result")]
	extern(ANDROID) static class ScannerExtensions
	{
		[Foreign(Language.Java)]
		public static void StartCamera(this Java.Object handle)
		@{
			((ZXingScannerView)handle).startCamera();
		@}

		[Foreign(Language.Java)]
		public static void StopCamera(this Java.Object handle)
		@{
			((ZXingScannerView)handle).stopCamera();
		@}

		[Foreign(Language.Java)]
		public static void InstallResultHandler(
			this Java.Object scannerViewHandle,
			Action<string> resultHandler)
		@{
			((ZXingScannerView)scannerViewHandle).setResultHandler(new ZXingScannerView.ResultHandler() {
					public void handleResult(Result result) {
						resultHandler.run(result.getText());
					}
				});
		@}

		[Foreign(Language.Java)]
		public static void RemoveResultHandler(this Java.Object scannerViewHandle)
		@{
			((ZXingScannerView)scannerViewHandle).setResultHandler(null);
		@}
	}
}