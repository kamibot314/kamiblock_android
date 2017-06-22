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

// SoundEditor.as
// John Maloney, June 2012

//2017/04/13 이승훈
//레코드 팔레트 스크립트 추가
package soundedit {
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.media.Microphone;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.Timer;
	
	import assets.Resources;
	
	import scratch.ScratchSound;
	
	import soundequalizer.everydayflash.equalizer.Equalizer;
	import soundequalizer.everydayflash.equalizer.EqualizerSettings;
	import soundequalizer.everydayflash.equalizer.color.SolidBarColor;
	
	import translation.Translator;
	
	import ui.parts.PaletteSoundsPart;
	import ui.parts.SoundsPart;
	import ui.parts.UIPart;
	
	import uiwidgets.ComboBox;
	import uiwidgets.IconButton;
	import uiwidgets.Menu;
	import uiwidgets.Scrollbar;
	import uiwidgets.Slider;
	
	import util.ApplicationManager;
	
public class PaletteSoundEditor extends Sprite {

	private const waveHeight:int = 25;
	private const borderColor:int = 0x606060;
	private const bgColor:int = 0xF0F0F0;
	private const cornerRadius:int = 20;

	public var app:Main;

	private static var microphone:Microphone = Microphone.getMicrophone();

	public var waveform:PaletteWaveformView;
	public var levelMeter:SoundLevelMeter;
	public var scrollbar:Scrollbar;

	private var buttons:Array = [];
	public var playButton:IconButton;
	public var stopButton:IconButton;
	public var recordButton:IconButton;
	//2017/04/18 이승훈
	public var comboButton:IconButton;
	
	private var editButton:IconButton;
	private var effectsButton:IconButton;

	private var recordIndicator:Shape;
	private var playIndicator:Shape;

	private var micVolumeLabel:TextField;
	private var micVolumeSlider:Slider;

	//2017/04/17 이승훈추가
	private var paletteSoundsPart:PaletteSoundsPart;
	
	//2017/06/12 이승훈 추가
	//플레이 레코드 표시
	private var recordingIndicator:TextField;
	private var playingIndicator:TextField;
	public var savingIndicator:TextField;
	public var equalizerSettings:EqualizerSettings;
	public var equalizer:Equalizer;
	public var recordPlayTime:TextField;
	public var recordPlayUnit:TextField;
	
	public function PaletteSoundEditor(app:Main, soundsPart:PaletteSoundsPart) {
		trace("PaletteSoundEditor In");
		this.app = app;
		paletteSoundsPart = soundsPart;
		//addChild(scrollbar = new Scrollbar(10, 10, waveform.setScroll));
		addChild(waveform = new PaletteWaveformView(this, soundsPart));
		addControls();
		var currentIdx:int = soundsPart.getCurrentIdx();
		trace("currentIdx : "+currentIdx);
		if(currentIdx){
			var nameIdx:int = currentIdx+1;
			comboButton.setLabel(Translator.map("recording"+nameIdx),null,null,true);
		}
		addIndicators();
		//addEditAndEffectsButtons();
		//addMicVolumeSlider();
		updateIndicators();
	}

	public static function strings():Array {
		var editor:PaletteSoundEditor = new PaletteSoundEditor(null, null);
		editor.editMenu(Menu.dummyButton());
		editor.effectsMenu(Menu.dummyButton());
		return ['Edit', 'Effects', 'Microphone Volume:'];
	}

	public function updateTranslation():void {
		if (editButton.parent) {
			removeChild(editButton);
			removeChild(effectsButton);
			removeChild(micVolumeSlider);
			removeChild(micVolumeLabel);
		}
		addEditAndEffectsButtons();
		setWidthHeight(width, height);
		addMicVolumeSlider();
	}

	public function shutdown():void { waveform.stopAll() }

	public function setWidthHeight(w:int, h:int):void {
		levelMeter.x = stopButton.x+10;
		levelMeter.y = stopButton.y;
		waveform.x = 23;
		waveform.y = 0;
		scrollbar.x = 25;
		scrollbar.y = waveHeight + 5;

		var waveWidth:int = w - waveform.x;
		waveform.setWidthHeight(waveWidth, waveHeight);
		scrollbar.setWidthHeight(waveWidth, 10);

		var nextX:int = waveform.x - 2;
		var buttonY:int = waveform.y + waveHeight + 25;
		for each (var b:IconButton in buttons) {
			b.x = nextX;
			b.y = buttonY;
			nextX += b.width + 8;
		}
		editButton.x = nextX + 20;
		editButton.y = buttonY;

		effectsButton.x = editButton.x + editButton.width + 15;
		effectsButton.y = editButton.y;

		recordIndicator.x = recordButton.x;
		recordIndicator.y = recordButton.y;

		playIndicator.x = playButton.x;
		playIndicator.y = playButton.y;
		
	}

	//2017/06/08 이승훈
	private function addControls():void {
		playButton = new IconButton(waveform.startPlaying, 'playSnd', null, true);
		stopButton = new IconButton(waveform.stopAll, 'stopSnd', null, true);
		recordButton = new IconButton(waveform.toggleRecording, 'recordSnd', null, true);
		comboButton = UIPart.makeMenuButton('recording1', comboList, true, CSS.textColor);
		buttons = [playButton, stopButton, recordButton, comboButton];
		var left:int = 35;
		var buttonY:int = 5;
		var idx:int = 0;
		for each (var b:IconButton in buttons) {
			if (b is IconButton){
				if(b.name != comboButton.name){
					b.isMomentary = false;
				}else{
					b.isMomentary = true;
				}
				
			}
			app.palette.addChild(b);
			//app.palette.addChild(b);
			b.x = 8+left*idx;
			b.y = buttonY;
			idx++;
		}
		comboButton.x = comboButton.x + 28;
		comboButton.y = comboButton.y + 6;
		comboButton.height = 18;
		//2017/06/12 이승훈 추가
		//타이머 및 진행정보
		equalizerSettings =  new EqualizerSettings(); 
		equalizerSettings.numOfBars = 1;
		equalizerSettings.height = 5;
		equalizerSettings.barSize = 100;
		equalizerSettings.vgrid = true;
		equalizerSettings.hgrid = 2;
		equalizerSettings.colorManager = new SolidBarColor(0xffff4444);
		equalizerSettings.effect = EqualizerSettings.FX_REFLECTION;
		
		equalizer = new Equalizer(null,this);
		equalizer.update(equalizerSettings);
		//app.palette.addChild(equalizer);
		//equalizer.x = 10;
		//equalizer.y = stopbar.y;
		//addEventListener(Event.ENTER_FRAME, equalizer.render);
		app.palette.addChild(levelMeter = new SoundLevelMeter(99, waveHeight));
		levelMeter.x = playButton.x+1;
		levelMeter.y = playButton.y+35;
		
		var fmt:TextFormat = new TextFormat(CSS.font, 18, 0xffffff);
		recordingIndicator = Resources.makeLabel(Translator.map('Recording...'), fmt, 8, 12);
		recordingIndicator.visible = false;
		app.palette.addChild(recordingIndicator);
		recordingIndicator.x += 1;
		recordingIndicator.y = playButton.y + 34;
		
		fmt = new TextFormat(CSS.font, 18, 0xffffff);
		playingIndicator = Resources.makeLabel(Translator.map('Playing...'), fmt, 8, 12);
		playingIndicator.visible = false;
		app.palette.addChild(playingIndicator);
		playingIndicator.x += 1;
		playingIndicator.y = playButton.y + 34;
		
		fmt = new TextFormat(CSS.font, 18, 0xffffff);
		savingIndicator = Resources.makeLabel(Translator.map('Saving...'), fmt, 8, 12);
		savingIndicator.visible = false;
		app.palette.addChild(savingIndicator);
		savingIndicator.x += 1;
		savingIndicator.y = playButton.y + 34;
		
		fmt = new TextFormat(CSS.font, 18, 0x333333);
		recordPlayTime = Resources.makeLabel('0', fmt, 15, 12);
		recordPlayTime.x = levelMeter.x+132;
		recordPlayTime.y = levelMeter.y;
		recordPlayTime.text = "0";
		app.palette.addChild(recordPlayTime);
		fmt = new TextFormat(CSS.font, 18, 0x333333);
		recordPlayUnit = Resources.makeLabel(Translator.map('sec'), fmt, 15, 12);
		recordPlayUnit.x = levelMeter.x+157;
		recordPlayUnit.y = levelMeter.y;
		app.palette.addChild(recordPlayUnit);
	}
	
	public var time:Number = new Number(); 
	public function onRecordTime(event:TimerEvent):void{
		trace("onRecordTime");
		recordPlayTime.text = event.target.currentCount;
	}
	public function onPlayTime(event:TimerEvent):void{
		trace("onPlayTime");
		recordPlayTime.text = event.target.currentCount;
	}
	
	private function comboList(b:IconButton):void {
		var m:ComboBox = new ComboBox(setRecordData,"recordComboBox",CSS.topBarColor, 28);
		m.addItem(Translator.map("recording1"));
		m.addItem(Translator.map("recording2"));
		m.addItem(Translator.map("recording3"));
		m.addItem(Translator.map("recording4"));
		m.addItem(Translator.map("recording5"));
		var p:Point = b.localToGlobal(new Point(0, 0));
		//2017/06/08 이승훈 수정
		m.showOnStage(app.palette.stage, p.x + 1, p.y + b.height - 1);
	}
	//2017/04/18 이승훈 레코드 파일 지정
	private function setRecordData(name:String):void{
		comboButton.setLabel(name,null,null,true);
		trace("Number(name.substr(name.length-1,1)) : "+Number(name.substr(name.length-1,1)));
		var snd:ScratchSound = app.viewedObj().sounds[Number(name.substr(name.length-1,1))-1];
		trace("setRecordData snd.soundName : "+snd.soundName);
		if (snd) {
			waveform.editSound(snd);
			paletteSoundsPart.setCurrentIdx(Number(name.substr(name.length-1,1))-1);
		}
	}
	private function addEditAndEffectsButtons():void {
		addChild(editButton = UIPart.makeMenuButton('Edit', editMenu, true, CSS.textColor));
		addChild(effectsButton = UIPart.makeMenuButton('Effects', effectsMenu, true, CSS.textColor));
		
	}

	private function addMicVolumeSlider():void {
		function setMicLevel(level:Number):void { microphone.gain = level }
		addChild(micVolumeLabel = Resources.makeLabel(Translator.map('Microphone volume:'), CSS.normalTextFormat, 22, 240));

		micVolumeSlider = new Slider(130, 5, setMicLevel);
		micVolumeSlider.min = 1;
		micVolumeSlider.max = 100;
		micVolumeSlider.value = 50;
		micVolumeSlider.x = micVolumeLabel.x + micVolumeLabel.textWidth + 15;
		micVolumeSlider.y = micVolumeLabel.y + 7;
		addChild(micVolumeSlider);
	}

	public function addIndicators():void {
		recordIndicator = new Shape();
		var g:Graphics = recordIndicator.graphics;
		g.beginFill(0xFF0000);
		g.drawCircle(8, 8, 8)
		g.endFill();
		//2017/06/08
		addChild(recordIndicator);

		playIndicator = new Shape();
		g = playIndicator.graphics;
		g.beginFill(0xFF00);
		g.moveTo(0, 0);
		g.lineTo(11, 8);
		g.lineTo(11, 10);
		g.lineTo(0, 18);
		g.endFill();
		//2017/06/08
		addChild(playIndicator);
		//2017/06/07 이승훈 추가
		recordIndicator.x = recordButton.x + 9;
		recordIndicator.y = recordButton.y + 8;
		
		playIndicator.x = playButton.x + 12;
		playIndicator.y = playButton.y + 7;
		
	}

	public function updateIndicators():void {
		recordIndicator.visible = waveform.isRecording();
		playIndicator.visible = waveform.isPlaying();
		stopButton.turnOff();
		playButton.turnOff();
		recordButton.turnOff();
		if(waveform.isRecording()){
			recordButton.turnOn();
			recordingIndicator.visible = true;
			playingIndicator.visible = false;
			//stopbar.visible = false;
		}else if(waveform.isPlaying()){
			playButton.turnOn();
			recordingIndicator.visible = false;
			playingIndicator.visible = true;
			//stopbar.visible = true;
		}else{
			stopButton.turnOn();
			recordingIndicator.visible = false;
			playingIndicator.visible = false;
			//stopbar.visible = true;
		}
		
		//if (microphone) micVolumeSlider.value = microphone.gain;
	}

	/* Menus */

	private function editMenu(b:IconButton):void {
		var m:Menu = new Menu();
		m.addItem('undo', waveform.undo);
		m.addItem('redo', waveform.redo);
		m.addLine();
		m.addItem('cut', waveform.cut);
		m.addItem('copy', waveform.copy);
		m.addItem('paste', waveform.paste);
		m.addLine();
		m.addItem('delete', waveform.deleteSelection);
		m.addItem('select all', waveform.selectAll);
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}

	private function effectsMenu(b:IconButton):void {
		function applyEffect(selection:String):void { waveform.applyEffect(selection, shiftKey) }
		var shiftKey:Boolean = b.lastEvent.shiftKey;
		var m:Menu = new Menu(applyEffect);
		m.addItem('fade in');
		m.addItem('fade out');
		m.addLine();
		m.addItem('louder');
		m.addItem('softer');
		m.addItem('silence');
		m.addLine();
		m.addItem('reverse');
		var p:Point = b.localToGlobal(new Point(0, 0));
		m.showOnStage(stage, p.x + 1, p.y + b.height - 1);
	}

	/* Keyboard Shortcuts */

	public function keyDown(evt:KeyboardEvent):void {
		if (!stage || stage.focus) return; // sound editor is hidden or someone else has keyboard focus; do nothing
		var k:int = evt.keyCode;
		if ((k == 8) || (k == 127)) waveform.deleteSelection(evt.shiftKey);
		if (k == 37) waveform.leftArrow();
		if (k == 39) waveform.rightArrow();
		if (evt.ctrlKey || evt.shiftKey) { // shift or control key commands (control keys may be grabbed by the browser on Windows...)
			switch (String.fromCharCode(k)) {
			case 'A': waveform.selectAll(); break;
			case 'C': waveform.copy(); break;
			case 'V': waveform.paste(); break;
			case 'X': waveform.cut(); break;
			case 'Y': waveform.redo(); break;
			case 'Z': waveform.undo(); break;
			}
		}
		if (!evt.ctrlKey) {
			var ch:String = String.fromCharCode(evt.charCode);
			if (ch == ' ') waveform.togglePlaying();
			if (ch == '+') waveform.zoomIn();
			if (ch == '-') waveform.zoomOut();
		}
	}

}}
