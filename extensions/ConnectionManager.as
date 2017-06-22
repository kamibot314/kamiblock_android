package extensions
{
	import com.google.analytics.debug.Label;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.ByteArray;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import ui.parts.MonitorPart;
	
	import uiwidgets.DialogBox;
	
	public class ConnectionManager extends EventDispatcher
	{
		private static var _instance:ConnectionManager;
		public var extensionName:String = "";
		public function ConnectionManager()
		{
		}
		
		public static function sharedManager():ConnectionManager{
			if(_instance==null){
				_instance = new ConnectionManager;
			}
			return _instance;
		}
		
//		public function onConnect(name:String):void{
//			switch(name){
//				case "search_ble_device":{
//					open();
//					setTimeout(ConnectionManager.sharedManager().onOpen,100);
//					break;
//				}
//				case "disconnect_ble_device": {
//					close();
//					setTimeout(ConnectionManager.sharedManager().onClose,100);
//					break;
//				}
//				default:{
//				}
//			}
//		}
		
		//2017/02/27 이승훈
		//위치 권한요청 추가
		public function requestAuthority():Boolean{
			return SerialManager.sharedManager().requestAuthority();
		}
		
		public function open():Boolean{
			return SerialManager.sharedManager().open();
		}
		
		public function close():void{
			SerialManager.sharedManager().close();
		}
		
		public function onClose():void{
//			if(!SerialManager.sharedManager().connected){
//				Main.app.topBarPart.setDisconnectedTitle();
//			}else{
//				if(SerialManager.sharedManager().connected){
////					Main.app.topBarPart.setConnectedTitle();
//				}
//			}
			Main.app.runtime.stopAll();
			setState(SEND);
			this.dispatchEvent(new Event(Event.CLOSE));
		}
		
		public function onRemoved(extName:String = ""):void{
			extensionName = extName;
			this.dispatchEvent(new Event(Event.REMOVED));
		}
		
		public function onOpen():void{
			Main.app.runtime.stopAll();
			setState(SEND);
			this.dispatchEvent(new Event(Event.CONNECT));
		}
		
		public function onReOpen():void{
			//			if(SerialPortManager.getInstance().port!=""){
			//				this.dispatchEvent(new Event(Event.CONNECT));
			//			}
		}
		
		private var _bytes:ByteArray;
		public function onReceived(bytes:ByteArray):void{
			_bytes = bytes;
			//2017/06/12 이승훈 수정
			var s:String;
			s = "";
			for(var i:Number = 0;i<_bytes.length;i++){
				s += ("0x"+_bytes[i].toString(16))+" ";
			}
			if(Main.app.isMonitorScreenOn){
				trace("s : "+s);
				Main.app.monitorPart.batteryValue.text = "1";
				Main.app.monitorPart.batteryUnit.x = Main.app.monitorPart.batteryValue.x+20+Main.app.monitorPart.batteryValue.text.length;
				Main.app.monitorPart.ultraSonicValue.text = "2";
				Main.app.monitorPart.ultraSonicUnit.x = Main.app.monitorPart.ultraSonicValue.x+20+Main.app.monitorPart.ultraSonicValue.text.length;;
				Main.app.monitorPart.infrared1Value.text = "3";
				Main.app.monitorPart.infrared2Value.text = "4";
				Main.app.monitorPart.infrared3Value.text = "5";
				Main.app.monitorPart.infrared4Value.text = "6";
				Main.app.monitorPart.infrared5Value.text = "7";
			}
//			readBytes();
			this.dispatchEvent(new Event(Event.CHANGE));
		}
		
		/**
		 * step 1 - first time: _state = SEND
		 * step 2 - send signal:  _state = WAIT
		 * step 3 - received response: _state = GOTONEXT
		 */
		private var _state:uint = SEND;
		
		public static const SEND:uint = 0;
		public static const WAIT:uint = 1;
		public static const GOTONEXT:uint = 2;
		
		public var greenFlag:Boolean = false;
		
		private var _timerId:uint = 0;
		public function sendBytes(bytes:ByteArray, moreTime:Boolean = false):void{
//			trace("sendBytes");
//			if (bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x2 && bytes[3] == 0x0 && bytes[4] == 0x4) {
//				bytes.position = 0;
//				SerialManager.sharedManager().sendBytes(bytes);
//				return;
//			}
			
			if (bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x2 && bytes[3] == 0x0 && bytes[4] == 0x4) {
				greenFlag = true;
				setState(SEND);
				SerialManager.sharedManager().sendBytes(bytes);
				setState(WAIT);
				return;
			}
			
			switch(_state)
			{
				case SEND:
				{
					trace("SEND");
					var timeoutCount:uint = 1;
					if(SerialManager.sharedManager().connected && bytes.length > 0){
						bytes.position = 0;
						SerialManager.sharedManager().sendBytes(bytes);
						setState(WAIT);
						Main.app.interp.doYield();
						if (_timerId == 0) {
							if (moreTime) {
									
								if (bytes.length > 6) {
									timeoutCount = bytes[6];
								}
								
								_timerId = setTimeout(onTimeout2, 10000 * timeoutCount);
								trace("set time out " + (10000 * timeoutCount));
							} else {
								_timerId = setTimeout(onTimeout, 1000);
								trace("set time out " + 1000);
							}
						} else {
							trace("sendBytes error! " + new Error().getStackTrace());
						}
					}
					// step 1. first comes
					break;
				}
				case WAIT://if first run block, send bytes and set waitng state 
				{
					trace("waiting...");
					Main.app.interp.doYield();//wating for response(bytes is send)
					// step 2. waiting response
					break;
				}
				case GOTONEXT:
				{
					setState(SEND);
					// step 4. goto next block (no nothing: if not yield, interpreter automatically go to next block)
					break;
				}
				default:
				{
					trace("sendBytes error! " + new Error().getStackTrace());
					break;
				}
			}
		}
		
		//clear timeout when stop flag pressed
		public function clearTimeoutTimer():void {
			clearTimeout(_timerId);
			_timerId = 0;
		}
		
		private function onTimeout():void {
			
//			Main.app.interp.isWaiting = false;
			
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("No response from KamiBot");
			dialog.addText("No response from KamiBot. Please ensure that your KamiBot is turned on.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(Main.app.stage);
			Main.app.runtime.stopAll();
			setState(SEND);
			_timerId = 0;
		}
		
		private function onTimeout2():void {
			var dialog:DialogBox = new DialogBox();
			dialog.addTitle("KamiBot Unable to detect any line");
			dialog.addText("KamiBot Unable to detect any line. Please place your KamiBot on the line.");
			function onCancel():void{
				dialog.cancel();
			}
			dialog.addButton("OK",onCancel);
			dialog.showOnStage(Main.app.stage);
			Main.app.runtime.stopAll();
			setState(SEND);
			_timerId = 0;
		}
		
		public function setState(state:uint):void {
			_state = state;
		}
		
		public function readBytes():ByteArray{
			trace("readBytes!!!!!");
			
			clearTimeoutTimer();
			if (_state == WAIT) {
				if (greenFlag) {
					setState(SEND);
					greenFlag = false;
				} else {
					setState(GOTONEXT);
				}
			}
			if(_bytes){
				trace("_bytes : "+_bytes);
				return _bytes;
			} else {
				return new ByteArray;//if emtpy, new empty bytes returns;
			}
		}		
	}
}