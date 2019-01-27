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
				new ScriptMethod<BarcodeScannerBase>("setFlashlightEnabled", setFlashlightEnabled),
				new ScriptMethod<BarcodeScannerBase>("getFlashlightEnabled", getFlashlightEnabled)
			);
		}

		static Future<string> scan(Context context, BarcodeScannerBase self, object[] args)
		{
			return self.Scan();
		}

		static void setFlashlightEnabled(BarcodeScannerBase self, object[] args)
		{
			self.SetFlashlightEnabled(Marshal.ToBool(args[0]));
		}

		static object getFlashlightEnabled(Context c, BarcodeScannerBase self, object[] args)
		{
			return self.GetFlashlightEnabled();
		}
	}
}