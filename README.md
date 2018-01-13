# blend

Embed and read blend files at runtime in Armory

Usage:
- git clone https://github.com/armory3d/blend (or Download Zip) into your `project_root/Libraries` folder
- Place .blend file into `project_root/Bundled`
- Create a new script trait:

```hx
Data.getBlob("test.blend", function(blob:kha.Blob) {
	var bl = new Blend(blob);
	trace(bl.dir("Scene")); // List Scene fields
	var scenes = bl.get("Scene"); // Get scenes
	if (scenes.length > 0) {
		trace(scenes[0].get("id").get("name")); // Print scene name
	}
});
```
