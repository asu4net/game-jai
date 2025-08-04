Rect :: struct {
    x: s32; 
    y: s32; 
    width: int; 
    height: int;
}

Image_Atlas_Item :: struct {
    name: string;
    rect: Rect;
}

Image_Atlas :: struct {
    image: Image; @JsonIgnore
    items: [] Image_Atlas_Item;
}

is_image_atlas_initialized :: inline (atlas : Image_Atlas) -> bool {
    return is_image_loaded(atlas.image);
}

deinit_image_atlas :: (atlas: *Image_Atlas) -> bool {
    if !is_image_atlas_initialized(atlas) then return false;
    for item: atlas.items {
        free(item.name);
    }
    free(*atlas.items);
    free_image(*atlas.image);
    return true;
}

init_image_atlas :: (atlas: *Image_Atlas, folder_path: string, name: string, max_width: s32 = 1024) -> bool {
    Image_Array :: [..] Image;
    visitor :: (info : *File_Utils.File_Visit_Info, images: *Image_Array) {
        ok, image := load_image(info.full_name);
        if !ok then return;
        array_add(*(images.*), image);
    }
    images: [..] Image;
    ok := File.make_directory_if_it_does_not_exist(folder_path, recursive = true);
    if !ok then return false;
    File_Utils.visit_files(folder_path, recursive = false, *images, visitor ,,temp);
    return init_image_atlas(atlas, images, name, max_width);
}

init_image_atlas :: (atlas: *Image_Atlas, images: []Image, name: string, max_width: s32 = 1024) -> bool {
    assert(atlas != null);
    log("Generating atlas [%] ...", name);

    if !name.count {
        log_error("Can not generate an atlas with an empty name.");
        return false;
    }

    if !images.count || max_width <= 0 {
        log_error("Could not generate atlas [%].", name);
        return false;
    }

    if is_image_atlas_initialized(atlas.*) {
        deinit_image_atlas(atlas);
    }
    atlas.image.name = copy_string(name);
    atlas.items = NewArray(images.count, Image_Atlas_Item);

    images_width: s32;
    for images images_width += it.width;

    atlas.image.width = min(images_width, max_width);
    x_offset, y_offset, max_row_height : s32;

    for images {
        if x_offset + it.width > atlas.image.width {
            x_offset = 0;
            y_offset += max_row_height;
            max_row_height = 0;
        }
        max_row_height = max(max_row_height, it.height);
        x_offset += it.width;
    }

    atlas.image.height = y_offset + max_row_height;

    pixel_count := atlas.image.width * atlas.image.height * 4;
    array_resize(*atlas.image.pixels, pixel_count);
    
    x_offset = 0; 
    y_offset = 0;
    max_row_height = 0;
    
    for image : images {
        if x_offset + image.width > atlas.image.width {
            x_offset = 0;
            y_offset += max_row_height;
            max_row_height = 0;
        }
        for y : 0..image.height - 1 {
            for x : 0..image.width - 1 {
                sprite_idx := ((y + y_offset) * atlas.image.width + (x + x_offset)) * 4;
                //img_idx := ((image.height - 1 - y) * image.width + x) * 4;
                img_idx := (y * image.width + x) * 4;
                if sprite_idx < pixel_count && img_idx < image.width * image.height * 4 {
                    atlas.image.pixels[sprite_idx] = image.pixels[img_idx];         //R
                    atlas.image.pixels[sprite_idx + 1] = image.pixels[img_idx + 1]; //G
                    atlas.image.pixels[sprite_idx + 2] = image.pixels[img_idx + 2]; //B
                    atlas.image.pixels[sprite_idx + 3] = image.pixels[img_idx + 3]; //A
                }
            }
        }

        item := *atlas.items[it_index];
        
        item.name = copy_string(image.name);
        rect := *item.rect;
        rect.width = image.width;
        rect.height = image.height;
        rect.x = x_offset;
        rect.y = y_offset;

        x_offset += image.width;
        max_row_height = max(max_row_height, image.height);
    }
    
    log("Image atlas generated [%].", name);
    return true;
}

save_image_atlas :: (atlas: Image_Atlas, location: string, flip := false) -> bool {
    ok := File.make_directory_if_it_does_not_exist(location, recursive = true);
    if !ok then return false;
    ok = save_image(atlas.image, location, flip);
    if !ok then return false;
    atlas_location := String.join(location, "/", atlas.image.name, ".json");
    #if JAISON then ok = Jaison.json_write_file(atlas_location, atlas);
    return ok;
}