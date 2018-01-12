// .blend file parser
// https://github.com/armory3d/blend
// Reference:
// https://github.com/fschutt/mystery-of-the-blend-backup
// https://web.archive.org/web/20170630054951/http://www.atmind.nl/blender/mystery_ot_blend.html
// Usage:
// var bl = new Blend(blob:kha.Blob);
// var scenes = bl.get("Scene");
// trace(scenes[0].get("id").get("name");
package blend;

// https://github.com/Kode/Kha
import kha.Blob;

class Blend {

	public var pos:Int;
	var blob:Blob;

	// Header
	public var version:String;
	public var pointerSize:Int;
	public var littleEndian:Bool;
	// Data
	public var blocks:Array<Block> = [];
	public var dna:Dna;

	public function new(blob:Blob) {
		this.blob = blob;
		this.pos = 0;

		if (readChars(7) == 'BLENDER') parse();
		// else decompress();
	}

	public function dir(type:String):Array<String> {
		// Return structure fields
		var typeIndex = getTypeIndex(dna, type);
		if (typeIndex == -1) return null;
		var ds = getStruct(dna, typeIndex);
		var fields:Array<String> = [];
		for (i in 0...ds.fieldNames.length) {
			var nameIndex = ds.fieldNames[i];
			var typeIndex = ds.fieldTypes[i];
			fields.push(dna.types[typeIndex] + ' ' + dna.names[nameIndex]);
		}
		return fields;
	}

	public function get(type:String):Array<Handle> {
		// Return all structures of type
		var typeIndex = getTypeIndex(dna, type);
		if (typeIndex == -1) return null;
		var ds = getStruct(dna, typeIndex);
		var handles:Array<Handle> = [];
		for (b in blocks) {
			if (dna.structs[b.sdnaIndex].type == typeIndex) {
				var h = new Handle();
				handles.push(h);
				h.block = b;
				h.ds = ds;
			}
		}
		return handles;
	}

	public static function getStruct(dna:Dna, typeIndex:Int):DnaStruct {
		for (ds in dna.structs) if (ds.type == typeIndex) return ds;
		return null;
	}

	public static function getTypeIndex(dna:Dna, type:String):Int {
		for (i in 0...dna.types.length) if (type == dna.types[i]) { return i; }
		return -1;
	}

	function parse() {

		// Pointer size: _ 32bit, - 64bit
		pointerSize = readChar() == '_' ? 4 : 8;

		// v - little endian, V - big endian
		littleEndian = readChar() == 'v';
		if (littleEndian) {
			read16 = read16LE;
			read32 = read32LE;
		}
		else {
			read16 = read16BE;
			read32 = read32BE;
		}

		version = readChars(3);

		// Reading file blocks
		// Header - data
		while (pos < blob.length) {

			align();

			var b = new Block();

			// Block type
			b.code = readChars(4);

			if (b.code == 'ENDB') break;
			
			blocks.push(b);
			b.blend = this;

			// Total block length
			b.size = read32();

			// var addr;
			pos += pointerSize;

			// Index of dna struct contained in this block
			b.sdnaIndex = read32();

			// Number of dna structs in this block
			b.count = read32();

			b.pos = pos;

			// This block stores dna structures
			if (b.code == 'DNA1') {
				dna = new Dna();

				var id = readChars(4); // SDNA
				var nameId = readChars(4); // NAME
				var namesCount = read32();
				for (i in 0...namesCount) {
					dna.names.push(readString());
				}
				align();


				var typeId = readChars(4); // TYPE
				var typesCount = read32();
				for (i in 0...typesCount) {
					dna.types.push(readString());
				}
				align();


				var lenId = readChars(4); // TLEN
				for (i in 0...typesCount) {
					dna.typesLength.push(read16());
				}
				align();


				var structId = readChars(4); // STRC
				var structCount = read32();
				for (i in 0...structCount) {
					var ds = new DnaStruct();
					dna.structs.push(ds);
					ds.dna = dna;
					ds.type = read16();
					var fieldCount = read16();
					if (fieldCount > 0) {
						ds.fieldTypes = [];
						ds.fieldNames = [];
						for (j in 0...fieldCount) {
							ds.fieldTypes.push(read16());
							ds.fieldNames.push(read16());
						}
					}
				}
			}
			else {
				pos += b.size;
			}
		}
	}

	function align() {
		// 4 bytes aligned
		var mod = pos % 4;
		if (mod > 0) pos += 4 - mod;
	}

	public function read8():Int {
		var i = blob.readU8(pos);
		pos += 1;
		return i;
	}

	public var read16:Void->Int;
	public var read32:Void->Int;

	function read16LE():Int {
		var i = blob.readS16LE(pos);
		pos += 2;
		return i;
	}

	function read32LE():Int {
		var i = blob.readS32LE(pos);
		pos += 4;
		return i;
	}

	function read16BE():Int {
		var i = blob.readS16BE(pos);
		pos += 2;
		return i;
	}

	function read32BE():Int {
		var i = blob.readS32BE(pos);
		pos += 4;
		return i;
	}

	function readString():String {
		var s = '';
		while (true) {
			var ch = read8();
			if (ch == 0) break;
			s += String.fromCharCode(ch);
		}
		return s;
	}

	function readChars(len:Int):String {
		var s = '';
		for (i in 0...len) s += readChar();
		return s;
	}

	function readChar():String {
		return String.fromCharCode(read8());
	}
}

class Block {
	public var blend:Blend;
	public var code:String;
	public var size:Int;
	// public var addr:Dynamic;
	public var sdnaIndex:Int;
	public var count:Int;
	public var pos:Int; // Byte pos of data start in blob
	public function new() {}
}

class Dna {
	public var names:Array<String> = [];
	public var types:Array<String> = [];
	public var typesLength:Array<Int> = [];
	public var structs:Array<DnaStruct> = [];
	public function new() {}
}

class DnaStruct {
	public var dna:Dna;
	public var type:Int; // Index in dna.types
	public var fieldTypes:Array<Int>; // Index in dna.types
	public var fieldNames:Array<Int>; // Index in dna.names
	public function new() {}
}

class Handle {
	public var block:Block;
	public var offset:Int = 0; // Block data bytes offset
	public var ds:DnaStruct;
	public function new() {}
	function traverse() {
		var n = dna.names[ds.fieldNames[j]];
		if (n.indexOf('[') > 0) {
			var c = Std.parseInt(n.substring(n.indexOf('[') + 1, n.indexOf(']')));
			size *= c;
		}
		else if (n.indexOf('*') > 0) {
			size = block.blend.pointerSize;
		}
	}
	public function get(name:String):Dynamic {
		// Return raw type or structure
		var dna = ds.dna;
		for (i in 0...ds.fieldNames.length) {
			var nameIndex = ds.fieldNames[i];
			if (name == dna.names[nameIndex]) {
				var typeIndex = ds.fieldTypes[i];
				var newOffset = offset;
				for (j in 0...i) newOffset += traverseSize();
				// Raw type
				if (dna.types[typeIndex] == 'int') {
					var blend = block.blend;
					blend.pos = block.pos + newOffset;
					return blend.read32();
				}
				else if (dna.types[typeIndex] == 'char') { return 0; } // 1
				else if (dna.types[typeIndex] == 'uchar') { return 0; } // 1
				else if (dna.types[typeIndex] == 'short') { return 0; } // 2
				else if (dna.types[typeIndex] == 'ushort') { return 0; } // 2
				else if (dna.types[typeIndex] == 'long') { return 0; } // 4
				else if (dna.types[typeIndex] == 'ulong') { return 0; } //4
				else if (dna.types[typeIndex] == 'float') { return 0; } // 4
				else if (dna.types[typeIndex] == 'double') { return 0; } // 8
				else if (dna.types[typeIndex] == 'int64_t') { return 0; } // 8
				else if (dna.types[typeIndex] == 'uint64_t') { return 0; } // 8
				else if (dna.types[typeIndex] == 'void') { return 0; } // 0

				// Structure
				var h = new Handle();
				h.ds = Blend.getStruct(dna, typeIndex);
				h.block = block;
				h.offset = newOffset;
				return h;
			}
		}
		return null;
	}
}
