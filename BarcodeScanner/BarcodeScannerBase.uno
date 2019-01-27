using Uno;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Controls
{

	interface IBarcodeScannerView
	{
		Future<string> Scan();
		void SetFlashlightEnabled(bool enable);
		bool GetFlashlightEnabled();
	}

	public abstract partial class BarcodeScannerBase : Panel
	{
		public Future<string> Scan()
		{
			var view = BarcodeScannerView;
			if (view != null)
				return view.Scan();
			else
			{
				var p = new Promise<string>();
				p.Reject(new Exception("Native view not initialized!"));
				return p;
			}
		}

		public void SetFlashlightEnabled(bool enable)
		{
			var view = BarcodeScannerView;
			if (view != null)
				view.SetFlashlightEnabled(enable);
		}

		public bool GetFlashlightEnabled()
		{
			var view = BarcodeScannerView;
			if (view != null)
				return view.GetFlashlightEnabled();

			return false;
		}

		IBarcodeScannerView BarcodeScannerView
		{
			get { return ViewHandle as IBarcodeScannerView; }
		}
	}
}