draw_editor_string :: (name : *u8, s : *string) {
    
    MAX_COUNT :: 500;
    buffer: [MAX_COUNT] u8;
    count := min(s.count, MAX_COUNT);
    memcpy(*buffer, s.data, count);
    buffer[count] = #char "\0";
    
    if ImGui.InputText(name, buffer.data, MAX_COUNT, .EnterReturnsTrue) {
        new_count := c_style_strlen(buffer.data);
        if new_count != s.count {
            new_data := alloc(new_count).(*u8);
            memcpy(new_data, *buffer, new_count);
            free(s.*);
            s.data  = new_data;
            s.count = new_count; 
        } else {
            memcpy(s.data, *buffer, new_count);
        }
    }
}