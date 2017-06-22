package extension2
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	
	public class ArudinoUploader extends EventDispatcher
	{
		private static var instance:ArudinoUploader;
		
		public static function getInstance(workingDir:File = null):ArudinoUploader{
			if (instance == null) {
				instance = new ArudinoUploader();
			}
			return instance;
		}
		
		public function upload(sdkDirectory:File, mcu:Object, port:String, hexFile:File):void
		{
			trace("ArudinoUploader upload");
			var avrdude:File = sdkDirectory.resolvePath(".\\hardware\\tools\\avr\\bin\\avrdude.exe");
			var avrdudeConf:File = sdkDirectory.resolvePath(".\\hardware\\tools\\avr\\etc\\avrdude.conf");
			
			var process:NativeProcess = new NativeProcess;
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			process.addEventListener(IOErrorEvent.STANDARD_OUTPUT_IO_ERROR, onIOError);
			process.addEventListener(IOErrorEvent.STANDARD_ERROR_IO_ERROR, onIOError);
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = avrdude;
			var v:Vector.<String> = new Vector.<String>();
			v.push("-C" + avrdudeConf.nativePath);
			v.push("-q");
			v.push("-q");
			
			v.push("-p" + mcu.mcu);
			v.push("-c" + mcu.protocol);
			v.push("-P" + port);
			v.push("-b" + mcu.speed);
			
			v.push("-D");
			
			v.push("-Uflash:w:"+hexFile.nativePath+":i");
			
			startupInfo.arguments = v;
			try
			{
				Main.app.scriptsPart.appendMessage("Start: " + avrdude.nativePath);
				Main.app.scriptsPart.appendMessage("Paramater : " + v.toString());
				Main.app.scriptsPart.appendMessage(hexFile.nativePath + " Upload to : " + port);
				process.start(startupInfo); 
			}
			catch (error:Error)
			{
				Main.app.scriptsPart.appendMessage("Failed to run avrdude");
			}
			
			function onOutputData(event:ProgressEvent):void
			{
				Main.app.scriptsPart.appendMessage(process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"euc-kr"));
			}
			
			function onErrorData(event:ProgressEvent):void
			{
				Main.app.scriptsPart.appendMessage("ERROR -" + process.standardOutput.readMultiByte(process.standardOutput.bytesAvailable,"euc-kr")); 
			}
			
			function onExit(event:NativeProcessExitEvent):void
			{
				Main.app.scriptsPart.appendMessage("avrdude.exe Process exited with " + event.exitCode);
				Main.app.scriptsPart.appendMessage(hexFile.nativePath);
				var buildDir:File = File.applicationStorageDirectory.resolvePath("build");
				//if (buildDir.exists) buildDir.deleteDirectory(true);
				if (event.exitCode == 0) Main.app.scriptsPart.appendMessage("upload success");
				else Main.app.scriptsPart.appendMessage("upload failure");
				dispatchEvent(new Event(Event.COMPLETE));
			}
			
			function onIOError(event:IOErrorEvent):void
			{
				Main.app.scriptsPart.appendMessage(event.toString());
			}
		}
	}
}