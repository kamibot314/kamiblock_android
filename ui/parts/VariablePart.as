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

public class VariablePart extends UIPart {

	private var shape:Shape;
	public var selector:PaletteSelector;
	private var spriteWatermark:Bitmap;
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
	private var bluetoothButton:IconButton;
	private var runButtonOnTicks:int;
	private var lastUpdateTime:uint;
	private var menuButton:IconButton;
	private var square:Sprite; //variable value Back
	
	public function VariablePart(app:Main):void {
		trace("VariablePart IN!!!!!");
		this.app = app;
	}
	
	// Define a mouse down handler (user is dragging)
	function mouseDownHandler(evt:MouseEvent):void {
		var object = evt.currentTarget;
		// we should limit dragging to the area inside the canvas
		object.startDrag();
	}
	
	function mouseUpHandler(evt:MouseEvent):void {
		var obj = evt.currentTarget;
		obj.stopDrag();
	}
	
	//2017/06/02 이승훈 수정
	public function createVariable(idx:int,varName:String, isList:Boolean):void {
		trace("createVariable In!!! nothing now");
		
	}
	
}
}
