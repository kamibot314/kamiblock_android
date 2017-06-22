package {
	import flash.desktop.NativeApplication;
	import flash.desktop.SystemIdleMode;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.InvokeEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.PermissionEvent;
	import flash.events.UncaughtErrorEvent;
	import flash.external.ExternalInterface;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileReference;
	import flash.net.LocalConnection;
	import flash.net.URLRequest;
	import flash.permissions.PermissionStatus;
	import flash.system.Capabilities;
	import flash.system.LoaderContext;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.ui.Keyboard;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import blocks.Block;
	
	import extensions.ExtensionManager;
	import extensions.SerialManager;
	
	import interpreter.Interpreter;
	
	import scratch.BlockMenus;
	import scratch.PaletteBuilder;
	import scratch.ScratchCostume;
	import scratch.ScratchObj;
	import scratch.ScratchRuntime;
	import scratch.ScratchSound;
	import scratch.ScratchSprite;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.CameraDialog;
	import ui.LoadProgress;
	import ui.media.MediaInfo;
	import ui.media.MediaLibrary;
	import ui.media.MediaPane;
	import ui.parts.MonitorPart;
	import ui.parts.PaletteSoundsPart;
	import ui.parts.ScriptsPart;
	import ui.parts.SoundsPart;
	import ui.parts.StagePart;
	
	import uiwidgets.CursorTool;
	import uiwidgets.DialogBox;
	import uiwidgets.Menu;
	import uiwidgets.ScriptsPane;
	
	import util.ApplicationManager;
	import util.GestureHandler;
	import util.LogManager;
	import util.ProjectIO;
	import util.Server;
	import util.SharedObjectManager;
	import util.Transition;
	
	import watchers.ListWatcher;
	
	public class Main extends Sprite {
		// Version
		private static var vxml:XML = NativeApplication.nativeApplication.applicationDescriptor; 
		private static var xmlns:Namespace = new Namespace(vxml.namespace());
		
		public static const versionString:String = 'v'+vxml.xmlns::versionNumber;
		public static var app:Main; // static reference to the app, used for debugging
		
		// Display modes
		public var editMode:Boolean; // true when project editor showing, false when only the player is showing
		public var isOffline:Boolean; // true when running as an offline (i.e. stand-alone) app
		public var isSmallPlayer:Boolean; // true when displaying as a scaled-down player (e.g. in search results)
		public var stageIsContracted:Boolean; // true when the stage is half size to give more space on small screens
		public var stageIsArduino:Boolean;
		public var isIn3D:Boolean;
		public var render3D:IRenderIn3D;
		public var jsEnabled:Boolean = false; // true when the SWF can talk to the webpage
		
		// Runtime
		public var runtime:ScratchRuntime;
		public var interp:Interpreter;
		public var extensionManager:ExtensionManager;
		public var server:Server;
		public var gh:GestureHandler;
		public var projectID:String = '';
		public var projectOwner:String = '';
		public var projectIsPrivate:Boolean;
		public var oldWebsiteURL:String = '';
		public var loadInProgress:Boolean;
		public var debugOps:Boolean = false;
		public var debugOpCmd:String = '';
		
		protected var autostart:Boolean;
		private var viewedObject:ScratchObj;
		private var lastTab:String = 'scripts';
		protected var wasEdited:Boolean; // true if the project was edited and autosaved
		private var _usesUserNameBlock:Boolean = false;
		public var languageChanged:Boolean; // set when language changed
		
		// UI Elements
//		public var playerBG:Shape;
		public var palette:BlockPalette;
		public var scriptsPane:ScriptsPane;
		public var stagePane:ScratchStage;
		public var mediaLibrary:MediaLibrary;
		public var lp:LoadProgress;
		public var cameraDialog:CameraDialog;
		
		// UI Parts
//		public var libraryPart:LibraryPart;
//		public var topBarPart:TopBarPart;
		public var scriptsPart:ScriptsPart;
		//2017/03/30 이승훈 변수파트 추가
//		public var variablePart:VariablePart;
//		public var imagesPart:ImagesPart;
		
		
		//protected var soundsPart:SoundsPart;
		protected var stagePart:StagePart;
		
		//2017/04/11 이승훈 팔레트 사운드 파트 추가
		public var soundsPart:PaletteSoundsPart;
		public var ga:Object={};
//		private var tabsPart:TabsPart;
		//2017/06/12 이승훈 모니터 파트 추가
		public var monitorPart:MonitorPart;
		private var _welcomeView:Loader;
		public static var currentVer:String = "17.06.14";
		private var exiting:Boolean = false;
		public var isRequestBluetooth:Boolean = false;
		public var isMonitorScreenOn:Boolean = false;
		public function Main() {
			this.addEventListener(Event.ADDED_TO_STAGE,initStage);
		}
		
		private function initStage(evt:Event):void{
			stage.color = 0xFFFFFF;//set background color white
			
			trace("Capabilities.os = " + Capabilities.os);
//			trace("Capabilities.manufacturer = " + Capabilities.manufacturer);
//			trace("Capabilities.version = " + Capabilities.version);
//			trace("Capabilities.screenDPI = " + Capabilities.screenDPI);
			
			//Multitouch.inputMode=MultitouchInputMode.TOUCH_POINT;
			
			ApplicationManager.sharedManager().isCatVersion = NativeApplication.nativeApplication.applicationDescriptor.toString().indexOf("猫友")>-1;
			
			track("/app/launch");
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
			
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE,onInvoked);
			NativeApplication.nativeApplication.addEventListener(Event.ACTIVATE, onActivate);
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, onDeactivate);
			NativeApplication.nativeApplication.addEventListener(Event.DEACTIVATE, onDeactivate);
			isOffline = (loaderInfo.url.indexOf('http:') == -1);
			checkFlashVersion();
			initServer();
			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;
//			stage.scaleMode = StageScaleMode.EXACT_FIT;
//			stage.frameRate = 30;
			stage.frameRate = 120;
			
			
			if(SharedObjectManager.sharedManager().available("labelSize")){
				var labelSize:int = SharedObjectManager.sharedManager().getObject("labelSize") as int;
				var argSize:int = Math.round(0.9 * labelSize);
				var vOffset:int = labelSize > 13 ? 1 : 0;
				Block.setFonts(labelSize, argSize, false, vOffset);
			} else {
				Block.setFonts(16, 14, true, 0); // default font sizes
			}
			
			Block.MenuHandlerFunction = BlockMenus.BlockMenuHandler;
			CursorTool.init(this);
			app = this;
			
			stagePane = new ScratchStage();
			gh = new GestureHandler(this, (loaderInfo.parameters['inIE'] == 'true'));
			initInterpreter();
			initRuntime();
			try{
				extensionManager = new ExtensionManager(this);
				//		extensionManager.importExtension();
				Translator.initializeLanguageList();
//				playerBG = new Shape(); // create, but don't add
				addParts();
				stage.addEventListener(MouseEvent.MOUSE_DOWN, gh.mouseDown);
				stage.addEventListener(MouseEvent.MOUSE_MOVE, gh.mouseMove);
				stage.addEventListener(MouseEvent.MOUSE_UP, gh.mouseUp);
				stage.addEventListener(MouseEvent.MOUSE_WHEEL, gh.mouseWheel);
				stage.addEventListener('rightClick', gh.rightMouseClick);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, runtime.keyDown);
				stage.addEventListener(KeyboardEvent.KEY_UP, runtime.keyUp);
				stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDown); // to handle escape key
				stage.addEventListener(Event.ENTER_FRAME, step);
				stage.addEventListener(Event.RESIZE, onResize);
				setEditMode(startInEditMode());
			}catch(e:Error){
				trace(e.getStackTrace());
				var textField:TextField = new TextField;
				textField.width = 600;
				textField.text = "The current issue should be due to that the user has his documents folder pointing (right click \"my documents\" -> properties -> location tab) to a folder on a remote drive that's not alway accessible. For example, pointing the folder to X: (\\orc-fs\temp) and then right-clicking on X to disconnect the drive."
				addChild(textField);
			}
			// install project before calling fixLayout()
			if (editMode) runtime.installNewProject();
			else runtime.installEmptyProject();
			fixLayout();
			var ver:String = currentVer;
			
			if(!SharedObjectManager.sharedManager().available("first-launch")){
				SharedObjectManager.sharedManager().setObject("first-launch",true);
//				openWelcome();
				//2016/06/05 이승훈 수정
				//저장소 접근 권한
//				var file:File = File.documentsDirectory.resolvePath("KamiBlock");
//				if(File.permissionStatus != PermissionStatus.GRANTED){
//					file.addEventListener(PermissionEvent.PERMISSION_STATUS, function(e:PermissionEvent):void {
//						
//						if (e.status == PermissionStatus.GRANTED){
//							if (!file.exists) file.createDirectory();
//						}else{
//							// permission denied
//						}
//					});
//					
//					try {
//						file.requestPermission();
//					}catch(e:Error){
//						// another request is in progress
//					}
//
//
//				}else{
//					if (!file.exists) file.createDirectory();
//				}
				
			}
			
			var lastConnection:String = "";
			
			setSmallStageMode(true);
			ApplicationManager.sharedManager().stage = stage;
			
			SerialManager.sharedManager();//init ANE
			
//			trace("stage.fullScreenWidth = " + stage.fullScreenWidth);
//			trace("stage.fullScreenHeight = " + stage.fullScreenHeight);
//			trace("stage.width = " + stage.width);
//			trace("stage.height = " + stage.height);
//			trace("ApplicationManager.sharedManager().scale = " + ApplicationManager.sharedManager().scale);
			
		}
		
		/*
		TransformGestureEvent.GESTURE_PAN
		TransformGestureEvent.GESTURE_ROTATE
		TransformGestureEvent.GESTURE_ZOOM
		GestureEvent.GESTURE_TWO_FINGER_TAP
		PressAndTapGestureEvent.GESTURE_PRESS_AND_TAP
		
		Multitouch.inputMode = MultitouchInputMode.GESTURE;
		elephant.addEventListener(TransformGestureEvent.GESTURE_ZOOM, onZoom);
		elephant.addEventListener(TransformGestureEvent.GESTURE_ROTATE, onRotate);
		
		private function onZoom(e:TransformGestureEvent):void
		{
		var elephant:Sprite = e.target as Sprite;
		elephant.scaleX *= e.scaleX;
		elephant.scaleY *= e.scaleY;
		}
		*/
		
		private function openWelcome():void{
			_welcomeView = new Loader();
			_welcomeView.load(new URLRequest("welcome.swf"));
			_welcomeView.contentLoaderInfo.addEventListener(Event.COMPLETE,onWelcomeLoaded);
		}
		
		private function onWelcomeLoaded(evt:Event):void{
			var w:uint = stage.stageWidth;
			var h:uint = stage.stageHeight;
			_welcomeView.x = (w-550)/2;
			_welcomeView.y = (h-400)/2+30;
			setTimeout(function():void{addChild(_welcomeView)},500);
		}
		
		public function track(msg:String):void{
			if(ga!=null){
			}
		}
		
//		protected function initTopBarPart():void {
//			topBarPart = new TopBarPart(this);
//		}
		
		protected function initInterpreter():void {
			interp = new Interpreter(this);
		}
		
		protected function initRuntime():void {
			runtime = new ScratchRuntime(this, interp);
		}
		
		protected function initServer():void {
			server = new Server();
		}
		
		public function showTip(tipName:String):void {}
		public function closeTips():void {}
		public function reopenTips():void {}
		
		protected function startInEditMode():Boolean {
			return isOffline;
		}
		
		public function getMediaLibrary(app:Main, type:String, whenDone:Function):MediaLibrary {
			return new MediaLibrary(app, type, whenDone);
		}
		
		public function getMediaPane(app:Main, type:String):MediaPane {
			return new MediaPane(app, type);
		}
		
		public function getScratchStage():ScratchStage {
			return new ScratchStage();
		}
		
		public function getPaletteBuilder():PaletteBuilder {
			return new PaletteBuilder(this);
		}
		
		private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
		{
			var dialogBox:DialogBox;
			if (event.error is Error)
			{
				var error:Error = event.error as Error;
				logException(error);
				
				dialogBox = new DialogBox();
				dialogBox.setText(error.message);
				dialogBox.setTitle("Error");
				dialogBox.setButton("OK");
				dialogBox.showOnStage(Main.app.stage);
			}
			else if (event.error is ErrorEvent)
			{
				var errorEvent:ErrorEvent = event.error as ErrorEvent;
				logMessage(errorEvent.toString());
				
				dialogBox = new DialogBox();
				dialogBox.setText(error.message);
				dialogBox.setTitle("Error");
				dialogBox.setButton("OK");
				dialogBox.showOnStage(Main.app.stage);
			}
		}
		
		private function onInvoked(evt:InvokeEvent):void{
			
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			if(evt.arguments.length>0){
				function openExtProject(v:String=null):void{
					if(v!=null&&v!=null){
						runtime.selectedProjectFile(v);
					}
				}
				setTimeout(openExtProject,0.5,evt.arguments[0]);
			}
		}
		
		private function onActivate(e:Event):void {
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
			trace("onActivate");
			if (ApplicationManager.isAndroid) {
				if (isRequestBluetooth) {
					if (!SerialManager.sharedManager().enabled) {
						DialogBox.notify('Bluetooth Disabled', 'Be enable bluetooth to connect device', Main.app.stage, true, null);
					} else {
						scriptsPart.connect();
					}
					isRequestBluetooth = false;
				}
			}
		}
		
		private function onDeactivate(e:Event):void {
			trace("onDeactivate");
			//lastConnection =SerialManager.sharedManager().connectedName;
			//SerialManager.sharedManager().disconnect();
			//NativeApplication.nativeApplication.exit();
			//track("/app/exit");
			//LogManager.sharedManager().save();
			NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.NORMAL;
			app.runtime.stopAll();
		}
		
		public function log(s:String):void {
			LogManager.sharedManager().log(s+"\r\n");
		}
		
		public function logException(e:Error):void {}
		public function logMessage(msg:String, extra_data:Object=null):void {}
		public function loadProjectFailed():void {}
		[Embed(source='libs/RenderIn3D.swf', mimeType='application/octet-stream')]
		public static const MySwfData:Class;
		protected function checkFlashVersion():void {
			if(Capabilities.playerType != "Desktop" || Capabilities.version.indexOf('IOS') === 0) {
				var isArmCPU:Boolean = (jsEnabled && ExternalInterface.call("window.navigator.userAgent.toString").indexOf('CrOS arm') > -1);
				var versionString:String = Capabilities.version.substr(Capabilities.version.indexOf(' ')+1);
				var versionParts:Array = versionString.split(',');
				var majorVersion:int = parseInt(versionParts[0]);
				var minorVersion:int = parseInt(versionParts[1]);
				if((majorVersion > 11 || (majorVersion == 11 && minorVersion >=1)) && !isArmCPU && Capabilities.cpuArchitecture == 'x86') {
					loadRenderLibrary();
					return;
				}
			}
			
			render3D = null;
		}
		
		protected var loading3DLib:Boolean = false;
		protected function loadRenderLibrary():void
		{
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onSwfLoaded);
			// we need the loaded code to be in the same (main) application domain
			var ctx:LoaderContext = new LoaderContext(false, loaderInfo.applicationDomain);
			ctx.allowCodeImport = true;
			loader.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
			loader.loadBytes(new MySwfData() as ByteArray, ctx);
			loading3DLib = true;
		}
		
		protected function handleRenderCallback(enabled:Boolean):void {
			loading3DLib = false;
			
			if(!enabled) {
				go2D();
				render3D = null;
			}
			else {
				for(var i:int=0; i<stagePane.numChildren; ++i) {
					var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
					if(spr) {
						spr.clearCachedBitmap();
						spr.updateCostume();
						spr.applyFilters();
					}
				}
				stagePane.clearCachedBitmap();
				stagePane.updateCostume();
				stagePane.applyFilters();
			}
		}
		
		protected function onSwfLoaded(e:Event):void {
			var info:LoaderInfo = LoaderInfo(e.target);
			var r3dClass:Class = info.applicationDomain.getDefinition("DisplayObjectContainerIn3D") as Class;
			render3D = (new r3dClass() as IRenderIn3D);
			render3D.setStatusCallback(handleRenderCallback);
		}
		
		public function clearCachedBitmaps():void {
			for(var i:int=0; i<stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if(spr) spr.clearCachedBitmap();
			}
			stagePane.clearCachedBitmap();
			
			// unsupported technique that seems to force garbage collection
			try {
				new LocalConnection().connect('foo');
				new LocalConnection().connect('foo');
			} catch (e:Error) {}
		}
		
		public function go3D():void {
			if(!render3D || isIn3D) return;
			
			var i:int = stagePart.getChildIndex(stagePane);
			stagePart.removeChild(stagePane);
			render3D.setStage(stagePane, stagePane.penLayer);
			stagePart.addChildAt(stagePane, i);
			isIn3D = true;
		}
		
		public function go2D():void {
			if(!render3D || !isIn3D) return;
			
			var i:int = stagePart.getChildIndex(stagePane);
			stagePart.removeChild(stagePane);
			render3D.setStage(null, null);
			stagePart.addChildAt(stagePane, i);
			isIn3D = false;
			for(i=0; i<stagePane.numChildren; ++i) {
				var spr:ScratchSprite = (stagePane.getChildAt(i) as ScratchSprite);
				if(spr) {
					spr.clearCachedBitmap();
					spr.updateCostume();
					spr.applyFilters();
				}
			}
			stagePane.clearCachedBitmap();
			stagePane.updateCostume();
			stagePane.applyFilters();
		}
		
		private var debugRect:Shape;
		public function showDebugRect(r:Rectangle):void {
			// Used during debugging...
			var p:Point = stagePane.localToGlobal(new Point(0, 0));
			if (!debugRect) debugRect = new Shape();
			var g:Graphics = debugRect.graphics;
			g.clear();
			if (r) {
				g.lineStyle(2, 0xFFFF00);
				g.drawRect(p.x + r.x, p.y + r.y, r.width, r.height);
				addChild(debugRect);
			}
		}
		
		public function strings():Array {
			return [
				'a copy of the project file on your computer.',
				'Project not saved!', 'Save now', 'Not saved; project did not load.',
				'Save now', 'Saved',
				'Revert', 'Undo Revert', 'Reverting...',
				'Throw away all changes since opening this project?',
			];
		}
		
		public function viewedObj():ScratchObj { return viewedObject; }
		public function stageObj():ScratchStage { return stagePane; }
		public function projectName():String { return stagePart.projectName(); }
//		public function highlightSprites(sprites:Array):void { libraryPart.highlight(sprites); }
//		public function refreshImageTab(fromEditor:Boolean):void { imagesPart.refresh(fromEditor); }
//		public function refreshSoundTab():void { soundsPart.refresh(); }
//		public function selectCostume():void { imagesPart.selectCostume(); }
//		public function selectSound(snd:ScratchSound):void { soundsPart.selectSound(snd); }
		public function clearTool():void { CursorTool.setTool(null); /*topBarPart.clearToolButtons();*/ }
//		public function tabsRight():int { return tabsPart.x + tabsPart.w; }
//		public function enableEditorTools(flag:Boolean):void { imagesPart.editor.enableTools(flag); }
		
		public function get usesUserNameBlock():Boolean {
			return _usesUserNameBlock;
		}
		
		public function set usesUserNameBlock(value:Boolean):void {
			_usesUserNameBlock = value;
			stagePart.refresh();
		}
		
		public function updatePalette(clearCaches:Boolean = true):void {
			// Note: updatePalette() is called after changing variable, list, or procedure
			// definitions, so this is a convenient place to clear the interpreter's caches.
			if (isShowing(scriptsPart)) scriptsPart.updatePalette();
			if (clearCaches) runtime.clearAllCaches();
		}
		
		public function setProjectName(s:String):void {
			if (s.slice(-3) == '.sb') s = s.slice(0, -3);
			if (s.slice(-4) == '.sb2') s = s.slice(0, -4);
			stagePart.setProjectName(s);
			if(_welcomeView!=null){
				_welcomeView.alpha = 0.5;
				setTimeout(function():void{
					if(contains(_welcomeView)){
						setChildIndex(_welcomeView,numChildren-1);
						_welcomeView.alpha = 1.0;
					}
				},600);
			}
		}
		
		protected var wasEditing:Boolean;
		public function setPresentationMode(enterPresentation:Boolean):void {
			if (enterPresentation) {
				wasEditing = editMode;
				if (wasEditing) {
					setEditMode(false);
					
				}
			} else {
				if (wasEditing) {
					setEditMode(true);
				}
			}
			if (isOffline) {
				Main.app.track(enterPresentation?"enterFullscreen":"enterNormal");
				stage.displayState = enterPresentation ? StageDisplayState.FULL_SCREEN_INTERACTIVE : StageDisplayState.NORMAL;
			}
			for each (var o:ScratchObj in stagePane.allObjects()) o.applyFilters();
			
			if (lp) fixLoadProgressLayout();
			stagePane.updateCostume();
			if(isIn3D) render3D.onStageResize();
		}
		
		private function keyDown(evt:KeyboardEvent):void {
			// Escape exists presentation mode.
			if ((evt.charCode == 27) && stagePart.isInPresentationMode()) {
				setPresentationMode(false);
				stagePart.exitPresentationMode();
			}
				// Handle enter key
				//		else if(evt.keyCode == 13 && !stage.focus) {
				//			stagePart.playButtonPressed(null);
				//			evt.preventDefault();
				//			evt.stopImmediatePropagation();
				//		}
				// Handle ctrl-m and toggle 2d/3d mode
			else if(evt.ctrlKey && evt.charCode == 109) {
				isIn3D ? go2D() : go3D();
				evt.preventDefault();
				evt.stopImmediatePropagation();
			}
			
			if (evt.keyCode == Keyboard.BACK) {
				if (!exiting) {
					setTimeout(function():void {
						exiting = false;
					},2000);
					SerialManager.sharedManager().showMessage(Translator.map("please back again to exit"));
					evt.preventDefault();
					exiting = true;
				} else {
					SerialManager.sharedManager().disconnect();
					NativeApplication.nativeApplication.exit(0);
				}
			}
		}
		
		private function setSmallStageMode(flag:Boolean):void {
			stageIsContracted = flag;
			stagePart.refresh();
			fixLayout();
//			libraryPart.refresh();
//			tabsPart.refresh();
			stagePane.applyFilters();
			stagePane.updateCostume();
		}
		
		public function projectLoaded():void {
			removeLoadProgressBox();
			System.gc();
			if (autostart) runtime.startGreenFlags();
			saveNeeded = false;
			
			// translate the blocks of the newly loaded project
			for each (var o:ScratchObj in stagePane.allObjects()) {
				o.updateScriptsAfterTranslation();
			}
		}
		
		protected function step(e:Event):void {
			// Step the runtime system and all UI components.
			gh.step();
			runtime.stepRuntime();
//			Transition.step(null);
//			stagePart.step();
//			libraryPart.step();
			scriptsPart.step();
//			imagesPart.step();
		}
		
//		public function updateSpriteLibrary(sortByIndex:Boolean = false):void { libraryPart.refresh() }
		public function threadStarted():void { scriptsPart.threadStarted() }
		
		public function selectSprite(obj:ScratchObj):void {
//			if (isShowing(imagesPart)) imagesPart.editor.shutdown();
//			if (isShowing(soundsPart)) soundsPart.editor.shutdown();

			viewedObject = obj;

			//			libraryPart.refresh();
//			tabsPart.refresh();
//			if (isShowing(imagesPart)) {
//				imagesPart.refresh();
//			}
//			if (isShowing(soundsPart)) {
//				soundsPart.currentIndex = 0;
//				soundsPart.refresh();
//			}
			if (isShowing(scriptsPart)) {
				scriptsPart.updatePalette();
				scriptsPane.viewScriptsFor(obj);
				scriptsPart.updateSpriteWatermark();
			}
		}
		
//		public function setTab(tabName:String):void {
//			if (isShowing(imagesPart)) imagesPart.editor.shutdown();
//			if (isShowing(soundsPart)) soundsPart.editor.shutdown();
//			hide(scriptsPart);
//			hide(imagesPart);
//			hide(soundsPart);
//			if (!editMode) return;
//			if (tabName == 'images') {
//				show(imagesPart);
//				imagesPart.refresh();
//			} else if (tabName == 'sounds') {
//				soundsPart.refresh();
//				show(soundsPart);
//			} else if (tabName && (tabName.length > 0)) {
//				tabName = 'scripts';
//				scriptsPart.updatePalette();
//				scriptsPane.viewScriptsFor(viewedObject);
//				scriptsPart.updateSpriteWatermark();
//				show(scriptsPart);
//			}
//			show(tabsPart);
//			show(stagePart); // put stage in front
//			tabsPart.selectTab(tabName);
//			lastTab = tabName;
//			if (saveNeeded) setSaveNeeded(true); // save project when switching tabs, if needed (but NOT while loading!)
//		}
		
		public function installStage(newStage:ScratchStage):void {
			var showGreenflagOverlay:Boolean = shouldShowGreenFlag();
			stagePart.installStage(newStage, showGreenflagOverlay);
			selectSprite(newStage);
//			libraryPart.refresh();
//			setTab('scripts');
			scriptsPart.resetCategory();
			wasEdited = false;
		}
		
		protected function shouldShowGreenFlag():Boolean {
			return !(autostart || editMode);
		}
		
		protected function addParts():void {
//			topBarPart = new TopBarPart(this);
			stagePart = new StagePart(this)
			scriptsPart = new ScriptsPart(this);
//			variablePart = new VariablePart(this);
			//2017/04/13 이승훈 추가
			soundsPart = new PaletteSoundsPart(this);
			//monitorPart = new MonitorPart(this);
//			addChild(stagePart);
			addChild(scriptsPart);
			//2017/04/13 이승훈 추가
			addChild(soundsPart);
			//2017/06/12 이승훈 추가
			//addChild(monitorPart);
//			soundsPart.getRecordSound();
			//addChild(topBarPart);
		}
		
		// -----------------------------
		// UI Modes and Resizing
		//------------------------------
		
		public function setEditMode(newMode:Boolean):void {
			editMode = newMode;
//			Menu.removeMenusFrom(stage);
//			if (editMode) {
//				hide(playerBG);
//				show(topBarPart);
////				show(libraryPart);
////				show(tabsPart);
////				setTab(lastTab);
//				//9stagePart.hidePlayButton();
//				runtime.edgeTriggersEnabled = true;
//			} else {
//				addChildAt(playerBG, 0); // behind everything
//				playerBG.visible = false;
//				hide(topBarPart);
////				hide(libraryPart);
////				hide(tabsPart);
////				setTab(null); // hides scripts, images, and sounds
//			}
//			show(stagePart); // put stage in front
//			fixLayout();
//			stagePart.refresh();
		}
		
		protected function hide(obj:DisplayObject):void { if (obj.parent) obj.parent.removeChild(obj) }
		protected function show(obj:DisplayObject):void { addChild(obj) }
		protected function isShowing(obj:DisplayObject):Boolean { return obj.parent != null }
		
		public function onResize(e:Event):void {
			trace("onResize");
			fixLayout();
		}
		
		public function fixLayout():void {
			
			var w:int = stage.stageWidth;
			var h:int = stage.stageHeight - 1; // fix to show bottom border...
			
//			w = Math.ceil(w / scaleX);
//			h = Math.ceil(h / scaleY);
			w = Math.ceil(w / util.ApplicationManager.sharedManager().scale);
			h = Math.ceil(h / util.ApplicationManager.sharedManager().scale);
			
//			trace("stage.stageWidth = " + stage.stageWidth + " stage.stageHeight = " + stage.stageHeight);
//			trace("w = " + w + " h = " + h);
			
			updateLayout(w, h);
			if(_welcomeView){
				_welcomeView.x = (w-550)/2;
				_welcomeView.y = (h-400)/2+30;
			}
		}
		
		protected function updateLayout(w:int, h:int):void {
//			w *= ApplicationManager.sharedManager().scale;
//			h *= ApplicationManager.sharedManager().scale;
//			topBarPart.x = 0;
//			topBarPart.y = 0;
//			topBarPart.setWidthHeight(w, 28);
			
			
			var margin:uint = 5 * util.ApplicationManager.sharedManager().scale;
			
			stagePart.hideFullScreenButton();
			stagePart.x = margin;
//			stagePart.y = (topBarPart.bottom()+ 5) * ApplicationManager.sharedManager().scale;
			stagePart.y = margin;
//			var tabsPartX:int = stagePart.right() + 5;
//			var tabsPartY:int = (topBarPart.bottom() + 5) * ApplicationManager.sharedManager().scale;
//			var tabsPartX:int = 5;
//			var tabsPartY:int = 5;
			updateContentArea(margin, margin, w - margin, h - margin);
		}
		
		protected function updateContentArea(contentX:int, contentY:int, contentW:int, contentH:int):void {
			scriptsPart.x = contentX;
			scriptsPart.y = contentY;
			scriptsPart.setWidthHeight(contentW, contentH);
			
//			if (frameRateGraph) {
//				frameRateGraph.y = stage.stageHeight - frameRateGraphH;
//				addChild(frameRateGraph); // put in front
//			}
			
			if(isIn3D) render3D.onStageResize();
		}
		
//		private function drawBG():void {
//			var g:Graphics = playerBG.graphics;
//			g.clear();
//			g.beginFill(0);
//			g.drawRect(0, 0, stage.stageWidth * util.ApplicationManager.sharedManager().scale, stage.stageHeight * util.ApplicationManager.sharedManager().scale);
//		}
		
		// -----------------------------
		// Translations utilities
		//------------------------------
		
		public function translationChanged():void {
			// The translation has changed. Fix scripts and update the UI.
			// directionChanged is true if the writing direction (e.g. left-to-right) has changed.
			for each (var o:ScratchObj in stagePane.allObjects()) {
				o.updateScriptsAfterTranslation();
			}
			var uiLayer:Sprite = app.stagePane.getUILayer();
			for (var i:int = 0; i < uiLayer.numChildren; ++i) {
				var lw:ListWatcher = uiLayer.getChildAt(i) as ListWatcher;
				if (lw) lw.updateTranslation();
			}
//			topBarPart.updateTranslation();
			stagePart.updateTranslation();
//			libraryPart.updateTranslation();
//			tabsPart.updateTranslation();
			updatePalette(false);
//			imagesPart.updateTranslation();
			soundsPart.updateTranslation();
		}
		
		// -----------------------------
		// Menus
		//------------------------------
		public function showFileMenu(b:*):void {
//			var m:Menu = new Menu(null, 'File', CSS.topBarColor, 28);
//			m.addItem('New', createNewProject);
//			m.addLine();
//			
//			// Derived class will handle this
//			addFileMenuItems(b, m);
//			
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
//			
//			track("/OpenFile");
		}
		
		protected function addFileMenuItems(b:*, m:Menu):void {
//			m.addItem('Load Project', runtime.selectProjectFile);
//			m.addItem('Save Project', exportProjectToFile);
			if (canUndoRevert()) {
				m.addLine();
				m.addItem('Undo Revert', undoRevert);
			} else if (canRevert()) {
				m.addLine();
				m.addItem('Revert', revertToOriginalProject);
			}
			
			if (b.lastEvent.shiftKey && jsEnabled) {
				m.addLine();
				m.addItem('Import experimental extension', function():void {
					function loadJSExtension(dialog:DialogBox):void {
						var url:String = dialog.fields['URL'].text.replace(/^\s+|\s+$/g, '');
						if (url.length == 0) return;
						ExternalInterface.call('ScratchExtensions.loadExternalJS', url);
					}
					var d:DialogBox = new DialogBox(loadJSExtension);
					d.addTitle('Load Javascript Scratch Extension');
					d.addField('URL', 120);
					d.addAcceptCancelButtons('Load');
					d.showOnStage(app.stage);
				});
			}
		}
		
		public function showEditMenu(b:*):void {
//			var m:Menu = new Menu(null, 'More', CSS.topBarColor, 28);
//			m.addItem('Undelete', runtime.undelete, runtime.canUndelete());
//			m.addLine();
////			m.addItem('Small stage layout', toggleSmallStage, true, stageIsContracted);
////			m.addItem('Turbo mode', toggleTurboMode, true, interp.turboMode);
////			m.addItem('Arduino mode', changeToArduinoMode, true, stageIsArduino);
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
//			track("/OpenEdit");
		}
		
		public function  showConnectMenu(b:*):void {
//			
//			var enabled:Boolean = extensionManager.checkExtensionEnabled();
//			var m:Menu = new Menu(ConnectionManager.sharedManager().onConnect, 'Connect', CSS.topBarColor, 28);
//			if (SerialManager.sharedManager().connected) {
//				m.addItem('Disconnect', 'disconnect_ble_device', true, false);
//			} else {
//				m.addItem('Connect to KamiBot', 'search_ble_device', true, false);
//			}
//			
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
		}
		
		public function showBoardMenu(b:*):void {/*
			Main.app.topBarPart.setBoardTitle();
			var m:Menu = new Menu(BoardManager0.getInstance().onSelectBoard, 'Board', CSS.topBarColor, 28);
			var list:Array = BoardManager0.getInstance().listBoard;
			
			for(var i:Number in list) {
				m.addItem(list[i], list[i], true, BoardManager0.getInstance().check(list[i]));
			}
			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);*/
		}
//		public function showExtensionMenu(b:*):void {
//			var m:Menu = new Menu(extensionManager.onSelectExtension, 'Extension', CSS.topBarColor, 28);
//			var list:Array = extensionManager.extensionList;
//			if(list.length==0){
////				Main.app.extensionManager.copyLocalFiles();
//				SharedObjectManager.sharedManager().setObject("first-launch",false);
//			}
//			for(var i:uint=0;i<list.length;i++){
//				var n:String = list[i].extensionName;
//				m.addItem(n, n, true, extensionManager.checkExtensionSelected(n));
//			}
//			//			m.addLine();
//			//m.addItem('import extension file', '_import_', true, false);
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
//		}
		
		private var reg:RegExp = /\b(\w)|\s(\w)/g;
		private function replaceReg(str:String):String{
			str = str.toLowerCase();
			return str.replace(reg,function(m):*{
				return m.toUpperCase();
			});
		}
		
		public function showExamplesMenu(b:*):void {
//			var url:URLRequest = new URLRequest("http://mblock.cc/examples/?mblock");
//			navigateToURL(url,"_blank");
//			track("/OpenExamples/");
//			return;
//			var m:Menu = new Menu(openExampleFile, '', CSS.topBarColor, 28);
//			var df:File = File.applicationDirectory.resolvePath("examples");
//			if(df.exists){
//				var fs:Array = df.getDirectoryListing();
//				for each(var f:File in fs){
//					if(!f.isDirectory){
//						if(f.extension.indexOf("sb2")>-1){
//							m.addItem(Translator.map(replaceReg(f.name.split(".sb2").join("").split("_").join(" "))), f.url, true, false);
//						}
//					}
//				}
//			}
//			df = File.applicationDirectory.resolvePath("examples/arduino");
//			if(df.exists){
//				fs = df.getDirectoryListing();
//				m.addLine();
//				for each(f in fs){
//					if(!f.isDirectory){
//						if(f.extension.indexOf("sb2")>-1){
//							m.addItem(Translator.map(replaceReg(f.name.split(".sb2").join("").split("_").join(" "))), f.url, true, false);
//						}
//					}
//				}
//			}
//			addEditMenuItems(b, m);
//			var p:Point = b.localToGlobal(new Point(0, 0));
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
		}
		
		public function openShare(b:*):void {
//			var url:URLRequest = new URLRequest("http://www.maoyouhui.org/forum.php?gid=57&mblock");
//			navigateToURL(url,"_blank");
//			track("/OpenShare/");
		}
		
		public function openFaq(b:*):void {
//			var url:URLRequest = new URLRequest("http://www.maoyouhui.org/forum.php?mod=forumdisplay&fid=62&mblock");
//			navigateToURL(url,"_blank");
//			track("/OpenFaq/");
		}
		
		private function openHelpMenu(v:String):void{
//			var url:URLRequest;
//			if(v=="forum"){
//				url = new URLRequest(Translator.map("http://forum.makeblock.cc/c/makeblock-products/mblock#scratch"));
//				navigateToURL(url,"_blank");
//			}else if(v=="report"){
//				url = new URLRequest("http://mblock.cc/report-a-bug");
//				navigateToURL(url,"_blank");
//			}else if(v=="license"){
//				url = new URLRequest("http://mblock.cc/license");
//				navigateToURL(url,"_blank");
//			}else if(v=="acknowledgements"){
//				url = new URLRequest("http://mblock.cc/acknowledgements");
//				navigateToURL(url,"_blank");
//			}else if(v=="about"){
//				url = new URLRequest("http://mblock.cc/about");
//				navigateToURL(url,"_blank");
//			}else if(v=="features"){
//				openWelcome();
//			}else if(v.indexOf("http")>-1){
//				url = new URLRequest(v);
//				navigateToURL(url,"_blank");
//			}
//			track("/OpenHelp/"+v);
			if(v=="about") {
			}
		}
		public function openAbout(b:*):void {
//			var m:Menu = new Menu(openHelpMenu, 'Help', CSS.topBarColor, 28);
//			
////			m.addItem('Forum', 'forum', true, false);
////			m.addItem('Report a Bug', 'report', true, false);
////			m.addLine();
////			m.addItem('License', 'license', true, false);
////			m.addItem('Acknowledgements', 'acknowledgements', true, false);
//			//			m.addItem('Features','features',true,false);
////			m.addItem('About Kamibot', 'about', true, false);
//			m.addLine();
//			m.addItem(''+versionString+"."+currentVer, 'version', false, false);
//			//			SerialManager.sharedManager().board = SharedObjectManager.sharedManager().getObject("board","uno");
//			//			SerialManager.sharedManager().device = SharedObjectManager.sharedManager().getObject("device","mbot");
//			
//			var p:Point = b.localToGlobal(new Point(0, 0));
//			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
//			
//			//			var url:URLRequest = new URLRequest(Translator.map("http://forum.makeblock.cc/c/makeblock-products/mblock#scratch"));
//			//			track("/OpenForum/"+url.url);
//			//			navigateToURL(url,"_blank");
		}
		
		private function openExampleFile(path:String):void{
			
			var filePath:String = path;
			this.runtime.selectedProjectFile(filePath);
			track("/Examples/"+path);
		}
		
		protected function canExportInternals():Boolean {
			return false;
		}
		
		private function showAboutDialog():void {
		}
		
		protected function createNewProject(ignore:* = null):void {
			function clearProject():void {
				startNewProject('', '');
				setProjectName('Untitled');
//				topBarPart.refresh();
				stagePart.refresh();
			}
			saveProjectAndThen(clearProject);
		}
		
		public function saveProjectAndThen(postSaveAction:Function = null):void {
			// Give the user a chance to save their project, if needed, then call postSaveAction.
			function doNothing():void {}
			function cancel():void { d.cancel(); }
			function proceedWithoutSaving():void { d.cancel(); postSaveAction() }
			function save():void {
				d.cancel();
				exportProjectToFile(false,postSaveAction); // if this succeeds, saveNeeded will become false
				if (!saveNeeded) postSaveAction();
			}
			if (postSaveAction == null) postSaveAction = doNothing;
			if (!saveNeeded) {
				postSaveAction();
				return;
			}
			var d:DialogBox = new DialogBox();
			d.addTitle(Translator.map('Save project') + '?');
			d.addButton('Save', save);
			d.addButton('Don\'t save', proceedWithoutSaving);
			d.addButton('Cancel', cancel);
			d.showOnStage(stage);
		}
		
		public function exportProjectToFile(fromJS:Boolean = false,postSaveAction:Function=null):void {
			function squeakSoundsConverted():void {
				scriptsPane.saveScripts(false);
//				var defaultName:String = (projectName().length > 1) ? projectName() + '.sb2' : 'project.sb2';
				var zipData:ByteArray = projIO.encodeProjectAsZipFile(stagePane);
				
				var fileStream:FileStream = new FileStream();
				var file:File = generateFileName();
				try {
					fileStream.open(file, FileMode.WRITE);
					fileStream.writeBytes(zipData);
					
					DialogBox.notify("saved","saved at " + file.name,stage);
					saveNeeded = false;
					if (!fromJS) setProjectName(file.name);
					if(postSaveAction!=null){
						postSaveAction();
					}
				} catch (e:Error) {
					DialogBox.notify("save failure","sorry, save failure");
					trace(e.getStackTrace());
				} finally {
					fileStream.close();
				}
			}
			
			if (loadInProgress) return;
			var projIO:ProjectIO = new ProjectIO(this);
			projIO.convertSqueakSounds(stagePane, squeakSoundsConverted);
		}
		
		private function generateFileName():File {
			//2016/10/01 이승훈 수정
			//폴더위치 검색
			var dir:File = File.documentsDirectory.resolvePath("KamiBlock");
			var array:Array = dir.getDirectoryListing();
			var i:uint = 1;
			
			for each (var f:File in array) 
			{
				if (f.name == "project"+i+".sb2") i++;
			}
			
			var file:File = dir.resolvePath("project"+i+".sb2");
			
			return file;
		}
		
		public static function fixFileName(s:String):String {
			// Replace illegal characters in the given string with dashes.
			const illegal:String = '\\/:*?"<>|%';
			var result:String = '';
			for (var i:int = 0; i < s.length; i++) {
				var ch:String = s.charAt(i);
				if ((i == 0) && ('.' == ch)) ch = '-'; // don't allow leading period
				result += (illegal.indexOf(ch) > -1) ? '-' : ch;
			}
			return result;
		}
		
		public function toggleSmallStage():void {
			setSmallStageMode(!stageIsContracted);
		}
		
		public function toggleTurboMode():void {
			interp.turboMode = !interp.turboMode;
			stagePart.refresh();
		}
		
//		public function changeToArduinoMode():void{
//			toggleArduinoMode();
//			if(stageIsArduino)
//				scriptsPart.parseArduinoCodeByStage();
//		}
//		
//		public function toggleArduinoMode():void {
//			stageIsArduino = !stageIsArduino;
//			setSmallStageMode(stageIsArduino);
//			this.scriptsPart.selector.select(stageIsArduino?6:1);
//			this.tabsPart.soundsTab.visible = !stageIsArduino;
//			this.tabsPart.imagesTab.visible = !stageIsArduino;
//			setTab("scripts");
//		}
		
		public function handleTool(tool:String, evt:MouseEvent):void { }
		
		public function showBubble(text:String, x:* = null, y:* = null, width:Number = 0):void {
			if (x == null) x = stage.mouseX;
			if (y == null) y = stage.mouseY;
			gh.showBubble(text, Number(x), Number(y), width);
		}
		
		// -----------------------------
		// Project Management and Sign in
		//------------------------------
		
//		public function setLanguagePressed(b:IconButton):void {
//			function setLanguage(lang:String):void {
//				Translator.setLanguage(lang);
//				languageChanged = true;
//			}
//			var m:Menu = new Menu(setLanguage, 'Language', CSS.topBarColor, 28);
//			m.addItem('Undelete', runtime.undelete, runtime.canUndelete());
//			m.addLine();
//			if (Translator.languages.length == 0) return; // empty language list
////			if (b.lastEvent.shiftKey) {
////				m.addItem('import translation file');
////				m.addLine();
////			}
//			for each (var entry:Array in Translator.languages) {
//				m.addItem(entry[1], entry[0],true,Translator.currentLang==entry[0]);
//			}
//			m.addLine();
//			m.addItem('set block size');
//			m.addLine();
//			m.addItem(''+versionString+"."+currentVer, 'version', false, false);
//			var p:Point = b.localToGlobal(new Point(0, 0));
////			m.showOnStage(stage, b.x, topBarPart.bottom() - 1);
//			m.showOnStage(stage);
//		}
		
		public function startNewProject(newOwner:String, newID:String):void {
			runtime.installNewProject();
			projectOwner = newOwner;
			projectID = newID;
			projectIsPrivate = true;
			loadInProgress = false;
		}
		
		// -----------------------------
		// Save status
		//------------------------------
		
		public var saveNeeded:Boolean;
		
		public function setSaveNeeded(saveNow:Boolean = false):void {
			trace("setSaveNeeded In");
			saveNow = false;
			// Set saveNeeded flag and update the status string.
			saveNeeded = true;
			if (!wasEdited) {
				trace("if !wasEdited In");
				saveNow = true; // force a save on first change
			}
			clearRevertUndo();
		}
		
		protected function clearSaveNeeded():void {
			// Clear saveNeeded flag and update the status string.
			function twoDigits(n:int):String { return ((n < 10) ? '0' : '') + n }
			saveNeeded = false;
			wasEdited = true;
		}
		
		// -----------------------------
		// Project Reverting
		//------------------------------
		
		protected var originalProj:ByteArray;
		private var revertUndo:ByteArray;
		
		public function saveForRevert(projData:ByteArray, isNew:Boolean, onServer:Boolean = false):void {
			originalProj = projData;
			revertUndo = null;
		}
		
		protected function doRevert():void {
			runtime.installProjectFromData(originalProj, false);
		}
		
		protected function revertToOriginalProject():void {
			function preDoRevert():void {
				revertUndo = new ProjectIO(Main.app).encodeProjectAsZipFile(stagePane);
				doRevert();
			}
			if (!originalProj) return;
			DialogBox.confirm('Throw away all changes since opening this project?', stage, preDoRevert);
		}
		
		protected function undoRevert():void {
			if (!revertUndo) return;
			runtime.installProjectFromData(revertUndo, false);
			revertUndo = null;
		}
		
		protected function canRevert():Boolean { return originalProj != null }
		protected function canUndoRevert():Boolean { return revertUndo != null }
		private function clearRevertUndo():void { revertUndo = null }
		
		public function addNewSprite(spr:ScratchSprite, showImages:Boolean = false, atMouse:Boolean = false):void {
			var c:ScratchCostume, byteCount:int;
			for each (c in spr.costumes) byteCount + c.baseLayerData.length;
			if (!okayToAdd(byteCount)) return; // not enough room
			spr.objName = stagePane.unusedSpriteName(spr.objName);
			spr.indexInLibrary = 1000000; // add at end of library
			spr.setScratchXY(int(50 * Math.random() - 25), int(50 * Math.random() - 25));
			if (atMouse) spr.setScratchXY(stagePane.scratchMouseX(), stagePane.scratchMouseY());
			stagePane.addChild(spr);
			selectSprite(spr);
//			setTab(showImages ? 'images' : 'scripts');
			if(stagePane.numChildren>4)
				setSaveNeeded(true);
			
//			libraryPart.refresh();
			for each (c in spr.costumes) {
				if (ScratchCostume.isSVGData(c.baseLayerData)) c.setSVGData(c.baseLayerData, false);
			}
		}
		
		public function addSound(snd:ScratchSound, targetObj:ScratchObj = null):void {
			if (snd.soundData && !okayToAdd(snd.soundData.length)) return; // not enough room
			if (!targetObj) targetObj = viewedObj();
			snd.soundName = targetObj.unusedSoundName(snd.soundName);
			targetObj.sounds.push(snd);
			setSaveNeeded(true);
			if (targetObj == viewedObj()) {
//				soundsPart.selectSound(snd);
//				setTab('sounds');
			}
		}
		
		//2017/04/13 이승훈 추가 팔레트
		public function PaletteAddSound(snd:ScratchSound, targetObj:ScratchObj = null):void {
			trace("Main.as PaletteAddSound In!!!!! ");
			if (snd.soundData && !okayToAdd(snd.soundData.length)){
				return; // not enough room
			}
			if (!targetObj) targetObj = viewedObj();
			snd.soundName = targetObj.unusedSoundName(snd.soundName);
			targetObj.sounds.push(snd);
			//targetObj.sounds.sort();
			targetObj.sounds.sortOn( ["soundName"],[Array.DESCENDING,null]);
			setSaveNeeded(true);
			if (targetObj == viewedObj()) {
				trace("if targetObj == viewedObj In");
				trace("snd.name : "+snd.soundName);
				soundsPart.selectSound(snd);
				soundsPart.refresh();
			}
		}
		
		public function addCostume(c:ScratchCostume, targetObj:ScratchObj = null):void {
			if (!c.baseLayerData) c.prepareToSave();
			if (!okayToAdd(c.baseLayerData.length)) return; // not enough room
			if (!targetObj) targetObj = viewedObj();
			c.costumeName = targetObj.unusedCostumeName(c.costumeName);
			targetObj.costumes.push(c);
			targetObj.showCostumeNamed(c.costumeName);
			setSaveNeeded(true);
//			if (targetObj == viewedObj()) setTab('images');
		}
		
		public function okayToAdd(newAssetBytes:int):Boolean {
			// Return true if there is room to add an asset of the given size.
			// Otherwise, return false and display a warning dialog.
			const assetByteLimit:int = 50 * 1024 * 1024; // 50 megabytes
			var assetByteCount:int = newAssetBytes;
			for each (var obj:ScratchObj in stagePane.allObjects()) {
				for each (var c:ScratchCostume in obj.costumes) {
					if (!c.baseLayerData) c.prepareToSave();
					assetByteCount += c.baseLayerData.length;
				}
				for each (var snd:ScratchSound in obj.sounds) assetByteCount += snd.soundData.length;
			}
			if (assetByteCount > assetByteLimit) {
				var overBy:int = Math.max(1, (assetByteCount - assetByteLimit) / 1024);
				DialogBox.notify(
					'Sorry!',
					'Adding that media asset would put this project over the size limit by ' + overBy + ' KB\n' +
					'Please remove some costumes, backdrops, or sounds before adding additional media.',
					stage);
				return false;
			}
			return true;
		}
		// -----------------------------
		// Flash sprite (helps connect a sprite on thestage with a sprite library entry)
		//------------------------------
		
		public function flashSprite(spr:ScratchSprite):void {
			function doFade(alpha:Number):void { box.alpha = alpha }
			function deleteBox():void { if (box.parent) { box.parent.removeChild(box) }}
			var r:Rectangle = spr.getVisibleBounds(this);
			var box:Shape = new Shape();
			box.graphics.lineStyle(3, CSS.overColor, 1, true);
			box.graphics.beginFill(0x808080);
			box.graphics.drawRoundRect(0, 0, r.width, r.height, 12, 12);
			box.x = r.x;
			box.y = r.y;
			addChild(box);
			Transition.cubic(doFade, 1, 0, 0.5, deleteBox);
		}
		
		// -----------------------------
		// Download Progress
		//------------------------------
		
		public function addLoadProgressBox(title:String):void {
			removeLoadProgressBox();
			lp = new LoadProgress();
			lp.setTitle(title);
			stage.addChild(lp);
			fixLoadProgressLayout();
		}
		
		public function removeLoadProgressBox():void {
			if (lp && lp.parent) lp.parent.removeChild(lp);
			lp = null;
		}
		
		private function fixLoadProgressLayout():void {
			if (!lp) return;
			var p:Point = stagePane.localToGlobal(new Point(0, 0));
			lp.scaleX = stagePane.scaleX;
			lp.scaleY = stagePane.scaleY;
			lp.x = int(p.x + ((stagePane.width - lp.width) / 2));
			lp.y = int(p.y + ((stagePane.height - lp.height) / 2));
		}
		
		// -----------------------------
		// Frame rate readout (for use during development)
		//------------------------------
		
		private var frameRateReadout:TextField;
		private var firstFrameTime:int;
		private var frameCount:int;
		
		protected function addFrameRateReadout(x:int, y:int, color:uint = 0):void {
			frameRateReadout = new TextField();
			frameRateReadout.autoSize = TextFieldAutoSize.LEFT;
			frameRateReadout.selectable = false;
			frameRateReadout.background = false;
			frameRateReadout.defaultTextFormat = new TextFormat(CSS.font, 12, color);
			frameRateReadout.x = x;
			frameRateReadout.y = y;
			addChild(frameRateReadout);
			frameRateReadout.addEventListener(Event.ENTER_FRAME, updateFrameRate);
		}
		
		private function updateFrameRate(e:Event):void {
			frameCount++;
			if (!frameRateReadout) return;
			var now:int = getTimer();
			var msecs:int = now - firstFrameTime;
			if (msecs > 500) {
				var fps:Number = Math.round((1000 * frameCount) / msecs);
				frameRateReadout.text = fps + ' fps (' + Math.round(msecs / frameCount) + ' msecs)';
				firstFrameTime = now;
				frameCount = 0;
			}
		}
//		
//		// TODO: Remove / no longer used
//		private const frameRateGraphH:int = 150;
//		private var frameRateGraph:Shape;
//		private var nextFrameRateX:int;
//		private var lastFrameTime:int;
//		
//		private function addFrameRateGraph():void {
//			addChild(frameRateGraph = new Shape());
//			frameRateGraph.y = stage.stageHeight - frameRateGraphH;
//			clearFrameRateGraph();
//			stage.addEventListener(Event.ENTER_FRAME, updateFrameRateGraph);
//		}
//		
//		public function clearFrameRateGraph():void {
//			var g:Graphics = frameRateGraph.graphics;
//			g.clear();
//			g.beginFill(0xFFFFFF);
//			g.drawRect(0, 0, stage.stageWidth, frameRateGraphH);
//			nextFrameRateX = 0;
//		}
//		
//		private function updateFrameRateGraph(evt:*):void {
//			var now:int = getTimer();
//			var msecs:int = now - lastFrameTime;
//			lastFrameTime = now;
//			var c:int = 0x505050;
//			if (msecs > 40) c = 0xE0E020;
//			if (msecs > 50) c = 0xA02020;
//			
//			if (nextFrameRateX > stage.stageWidth) clearFrameRateGraph();
//			var g:Graphics = frameRateGraph.graphics;
//			g.beginFill(c);
//			var barH:int = Math.min(frameRateGraphH, msecs / 2);
//			g.drawRect(nextFrameRateX, frameRateGraphH - barH, 1, barH);
//			nextFrameRateX++;
//		}
		
		// -----------------------------
		// Camera Dialog
		//------------------------------
		
		public function openCameraDialog(savePhoto:Function):void {
			closeCameraDialog();
			cameraDialog = new CameraDialog(savePhoto);
			cameraDialog.fixLayout();
			cameraDialog.x = (stage.stageWidth - cameraDialog.width) / 2;
			cameraDialog.y = (stage.stageHeight - cameraDialog.height) / 2;;
			addChild(cameraDialog);
		}
		
		public function closeCameraDialog():void {
			if (cameraDialog) {
				cameraDialog.closeDialog();
				cameraDialog = null;
			}
		}
		
		// Misc.
		public function createMediaInfo(obj:*, owningObj:ScratchObj = null):MediaInfo {
			return new MediaInfo(app, obj, owningObj);
		}
	}
}
