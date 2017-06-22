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

// PaletteSelector.as
// John Maloney, August 2009
//
// PaletteSelector is a UI widget that holds set of PaletteSelectorItems
// and supports changing the selected category. When the category is changed,
// the blocks palette is filled with the blocks for the selected category.

package ui {
	import flash.display.Graphics;
	import flash.display.Sprite;
	import flash.filters.ColorMatrixFilter;
	import flash.system.Capabilities;
	
	import scratch.PaletteBuilder;
	
	import translation.Translator;
	
	import uiwidgets.Menu;

public class PaletteSelector extends Sprite {

	//2017/04/11 이승훈 추가
	//녹음 카테고리, Monitor Category
	private static const categories:Array = [
		'Events','Robots','Sound','Record', // column 1
		'Data','Control', 'Operators']; // column 2
		//'Data','Control', 'Operators', 'Monitor']; // column 2
		
	
	public var selectedCategory:int = 0;
	private var app:Main;
	public static var paletteSoundsPartInitChk:Boolean = true;
	
	public function PaletteSelector(app:Main) {
		this.app = app;
		initCategories();
	}

	public static function strings():Array { return categories }
	public function updateTranslation():void { initCategories() }

	public function select(id:int, shiftKey:Boolean = false):void {
		for (var i:int = 0; i < numChildren; i++) {
			var item:PaletteSelectorItem = getChildAt(i) as PaletteSelectorItem;
			item.setSelected(item.categoryID == id);
//			if(i<=3||i==5||i==7){
//				if(app.stageIsArduino){
//					item.mouseEnabled = false;
//					item.mouseChildren = false;
//					item.alpha = 0.4;
//				}else{
//					item.mouseEnabled = true;
//					item.mouseChildren = true;
//					item.alpha = 1.0;
//				}
//			}
		}
		var oldID:int = selectedCategory;
		selectedCategory = id;
		//2017/04/11 이승훈
		//녹음 카테고리 진입시 녹음창 생성 id ==13, 아닐경우 블록 생성
		if(selectedCategory==13){
			//2017/06/08 이승훈 추가
			if(paletteSoundsPartInitChk){
				app.soundsPart.getRecordSound();
				paletteSoundsPartInitChk = false;
			}
			app.getPaletteBuilder().showRecordPalette((id != oldID), shiftKey);
		}else if(selectedCategory==3){
			if(paletteSoundsPartInitChk){
				app.soundsPart.getRecordSound()
				paletteSoundsPartInitChk = false;
			}
			app.getPaletteBuilder().showBlocksForCategory(selectedCategory, (id != oldID), shiftKey);
		}else{
			app.getPaletteBuilder().showBlocksForCategory(selectedCategory, (id != oldID), shiftKey);
		}
		
	}

	private function initCategories():void {
		const numberOfRows:int = 4;
		const w:int = 235;
//		const w:int = Capabilities.screenDPI * 1.35;
		
		const startY:int = 3;
		var itemH:int;
		var x:int, i:int;
		var y:int = startY;
		while (numChildren > 0) removeChildAt(0); // remove old contents

		for (i = 0; i < categories.length; i++) {
			if (i == numberOfRows) {
				x = (w / 2) - 7;
				y = startY;
			}
			var entry:Array = Specs.entryForCategory(categories[i]);
			var item:PaletteSelectorItem = new PaletteSelectorItem(entry[0], Translator.map(entry[1]), entry[2]);
			item.scaleX = 1.5;
			item.scaleY = 1.5;
			itemH = item.height;
			item.x = x;
			item.y = y;
			addChild(item);
			y += itemH;
		}
		setWidthHeightColor(w, startY + (numberOfRows * itemH) + 5);
	}

	private function setWidthHeightColor(w:int, h:int):void {
		var g:Graphics = graphics;
		g.clear();
		g.beginFill(0x000000, 0); // invisible (alpha = 0) rectangle used to set size
		g.drawRect(0, 0, w, h);
	}

}}
