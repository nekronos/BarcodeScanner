using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.iOS
{

	delegate void ResultHandler(string code);

	extern(!iOS) internal class BarcodeScanner
	{
		[UXConstructor]
		public BarcodeScanner([UXParameter("Host")]IBarcodeScannerHost host) {}
	}

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/BarcodeView.h")]
	[Require("Source.Include", "MTBBarcodeScanner/MTBBarcodeScanner.h")]
	[Require("Cocoapods.Podfile.Target", "pod 'MTBBarcodeScanner'")]
	extern(iOS) internal class BarcodeScanner : ViewHandle, IBarcodeScannerView
	{

		[Require("Source.Include", "UIKit/UIKit.h")]
		[Require("Source.Include", "iOS/BarcodeView.h")]
		[Require("Source.Include", "MTBBarcodeScanner/MTBBarcodeScanner.h")]
		[Require("Cocoapods.Podfile.Target", "pod 'MTBBarcodeScanner'")]
		class Scanner
		{
			readonly ObjC.Object _handle;

			public Scanner(ObjC.Object handle)
			{
				_handle = handle;
				InstallResultHandler(_handle, OnGotResult);
			}

			void OnGotResult(string code)
			{
				var eventHandler = ResultEvent;
				if (eventHandler != null)
					eventHandler(code);
			}

			public event ResultHandler ResultEvent;
			public bool IsScanning { get { return IsScanningImpl(_handle); } }
			public void Freeze() { Freeze(_handle); }
			public void Unfreeze() { Unfreeze(_handle); }
			public bool StartScanning(out string errorMessage) { return StartScanningImpl(_handle, out errorMessage); }
			public void SetFlashlightEnabled(bool enabled) { SetFlashlightEnabled(_handle, enabled); }
			public void StopScanning() { StopScanning(_handle); }
			public bool GetFlashlightEnabled() { return GetFlashlightEnabled(_handle); }

			[Foreign(Language.ObjC)]
			static void Freeze(ObjC.Object scannerHandle)
			@{
				[(MTBBarcodeScanner*)scannerHandle freezeCapture];
			@}

			[Foreign(Language.ObjC)]
			static void Unfreeze(ObjC.Object scannerHandle)
			@{
				[(MTBBarcodeScanner*)scannerHandle unfreezeCapture];
			@}

			[Foreign(Language.ObjC)]
			static bool IsScanningImpl(ObjC.Object scannerHandle)
			@{
				return ((MTBBarcodeScanner*)scannerHandle).isScanning;
			@}

			[Foreign(Language.ObjC)]
			static void StopScanning(ObjC.Object scannerHandle)
			@{
				[((MTBBarcodeScanner*)scannerHandle) stopScanning];
			@}

			[Foreign(Language.ObjC)]
			static bool StartScanningImpl(ObjC.Object scannerHandle, out string errorMessage)
			@{
				MTBBarcodeScanner* scanner = (MTBBarcodeScanner*)scannerHandle;
				NSError* error = nil;
	            if (![scanner startScanningWithError: &error]) {
	            	*errorMessage = [NSString stringWithFormat:@"%@", error];
	            	return false;
	            } else {
	            	return true;
	            }
			@}

			[Foreign(Language.ObjC)]
			static void InstallResultHandler(ObjC.Object scannerHandle, Action<string> resultHandler)
			@{
				MTBBarcodeScanner* scanner = (MTBBarcodeScanner*)scannerHandle;
	            scanner.resultBlock = ^(NSArray<AVMetadataMachineReadableCodeObject*>* codes) {
	                if (codes.count > 0) {
	                    resultHandler(codes.firstObject.stringValue);
	                }
	            };
			@}

			[Foreign(Language.ObjC)]
			static void SetFlashlightEnabled(ObjC.Object scannerHandle, bool enabled)
			@{
				MTBBarcodeScanner* scanner = (MTBBarcodeScanner*)scannerHandle;
				scanner.torchMode = enabled ? MTBTorchModeOn : MTBTorchModeOff;
			@}
			
			[Foreign(Language.ObjC)]
			static bool GetFlashlightEnabled(ObjC.Object scannerHandle)
			@{
				MTBBarcodeScanner* scanner = (MTBBarcodeScanner*)scannerHandle;
				return scanner.torchMode == MTBTorchModeOn ? true : false;
			@}
		}

		[UXConstructor]
		public BarcodeScanner([UXParameter("Host")]IBarcodeScannerHost host) : this(host, CreateView()) { }

		BarcodeScanner(IBarcodeScannerHost host, ObjC.Object view) : this(host, view, CreateScanner(view)) {}

		BarcodeScanner(IBarcodeScannerHost host, ObjC.Object view, ObjC.Object scanner) : base(view)
		{
			_host = host;
			_view = view;
			_scanner = new Scanner(scanner);
		}

		readonly IBarcodeScannerHost _host;
		readonly ObjC.Object _view;
		readonly Scanner _scanner;

		bool _isStarted = false;
		Future<object> IBarcodeScannerView.Start()
		{
			if (_isStarted)
				return Reject("Scanner already started");
			
			string error = null;
			if (!_scanner.StartScanning(out error))
				return Reject("Failed to start scanner: " + error);

			_isStarted = true;
			_scanner.ResultEvent += _host.OnCodeScanned;
			return Resolve();
		}

		Future<object> IBarcodeScannerView.Stop()
		{
			if (!_isStarted)
				return Reject("Scanner already stopped");

			_isStarted = false;
			_scanner.StopScanning();
			_scanner.ResultEvent -= _host.OnCodeScanned;
			return Resolve();
		}

		Future<object> IBarcodeScannerView.Pause()
		{
			if (!_isStarted)
				return Reject("Scanner not started");

			_scanner.Freeze();
			return Resolve();
		}

		Future<object> IBarcodeScannerView.Resume()
		{
			if (!_isStarted)
				return Reject("Scanner not started");

			_scanner.Unfreeze();
			return Resolve();
		}

		void IBarcodeScannerView.SetFlashlightEnabled(bool enable)
		{
			_scanner.SetFlashlightEnabled(enable);
		}

		bool IBarcodeScannerView.GetFlashlightEnabled()
		{
			return _scanner.GetFlashlightEnabled();
		}

		Future<object> Reject(string message) { return new Promise<object>().RejectWithMessage(message); }

		Future<object> Resolve() { return new Promise<object>(new object()); }

		public override void Dispose()
		{
			base.Dispose();
		}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateView()
		@{
			return [[BarcodeView alloc] init];
		@}

		[Foreign(Language.ObjC)]
		static ObjC.Object CreateScanner(ObjC.Object previewView)
		@{
			return [[MTBBarcodeScanner alloc] initWithPreviewView:previewView];
		@}
	}
}