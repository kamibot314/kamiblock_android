package extensions
{
	import flash.events.Event;
	import flash.utils.ByteArray;

	public class SerialDevice
	{
		private static var _instance:SerialDevice;
		private var _ports:Array = [];
		
		public function SerialDevice()
		{
		}
		
		public static function sharedDevice():SerialDevice{
			if(_instance==null){
				_instance = new SerialDevice;
			}
			return _instance;
		}
		
		public function onConnect(port:String):void{
		}
		
		private var _receiveHandlers:Function;;
		public function clear(v:String):void{
			var index:int = _ports.indexOf(v);
			_ports.splice(index);
			_receiveHandlers = null;
			
			isFirst = true;
			ParseManager.sharedManager().clearFirmVersion();
		}
		
		public function set_receive_handler(name:String,receiveHandler:Function):void{
			if(receiveHandler!=null){
				_receiveHandlers = receiveHandler;
				ConnectionManager.sharedManager().removeEventListener(Event.CHANGE,onReceived);
				ConnectionManager.sharedManager().addEventListener(Event.CHANGE,onReceived);
			}
		}
		
		public function send(bytes:Array, moreTime:Boolean = false):void{
			var buffer:ByteArray = new ByteArray();
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			ConnectionManager.sharedManager().sendBytes(buffer, moreTime);
//			buffer.clear();
		}
		
		public function sendBytes(bytes:ByteArray):void{
			ConnectionManager.sharedManager().sendBytes(bytes);
		}
		
		private var l:uint = 0;
		private var _receivedBuffer:ByteArray;
		private var _receivedBytes:Array;
		private var isFirst:Boolean = true;
		private function onReceived(evt:Event):void{
			if(_receiveHandlers != null){
				_receivedBuffer = ConnectionManager.sharedManager().readBytes();
				if (isFirst && _receivedBuffer.length > 0) {
//					ParseManager.sharedManager().queryVersion();
					isFirst = false;
				} else {
					if (ParseManager.sharedManager().isFirmVersionDetected())
						ParseManager.sharedManager().parseFirmVersion(_receivedBuffer);
					
					_receivedBytes = [];
					while(_receivedBuffer.bytesAvailable){
						_receivedBytes.push(_receivedBuffer.readUnsignedByte());
					}
	//				trace(bytes)
					try{
						_receiveHandlers(_receivedBytes);
					}catch(e:Error){
						trace(e.getStackTrace());
					}
				}
				_receivedBuffer.clear();
			}
		}
	}
}