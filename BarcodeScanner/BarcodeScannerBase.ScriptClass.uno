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
		static BarcodeScannerBase()
		{
			ScriptClass.Register(typeof(BarcodeScannerBase),
				new ScriptPromise<BarcodeScannerBase,string,object>("scan", ExecutionThread.MainThread, scan),
				new ScriptMethod<BarcodeScannerBase>("toggleFlash", toggleFlash));
		}

		static Future<string> scan(Context context, BarcodeScannerBase self, object[] args)
		{
			return self.Scan();
		}

		static void toggleFlash(BarcodeScannerBase self, object[] args)
		{
			self.ToggleFlash();
		}
	}
}