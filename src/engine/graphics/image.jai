Image :: struct {
    name: string;
    width: s32;
    height: s32;
    pixels: [] u8;
}

is_image_loaded :: inline (image: Image) -> bool {
    return image.pixels.count > 0;
}

load_image :: inline (src: string) -> bool, Image {
    image: Image;
    ok := load_image(*image, src);
    return ok, image;
}

load_image :: (image: *Image, src: string) -> bool {
    assert(image != null);
    if is_image_loaded(image) then free_image(image);
    path, basename, ext := String.path_decomp(src ,,temp);
    if ext != "png" && ext != "jpg" then return false;
    image.name = String.copy_string(basename);
    log("Loading image [%] ...", src);
    #import "stb_image";
    stbi_set_flip_vertically_on_load(1);
    count: s32;
    image.pixels.data = stbi_load(to_c_string(src ,,temp), *image.width, *image.height, *count, 0);
    image.pixels.count = image.width * image.height * count;
    success := image.pixels.data != null;
    if !success then log("Could not load image [%]", src);
    return success;
}

free_image :: (image: *Image) -> bool {
    assert(image != null);
    if !is_image_loaded(image) then return false; 
    free(image.name);
    free(image.pixels.data);
    Initialize(image);
    return true;
}

save_image :: (using image: Image, location: string, flip := false) -> bool {
    if !is_image_loaded(image) then return false;
    log("Saving image [%] ...", image.name);
    final_image := image;

    if flip {
        ok, flipped_image := flip_image(image);
        if !ok then return false;
        final_image = flipped_image;
    }
    path := String.join(location, "/", name, ".png" ,,temp);
    if File_Utils.file_exists(path) then File.file_delete(path);
    
    #import "stb_image_write";
    ok := stbi_write_png(to_c_string(path), width, height, 4, final_image.pixels.data, width * 4) != 0;
    
    if flip then free_image(*final_image); 
    log("Image [%] saved at [%].", name, path);
    return ok;
}

flip_image :: (using image: Image, new_name := "") -> bool, Image {
    if !is_image_loaded(image) then return false, .{};

    row_size := width * 4;
    flipped_pixels := alloc(width * height * 4);

    src: *u8 = pixels.data;
    dst: *u8 = flipped_pixels;

    for y: 0..height {
        src_row := src + (height - 1 - y) * row_size;
        dst_row := dst + y * row_size;
        memcpy(dst_row, src_row, row_size);
    }
    
    image_copy := image;
    image_copy.name = new_name;
    image_copy.pixels.data = flipped_pixels;
    return true, image_copy;
}