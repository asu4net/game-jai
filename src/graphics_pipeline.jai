#import "File";

Graphics_Pipeline :: struct {
    
}

init_graphics_pipeline :: (p : *Graphics_Pipeline, vertex_file : string, fragment_file : string) {
    vertex_code   := read_entire_file(vertex_file);
    fragment_code := read_entire_file(fragment_file);
}