PATH_OF_IMAGES :: "../bin/assets/images/" 

generate_spritesheet :: () {
    visit_files(PATH_OF_IMAGES, false, null, visitor);
}

#scope_file

Image :: struct {
    name   : string;
    width  : s32;
    height : s32;
    pixels : [..] u8;
}

images : [..] Image;

visitor :: (info : *File_Visit_Info, data : *void) {
	
    path, basename, ext := path_decomp(info.full_name);

    if ext != "png" && ext != "jpg" then return;
    
    load_image :: (basename : string, ext : string) -> bool, Image {
        image : Image;
        count : s32;
        image_path := String.join(PATH_OF_IMAGES, basename, ".", ext);
        log("Loading %", image_path);
        stbi_set_flip_vertically_on_load(1);
        image.pixels.data = stbi_load(image_path.data, *image.width, *image.height, *count, 0);
        image.pixels.count = count;
        image.name = basename;
        ok := image.pixels.data != null; 
        return ok, image;
    }
    
    ok, image := load_image(basename, ext);

    if !ok then {
        log_error("Could not load image: %", basename);
        return;
    }

    array_add(*images, image);
}

#import "Basic";
#import "String";
#import "File_Utilities";
#import "Hash_Table";
#import "Rect_Pack";
#import "stb_image_write";
#import "stb_image";