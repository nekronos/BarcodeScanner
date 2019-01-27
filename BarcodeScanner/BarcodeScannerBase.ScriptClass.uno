using Uno;
using Uno.UX;
using Uno.Time;
using Uno.Compiler.ExportTargetInterop;
using Uno.Threading;
using Uno.Collections;

using Fuse;
using Fuse.Controls;
using Fuse.Controls.Native;
using Fuse.Scripting;

namespace Fuse.Controls
{
	public abstract partial class BarcodeScannerBase
	{
		class CodeScannedHandler
		{
			readonly Context _context;
			readonly Fuse.Scripting.Function _function;

			public CodeScannedHandler(
				Context context,
				Fuse.Scripting.Function function)
			{
				_context = context;
				_function = function;
			}

			void OnCodeScanned(object sender, string code)
			{
				_function.Call(_context, code);
			}

			public void Bind(BarcodeScannerBase barcodeScannerbase)
			{
				new BindCodeScannedHandler(this, barcodeScannerbase);
			}

			class BindCodeScannedHandler
			{
				readonly CodeScannedHandler _codeScannedHandler;
				readonly BarcodeScannerBase _barcodeScanner;

				public BindCodeScannedHandler(
					CodeScannedHandler codeScannedHandler,
					BarcodeScannerBase barcodeScannerbase)
				{
					_codeScannedHandler = codeScannedHandler;
					_barcodeScanner = barcodeScannerbase;
					UpdateManager.PostAction(OnBind);
				}

				void OnBind()
				{
					_barcodeScanner.CodeScanned += _codeScannedHandler.OnCodeScanned;
				}
			}
		}

		static BarcodeScannerBase()
		{
			ScriptClass.Register(typeof(BarcodeScannerBase),
				new ScriptPromise<BarcodeScannerBase,object,object>("start", ExecutionThread.MainThread, start, ConvertObject),
				new ScriptPromise<BarcodeScannerBase,object,object>("stop", ExecutionThread.MainThread, stop, ConvertObject),
				new ScriptPromise<BarcodeScannerBase,object,object>("pause", ExecutionThread.MainThread, pause, ConvertObject),
				new ScriptPromise<BarcodeScannerBase,object,object>("resume", ExecutionThread.MainThread, resume, ConvertObject),
				new ScriptPromise<BarcodeScannerBase,bool,object>("getFlashlightEnabled", ExecutionThread.MainThread, getFlashlightEnabled),
				new ScriptMethod<BarcodeScannerBase>("setFlashlightEnabled", setFlashlightEnabled),
				new ScriptMethod<BarcodeScannerBase>("onCodeScanned", onCodeScanned));
		}

		static Future<object> start(Context context, BarcodeScannerBase self, object[] args) { return self.Start(); }

		static Future<object> stop(Context context, BarcodeScannerBase self, object[] args) { return self.Stop(); }

		static Future<object> pause(Context context, BarcodeScannerBase self, object[] args) { return self.Pause(); }

		static Future<object> resume(Context context, BarcodeScannerBase self, object[] args) { return self.Resume(); }

		static Future<bool> getFlashlightEnabled(Context context, BarcodeScannerBase self, object[] args)
		{
			return new Promise<bool>(self.GetFlashlightEnabled());
		}

		static void setFlashlightEnabled(BarcodeScannerBase self, object[] args)
		{
			self.SetFlashlightEnabled(Marshal.ToBool(args[0]));
		}

		static object ConvertObject(Context c, object obj)
		{
			return c.NewObject();
		}

		static object onCodeScanned(Context context, BarcodeScannerBase self, object[] args)
		{
			if (args.Length != 1)
				throw new Exception("Unexpected number of arguments");

			if (!(args[0] is Fuse.Scripting.Function))
				throw new Exception("Argument must by a function");

			var function = (Fuse.Scripting.Function)args[0];

			var codeScannedHandler = new CodeScannedHandler(context, function);

			codeScannedHandler.Bind(self);

			return null;
		}
	}
}