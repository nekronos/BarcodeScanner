using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(!ANDROID) public class BarcodeScanner {}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zxing:1.9.1")]
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
			readonly Java.Object _resultHandler;
			readonly BarcodeScanner _barcodeScanner;

			public ScanPromise(BarcodeScanner barcodeScanner, Java.Object scannerView)
			{
				_barcodeScanner = barcodeScanner;
				_scannerView = scannerView;
				_resultHandler = CreateResultHandler(OnGotResult);

				Permissions.Request(new PlatformPermission[] { Permissions.Android.CAMERA }).Then(DoScan, Reject);
				Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
				Fuse.Platform.Lifecycle.EnteringBackground += OnEnteringBackground;
			}

			bool _inForeground = true;
			void OnEnteringBackground(Fuse.Platform.ApplicationState s)
			{
				if (!_inForeground)
					return;
				_inForeground = false;
			}

			void OnEnteringForeground(Fuse.Platform.ApplicationState s)
			{
				if (_inForeground)
					return;
				_inForeground = true;
				_scannerView.ResumeCameraPreview(_resultHandler);
			}

			void DoScan(PlatformPermission[] permission)
			{
				_scannerView.InstallResultHandler(_resultHandler);
				_scannerView.StartCamera();
			}

			void OnGotResult(string code)
			{
				_barcodeScanner._scanningSession = null;
				_scannerView.StopCamera();
				_scannerView.RemoveResultHandler();
				Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
				Fuse.Platform.Lifecycle.EnteringBackground -= OnEnteringBackground;
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
			class EmptyViewFinder extends android.view.View implements IViewFinder {
				public EmptyViewFinder(Context context) { super(context); }
				public void setupViewFinder() {}
				public Rect getFramingRect() {
					return new Rect(0, 0, getWidth(), getHeight());
				}
			}
			return new ZXingScannerView(@(Activity.Package).@(Activity.Name).GetRootActivity()) {
				@Override
				protected IViewFinder createViewFinderView(Context context) {
					return new EmptyViewFinder(context);
				}
			};
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateResultHandler(Action<string> handler)
		@{
			return new ZXingScannerView.ResultHandler() {
				public void handleResult(Result result) {
					handler.run(result.getText());
				}
			};
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
		public static void ResumeCameraPreview(this Java.Object handle, Java.Object resultHandler)
		@{
			((ZXingScannerView)handle).resumeCameraPreview((ZXingScannerView.ResultHandler)resultHandler);
		@}

		[Foreign(Language.Java)]
		public static void InstallResultHandler(this Java.Object scannerViewHandle, Java.Object resultHandler)
		@{
			((ZXingScannerView)scannerViewHandle).setResultHandler((ZXingScannerView.ResultHandler)resultHandler);
		@}

		[Foreign(Language.Java)]
		public static void RemoveResultHandler(this Java.Object scannerViewHandle)
		@{
			((ZXingScannerView)scannerViewHandle).setResultHandler(null);
		@}
	}
}