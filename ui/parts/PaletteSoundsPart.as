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

// SoundsPart.as
// John Maloney, November 2011
//
// This part holds the sounds list for the current sprite (or stage),
// as well as the sound recorder, editor, and import button.

//2017/04/13 이승훈
//레코드 팔레트 스크립트 추가
package ui.parts {
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.PermissionEvent;
	import flash.filesystem.File;
	import flash.filesystem.StorageVolumeInfo;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.net.FileReference;
	import flash.permissions.PermissionStatus;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.setTimeout;
	
	import assets.Resources;
	
	import scratch.PaletteBuilder;
	import scratch.ScratchObj;
	import scratch.ScratchSound;
	
	import sound.WAVFile;
	import sound.mp3.MP3Loader;
	
	import soundedit.PaletteSoundEditor;
	
	import soundequalizer.everydayflash.equalizer.util.SpectrumReader;
	
	import translation.Translator;
	
	import ui.media.MediaLibrary;
	import ui.media.MediaPane;
	
	import uiwidgets.DialogBox;
	import uiwidgets.EditableLabel;
	import uiwidgets.IconButton;
	import uiwidgets.Menu;
	import uiwidgets.ScrollFrame;
	import uiwidgets.SimpleTooltips;

public class PaletteSoundsPart extends UIPart {

	public var editor:PaletteSoundEditor;
	public static var currentIndex:int;
	
	private const columnWidth:int = 106;

	private var shape:Shape;
	private var listFrame:ScrollFrame;
	private var nameField:EditableLabel;
	private var undoButton:IconButton;
	private var redoButton:IconButton;

	private var newSoundLabel:TextField;
	//2017/04/17 이승훈 수정
//	private var libraryButton:IconButton;
//	private var importButton:IconButton;
//	public var recordButton:IconButton;
	
	
	public function PaletteSoundsPart(app:Main) {
		trace("PaletteSoundsPart In");
		this.app = app;
		app.palette.addChild(shape = new Shape());
		//app.palette.addChild(newSoundLabel = makeLabel('', new TextFormat(CSS.font, 12, CSS.textColor, true)));
		//addNewSoundButtons();
		//addListFrame();
		app.palette.addChild(editor = new PaletteSoundEditor(app, this));
		//app.palette.addChild(nameField = new EditableLabel(nameChanged));
		//addUndoButtons();
		//app.stage.addEventListener(KeyboardEvent.KEY_DOWN, editor.keyDown);
		updateTranslation();
		//2017/06/13 이승훈 추가
		
	}

	
	public static function strings():Array {
		new PaletteSoundsPart(Main.app).showNewSoundMenu(Menu.dummyButton());
		return [
			'New sound:', 'recording1',
			'Choose sound from library', 'Record new sound', 'Upload sound from file',
		];
	}

	public function updateTranslation():void {
		//newSoundLabel.text = Translator.map('New sound:');
		//editor.updateTranslation();
		//SimpleTooltips.add(libraryButton, {text: 'Choose sound from library', direction: 'bottom'});
		//SimpleTooltips.add(recordButton, {text: 'Record new sound', direction: 'bottom'});
		//SimpleTooltips.add(importButton, {text: 'Upload sound from file', direction: 'bottom'});			
		fixlayout();
	}

	public function selectSound(snd:ScratchSound):void{
		var obj:ScratchObj = app.viewedObj();
		trace("selectSound() app.viewedObj() : "+app.viewedObj());
		if (obj == null) return;
		if (obj.sounds.length == 0) return;
		currentIndex = 0;
		for (var i:int = 0; i < obj.sounds.length; i++) {
			if ((obj.sounds[i] as ScratchSound) == snd) currentIndex = i;
		}
		//(listFrame.contents as MediaPane).updateSelection();
		refresh();
	}
	
	public function refresh():void {
		trace("PaletteSoundsPart refresh() In!!!!!!!!!!!");
//		var contents:MediaPane = listFrame.contents as MediaPane;
//		contents.refresh();
//		nameField.setContents('');
		var viewedObj:ScratchObj = app.viewedObj();
		if (viewedObj.sounds.length < 1) {
//			nameField.visible = false;
//			editor.visible = false;
//			undoButton.visible = false;
//			redoButton.visible = false;
			return;
		} else {
//			nameField.visible = true;
//			editor.visible = true;
//			undoButton.visible = true;
//			redoButton.visible = true;
//			refreshUndoButtons();
		}
		editor.waveform.stopAll();
		var snd:ScratchSound = viewedObj.sounds[currentIndex];
		trace("currentIndex : "+currentIndex);
		if (snd) {
			editor.waveform.editSound(snd);
		}
		
	}

	//2017/04/20 이승훈
	public function setCurrentIdx(idx:int):void { currentIndex = idx;  }
	public function getCurrentIdx():int { return currentIndex;  }
	
	public function setWidthHeight(w:int, h:int):void {
		this.w = w;
		this.h = h;
		var g:Graphics = shape.graphics;
		g.clear();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.tabColor);
		g.drawRect(0, 0, w, h);
		g.endFill();

		g.lineStyle(0.5, CSS.borderColor, 1, true);
		g.beginFill(CSS.panelColor);
		g.drawRect(columnWidth + 1, 5, w - columnWidth - 6, h - 10);
		g.endFill();

		fixlayout();
	}

	private function fixlayout():void {
		//newSoundLabel.x = 7;
		//newSoundLabel.y = 7;

		//listFrame.x = 1;
		//listFrame.y = 90;
		//listFrame.width = app.palette.width/2;
		//listFrame.height = app.palette.height*2/3;
		//listFrame.setWidthHeight(columnWidth, h - listFrame.y);

		var contentsX:int = columnWidth + 13;
		var contentsW:int = w - contentsX - 15;

		//nameField.setWidth(Math.min(135, contentsW));
		//nameField.setWidth(app.palette.width);
		//nameField.x = 7;
		//nameField.x = contentsX;
		//nameField.y = 60;

		// undo buttons
//		undoButton.x = nameField.x + nameField.width + 30;
//		redoButton.x = undoButton.right() + 8;
//		undoButton.y = redoButton.y = nameField.y - 2;

//		editor.setWidthHeight(contentsW, 200);
//		editor.x = contentsX;
//		editor.y = 50;
	}
	
	private function addNewSoundButtons():void {
		var left:int = 16;
		var buttonY:int = 31;
		//app.palette.addChild(libraryButton = makeButton(soundFromLibrary, 'soundlibrary', left, buttonY));
		//app.palette.addChild(recordButton = makeButton(recordSound, 'record', left, buttonY));
		//app.palette.addChild(importButton = makeButton(soundFromComputer, 'import', left + 61, buttonY - 1));
	}

	private function makeButton(fcn:Function, iconName:String, x:int, y:int):IconButton {
		var b:IconButton = new IconButton(fcn, iconName);
		b.isMomentary = true;
		b.x = x;
		b.y = y;
		return b;
	}
	
	private function addListFrame():void {
		listFrame = new ScrollFrame();
		listFrame.setContents(app.getMediaPane(app, 'sounds'));
		listFrame.contents.color = CSS.tabColor;
		listFrame.allowHorizontalScrollbar = false;
		app.palette.addChild(listFrame);
	}

	// -----------------------------
	// Sound Name
	//------------------------------

	private function nameChanged():void {
		currentIndex = Math.min(currentIndex, app.viewedObj().sounds.length - 1);
		var current:ScratchSound = app.viewedObj().sounds[currentIndex] as ScratchSound;
		current.soundName = nameField.contents();
		(listFrame.contents as MediaPane).refresh();
	}

	// -----------------------------
	// Undo/Redo
	//------------------------------
	
	private function addUndoButtons():void {
//		addChild(undoButton = new IconButton(editor.waveform.undo, makeButtonImg('undo', true), makeButtonImg('undo', false)));
//		addChild(redoButton = new IconButton(editor.waveform.redo, makeButtonImg('redo', true), makeButtonImg('redo', false)));
		undoButton.isMomentary = true;
		redoButton.isMomentary = true;
	}

	public function refreshUndoButtons():void {
//		undoButton.setDisabled(!editor.waveform.canUndo(), 0.5);
//		redoButton.setDisabled(!editor.waveform.canRedo(), 0.5);
	}
	
	public static function makeButtonImg(iconName:String, isOn:Boolean, buttonSize:Point = null):Sprite {
		var icon:Bitmap = Resources.createBmp(iconName + (isOn ? 'On' : 'Off'));
		var buttonW:int = Math.max(icon.width, buttonSize ? buttonSize.x : 24);
		var buttonH:int = Math.max(icon.height, buttonSize ? buttonSize.y : 24);

		var img:Sprite = new Sprite();
		var g:Graphics = img.graphics;
		g.clear();
		g.lineStyle(0.5, CSS.borderColor, 1, true);
		if (isOn) {
			g.beginFill(CSS.overColor);
		} else {
			var m:Matrix = new Matrix();
			m.createGradientBox(24, 24, Math.PI / 2, 0, 0);
			g.beginGradientFill(GradientType.LINEAR, CSS.titleBarColors , [100, 100], [0x00, 0xFF], m);
		}
		g.drawRoundRect(0, 0, buttonW, buttonH, 8);
		g.endFill();

		icon.x = (buttonW - icon.width) / 2;
		icon.y = (buttonH - icon.height) / 2;
		img.addChild(icon);
		return img;
	}

	// -----------------------------
	// Menu
	//------------------------------

	private function showNewSoundMenu(b:IconButton):void {
		var m:Menu = new Menu(null, 'New Sound', 0xB0B0B0, 28);
		m.minWidth = 90;
		//m.addItem('Library', soundFromLibrary);
		//m.addItem('Record', recordSound);
		//m.addItem('Import', soundFromComputer);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x - 1, p.y + b.height - 2);
	}

	public function soundFromLibrary(b:* = null):void {
		new MediaLibrary(app, "sound", app.PaletteAddSound).open();
	}

	public function soundFromComputer(b:* = null):void {
		new MediaLibrary(app, "sound", app.PaletteAddSound).importFromDisk();
	}

	//2017/04/19 이승훈 추가
	private var idx1Chk:Boolean=false;
	private var idx2Chk:Boolean=false;
	private var idx3Chk:Boolean=false;
	private var idx4Chk:Boolean=false;
	private var idx5Chk:Boolean=false;
	
	public function getRecordSound(b:* = null):Boolean {
		var v:Boolean;
		trace("getRecordSound In ");
		//new MediaLibrary(app, "sound", app.PaletteAddSound).importFromDisk();
		var dir:File = File.documentsDirectory.resolvePath("KamiBlock/Sounds");
		trace("dir.nativePath : "+dir.nativePath);
		var filesList:Array = new Array();
		if (File.permissionStatus!=PermissionStatus.GRANTED)
		{
			dir.addEventListener(PermissionEvent.PERMISSION_STATUS,
			function(e:PermissionEvent):void{
				if(e.status == PermissionStatus.GRANTED)
				{
					if(dir.exists){
						filesList = dir.getDirectoryListing();
					}else{
						dir.createDirectory();	
					}
					//you can also use getDirectoryListingAsync to have this run in the background
					//인덱스 저장
					idx1Chk=false;
					idx2Chk=false;
					idx3Chk=false;
					idx4Chk=false;
					idx5Chk=false;
					
					for (var idx:int = 0; idx < filesList.length; idx++)
					{
						var file:FileReference = FileReference(filesList[idx]);
						if(file.name.substr(0,9)=='recording'){
							if(file.name.substr(9,file.name.indexOf(".")-9)=="1"){
								idx1Chk = true;
							}
							else if(file.name.substr(9,file.name.indexOf(".")-9)=="2")
							{
								idx2Chk = true;
							}
							else if(file.name.substr(9,file.name.indexOf(".")-9)=="3")
							{
								idx3Chk = true;
							}
							else if(file.name.substr(9,file.name.indexOf(".")-9)=="4")
							{
								idx4Chk = true;
							}
							else if(file.name.substr(9,file.name.indexOf(".")-9)=="5")
							{
								idx5Chk = true;
							}
							file.addEventListener(Event.COMPLETE, fileLoaded);
							file.load();
							function fileLoaded(e:Event):void {
								var newName:String = FileReference(e.target).name.substr(0,file.name.indexOf("."));
								trace("fileLoaded In!!! newName : "+newName);
								app.PaletteAddSound(new ScratchSound(newName, FileReference(e.target).data));
							}
						}
					}
					
					allDone();
				}
				else
				{
					//permission denied
					v=false;
				}
			});
				
			try
			{
				dir.requestPermission();
				v=false;
			} catch(e:Error)
			{
				//another request is in progress
			}
		}
		else
		{
			if(dir.exists){
				filesList = dir.getDirectoryListing();
			}else{
				dir.createDirectory();	
			}
			//you can also use getDirectoryListingAsync to have this run in the background
			//인덱스 저장
			idx1Chk=false;
			idx2Chk=false;
			idx3Chk=false;
			idx4Chk=false;
			idx5Chk=false;
			
			for (var idx:int = 0; idx < filesList.length; idx++)
			{
				var file:FileReference = FileReference(filesList[idx]);
				if(file.name.substr(0,9)=='recording'){
					if(file.name.substr(9,file.name.indexOf(".")-9)=="1"){
						idx1Chk = true;
					}
					else if(file.name.substr(9,file.name.indexOf(".")-9)=="2")
					{
						idx2Chk = true;
					}
					else if(file.name.substr(9,file.name.indexOf(".")-9)=="3")
					{
						idx3Chk = true;
					}
					else if(file.name.substr(9,file.name.indexOf(".")-9)=="4")
					{
						idx4Chk = true;
					}
					else if(file.name.substr(9,file.name.indexOf(".")-9)=="5")
					{
						idx5Chk = true;
					}
					file.addEventListener(Event.COMPLETE, fileLoaded);
					file.load();
					function fileLoaded(e:Event):void {
						var newName:String = FileReference(e.target).name.substr(0,file.name.indexOf("."));
						trace("fileLoaded In!!! newName : "+newName);
						app.PaletteAddSound(new ScratchSound(newName, FileReference(e.target).data));
					}
				}
			}
			
			allDone();
			
			v=true;
		}
		
		return v;
		
	}
	
	public function allDone(b:* = null):void{
		if(!idx1Chk){
			var newName1:String = app.viewedObj().unusedSoundName('recording1');
			app.PaletteAddSound(new ScratchSound(newName1, WAVFile.empty()));
		}
		if(!idx2Chk){
			var newName2:String = app.viewedObj().unusedSoundName('recording2');
			app.PaletteAddSound(new ScratchSound(newName2, WAVFile.empty()));
		}
		if(!idx3Chk){
			var newName3:String = app.viewedObj().unusedSoundName('recording3');
			app.PaletteAddSound(new ScratchSound(newName3, WAVFile.empty()));
		}
		if(!idx4Chk){
			var newName4:String = app.viewedObj().unusedSoundName('recording4');
			app.PaletteAddSound(new ScratchSound(newName4, WAVFile.empty()));
		}
		if(!idx5Chk){
			var newName5:String = app.viewedObj().unusedSoundName('recording5');
			app.PaletteAddSound(new ScratchSound(newName5, WAVFile.empty()));
		}
	}
}}
