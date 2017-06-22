/*
 * Scratch Project Editor and Player
 * Copyright (C) 2014 Massachusetts Institute of Technology
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */

// ScriptsPart.as
// John Maloney, November 2011
//
// This part holds the palette and scripts pane for the current sprite (or stage).

package ui.parts {
	import com.kamibot.bleextension.BluetoothExtension;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import blocks.Block;
	
	import extensions.ConnectionManager;
	import extensions.SerialDevice;
	import extensions.SerialManager;
	
	import scratch.ScratchObj;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.PaletteSelector;
	
	import uiwidgets.DialogBox;
	import uiwidgets.IconButton;
	import uiwidgets.IndicatorLight;
	import uiwidgets.Menu;
	import uiwidgets.ScriptsPane;
	import uiwidgets.ScrollFrame;
	import uiwidgets.ZoomWidget;
	
	import util.ApplicationManager;

public class ScriptsPart extends UIPart {

	private var shape:Shape;
	public var selector:PaletteSelector;
	private var spriteWatermark:Bitmap;
	private var paletteFrame:ScrollFrame;
	private var scriptsFrame:ScrollFrame;
//	private var arduinoFrame:ScrollFrame;
//	private var arduinoTextPane:TextPane;
//	private var messageTextPane:TextPane;
//	private var lineNumText:TextField;
	private var zoomWidget:ZoomWidget;

//	private var lineNumWidth:uint = 20;
//	private const readoutLabelFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor, true);
//	private const readoutFormat:TextFormat = new TextFormat(CSS.font, 12, CSS.textColor);

//	private var xyDisplay:Sprite;
//	private var xLabel:TextField;
//	private var yLabel:TextField;
//	private var xReadout:TextField;
//	private var yReadout:TextField;
	private var lastX:int = -10000000; // impossible value to force initial update
	private var lastY:int = -10000000; // impossible value to force initial update
//	private var backBt:Button = new Button(Translator.map("Back"));
//	private var uploadBt:Button = new Button(Translator.map("Upload to Arduino"));
//	private var openBt:Button = new Button(Translator.map("Open with Arduino IDE"));
//	private var sendBt:Button = new Button(Translator.map("Send"));
//	private var sendTextPane:TextPane;
	
	private var runButton:IconButton;
	private var stopButton:IconButton;
	//2017/06/15 이승훈 추가 
	private var resetButton:IconButton;
	private var _serial:BluetoothExtension;
	
	private var bluetoothButton:IconButton;
	
	private var runButtonOnTicks:int;
	private var lastUpdateTime:uint;
	private var menuButton:IconButton;

	public function ScriptsPart(app:Main) {
		this.app = app;

		addChild(shape = new Shape());
		addChild(spriteWatermark = new Bitmap());
//		addXYDisplay();
		addChild(selector = new PaletteSelector(app));

		var palette:BlockPalette = new BlockPalette();
		palette.color = CSS.tabColor;
		paletteFrame = new ScrollFrame();
		paletteFrame.allowHorizontalScrollbar = false;
		paletteFrame.setContents(palette);
		addChild(paletteFrame);

		var scriptsPane:ScriptsPane = new ScriptsPane(app);
		scriptsFrame = new ScrollFrame(true);
		scriptsFrame.setContents(scriptsPane);
		addChild(scriptsFrame);
		
		app.palette = palette;
		app.scriptsPane = scriptsPane;

		addChild(zoomWidget = new ZoomWidget(scriptsPane));
		
		addButtons();
		
		ConnectionManager.sharedManager().addEventListener(Event.CONNECT,onConnect);		
		ConnectionManager.sharedManager().addEventListener(Event.CLOSE,onClose);
	}
	
	public function resetCategory():void { selector.select(Specs.eventsCategory) }//Debug

	public function updatePalette():void {
		selector.updateTranslation();
		selector.select(selector.selectedCategory);
	}
	public function updateSpriteWatermark():void {
		var target:ScratchObj = app.viewedObj();
		if (target && !target.isStage) {
			spriteWatermark.bitmapData = target.currentCostume().thumbnail(40, 40, false);
		} else {
			spriteWatermark.bitmapData = null;
		}
	}

	public function step():void {
		// Update the mouse reaadouts. Do nothing if they are up-to-date (to minimize CPU load).
		var target:ScratchObj = app.viewedObj();
//		if (target.isStage) {
//		} else {
//
//			var spr:ScratchSprite = target as ScratchSprite;
//			if (!spr) return;
//			if (spr.scratchX != lastX) {
//				lastX = spr.scratchX;
//				xReadout.text = String(lastX);
//			}
//			if (spr.scratchY != lastY) {
//				lastY = spr.scratchY;
//				yReadout.text = String(lastY);
//			}
//		}
		updateExtensionIndicators();
		
		updateRunStopButtons();
	}

	private function updateExtensionIndicators():void {
		if ((getTimer() - lastUpdateTime) < 500) return;
		for (var i:int = 0; i < app.palette.numChildren; i++) {
			var indicator:IndicatorLight = app.palette.getChildAt(i) as IndicatorLight;
			if (indicator) app.extensionManager.updateIndicator(indicator, indicator.target);
		}		
		lastUpdateTime = getTimer();
	}

	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		fixlayout();
		redraw();
	}

	private function fixlayout():void {
		
		this.scaleX = ApplicationManager.sharedManager().scale;
		this.scaleY = ApplicationManager.sharedManager().scale;
		
		selector.x = 1;
		selector.y = 5;
		paletteFrame.x = selector.x;
		paletteFrame.y = selector.y + selector.height + 2;
		
		paletteFrame.setWidthHeight(selector.width + 1, h - paletteFrame.y - 2);
		scriptsFrame.x = selector.x + selector.width + 2;
		scriptsFrame.y = selector.y + 1;
		
		scriptsFrame.setWidthHeight(w - scriptsFrame.x - 15, h - scriptsFrame.y - 5);
		
		spriteWatermark.x = w - 60;
		spriteWatermark.y = scriptsFrame.y + 10;
		zoomWidget.x = w - zoomWidget.width - 30;
		zoomWidget.y = h - zoomWidget.height - 15;
		
		runButton.x = scriptsFrame.x + 10;
		runButton.y = 10;
		runButton.scaleX = 0.15;
		runButton.scaleY = 0.15;
		stopButton.x = runButton.x + 60;
		stopButton.y = runButton.y + 1;
		stopButton.scaleX = 0.15;
		stopButton.scaleY = 0.15;
		//2017/06/15 이승훈 
		resetButton.x = stopButton.x +55;
		resetButton.y = stopButton.y -2.5 ;
		resetButton.width =runButton.width+8;
		resetButton.height =runButton.height+8;
		
		bluetoothButton.x = scriptsFrame.x + scriptsFrame.width - bluetoothButton.width - menuButton.width - 20;
		bluetoothButton.y = 10;
		bluetoothButton.scaleX = 0.18;
		bluetoothButton.scaleY = 0.18;
		
		menuButton.x = bluetoothButton.x + 60;
		menuButton.y = bluetoothButton.y;
		menuButton.isMomentary = true;
		menuButton.scaleX = 0.08;
		menuButton.scaleY = 0.08;
		
	}
	
	private function updateRunStopButtons():void {
		// Update the run/stop buttons.
		// Note: To ensure that the user sees at least a flash of the
		// on button, it stays on a minumum of two display cycles.
		if (app.interp.threadCount() > 0) threadStarted();
		else { // nothing running
			if (runButtonOnTicks > 2) {
				runButton.turnOff();
				stopButton.turnOn();
			}
		}
		runButtonOnTicks++;
	}
	
	public function threadStarted():void {
		runButtonOnTicks = 0;
		runButton.turnOn();
		stopButton.turnOff();
	}

	private function redraw():void {
		var paletteW:int = paletteFrame.visibleW();
		var paletteH:int = paletteFrame.visibleH();
		var scriptsW:int = scriptsFrame.visibleW();
		var scriptsH:int = scriptsFrame.visibleH();
		
		var g:Graphics = shape.graphics;
		g.clear();
		g.lineStyle(1, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		var lineY:int = selector.y + selector.height;
		var darkerBorder:int = CSS.borderColor - 0x141414;
		var lighterBorder:int = 0xF2F2F2;
		g.lineStyle(1, darkerBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY, paletteW - 20);
		g.lineStyle(1, lighterBorder, 1, true);
		hLine(g, paletteFrame.x + 8, lineY + 1, paletteW - 20);

		g.lineStyle(1, darkerBorder, 1, true);
		g.drawRect(scriptsFrame.x - 1, scriptsFrame.y - 1, scriptsW + 1, scriptsH + 1);
	}

	private function hLine(g:Graphics, x:int, y:int, w:int):void {
		g.moveTo(x, y);
		g.lineTo(x + w, y);
	}
	
	
	private function onConnect(e:Event):void {
		bluetoothButton.turnOn();
	}
	
	private function onClose(e:Event):void {
		bluetoothButton.turnOff();
	}
	
	//2017/04/10 이승훈녹음 재생 버튼 추
	private function addButtons():void {
		function startAll(b:IconButton):void { 
			if (Main.app.interp.isWaiting) { trace("interp.isWaiting");return; }
			playButtonPressed(b.lastEvent);
		}
		function stopAll(b:IconButton):void {
			app.runtime.stopAll();
		}
		function bluetoothPressed(b:IconButton):void {
			
			if (!SerialManager.sharedManager().enabled) {
				requestEnabled();
				return;
			}
			
			if (!SerialManager.sharedManager().connected) {
				connect();
			} else {
				disconnect();
			}
		}
		function setMenuPressed(b:IconButton):void {
			
			function setMenu(v:String):void {
//				for each (var lang:Array in Translator.languages) {
//					if (v == lang[0]) {
//						Translator.setLanguage(lang[0]);
//						Main.app.languageChanged = true;
//						return;
//					}
//				}
				Translator.setLanguage(v);
				Main.app.languageChanged = true;
			}
			
			var m:Menu = new Menu(setMenu, 'Menu', CSS.topBarColor, 28);
			if (Translator.languages.length == 0) return;
			for each (var entry:Array in Translator.languages) {
				m.addItem(entry[1], entry[0],true,Translator.currentLang==entry[0]);
			}
			m.addLine();
			m.addItem('set block size');
			m.addLine();
			m.addItem(''+Main.versionString+"."+Main.currentVer, 'version', false, false);
			var p:Point = b.localToGlobal(new Point(b.x, b.bottom()));
			
			m.showOnStage(
				stage,
				p.x - (b.width * util.ApplicationManager.sharedManager().scale),
				p.y + (b.height * util.ApplicationManager.sharedManager().scale)
				);
		}
		
		//2017/06/15 이승훈 
		
		function setResetPressed(b:IconButton):void {
			trace("runButton.isOn() : "+runButton.isOn());
			if(SerialManager.sharedManager().connected&&!runButton.isOn()){
				app.extensionManager.call("KamiBot","setRGbLed",["Blue"]);
				app.interp.isWaiting = false;
				function sleep(ms:int):void {
					var init:int = getTimer();
					while(true) {
						if(getTimer() - init >= ms) {
							break;
						}
					}
				}
				sleep(200);
				ConnectionManager.sharedManager().setState(0);
				app.extensionManager.call("KamiBot","runServo",[90]);
				app.interp.isWaiting = false;
				resetButton.turnOff();
				
			}else{
				resetButton.turnOff();
			}
		}
		
		runButton = new IconButton(startAll, 'greenflag');
		runButton.actOnMouseUp();
		addChild(runButton);
		stopButton = new IconButton(stopAll, 'stop');
		addChild(stopButton);
		bluetoothButton = new IconButton(bluetoothPressed, 'bluetoothIcon');
		addChild(bluetoothButton);
		menuButton = new IconButton(setMenuPressed, 'menu');
		addChild(menuButton);
		//2017/06/15 이승훈
		resetButton = new IconButton(setResetPressed, 'reset');
		addChild(resetButton);
		
	}
	
	public function connect():void {
		if(ConnectionManager.sharedManager().requestAuthority()){
			ConnectionManager.sharedManager().open();
			//twinkle bluetooth button 100ms
			var myTimer:Timer = new Timer(100,0);
			myTimer.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void{
				if (SerialManager.sharedManager().scanning) {
					trace("bluetoothButton.isOn() = " + bluetoothButton.isOn());
					if (bluetoothButton.isOn()) bluetoothButton.turnOff();
					else bluetoothButton.turnOn();
				} else {
					myTimer.stop();
				}
			});
			myTimer.start();
			
		}else{
			bluetoothButton.turnOff();
		}
	}
	
	public function requestEnabled():void {
		
		if (ApplicationManager.isAndroid) {
			SerialManager.sharedManager().requestEnabled();
			Main.app.isRequestBluetooth = true;
		} else {
			DialogBox.notify('Bluetooth Disabled', 'Be enable bluetooth to connect device', Main.app.stage, true, null);
		}
		bluetoothButton.turnOff();
	}
	
	public function disconnect():void {
		ConnectionManager.sharedManager().close();
		bluetoothButton.turnOff();
		Main.app.runtime.stopAll();
	}
	
	public function playButtonPressed(evt:MouseEvent):void {
		if(app.loadInProgress) {
			stopEvent(evt);
			return;
		}
		
		// Mute the project if it was started with the control key down
		SoundMixer.soundTransform = new SoundTransform((evt && evt.ctrlKey ? 0 : 1));
		
		if (evt && evt.shiftKey) {
			app.toggleTurboMode();
			return;
		}
		
		stopEvent(evt);
		app.runtime.startGreenFlags();
	}
	
	private function stopEvent(e:Event):void {
		e.stopImmediatePropagation();
		e.preventDefault();
	}

}}
