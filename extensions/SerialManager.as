package extensions
{
	import com.kamibot.bleextension.BluetoothExtension;
	
	import flash.desktop.NativeApplication;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import translation.Translator;
	
	import uiwidgets.DialogBox;
	
	import util.ApplicationManager;
	
	public class SerialManager extends EventDispatcher
	{
		private var moduleList:Array = [];
		private var _currentList:Array = [];
		private var currentPort:String = "";
		private var _selectPort:String = "";
		private var _upgradeBytesLoaded:Number = 0;
		private var _upgradeBytesTotal:Number = 0;
		private var _isInitUpgrade:Boolean = false;
		private var _dialog:DialogBox = new DialogBox();
		private var _hexToDownload:String = "";
		private var _lastSentByte:ByteArray = new ByteArray();
		
		private var _isMacOs:Boolean = ApplicationManager.sharedManager().system==ApplicationManager.MAC_OS;
		private var _avrdude:String = "";
		private var _avrdudeConfig:String = "";
		
		private var _serial:BluetoothExtension;
		private static var _instance:SerialManager = new SerialManager;
		
		public static function sharedManager():SerialManager{
			return _instance;
		}
		
		public function SerialManager()
		{
			_serial = new BluetoothExtension();
			_serial.addEventListener(BluetoothExtension.CONNECTED, onConnected);
			_serial.addEventListener(BluetoothExtension.DISCONNECTED, onDisconnected);
			_serial.addEventListener(BluetoothExtension.FIND_FAILURE, onFindFailure);
			_serial.addEventListener(BluetoothExtension.FIND_NEAREST_DEVICE, onFindNearestDevice);
			_serial.addEventListener(BluetoothExtension.RECEIVED, onReceived);
			_serial.addEventListener(BluetoothExtension.REQUEST_AUTHORITY, onRequestAuthority);
			//2017/02/28 이승훈 추가
			if (ApplicationManager.isIOS) {
				_serial.addEventListener(BluetoothExtension.ENABLE_BLUETOOTH, onEnabled);
 				_serial.addEventListener(BluetoothExtension.DISABLE_BLUETOOTH, onDisabled);
			}
		}
		
		//2017/02/28 이승훈
		public function requestAuthority():Boolean{
			var authority:Boolean = _serial.requestAuthority();
			trace("authority : "+authority);
			return authority;	
		}
		
		//permission 
		public function onRequestAuthority(e:Event):void {
			trace("onRequestAuthority!!");
		}
		
		public function get enabled():Boolean{
			return _serial.isEnabled;
		}
		
		public function get connected():Boolean{
			return (_serial.isConnected);
		}
		
		public function get scanning():Boolean{
			return (_serial.isScanning);
		}
		
		public function requestEnabled():Boolean{
			return _serial.requestEnabled();
		}
		
		public function showMessage(s:String):void{
			_serial.showMessage(s);
		}
		
		public var asciiString:String = "";
		
//		public function update():void{
//			if(!_serial.isConnected){
//				Main.app.topBarPart.setDisconnectedTitle();
//				return;
//			} else {
//				Main.app.topBarPart.setConnectedTitle();
//			}
//		}
		
		public function sendBytes(bytes:ByteArray):void{
			if(_serial.isConnected){
			
				var s:String;
				s = "";
				for(var i:uint = 0;i<bytes.length;i++){
					s += ("0x"+bytes[i].toString(16))+" ";
				}
				
				_lastSentByte =  new ByteArray();
				_lastSentByte.writeBytes(bytes);
				
				var date:Date = new Date();
				trace(date.time + " : send: " + s);
				
				return _serial.write(bytes);
			}
		}
		
		public function sendString(msg:String):void{
			trace("sendString " + msg);
			var byteArray:ByteArray = new ByteArray()
			byteArray.writeUTFBytes(msg);
			_serial.write(byteArray);
		}
		
		public function open():Boolean{
			if(connected) return false;
			if (!enabled) return false;
			
			trace("connect 1000");
			_serial.connect(1000);
//			Main.app.topBarPart.setConnectedTitle(Translator.map("finding..."));
			return true;
		}
		
		public function close():void{
			if (connected) {
				_serial.close();
			}
		}
		
		public function disconnect():void{
			//			currentPort = "";
			//			Main.app.topBarPart.setDisconnectedTitle();
			//			//			MBlock.app.topBarPart.setBluetoothTitle(false);
			//			ArduinoManager.sharedManager().isUploading = false;
			//			_serial.close();
			//			_serial.removeEventListener(Event.CHANGE,onChanged);
		}
		
		public function reconnectSerial():void{
			//			toggleConnection(currentPort);
		}
		
		
		public function onConnected(e:Event):void {
			trace("onConnected");
//			Main.app.topBarPart.setConnectedTitle();
			ConnectionManager.sharedManager().onOpen();
		}
		
		//when unexpected connection termination
		public function onDisconnected(e:Event):void {
			trace("onDisconnected");
			DialogBox.notify('Lost connection to KamiBot', 'Lost connection to KamiBot. Please ensure that your KamiBot is turned on.', Main.app.stage);
//			Main.app.topBarPart.setDisconnectedTitle();
			ConnectionManager.sharedManager().onClose();
		}
		
		//cannot find kamibot
		public function onFindFailure(e:Event):void {
			trace("onFindFailure");
			
			DialogBox.notify('Cannot find KamiBot', 'Cannot find KamiBot. Make sure that your KamiBot turn on.', Main.app.stage);
//			Main.app.topBarPart.setDisconnectedTitle();
			_serial.close();
			ConnectionManager.sharedManager().onClose();
		}
		
		//found kamibot, connecting...
		public function onFindNearestDevice(e:Event):void {
			trace("onFindNearestDevice");
//			Main.app.topBarPart.setConnectedTitle(Translator.map("connecting..."));
		}
		    
		//bluetooth is enabled (only ios)
		public function onEnabled(e:Event):void{
			trace("onEnabled");
		}
		
		//bluetooth is disabled (only ios)
		public function onDisabled(e:Event):void{
			trace("onDisabled");
		}
		
		public function onReceived(e:Event):void {
			var bytes:ByteArray = _serial.read();
			
			if (bytes == null) {trace("onReceived bytes == null"); return;}
			else {trace(bytes);}
			
			if (bytes.length > 0) {
				var s:String;
				s = "";
				for(var i:Number = 0;i<bytes.length;i++){
					s += ("0x"+bytes[i].toString(16))+" ";
				}
				var date:Date = new Date();
				
				//2017/06/12 이승훈 수정
				//trace(date.time + " : read: " + s);
				
				if (bytes.length == 5 && bytes[0] == 0xff && bytes[1] == 0x55 && bytes[2] == 0x1 && bytes[3] == 0xd && bytes[4] == 0xa) {
//					sendBytes(_lastSentByte);
//					trace("retry send");
				} else {
					ConnectionManager.sharedManager().onReceived(bytes);
				}
				
			}
		}
	}
}