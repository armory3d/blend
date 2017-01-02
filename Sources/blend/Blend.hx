// http://www.atmind.nl/blender/mystery_ot_blend.html
package blend;

class Blend {

	var pos = 0;
	var blob:kha.Blob;

	public function new(blob:kha.Blob) {
		this.blob = blob;

		var s = '';
		for (i in 0...7) {
			s += String.fromCharCode(blob.readU8(pos));
			pos++;
		}
		if (s == 'BLENDER') parse();
	}

	function parse() {
		// Pointer size: _ 32bit, - 64bit
		var psize = String.fromCharCode(blob.readU8(pos));
		pos++;

		// v - little endian, V - big endian
		var endian =String.fromCharCode(blob.readU8(pos));
		pos++;

		var ver = '';
		for (i in 0...3) {
			ver += String.fromCharCode(blob.readU8(pos));
			pos++;
		}

		while (pos < blob.length) {

			var code = '';
			for (i in 0...4) {
				code += String.fromCharCode(blob.readU8(pos));
				pos++;
			}

			if (code == 'ENDB') {
				break;
			}

			var size = blob.readS32LE(pos); // LE/BE
			pos += 4;

			// var oldMemAddr;
			pos += 8; // pointer-size (4/8)

			var sdnaIndex = blob.readS32LE(pos);
			pos += 4;

			var count = blob.readS32LE(pos);
			pos += 4;

			if (code == 'DNA1') {
			}

			// Global
			else if (code == 'GLOB') {}
			// Image
			else if (StringTools.startsWith(code, 'IM')) {}
			// Lamp
			else if (StringTools.startsWith(code, 'LA')) {}
			// Material
			else if (StringTools.startsWith(code, 'MA')) {}
			// Mesh
			else if (StringTools.startsWith(code, 'ME')) {}
			// Object
			else if (StringTools.startsWith(code, 'OB')) {}
			// Scene
			else if (StringTools.startsWith(code, 'SC')) {}

			pos += size;

			// 4 bytes aligned
			var mod = pos % 4;
			if (mod > 0) pos += 4 - mod;
		}
	}
}
