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

//2017/04/12 이승훈
// VariablePart.as

package ui.parts {
	import com.google.analytics.debug.Label;
	
	import flash.display.Bitmap;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.geom.Point;
	import flash.media.SoundMixer;
	import flash.media.SoundTransform;
	import flash.net.FileReference;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import flash.utils.setTimeout;
	
	import blocks.Block;
	
	import extensions.ConnectionManager;
	import extensions.SerialManager;
	
	import interpreter.Interpreter;
	import interpreter.Variable;
	
	import scratch.ScratchObj;
	import scratch.ScratchRuntime;
	import scratch.ScratchStage;
	
	import translation.Translator;
	
	import ui.BlockPalette;
	import ui.PaletteSelector;
	
	import uiwidgets.Button;
	import uiwidgets.DialogBox;
	import uiwidgets.IconButton;
	import uiwidgets.IndicatorLight;
	import uiwidgets.Menu;
	import uiwidgets.ScriptsPane;
	import uiwidgets.ScrollFrame;
	import uiwidgets.ZoomWidget;
	
	import util.ApplicationManager;
	import util.SharedObjectManager;

public class MonitorPart extends UIPart {

	public var nextY:int;
	private var shape:Shape;
	public var selector:PaletteSelector;
	private var batteryText:Sprite;
	private var ultraSonicText:Sprite;
	private var infrared1Text:Sprite;
	private var infrared2Text:Sprite;
	private var infrared3Text:Sprite;
	private var infrared4Text:Sprite;
	private var infrared5Text:Sprite;
	public var batteryValue:Label;
	public var ultraSonicValue:Label;
	public var infrared1Value:Label;
	public var infrared2Value:Label;
	public var infrared3Value:Label;
	public var infrared4Value:Label;
	public var infrared5Value:Label;
	public var batteryUnit:Sprite;
	public var ultraSonicUnit:Sprite;
	
	public function MonitorPart(app:Main):void {
		trace("MonitorPart IN!!!!!");
		this.app = app;
	}
	
	public function addMonitorText(name:String,value:int):void {
		nextY += 7;
		if(name=='battery level'){
			batteryText = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			batteryText.x = 5;
			batteryText.y = nextY;
			app.palette.addChild(batteryText);
			batteryValue = new Label(value.toString());
			batteryValue.name = name;
			batteryValue.x = app.palette.width-60;
			batteryValue.y = batteryText.y;
			app.palette.addChild(batteryValue);
			addLine(7, batteryText.y+batteryText.height+5, app.palette.width-25);
			
			batteryUnit = UIPart.makeButtonLabel(Translator.map('%'), CSS.textColor, false);
			batteryUnit.x = batteryValue.x+20;
			batteryUnit.y = batteryValue.y;
			app.palette.addChild(batteryUnit);
			
			nextY += batteryText.height/2*2.5;
		}else if(name=='ultrasonic sensor'){
			ultraSonicText = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			ultraSonicText.x = 5;
			ultraSonicText.y = nextY;
			app.palette.addChild(ultraSonicText);
			ultraSonicValue = new Label(value.toString());
			ultraSonicValue.name = name;
			ultraSonicValue.x = app.palette.width-60;
			ultraSonicValue.y = ultraSonicText.y;
			app.palette.addChild(ultraSonicValue);
			addLine(7, ultraSonicText.y+ultraSonicText.height+5, app.palette.width-25);
			
			ultraSonicUnit = UIPart.makeButtonLabel(Translator.map('cm'), CSS.textColor, false);
			ultraSonicUnit.x = ultraSonicValue.x+20;
			ultraSonicUnit.y = ultraSonicValue.y;
			app.palette.addChild(ultraSonicUnit);
			
			nextY += ultraSonicText.height/2*2.5;
		}else if(name=='infrared sensor No.1'){
			infrared1Text = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			infrared1Text.x = 5;
			infrared1Text.y = nextY;
			app.palette.addChild(infrared1Text);
			infrared1Value = new Label(value.toString());
			infrared1Value.name = name;
			infrared1Value.x = app.palette.width-60;
			infrared1Value.y = infrared1Text.y;
			app.palette.addChild(infrared1Value);
			
			nextY += infrared1Text.height/2*2.5;
		}else if(name=='infrared sensor No.2'){
			infrared2Text = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			infrared2Text.x = 5;
			infrared2Text.y = nextY;
			app.palette.addChild(infrared2Text);
			infrared2Value = new Label(value.toString());
			infrared2Value.name = name;
			infrared2Value.x = app.palette.width-60;
			infrared2Value.y = infrared2Text.y;
			app.palette.addChild(infrared2Value);
			
			nextY += infrared2Text.height/2*2.5;
		}else if(name=='infrared sensor No.3'){
			infrared3Text = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			infrared3Text.x = 5;
			infrared3Text.y = nextY;
			app.palette.addChild(infrared3Text);
			infrared3Value = new Label(value.toString());
			infrared3Value.name = name;
			infrared3Value.x = app.palette.width-60;
			infrared3Value.y = infrared3Text.y;
			app.palette.addChild(infrared3Value);
			
			nextY += infrared3Text.height/2*2.5;
		}else if(name=='infrared sensor No.4'){
			infrared4Text = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			infrared4Text.x = 5;
			infrared4Text.y = nextY;
			app.palette.addChild(infrared4Text);
			infrared4Value = new Label(value.toString());
			infrared4Value.name = name;
			infrared4Value.x = app.palette.width-60;
			infrared4Value.y = infrared4Text.y;
			app.palette.addChild(infrared4Value);
			
			nextY += infrared4Text.height/2*2.5;
		}else if(name=='infrared sensor No.5'){
			infrared5Text = UIPart.makeButtonLabel(Translator.map(name), CSS.textColor, false);
			infrared5Text.x = 5;
			infrared5Text.y = nextY;
			app.palette.addChild(infrared5Text);
			infrared5Value = new Label(value.toString());
			infrared5Value.name = name;
			infrared5Value.x = app.palette.width-60;
			infrared5Value.y = infrared5Text.y;
			app.palette.addChild(infrared5Value);
			addLine(7, infrared5Text.y+infrared5Text.height+5, app.palette.width-25);
			
			nextY += infrared5Text.height/2*2.5;
		}
		
	}
	
	public function changeMonitorValue(name:String,value:int):void {
		
	}
	
	private function addLine(x:int, y:int, w:int):void {
		const light:int = 0xF2F2F2;
		const dark:int = CSS.borderColor - 0x141414;
		var line:Shape = new Shape();
		var g:Graphics = line.graphics;
		
		g.lineStyle(1, dark, 1, true);
		g.moveTo(0, 0);
		g.lineTo(w, 0);
		
		g.lineStyle(1, light, 1, true);
		g.moveTo(0, 1);
		g.lineTo(w, 1);
		line.x = x;
		line.y = y;
		app.palette.addChild(line);
	}
	
}
}
