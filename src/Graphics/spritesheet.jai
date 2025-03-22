Spritesheet :: struct {
    texture : Texture;
    rects   : Table(string, Rect);
}

fini_spritesheet :: (sheet : *Spritesheet) {
    assert(sheet != null);
    fini_texture(*sheet.texture);
    deinit(*sheet.rects);
}

generate_spritesheet :: (sheet_name : string, src_path : string, dst_path : string, max_width : s32, sheet : *Spritesheet) {
    assert(sheet != null);
    
    Image :: struct {
        name   : string;
        width  : s32;
        height : s32;
        pixels : [..] u8;
    }

    Visitor_Data :: struct {
        src_path : string;
        images   : [..] Image;
    }

    visitor :: (info : *File_Visit_Info, visitor_data : *Visitor_Data) {
	
        path, basename, ext := path_decomp(info.full_name);

        if ext != "png" && ext != "jpg" then return;

        load_image :: (folder_path : string, basename : string, ext : string) -> bool, Image {
            image : Image;
            count : s32;
            image_path := join(folder_path, basename, ".", ext);
            defer free(image_path);
            log("Loading %", image_path);
            stbi_set_flip_vertically_on_load(1);
            image.pixels.data = stbi_load(to_c_string(image_path ,,temp), *image.width, *image.height, *count, 0);
            image.pixels.count = image.width * image.height * count;
            image.name = basename;
            ok := image.pixels.data != null; 
            return ok, image;
        }

        ok, image := load_image(visitor_data.src_path, basename, ext);

        if !ok then {
            log_error("Could not load image: %", basename);
            return;
        }

        array_add(*visitor_data.images, image);
    }
    
    vst_data : Visitor_Data;
    vst_data.src_path = src_path;
    visit_files(src_path, false, *vst_data, visitor);
    
    images := vst_data.images;
    table_ensure_space(*sheet.rects, images.count);
    defer free(images.data);

    images_width : s32;
    for images images_width += it.width;

    sheet_width := min(images_width, max_width);
    x_offset, y_offset, max_row_height : s32;

    for images {
        if x_offset + it.width > sheet_width {
            x_offset = 0;
            y_offset += max_row_height;
            max_row_height = 0;
        }
        max_row_height = max(max_row_height, it.height);
        x_offset += it.width;
    }

    sheet_height := y_offset + max_row_height;

    pixel_count := sheet_width * sheet_height * 4;
    assert(sheet.texture.pixels.data == null);
    array_resize(*sheet.texture.pixels, pixel_count);

    x_offset = 0; 
    y_offset = 0;
    max_row_height = 0;
    
    for image : images {
        if x_offset + image.width > sheet_width {
            x_offset = 0;
            y_offset += max_row_height;
            max_row_height = 0;
        }
        for y : 0..image.height - 1 {
            for x : 0..image.width - 1 {
                sprite_idx := ((y + y_offset) * sheet_width + (x + x_offset)) * 4;
                //img_idx := ((image.height - 1 - y) * image.width + x) * 4;
                img_idx := (y * image.width + x) * 4;
                if sprite_idx < pixel_count && img_idx < image.width * image.height * 4 {
                    sheet.texture.pixels[sprite_idx] = image.pixels[img_idx];         //R
                    sheet.texture.pixels[sprite_idx + 1] = image.pixels[img_idx + 1]; //G
                    sheet.texture.pixels[sprite_idx + 2] = image.pixels[img_idx + 2]; //B
                    sheet.texture.pixels[sprite_idx + 3] = image.pixels[img_idx + 3]; //A
                }
            }
        }

        rect : Rect;
        rect.width  = image.width;
        rect.height = image.height;
        rect.x      = xx x_offset;
        rect.y      = xx y_offset;
        table_add(*sheet.rects, image.name, rect);

        x_offset += image.width;
        max_row_height = max(max_row_height, image.height);
    }

    sheet.texture.height   = xx sheet_height;
    sheet.texture.width    = xx sheet_width;
    sheet.texture.channels = 4;

    full_path := join(dst_path, "\\", sheet_name, ".png" ,,temp); 
    upload_texture_to_gpu(*sheet.texture);
    
    flip_pixels(sheet.texture.pixels.data, sheet_width, sheet_height ,,temp);
    stbi_write_png(to_c_string(full_path ,,temp), sheet_width, sheet_height, 4, sheet.texture.pixels.data, sheet_width * 4);
}

#scope_file

flip_pixels :: (pixels: *u8, width: int, height: int) {
    row_size := width * 4;
    aux := alloc(row_size);

    for y : 0..(height / 2) {
        top_idx := y * row_size;
        bottom_idx := (height - 1 - y) * row_size;

        memcpy(aux, pixels + bottom_idx, row_size);
        memcpy(pixels + bottom_idx, pixels + top_idx, row_size);
        memcpy(pixels + top_idx, aux, row_size);
    }
}


#import "Basic";
#import "String";
#import "File_Utilities";
#import "Hash_Table";
#import "stb_image_write";
#import "stb_image";