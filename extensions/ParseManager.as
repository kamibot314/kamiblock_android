package extensions
{
	import flash.events.TimerEvent;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;

	public class ParseManager
	{
		private static var _instance:ParseManager;
		private var _rxBuf:ByteArray = new ByteArray;
		private var _lineBuf:ByteArray = new ByteArray;
		private var _lines:Array = [];
		private var _cmds:Object = {};
		
		private var _firmVersion:String = "";
		public var extVersion:Array = [];
		private var versionIndex:uint = 0xFA;
		
		private var _isParseStart:Boolean = false;
		private var _isParseStartIndex:uint = 0;
		private var _timeoutTimer:Timer = new Timer(3000);
		public var extNames:Object = {};
		
		public function ParseManager()
		{
			_rxBuf.endian = Endian.LITTLE_ENDIAN;
		}
		
		public static function sharedManager():ParseManager{
			if(_instance==null){
				_instance = new ParseManager;
			}
			return _instance;
		}
		
		public function get connected():Boolean{
			if(SerialManager.sharedManager().connected){
				return true;
			}
			return false;
		}
		
		public function queryVersion():void{
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.writeByte(0xff);
			bytes.writeByte(0x55);
			bytes.writeByte(0x3);
			bytes.writeByte(versionIndex);
			bytes.writeByte(0x1);
			bytes.writeByte(0x0);
			ConnectionManager.sharedManager().sendBytes(bytes);
			
			trace("query version");
//			_queryTimer.start();
		}
		
//		public function queryVersion():void{
//			reset();
//			start();
//			var bytes:ByteArray = new ByteArray;
//			bytes.endian = Endian.LITTLE_ENDIAN;
//			bytes.writeByte(0xff);
//			bytes.writeByte(0x55);
//			bytes.writeByte(3);
//			bytes.writeByte(versionIndex);
//			bytes.writeByte(0x1);
//			bytes.writeByte(0x0);
//			sendBytes(bytes);
//			trace("queryVersion");
//			reset();
//		}
//		public function start():void{
//			var bytes:ByteArray = new ByteArray;
//			bytes.endian = Endian.LITTLE_ENDIAN;
//			bytes.writeByte(0xff);
//			bytes.writeByte(0x55);
//			bytes.writeByte(0x02);
//			bytes.writeByte(0x00);
//			bytes.writeByte(0x05);
//			sendBytes(bytes);
//			trace("start");
//		}
//		
//		public function reset():void{
//			var bytes:ByteArray = new ByteArray;
//			bytes.endian = Endian.LITTLE_ENDIAN;
//			bytes.writeByte(0xff);
//			bytes.writeByte(0x55);
//			bytes.writeByte(0x02);
//			bytes.writeByte(0x00);
//			bytes.writeByte(0x04);
//			sendBytes(bytes);
//			trace("reset");
//		}
		
		public function isFirmVersionDetected():Boolean {
			return (_firmVersion == "");
		}
		
		public function clearFirmVersion():void{
			_firmVersion = "";
		}
		
		public function get firmVersion():String {
			return _firmVersion;
		}
		
//		private function onQueryVersion(evt:TimerEvent):void{
//			var bytes:ByteArray = new ByteArray;
//			bytes.endian = Endian.LITTLE_ENDIAN;
//			bytes.writeByte(0xff);
//			bytes.writeByte(0x55);
//			bytes.writeByte(0x3);
//			bytes.writeByte(versionIndex);
//			bytes.writeByte(0x1);
//			bytes.writeByte(0x0);
////			bytes.writeByte(0xa);
//			sendBytes(bytes);
//			trace("query version");
//		}
		
		
		public function parseFirmVersion(bytes:ByteArray):void
		{/*
			var _rxBuf:ByteArray = new ByteArray();
			if (bytes.length <= 3) return;
			
			if (bytes[0] == 0xff && bytes[1] == 0x55 &&  bytes[2] == versionIndex && bytes[3] == 0x04) {
				for (var idx:Number = 5; idx < bytes[4] + 5; idx++) {
					_rxBuf.writeByte(bytes[idx]);
				}
//				var value:String;
//				for(var ii:uint=0;ii<_rxBuf.length;ii++){
//					value += String.fromCharCode(_rxBuf[ii+_rxBuf.position]);
//				}
				_firmVersion = _rxBuf.toString();
				_timeoutTimer.stop();
				Main.app.topBarPart.updateVersion();
			}*/
		}
		
//		public function onReceived(bytes:ByteArray):void{
//			try{
//				bytes.position = 0;
//				var len:uint = bytes.length;
//				if(_rxBuf.length>30){
//					_rxBuf.clear();
//				}
//				for(var index:uint=0;index<bytes.length;index++){
//					var c:uint = bytes[index];
//					_rxBuf.writeByte(c);
//					if(c==0xd||c==0xa){
//						if(_lineBuf.position>0){
//							_lineBuf.position = 0;
//							var s:String = unescape(_lineBuf.readUTFBytes(_lineBuf.length));
//							_lines.push(s);
//							var cmds:Array = s.split("=");//.push(s);
//							if(s.length>1){
//								for(var i:uint=0;i<s.length/2;i++){
//									_cmds[cmds[i*2]]=cmds[i*2+1];
//								}
//							}
//							_lineBuf.clear();
//						}
//					}else{
//						_lineBuf.writeByte(c);
//					}
//					
//					if(_rxBuf.length>=2){
//						if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
//							_isParseStart = true;
//							_isParseStartIndex = _rxBuf.length-2;
//						}
//						if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
//							_isParseStart = false;
//							_rxBuf.position = _isParseStartIndex+2;
//							var extId:int = _rxBuf.readUnsignedByte();
//							var type:int = _rxBuf.readUnsignedByte();
//							//1 byte 2 float 3 short 4 len+string 5 double
//							var value:*;
//							switch(type){
//								case 1:{
//									value = _rxBuf.readUnsignedByte();
//								}
//									break;
//								case 2:{
//									value = _rxBuf.readFloat();
//									if(value<-255||value>1023){
//										value = 0;
//									}
//									value = Math.round(value*10)/10;
//								}
//									break;
//								case 3:{
//									value = _rxBuf.readShort();
//								}
//									break;
//								case 4:{
//									var l:uint = _rxBuf.readUnsignedByte();
//									try{
//										value = "";
//										for(var ii:uint=0;ii<l;ii++){
//											value += String.fromCharCode(_rxBuf[ii+_rxBuf.position]);
//										}
//									}catch(err:Error){
//										value = "";
//									}
//								}
//									break;
//								case 5:{
//									value = _rxBuf.readDouble();
//								}
//									break;
//							}
//							if(extId==versionIndex){
//								firmVersion = value;
//								_queryTimer.stop();
//							}
//						}
//					} //end of parser
//				} // end of while read
//			}catch(e){
//				trace(e);
//			}
//		}
//		
//		private function onQueryComplete(evt:TimerEvent):void{
//			MBlock.app.topBarPart.updateVersion();
//		}
		
		//2017/06/02 프로토콜 변경 파서부분
		public function parseEncode(url:String,encode:String,nextID:int,args:*,ext:ScratchExtension):void{
//			SerialManager.sharedManager().update();
			encode = substitute(encode,args,ext);
			var bytes:ByteArray = new ByteArray;
			bytes.endian = Endian.LITTLE_ENDIAN;
			bytes.writeByte(0xff);
			bytes.writeByte(0x55);
			bytes.writeByte(0);
			bytes.writeByte(nextID);
			var actions:Array = url.split("/");
			var params:Array = encode.split("{").join("").split("}");
			params.splice(-1,1);
			for(var i:uint = 0; i < actions.length-args.length;i++){
				bytes.writeByte(ext.values[actions[i]]);
			}
			for(i=0;i<params.length;i++){
				var s:String = params[i];
				var fmt:String = s.substr(0,1);
				var idx:int = Number(s.substr(1,s.length-1));
				var v:* = ext.getValue(args[idx]);
				if(fmt=="d"){
					bytes.writeByte(v);
				}else if(fmt=="s"){
					bytes.writeShort(v);
				}else if(fmt=="m"){
					bytes.writeUTFBytes(v);
				}else if(fmt=="n"){
					bytes.writeByte(idx);
				}else if(fmt=="f"){
					bytes.writeFloat(v);
				}
			}
			bytes[2] = bytes.length-3;
			bytes.writeByte(0xa);
			bytes.position = 0;
//			s = "";
//			for(i=0;i<bytes.length;i++){
//				s += ("0x"+bytes[i].toString(16))+" ";
//			}
//			trace(s);
//			trace("---------------------------------------");
//			bytes.position = 0;
			sendBytes(bytes);
		}
		private function substitute(str:String,params:Array,ext:ScratchExtension):String{
			var bytes:ByteArray = new ByteArray();
			for(var i:uint=0;i<params.length;i++){
				var o:* = params[i];
				var v:* = ext.values[o];
				var s:* = ext==null?params[i]:((v==null||v==undefined)?params[i]:v);
				var ts:String = "";
				try{
					var j:uint;
					if(isNaN(Number(s))){
						for(j=0;j<s.length;j++){
							ts += ("00"+s.charCodeAt(j).toString(16)).substr(-2,2);
						}
					}else{
						bytes.clear();
						bytes.writeShort(Number(s));
						for(j=0;j<bytes.length;j++){
							ts += ("00"+(bytes[j].toString(16))).substr(-2,2);
						}
					}
				}catch(e:Error){
					
				}
				str = str.split("{"+i+"}").join(ts);
			}
			return str;
		}
		public function parse(url:String):void{
			//SerialManager.sharedManager().update();
			//SocketManager.sharedManager().update();
//			if(url.indexOf("serial")>-1){
//				var c:Array = url.split("/");
//				var buf:ByteArray = new ByteArray();
//				if(url.indexOf("line")>-1){
//					buf.writeUTFBytes(c[c.length-1]+"\r\n");
//					this.sendBytes(buf);
//				}else if(url.indexOf("command")>-1){
//					buf.writeUTFBytes(c[c.length-2]+"/"+c[c.length-1]+"\r\n");
//					this.sendBytes(buf);
//				}else if(url.indexOf("clear")>-1){
//					_lines = [];
//					_cmds = {};
//				}
//				return;
//			}
//			var bytes:ByteArray = new ByteArray;
//			bytes.endian = Endian.LITTLE_ENDIAN;
//			bytes.writeByte(0xff);
//			bytes.writeByte(0x55);
//			if(url=="resetAll"){
//				bytes.writeByte(0x2);
//				bytes.writeByte(0x0);
//				bytes.writeByte(0x4);
//				bytes.writeByte(0xa);
//				bytes.writeByte(0xd);
//				_lines = [];
//				_cmds = {};
//			}else if(url=="start"){
//				bytes.writeByte(0x2);
//				bytes.writeByte(0x0);
//				bytes.writeByte(0x5);
//				bytes.writeByte(0xa);
//				bytes.writeByte(0xd);
//			}
//			sendBytes(bytes);
		}
		
		public function sendBytes(bytes:ByteArray):void{
			if(SerialManager.sharedManager().connected){
				SerialDevice.sharedDevice().sendBytes(bytes);
			}
		}
		
//		public function parseBuffer(bytes:ByteArray):void{
////			if(bytes.length>2){
////				var dbgStr:String = "Rx:";
////				for(var i:uint=0;i<bytes.length;i++){
////					dbgStr+=bytes[i].toString(16);
////					dbgStr+=" ";
////				}
////				trace(dbgStr);
//////				return;
////			}
//			if(ArduinoUploader.sharedManager().parseCmd(bytes)){
//				return;
//			}
//			try{
//				bytes.position = 0;
//				var len:uint = bytes.length;
//				if(_rxBuf.length>30){
//					_rxBuf.clear();
//				}
//				for(var index:uint=0;index<bytes.length;index++){
//					var c:uint = bytes[index];
//					_rxBuf.writeByte(c);
//					if(c==0xd||c==0xa){
//						if(_lineBuf.position>0){
//							_lineBuf.position = 0;
//							var s:String = unescape(_lineBuf.readUTFBytes(_lineBuf.length));
//							_lines.push(s);
//							var cmds:Array = s.split("=");//.push(s);
//							if(s.length>1){
//								for(var i:uint=0;i<s.length/2;i++){
//									_cmds[cmds[i*2]]=cmds[i*2+1];
//								}
//							}
//							_lineBuf.clear();
//						}
//					}else{
//						_lineBuf.writeByte(c);
//					}
//					
//					if(_rxBuf.length>=2){
//						if(_rxBuf[_rxBuf.length-1]==0x55 && _rxBuf[_rxBuf.length-2]==0xff){
//							_isParseStart = true;
//							_isParseStartIndex = _rxBuf.length-2;
//						}
//						if(_rxBuf[_rxBuf.length-1]==0xa && _rxBuf[_rxBuf.length-2]==0xd&&_isParseStart){
//							_isParseStart = false;
//							_rxBuf.position = _isParseStartIndex+2;
//							var extId:int = _rxBuf.readUnsignedByte();
//							var type:int = _rxBuf.readUnsignedByte();
//							//1 byte 2 float 3 short 4 len+string 5 double
//							var value:*;
//							switch(type){
//								case 1:{
//									value = _rxBuf.readUnsignedByte();
//								}
//									break;
//								case 2:{
//									value = _rxBuf.readFloat();
//									if(value<-255||value>1023){
//										value = 0;
//									}
//									value = Math.round(value*10)/10;
//								}
//									break;
//								case 3:{
//									value = _rxBuf.readShort();
//								}
//									break;
//								case 4:{
//									var l:uint = _rxBuf.readUnsignedByte();
//									try{
//										value = "";
//										for(var ii:uint=0;ii<l;ii++){
//											value += String.fromCharCode(_rxBuf[ii+_rxBuf.position]);
//										}
//									}catch(err:Error){
//										value = "";
//									}
//								}
//									break;
//								case 5:{
//									value = _rxBuf.readDouble();
//								}
//									break;
//							}
//							if(extId==versionIndex){
//								firmVersion = value;
//								MBlock.app.topBarPart.updateVersion();
//								_queryTimer.stop();
//							}else{
//								MBlock.app.extensionManager.reporterCompleted(extNames[extId],extId,value);
//							}
//							MBlock.app.runtime.exitRequest();
//							_rxBuf.clear();
//						}
//					} //end of parser
//					else{
//						
//					}
//				} // end of while read
//			}catch(e){
//				trace(e);
//			}
//		}
		public function get lines():Array{
			return _lines;
		}
		public function getFirstLine():String{
			return _lines.length>0?_lines.shift():"";
		}
		public function getCommand(cmd:String):String{
			var s:String = _cmds[cmd];
			delete _cmds[cmd];
			return s;
		}
	}
}