package extensions
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	
	import util.LogManager;
	
	public class JavaScriptEngine
	{
		private var _timer:Timer = new Timer(1000);
		private var _name:String = "";
		public var port:String = "";
		public var device:SerialDevice;
		
		
		private var idDict:Array = [];
		private var _rxBuf:Array = [];
		private var values:Object = new Object();
		private var indexs:Array = [];
		
		
		private var startTimer:uint = 0;
		private var versionIndex:uint = 0xFA;
		
		private var pins:Object = {
			"LEFT_MOTOR_SPEED_PIN":19,
			"LEFT_MOTOR_DIR1_PIN":21,
			"LEFT_MOTOR_DIR2_PIN":20,
			"RIGHT_MOTOR_SPEED_PIN":24,
			"RIGHT_MOTOR_DIR1_PIN":22,
			"RIGHT_MOTOR_DIR2_PIN":23,
			"IR_LEFT1_PIN":16,
			"IR_LEFT2_PIN":26,
			"IR_CENTER_PIN":5,
			"IR_RIGHT2_PIN":17,
			"IR_RIGHT1_PIN":4,
			"IR_SENSOR_ON":3,
			"RGB_RED_PIN":11,
			"RGB_GREEN_PIN":27,
			"RGB_BLUE_PIN":6,
			"UTRASONIC_TRIG_PIN":10,
			"UTRASONIC_ECHO_PIN":12,
			"SERVO_MOTOR_PIN":7,
			"BUZZER_PIN":13,
			"BATTERY_PIN":"A0"
		};
		
		private var colors:Object = {
			"Red":4,
			"Pink":5,
			"Blue":1,
			"Green":2,
			"Sky Blue":3,
			"Yellow":6
		};
		
		private var tones:Object = {"B0":31,"C1":33,"D1":37,"E1":41,"F1":44,"G1":49,"A1":55,"B1":62,
			"C2":65,"D2":73,"E2":82,"F2":87,"G2":98,"A2":110,"B2":123,
			"C3":131,"D3":147,"E3":165,"F3":175,"G3":196,"A3":220,"B3":247,
			"C4":262,"D4":294,"E4":330,"F4":349,"G4":392,"A4":440,"B4":494,
			"C5":523,"D5":587,"E5":659,"F5":698,"G5":784,"A5":880,"B5":988,
			"C6":1047,"D6":1175,"E6":1319,"F6":1397,"G6":1568,"A6":1760,"B6":1976,
			"C7":2093,"D7":2349,"E7":2637,"F7":2794,"G7":3136,"A7":3520,"B7":3951,
			"C8":4186,"D8":4699};
		
		private var beats:Object = {"Whole":1000,"Half":500,"Quater":250,"Eighth":125,"Zero":0};
		private var direction:Object = {
			"forward":0,
			"backward":1
		}
		
		public function JavaScriptEngine(name:String="")
		{
			_name = name;
			_timer.addEventListener(TimerEvent.TIMER,onTimer);
			ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
			ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnected);
			ConnectionManager.sharedManager().addEventListener(Event.REMOVED,onRemoved);
			ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClosed);
		}
		
		private function onTimer(evt:TimerEvent):void{
			LogManager.sharedManager().log("Status:"+getStatus());
		}
		
		public function register(name:String,descriptor:Object,ext:Object,param:Object):void{
			LogManager.sharedManager().log("registed:"+getStatus());
			
		}
		public function get connected():Boolean{
			return SerialManager.sharedManager().connected;
		}
		
		public function get msg():String{
			return getStatus();
		}
		
		public function call(method:String,param:Array,ext:ScratchExtension):void{
//			trace("call method = " + method);
			if(!this.connected){
				return;
			}
			try {
				switch(param.length){
					case 0:{
						this[method]();
						break;
					}
					case 1:{
						this[method](param[0]);
						break;
					}
					case 2:{
						this[method](param[0],param[1]);
						break;
					}
					case 3:{
						this[method](param[0],param[1],param[2]);
						break;
					}
					case 4:{
						this[method](param[0],param[1],param[2],param[3]);
						break;
					}
					case 5:{
						this[method](param[0],param[1],param[2],param[3],param[4]);
						break;
					}
					case 6:{
						this[method](param[0],param[1],param[2],param[3],param[4],param[5]);
						break;
					}
				}
			} catch(e:Error) {
				trace(e.getStackTrace());
			}
		}
		
		public function requestValue(method:String,param:Array,ext:ScratchExtension):Boolean{
			if(!this.connected){
				return false;
			}
			getValue(method,[ext.nextID].concat(param),ext);
//			Main.app.extensionManager.reporterCompleted(ext.name,ext.nextID,v);
			return true;
		}
		
		public function getValue(method:String,param:Array,ext:ScratchExtension):*{
			trace("getValue method = " + method);
			if(!this.connected){
				return false;
			}
			var v:*;
			for(var i:uint=0;i<param.length;i++){
				param[i] = ext.getValue(param[i]);
			}
			switch(param.length){
				case 0:{
					v = this[method]();
					break;
				}
				case 1:{
					v = this[method](param[0]);
					break;
				}
				case 2:{
					v = this[method](param[0],param[1]);
					break;
				}
				case 3:{
					v = this[method](param[0],param[1],param[2]);
					break;
				}
				case 4:{
					v = this[method](param[0],param[1],param[2],param[3]);
					break;
				}
				case 5:{
					v = this[method](param[0],param[1],param[2],param[3],param[4]);
					break;
				}
				case 6:{
					v = this[method](param[0],param[1],param[2],param[3],param[4],param[5]);
					break;
				}
			}
			return v;
		}
		
		private function onConnected(evt:Event):void{
			trace("JavaScriptEngine onConnected");
			device = SerialDevice.sharedDevice();
			device.set_receive_handler('kamibot',processData);
			LogManager.sharedManager().log("register:"+_name);
		}
		
		private function onClosed(evt:Event):void{
			trace("JavaScriptEngine onClosed");
			var dev:SerialDevice = SerialDevice.sharedDevice();
			
			deviceRemoved(dev);
			LogManager.sharedManager().log("unregister:"+_name);
			
			if(device) SerialManager.sharedManager().close();
			device = null;
		}
		
		private function onRemoved(evt:Event):void{
			trace("JavaScriptEngine onRemoved");
			if(ConnectionManager.sharedManager().extensionName==_name){
				ConnectionManager.sharedManager().removeEventListener(Event.CONNECT,onConnected);
				ConnectionManager.sharedManager().removeEventListener(Event.REMOVED,onRemoved);
				ConnectionManager.sharedManager().removeEventListener(Event.CLOSE,onClosed);
				var dev:SerialDevice = SerialDevice.sharedDevice();
				deviceRemoved(dev);
			}
		}
		
		private function uncaughtScriptExceptionHandler(evt:Event):void{
			
		}
		
		public function log(l:String):void {
			trace(l);
		}
		
		public function responseValue(extId:uint,value:*):void{
			Main.app.extensionManager.reporterCompleted(_name,extId,value);
			ConnectionManager.sharedManager().setState(ConnectionManager.SEND);
		}
		
		public function readFloat(bytes:Array):Number{
			var buffer:ByteArray = new ByteArray();
			buffer.endian = Endian.LITTLE_ENDIAN;
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			if(buffer.length>=4){
				buffer.position = 0;
				var f:Number = buffer.readFloat();
				f = Number(f.toFixed(2));
				buffer.clear();
				return f;
			}
			return 0;
		}
		
		public function readDouble(bytes:Array):Number{
			return readFloat(bytes);
		}
		
		public function readShort(bytes:Array):Number{
			var buffer:ByteArray = new ByteArray();
			buffer.endian = Endian.LITTLE_ENDIAN;
			for(var i:uint=0;i<bytes.length;i++){
				buffer.writeByte(bytes[i]);
			}
			if(buffer.length>=2){
				buffer.position = 0;
				var v:Number = buffer.readUnsignedShort();
				buffer.clear();
				return v;
			}
			return 0;
		}
		
		public function float2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeFloat(v);
			var array:Array = [buffer[0],buffer[1],buffer[2],buffer[3]];
			buffer.clear();
			return array;
		}
		
		public function short2array(v:Number):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.endian = Endian.LITTLE_ENDIAN;
			buffer.writeShort(v);
			var array:Array = [buffer[0],buffer[1]];
			buffer.clear();
			return array;
		}
		
		public function string2array(v:String):Array{
			var buffer:ByteArray = new ByteArray;
			buffer.writeUTFBytes(v);
			var array:Array = [];
			for(var i:uint=0;i<buffer.length;i++){
				array[i] = buffer[i];
			}
			buffer.clear();
			return array;
		}
		
		private function resetAll():void {
			
			try {
				var bytes:Array = [];
				bytes.push(0xff);
				bytes.push(0x55);
				bytes.push(0x02);
				bytes.push(0x00);
				bytes.push(0x04);
				device.send(bytes);
			} catch (e:Error) {
				trace(e.getStackTrace());
			}
		}
		
		private function runMoveForward(speed):void{
			runPackage(90,speed);
		}
		
		private function runMoveForwardBalanced(speed1,speed2):void{
			runPackage(96,speed1,speed2);
		}
		
		private function runMoveLeft(speed):void{
			runPackage(91,speed);
		}
		
		private function runMoveRight(speed):void{
			runPackage(92,speed);
		}
		
		private function runMoveBackward(speed):void{
			runPackage(93,speed);
		}
		
		private function runMoveBackwardBalanced(speed1,speed2):void{
			runPackage(97,speed1,speed2);
		}
		
		private function runStop():void{
			runPackage(94);
		}
		
		private function runBlockMove(count:uint):void{
			trace("runBlockMove");
			runPackage2(100,count);
		}
		
		private function runBlockTurnLeft():void{
			runPackage2(101);
		}
		
		private function runBlockTurnRight():void{
			runPackage2(102);
		}
		
		private function runBlockTurnBack():void{
			runPackage2(103);
		}
		
		private function setRGbLed(rgb):void {
			
			if (typeof rgb != "string") rgb = 0;
			else rgb = colors[rgb];
			runPackage(95,rgb);
		}
		
		private function runRotateLeftMoter(dir, speed):void{
			runPackage(98, direction[dir], speed);
		}
		
		private function runRotateRightMoter(dir, speed):void{
			runPackage(99, direction[dir], speed);
		}
		
		private function runServo(angle):void {
			//2016/12/23 이승훈
			runPackage(33,pins["SERVO_MOTOR_PIN"],180-angle);
		}
		
		private function runTone(tone,beat):void {
			runPackage(34,pins["BUZZER_PIN"],short2array(typeof tone=="number"?tone:tones[tone]),short2array(typeof beat=="number"?beat:beats[beat]));
		}
		
		private function getBattery(nextID:uint):void {
			var deviceId:uint = 31;
			nextID = genNextID(nextID, [pins["BATTERY_PIN"]]);
			getPackage(nextID,deviceId,pins["BATTERY_PIN"]);
		}
		
		private function getUltraSonic(nextID:uint):void {
			var deviceId:uint = 1;
			nextID = genNextID(nextID, [pins["UTRASONIC_TRIG_PIN"],pins["UTRASONIC_ECHO_PIN"]]);
			getPackage(nextID,deviceId,pins["UTRASONIC_TRIG_PIN"],pins["UTRASONIC_ECHO_PIN"]);
		}
		
		private function getIR(nextID:uint, pin:uint):void {
			var deviceId:uint = 13;
			nextID = genNextID(nextID, [pin]);
			getPackage(nextID,deviceId,pin);
		}
		
		private function deviceRemoved(dev:SerialDevice):void {
			if(device != dev) return;
			device = null;
		}
		
		private function genNextID(realId, args):uint {
			var nextID:uint = (((args[0] << 4) | args[1]) % 0xff);
			idDict[nextID] = realId;
			return nextID;
		}
		
		private function getStatus():String {
			if(!device) return 'KamiBot disconnected';
			return 'KamiBot connected';
		}
		
		private function runPackage(... args):void{
			var bytes:Array = [];
			bytes.push(0xff);
			bytes.push(0x55);
			bytes.push(0x00);
			bytes.push(0x00);
			bytes.push(0x02);
			for(var i:int=0;i<args.length;i++){
				if(args[i].constructor == "[class Array]"){
					bytes = bytes.concat(args[i]);
				}else{
					bytes.push(args[i]);
				}
			}
			bytes[2] = bytes.length-3;
			
			try {
				device.send(bytes);
			} catch (e:Error) {
				trace(e.getStackTrace());
			}
		}
		
		private function runPackage2(... args):void{
			var bytes:Array = [];
			bytes.push(0xff);
			bytes.push(0x55);
			bytes.push(0x00);
			bytes.push(0x00);
			bytes.push(0x02);
			for(var i:int=0;i<args.length;i++){
				if(args[i].constructor == "[class Array]"){
					bytes = bytes.concat(args[i]);
				}else{
					bytes.push(args[i]);
				}
			}
			bytes[2] = bytes.length-3;
			
			try {
				device.send(bytes, true);
			} catch (e:Error) {
				trace(e.getStackTrace());
			}
		}
		
		private var getPackDict:Array = [];
		private function resetPackDict(nextID):void{
			getPackDict[nextID] = false;
		}
		
		private function getPackage(... args):void{
			var nextID:int = args[0];
//			if(getPackDict[nextID]){
//				return;
//			}
//			getPackDict[nextID] = true;
//			setTimeout(resetPackDict, 0, nextID);
			var bytes:Array = [0xff, 0x55];
			bytes.push(args.length+1);
			bytes.push(nextID);
			bytes.push(1);
			for(var i:int=1;i<args.length;i++){
				bytes.push(args[i]);
			}
			try {
				device.send(bytes);
			} catch (e:Error) {
				trace(e.getStackTrace());
			}
		}
		
		private var inputArray:Array = [];
		private var _isParseStart:Boolean = false;
		private var _isParseStartIndex:int = 0;
		private function processData(bytes):void {
			var len:int = bytes.length;
			if(_rxBuf.length>30){
				_rxBuf = [];
			}
			for(var index:int=0;index<bytes.length;index++){
				var c:int = bytes[index];
				_rxBuf.push(c);
				if(_rxBuf.length>=2){
					if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
						_isParseStart = true;
						_isParseStartIndex = _rxBuf.length-2;
					}
					if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
						_isParseStart = false;
						
						var position:int = _isParseStartIndex+2;
						var extId:int = _rxBuf[position];
						position++;
						var type:int = _rxBuf[position];
						position++;
						//1 byte 2 float 3 short 4 len+string 5 double
						var value:*;
						switch(type){
							case 1:{
								value = _rxBuf[position];
								position++;
							}
							break;
							case 2:{
								value = _readFloat(_rxBuf,position);
								position+=4;
								if(value<-255||value>1023){
									value = 0;
								}
							}
							break;
							case 3:{
								value = _readShort(_rxBuf,position);
								position+=2;
							}
							break;
							case 4:{
								var l:int = _rxBuf[position];
								position++;
								value = _readString(_rxBuf,position,l);
							}
							break;
							case 5:{
								value = _readDouble(_rxBuf,position);
								position+=4;
							}
							break;
						}
						if(type<=5){
							extId = idDict[extId];
							if(values[extId]!=undefined){
								responseValue(extId,values[extId](value));
							}else{
								responseValue(extId,value);
							}
							values[extId] = null;
						}
						_rxBuf = [];
					}
				} 
			}
		}
		
		private function _readFloat(arr,position):Number{
			var f:Array = [arr[position],arr[position+1],arr[position+2],arr[position+3]];
			return readFloat(f);
		}
		
		private function _readShort(arr,position):uint{
			var s:Array = [arr[position],arr[position+1]];
			return readShort(s);
		}
		
		private function _readDouble(arr,position):Number{
			return _readFloat(arr,position);
		}
		
		private function _readString(arr,position,len):String{
			var value:String = "";
			for(var ii:int=0;ii<len;ii++){
				value += String.fromCharCode(_rxBuf[ii+position]);
			}
			return value;
		}
		private function appendBuffer( buffer1:String, buffer2:String ):String {
			return buffer1.concat( buffer2 );
		}
	}
}