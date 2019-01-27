using Uno;
using Uno.UX;
using Uno.Threading;

namespace Fuse.Controls
{
	interface IBarcodeScannerView
	{
		void SetFlashlightEnabled(bool enable);
		bool GetFlashlightEnabled();
		Future<object> Start();
		Future<object> Stop();
		Future<object> Pause();
		Future<object> Resume();
	}

	internal interface IBarcodeScannerHost
	{
		void OnCodeScanned(string code);
	}

	public abstract partial class BarcodeScannerBase : Panel, IBarcodeScannerHost
	{

		public event EventHandler<string> CodeScanned;

		void IBarcodeScannerHost.OnCodeScanned(string code)
		{
			var handler = CodeScanned;
			if (handler != null)
				handler(this, code);
		}

		public void SetFlashlightEnabled(bool enable) { BarcodeScannerView.SetFlashlightEnabled(enable); }
		public bool GetFlashlightEnabled() { return BarcodeScannerView.GetFlashlightEnabled(); }
		public Future<object> Start() { return BarcodeScannerView.Start(); }
		public Future<object> Stop() { return BarcodeScannerView.Stop(); }
		public Future<object> Resume() { return BarcodeScannerView.Resume(); }
		public Future<object> Pause() { return BarcodeScannerView.Pause(); }

		IBarcodeScannerView BarcodeScannerView
		{
			get { return (ViewHandle as IBarcodeScannerView) ?? DummyBarcodeScannerView.Instance; }
		}

		class DummyBarcodeScannerView : IBarcodeScannerView
		{
			Future<T> Reject<T>() { return new Promise<T>().RejectWithMessage("Native view not initialized!"); }
			
			Future<object> IBarcodeScannerView.Start() { return Reject<object>(); }
			Future<object> IBarcodeScannerView.Stop() { return Reject<object>(); }
			Future<object> IBarcodeScannerView.Pause() { return Reject<object>(); }
			Future<object> IBarcodeScannerView.Resume() { return Reject<object>(); }

			void IBarcodeScannerView.SetFlashlightEnabled(bool enable) { }
			bool IBarcodeScannerView.GetFlashlightEnabled() { return false; }

			DummyBarcodeScannerView() {}

			public static readonly IBarcodeScannerView Instance = new DummyBarcodeScannerView();
		}
	}
}