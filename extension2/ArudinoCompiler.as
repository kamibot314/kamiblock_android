package extension2
{
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;

	public class ArudinoCompiler extends EventDispatcher
	{
		
		private static var instance:ArudinoCompiler;
		private var selectedFile:File;
		public var isUploading:Boolean = false;
		private var compileErr:Boolean = false;
		private var process:NativeProcess;

		private var _hexFile:File;
		
		public static  function getInstance():ArudinoCompiler{
			if(instance==null){
				instance = new ArudinoCompiler();
			}
			return instance;
		}
		
		public function complie(sdkDirectory:File, selectedFile:File, boardCodeName:String, mcu:String):void
		{
			trace("ArudinoCompiler complie");
			isUploading = false;
			compileErr = false;
			this.selectedFile = selectedFile;
			
			var buildDir:File = File.applicationStorageDirectory.resolvePath("build");
			if (buildDir.exists) buildDir.deleteDirectory(true);
			buildDir.createDirectory();
			
			var arduinoBuilder:File = sdkDirectory.resolvePath("arduino-builder.exe");
			var hardwareDirectory:File = sdkDirectory.resolvePath(".\\hardware\\");
			var tools1Directory:File = sdkDirectory.resolvePath(".\\tools-builder\\");
			var tools2Directory:File = sdkDirectory.resolvePath(".\\hardware\\tools\\avr\\");
			var builtInextDirectory:File = sdkDirectory.resolvePath(".\\libraries\\");
			var extDirectory:File = sdkDirectory.resolvePath(".\\libraries\\");
			var buildPath:File = buildDir;
			
			process = new NativeProcess;
			process.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, onErrorData);
			process.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, onOutputData);
			process.addEventListener(NativeProcessExitEvent.EXIT, onExit);
			
			var startupInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			startupInfo.executable = arduinoBuilder;
			var v:Vector.<String> = new Vector.<String>();
			
			v.push("-compile");
			v.push("-logger=machine");
			
			v.push("-hardware");
			v.push(hardwareDirectory.nativePath);
			
			v.push("-tools");
			v.push(tools1Directory.nativePath);
			
			v.push("-tools");
			v.push(tools2Directory.nativePath);
			
			v.push("-built-in-libraries");
			v.push(builtInextDirectory.nativePath);
			
			v.push("-libraries");
			v.push(extDirectory.nativePath);
			
			v.push("-fqbn=arduino:avr:" + boardCodeName + ":cpu=" + mcu);
			
			v.push("-build-path");
			v.push(buildDir.nativePath);
			
			v.push("-warnings=null");
			v.push("-prefs=build.warn_data_percentage=75");
			v.push(selectedFile.nativePath);
			
			startupInfo.arguments = v;
			try
			{
				Main.app.scriptsPart.appendMessage("Start: " + arduinoBuilder.nativePath);
				Main.app.scriptsPart.appendMessage("Paramater : " + v.toString());
				Main.app.scriptsPart.appendMessage(selectedFile.nativePath + " Compile to : " + buildDir.nativePath);
				process.start(startupInfo);
			}
			catch (error:Error)
			{
				Main.app.scriptsPart.appendMessage("Failed to run arduinoBuilder");
			}
		}
		
		private function onOutputData(event:ProgressEvent):void 
		{ 
			/*isUploading = true;
			var output:String = process.standardOutput.readUTFBytes(process.standardOutput.bytesAvailable)
			var date:Date = new Date;
			MBlock.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": Got: "+output); */
		}
		
		private function onErrorData(event:ProgressEvent):void
		{
			isUploading = false;
			compileErr = true;
			var errOut:String = process.standardError.readUTFBytes(process.standardError.bytesAvailable);
			var date:Date = new Date;
			Main.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": ####Error####\n"+errOut)
		}
		
		private function onExit(event:NativeProcessExitEvent):void
		{
			trace("ArudinoCompiler onExit compileErr = " + compileErr);
			isUploading = false;
			var date:Date = new Date;
			
			Main.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": Process exited with "+event.exitCode);
			
			_hexFile = File.applicationStorageDirectory.resolvePath("build").resolvePath( selectedFile.name + ".hex");
			if(compileErr) {
				Main.app.scriptsPart.appendMessage(""+(date.month+1)+"-"+date.date+" "+date.hours+":"+date.minutes+": Sorry, catch compile error! complie is abort.");
			} else {
				dispatchEvent(new Event(Event.COMPLETE));
				trace("ArudinoCompiler Event.COMPLETE");
			}
		}
		
		public function get hexFile():File {
			var file:File = new File(_hexFile.nativePath);
			_hexFile = null;
			return file;
		}
	}
}