﻿import soundequalizer.everydayflash.equalizer;

/**
 * Copyright (c) 2008 Bartek Drozdz (http://www.everydayflash.com)
 * 
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

 /**
  * If the equalizer has only one color this is the class to use.
  */
 package soundequalizer.everydayflash.equalizer.color {
	
	import soundequalizer.everydayflash.equalizer.EqualizerSettings;
	
	/**
	  * @author Bartek Drozdz (http://www.everydayflash.com)
	  * @version 1.0
	  */
	public class SolidBarColor implements BarColor {
		
		private var color:uint;
		
		public function SolidBarColor(cl:uint=0xffffffff) {
			color = cl;
		}
		
		public function setSettings(settings:EqualizerSettings):void {
			// Solid color does not need the settings
		}
		
		public function getColor(x:int, y:int):uint {
			// return color;
			return color;
		}
		
		public function onRendered():void {
			// Solid color does not need the settings
		}
	}
	
}