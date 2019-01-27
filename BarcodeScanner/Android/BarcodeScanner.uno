using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Collections;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(!ANDROID) internal class BarcodeScanner
	{
		[UXConstructor]
		public BarcodeScanner([UXParameter("Host")]IBarcodeScannerHost host) {}
	}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zxing:1.9.1")]
	[Require("AndroidManifest.Permission", "android.permission.CAMERA")]
	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.zxing.ZXingScannerView",
		"com.google.zxing.Result",
		"me.dm7.barcodescanner.core.IViewFinder",
		"android.content.Context",
		"android.graphics.Rect")]
	extern(ANDROID) internal class BarcodeScanner : ViewHandle, IBarcodeScannerView
	{
		[UXConstructor]
		public BarcodeScanner([UXParameter("Host")]IBarcodeScannerHost host) : this(host, Create()) { }

		BarcodeScanner(IBarcodeScannerHost host, Java.Object scannerView) : base(scannerView)
		{
			_host = host;
			_scannerView = scannerView;
			_resultHandler = CreateResultHandler(OnCodeScanned);
			_scannerView.InstallResultHandler(_resultHandler);

			Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
		}

		readonly IBarcodeScannerHost _host;
		readonly Java.Object _scannerView;
		readonly Java.Object _resultHandler;

		object _scanningSession = null;

		void Start() { _scannerView.StartCamera(); }
		void Stop() { _scannerView.StopCamera(); }
		void Pause() { _scannerView.StopCameraPreview(); }
		void Resume() { _scannerView.ResumeCameraPreview(_resultHandler); }

		bool _isRunning = false;
		Future<object> IBarcodeScannerView.Start()
		{
			if (!_isRunning)
			{
				Start();
				_isRunning = true;
				return Resolve();
			}
			else
				return Reject("Scanner already running");
		}

		Future<object> IBarcodeScannerView.Stop()
		{
			if (_isRunning)
			{
				Stop();
				_isRunning = false;
				return Resolve();
			}
			else
				return Reject("Scanner not running");
		}

		Future<object> IBarcodeScannerView.Pause()
		{
			if (_isRunning)
			{
				Pause();
				return Resolve();
			}
			else
				return Reject("Scanner not running");
		}

		Future<object> IBarcodeScannerView.Resume()
		{
			if (_isRunning)
			{
				Resume();
				return Resolve();
			}
			else
				return Reject("Scanner not running");
		}

		void IBarcodeScannerView.SetFlashlightEnabled(bool enable)
		{
			_scannerView.SetFlashlightEnabled(enable);
		}

		bool IBarcodeScannerView.GetFlashlightEnabled()
		{
			return _scannerView.GetFlashlightEnabled();
		}

		Future<object> Reject(string message) { return new Promise<object>().RejectWithMessage(message); }

		Future<object> Resolve() { return new Promise<object>(new object()); }

		void OnCodeScanned(string code)
		{
			_host.OnCodeScanned(code);
			ResumeIfRunning();
		}

		void OnEnteringForeground(Fuse.Platform.ApplicationState s)
		{
			ResumeIfRunning();
		}

		void ResumeIfRunning()
		{
			if (_isRunning)
				_scannerView.ResumeCameraPreview(_resultHandler);
		}

		public override void Dispose()
		{
			base.Dispose();
			Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
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
		public static void StopCameraPreview(this Java.Object handle)
		@{
			((ZXingScannerView)handle).stopCameraPreview();
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

		[Foreign(Language.Java)]
		public static void SetFlashlightEnabled(this Java.Object scannerViewHandle, bool enable)
		@{
			((ZXingScannerView)scannerViewHandle).setFlash(enable);	
		@}

		[Foreign(Language.Java)]
		public static bool GetFlashlightEnabled(this Java.Object scannerViewHandle)
		@{
			return ((ZXingScannerView)scannerViewHandle).getFlash();	
		@}
	}
}