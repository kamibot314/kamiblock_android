package util{
	import flash.display.Stage;
	import flash.filesystem.File;
	import flash.system.Capabilities;

	public class ApplicationManager{
		public function ApplicationManager():void{

		}
		public static const WINDOWS:uint = 1;
		public static const MAC_OS:uint = 2;
		private static var _instance:ApplicationManager;
		public var launchTime:uint = 0;
		public var contractedOffsetX:int = -480;
		public var contractedOffsetY:int = 0;
		public var isCatVersion:Boolean = false;
		
		public static var isIOS:Boolean = (Capabilities.manufacturer.indexOf("iOS") != -1);
		public static var isAndroid:Boolean = (Capabilities.manufacturer.indexOf("Android") != -1);
		
		private var _scale:Number = 1.0;
		
		public static function sharedManager():ApplicationManager{
			if(_instance==null){
				_instance = new ApplicationManager;
			}
			return _instance;
		}
		private var _file:File;
		/*public function get documents():File{
			if(_file==null){
				try{
					_file = File.documentsDirectory;
				}catch(err:Error){
					_file = File.applicationStorageDirectory;
				}
			}
			return _file;
		}*/
		public function get system():uint{
			if(Capabilities.os.indexOf("Window")>-1){
				return 1;
			}
			return 2;
		}
		
		public function get isTable():Boolean{
			return true;
		}
		
		public function get isPhone():Boolean{
			return false;
		}
		
		public function set stage(stage:Stage):void{
			
//			_scale = stage.width / 500;
//			_scale = stage.width / 700;
//			_scale = stage.width / 1000;
			
//			_scale = 0.8;//DEBUG
			_scale = stage.fullScreenWidth / 700;
		}
		
		public function get scale():Number{
			return _scale;
		}
	}
}