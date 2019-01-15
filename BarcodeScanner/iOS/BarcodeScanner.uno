using Uno;
using Uno.UX;
using Uno.Threading;
using Uno.Compiler.ExportTargetInterop;

using Fuse.Controls.Native;

namespace Fuse.Controls.Native.iOS
{

	delegate void ResultHandler(string code);

	extern(!iOS) public class BarcodeScanner {}

	[Require("Source.Include", "UIKit/UIKit.h")]
	[Require("Source.Include", "iOS/BarcodeView.h")]
	[Require("Source.Include", "MTBBarcodeScanner/MTBBarcodeScanner.h")]
	[Require("Cocoapods.Podfile.Target", "pod 'MTBBarcodeScanner'")]
	extern(iOS) public class BarcodeScanner : ViewHandle, IBarcodeScannerView
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
			public void ToggleFlash() { ToggleFlash(_handle); }

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
			static void ToggleFlash(ObjC.Object scannerHandle)
			@{
				MTBBarcodeScanner* scanner = (MTBBarcodeScanner*)scannerHandle;
				[scanner toggleTorch];
			@}
		}

		class ScanPromise : Promise<string>
		{
			BarcodeScanner _barcodeScanner;
			Scanner _scanner;

			public ScanPromise(
				BarcodeScanner barcodeScanner,
				Scanner scanner)
			{
				_barcodeScanner = barcodeScanner;
				_barcodeScanner._scanningSession = this;
				_scanner = scanner;
				_scanner.ResultEvent += OnGotResult;
				_scanner.Unfreeze();
			}

			void OnGotResult(string code)
			{
				_scanner.Freeze();
				_scanner.ResultEvent -= OnGotResult;
				_barcodeScanner._scanningSession = null;
				Resolve(code);
			}

		}

		public BarcodeScanner() : this(CreateView()) { }

		BarcodeScanner(ObjC.Object view) : this(view, CreateScanner(view)) {}

		BarcodeScanner(ObjC.Object view, ObjC.Object scanner) : base(view)
		{
			_view = view;
			_scanner = new Scanner(scanner);

			string error = null;
			var _ = _scanner.StartScanning(out error);
		}

		readonly ObjC.Object _view;
		readonly Scanner _scanner;

		object _scanningSession = null;

		Future<string> IBarcodeScannerView.Scan()
		{
			if (_scanningSession != null)
				return new Promise<string>().RejectWithMessage("Scanning already in progress");

			if (!_scanner.IsScanning)
			{
				string error = null;
				if (_scanner.StartScanning(out error))
					return new Promise<string>().RejectWithMessage(error);
			}
			return new ScanPromise(this, _scanner);
		}

		void IBarcodeScannerView.ToggleFlash()
		{
			_scanner.ToggleFlash();
		}

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