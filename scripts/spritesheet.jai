generate_spritesheet :: () {
    visit_files("../bin/assets/images", false, null, visitor);
}

#scope_file

visitor :: (info : *File_Visit_Info, data : *void) {
	path, basename, ext := path_decomp(info.full_name);
	
    if ext == "png" {
        log("PNG: %", basename);
	} 
    else if ext == "jpg" {
		log("JPG: %", basename);
	}
}

#import "Basic";
#import "String";
#import "File_Utilities";