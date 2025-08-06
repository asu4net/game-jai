#insert #run generate_comp_time_atlas();

get_atlas_rect :: (t: Atlas_Image) -> Rect {
    if t == .COUNT then return .{};
    return ATLAS_RECT_DATA[xx t];
}

#scope_file

ATLAS_CODE :: #string SCOPE
ATLAS_FILE_LOCATION :: "%";

Atlas_Image :: enum {
%
    COUNT;
}

ATLAS_RECT_DATA :: Rect.[
%];
SCOPE

ATLAS_IMAGE_ENUM_ELEM :: #string SCOPE
    %;
SCOPE

RECT_ENTRY_CODE :: #string SCOPE
    .{ %, %, %, % },
SCOPE

generate_comp_time_atlas :: () -> string {
    #import "Compiler";

    default_code :: inline () -> string {
        return sprint(ATLAS_CODE, "", "", "");
    }

    cwd := get_working_directory();

    ASSETS_DIR :: "bin/assets";

    assets_dir_created := File.make_directory_if_it_does_not_exist(ASSETS_DIR, recursive = true);
    if !assets_dir_created {
        log_error("Failed to create atlas. Couldn't setup the binaries dir. [%]", ASSETS_DIR);
        return default_code();
    } 

    set_working_directory("bin");
    
    defer set_working_directory(cwd);
    atlas: Image_Atlas;

    ATLAS_JSON_SRC  :: #run, stallable String.join(ATLAS_DST_DIR, "/", ATLAS_NAME, ".json");
    ATLAS_IMAGE_SRC :: #run, stallable String.join(ATLAS_DST_DIR, "/", ATLAS_NAME, ".png");
    
    log("Looking for atlas in [%] [%]", ATLAS_JSON_SRC, ATLAS_IMAGE_SRC);
    if File_Utils.file_exists(ATLAS_IMAGE_SRC) && File_Utils.file_exists(ATLAS_JSON_SRC) {
        log("Atlas found.");
        atlas_str := File.read_entire_file(ATLAS_JSON_SRC);
        ok, res := Jaison.json_parse_string(atlas_str, Image_Atlas);
        if ok then {
            atlas = res;
        }
    }
    
    if !atlas.items.count {
        log("Atlas not found.");
        ok := init_image_atlas(*atlas, ATLAS_SRC_DIR, ATLAS_NAME);
        if !ok {
            log("Failed to create atlas % from %", ATLAS_NAME, ATLAS_SRC_DIR);
            return default_code();
        }
        ok = save_image_atlas(*atlas, ATLAS_DST_DIR, flip = true);
        if !ok {
            log("Failed to save atlas % at %", ATLAS_NAME, ATLAS_DST_DIR);
            return default_code();
        }
    }
    
    atlas_enum_builder: String_Builder;
    atlas_rect_entry_builder: String_Builder;

    for item: atlas.items {
        upper_name := String.to_upper_copy(item.name);
        String.print_to_builder(*atlas_enum_builder, ATLAS_IMAGE_ENUM_ELEM, upper_name);
        using item.rect;
        String.print_to_builder(*atlas_rect_entry_builder, RECT_ENTRY_CODE, x, y, width, height);
    }
    
    return sprint(ATLAS_CODE,
        String.join(ATLAS_DST_DIR, "/", ATLAS_NAME, ".png"), 
        String.builder_to_string(*atlas_enum_builder),
        String.builder_to_string(*atlas_rect_entry_builder)
    );
}