using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;
using Uno.Permissions;
using Uno.Collections;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.Android
{
	extern(ANDROID) internal class BarcodeScanner : ViewHandle, IBarcodeScannerView
	{
		static BarcodeScannerHandle CreateBarcodeScannerView()
		{
			if defined(ZXING)
				return new ZXingView();
			else
				return new ZBarView();
		}

		[UXConstructor]
		public BarcodeScanner([UXParameter("Host")]IBarcodeScannerHost host) : this(host, CreateBarcodeScannerView()) { }

		BarcodeScanner(IBarcodeScannerHost host, BarcodeScannerHandle handle) : base(handle.Handle)
		{
			_host = host;
			_handle = handle;
			_handle.CodeScanned += OnCodeScanned;
			Fuse.Platform.Lifecycle.EnteringForeground += OnEnteringForeground;
		}

		readonly IBarcodeScannerHost _host;
		readonly BarcodeScannerHandle _handle;

		bool _isRunning = false;
		Future<object> IBarcodeScannerView.Start()
		{
			if (!_isRunning)
			{
				_handle.StartCamera();
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
				_handle.StopCamera();
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
				_handle.StopCameraPreview();
				return Resolve();
			}
			else
				return Reject("Scanner not running");
		}

		Future<object> IBarcodeScannerView.Resume()
		{
			if (_isRunning)
			{
				_handle.ResumeCameraPreview();
				return Resolve();
			}
			else
				return Reject("Scanner not running");
		}

		void IBarcodeScannerView.SetFlashlightEnabled(bool enable)
		{
			_handle.IsFlashOn = enable;
		}

		bool IBarcodeScannerView.GetFlashlightEnabled()
		{
			return _handle.IsFlashOn;
		}

		Future<object> Reject(string message) { return new Promise<object>().RejectWithMessage(message); }

		Future<object> Resolve() { return new Promise<object>(new object()); }

		void OnCodeScanned(object sender, string code)
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
				_handle.ResumeCameraPreview();
		}

		public override void Dispose()
		{
			_handle.CodeScanned -= OnCodeScanned;
			Fuse.Platform.Lifecycle.EnteringForeground -= OnEnteringForeground;
			base.Dispose();
		}
	}

	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.core.BarcodeScannerView")]
	extern(ANDROID) internal abstract class BarcodeScannerHandle
	{
		public Java.Object Handle { get { return _handle; } }

		readonly Java.Object _handle;

		public BarcodeScannerHandle(Java.Object handle)
		{
			if (!IsBarcodeScannerView(handle))
				throw new Exception("Handle not instanceof BarcodeScannerView");
			_handle = handle;
		}

		public bool IsFlashOn
		{
			get { return GetFlash(_handle); }
			set { SetFlash(_handle, value); }
		}

		public void StartCamera()
		{
			StartCamera(_handle);
			OnCameraStarted();
		}

		public void StopCamera()
		{
			StopCamera(_handle);
		}

		public void StopCameraPreview()
		{
			StopCameraPreview(_handle);
		}

		public abstract void ResumeCameraPreview();
		public abstract event EventHandler<string> CodeScanned;

		protected virtual void OnCameraStarted() {}

		[Foreign(Language.Java)]
		static bool GetFlash(Java.Object handle)
		@{
			return ((BarcodeScannerView)handle).getFlash();
		@}

		[Foreign(Language.Java)]
		static void SetFlash(Java.Object handle, bool value)
		@{
			((BarcodeScannerView)handle).setFlash(value);
		@}

		[Foreign(Language.Java)]
		static void StartCamera(Java.Object handle)
		@{
			((BarcodeScannerView)handle).startCamera();
		@}

		[Foreign(Language.Java)]
		static void StopCamera(Java.Object handle)
		@{
			((BarcodeScannerView)handle).stopCamera();
		@}

		[Foreign(Language.Java)]
		static void StopCameraPreview(Java.Object handle)
		@{
			((BarcodeScannerView)handle).stopCameraPreview();
		@}

		[Foreign(Language.Java)]
		static bool IsBarcodeScannerView(Java.Object handle)
		@{
			return handle instanceof BarcodeScannerView;
		@}
	}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zbar:1.9.1")]
	[Require("AndroidManifest.Permission", "android.permission.CAMERA")]
	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.zbar.ZBarScannerView",
		"me.dm7.barcodescanner.zbar.Result",
		"me.dm7.barcodescanner.core.BarcodeScannerView",
		"me.dm7.barcodescanner.core.IViewFinder",
		"android.content.Context",
		"android.graphics.Rect")]
	extern(ANDROID) internal class ZBarView : BarcodeScannerHandle
	{
		readonly Java.Object _resultHandler;

		public ZBarView() : base(Create())
		{
			_resultHandler = CreateResultHandler(OnCodeScanned);
		}

		public override event EventHandler<string> CodeScanned;

		void OnCodeScanned(string code)
		{
			var handler = CodeScanned;
			if (handler != null)
				handler(this, code);
		}

		public override void ResumeCameraPreview()
		{
			Resume(Handle, _resultHandler);
		}

		protected override void OnCameraStarted()
		{
			SetResultHandler(Handle, _resultHandler);
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
			return new ZBarScannerView(@(Activity.Package).@(Activity.Name).GetRootActivity()) {
				@Override
				protected IViewFinder createViewFinderView(Context context) {
					return new EmptyViewFinder(context);
				}
			};
		@}

		[Foreign(Language.Java)]
		static Java.Object CreateResultHandler(Action<string> callback)
		@{
			return new ZBarScannerView.ResultHandler() {
				public void handleResult(Result rawResult) {
					callback.run(rawResult.getContents());
				}
			};
		@}

		[Foreign(Language.Java)]
		static void SetResultHandler(Java.Object handle, Java.Object resultHandler)
		@{
			((ZBarScannerView)handle).setResultHandler((ZBarScannerView.ResultHandler)resultHandler);
		@}

		[Foreign(Language.Java)]
		static void Resume(Java.Object handle, Java.Object resultHandler)
		@{
			((ZBarScannerView)handle).resumeCameraPreview((ZBarScannerView.ResultHandler)resultHandler);
		@}
	}

	[Require("Gradle.Dependency.Compile", "me.dm7.barcodescanner:zxing:1.9.1")]
	[Require("AndroidManifest.Permission", "android.permission.CAMERA")]
	[ForeignInclude(Language.Java,
		"me.dm7.barcodescanner.zxing.ZXingScannerView",
		"com.google.zxing.Result",
		"me.dm7.barcodescanner.core.IViewFinder",
		"android.content.Context",
		"android.graphics.Rect")]
	extern(ANDROID) internal class ZXingView : BarcodeScannerHandle
	{

		readonly Java.Object _resultHandler;

		public ZXingView() : base(Create())
		{
			_resultHandler = CreateResultHandler(OnCodeScanned);
		}

		public override event EventHandler<string> CodeScanned;

		void OnCodeScanned(string code)
		{
			var handler = CodeScanned;
			if (handler != null)
				handler(this, code);
		}

		public override void ResumeCameraPreview()
		{
			ResumeCameraPreview(Handle, _resultHandler);
		}

		protected override void OnCameraStarted()
		{
			InstallResultHandler(Handle, _resultHandler);
		}

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
}