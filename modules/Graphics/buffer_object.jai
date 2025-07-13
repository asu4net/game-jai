Vertex_Buffer :: struct {
    id : u32;
    layout : Buffer_Layout;
}

Buffer_Element :: struct {
    type : Shader_Data_Type;
    name : string;
    normalized : bool;
    size : u32;
    offset : u32;
}

Buffer_Layout :: struct {
    elements : [..] Buffer_Element;
    stride : u32;
}

add_layout :: (vertex_buffer : *Vertex_Buffer, type : Shader_Data_Type, name : string, normalized : bool = false) {
    
    layout := *vertex_buffer.layout;
    
    element : Buffer_Element = .{

        type       = type,
        name       = name,
        normalized = normalized,
        size       = shader_data_type_to_size(type),
        offset     = layout.stride
    };
    
    layout.stride += element.size;
    array_add(*layout.elements, element);
}

deinit_buffer_layout :: (buffer : *Buffer_Layout) {
    if buffer.elements.count != 0 {
        array_free(buffer.elements);
    }
    buffer.* = .{};
}

init_vertex_buffer :: (using vertex_buffer : *Vertex_Buffer, size : u64) {
    glCreateBuffers(1, *id);
    glBindBuffer(GL_ARRAY_BUFFER, id);
    glBufferData(GL_ARRAY_BUFFER, xx size, null, GL_DYNAMIC_DRAW);
}

deinit_vertex_buffer :: (using vertex_buffer : *Vertex_Buffer) {
    assert(id != 0);
    glDeleteBuffers(1, *id);
    deinit_buffer_layout(*layout);
    vertex_buffer.* = .{};
}

init_vertex_buffer :: (using vertex_buffer : *Vertex_Buffer, vertices : *void, size : u64) {
    glCreateBuffers(1, *id);
    glBindBuffer(GL_ARRAY_BUFFER, id);
    glBufferData(GL_ARRAY_BUFFER, xx size, vertices, GL_STATIC_DRAW);
}

set_vertex_buffer_data :: (using vertex_buffer : *Vertex_Buffer, data : *void, size : u64) {
    glBindBuffer(GL_ARRAY_BUFFER, id);
    glBufferSubData(GL_ARRAY_BUFFER, 0, xx size, data);
}

bind :: (using vertex_buffer : *Vertex_Buffer) {
    glBindBuffer(GL_ARRAY_BUFFER, id);
}

unbind :: (vertex_buffer : *Vertex_Buffer) {
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

Index_Buffer :: struct {
    id : u32;
    count : u64;
}

init_index_buffer :: (using index_buffer : *Index_Buffer, indices : *u32, indices_count : u64) {
    count = indices_count;
    glCreateBuffers(1, *id);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, xx (count * size_of(u32)), indices, GL_STATIC_DRAW);
}

deinit_index_buffer :: (using index_buffer : *Index_Buffer) {
    assert(id != 0);
    glDeleteBuffers(1, *id);
    index_buffer.* = .{};
}

bind :: (using index_buffer : *Index_Buffer) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
}

unbind :: (using index_buffer : *Index_Buffer) {
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

Vertex_Array :: struct {
    id : u32;
    vertex_buffers : [..] *Vertex_Buffer;
    index_buffer : *Index_Buffer;
}

init_vertex_array :: (using vertex_array : *Vertex_Array) {
    glCreateVertexArrays(1, *id);
}

deinit_vertex_array :: (using vertex_array : *Vertex_Array) {
    for vertex_buffer : vertex_buffers {
        assert(vertex_buffer != null);
        if vertex_buffer.id != 0 {
            deinit(vertex_buffer);
        }
    }
    if vertex_buffers.count != 0 {
        array_free(vertex_buffers);
    }
    assert(index_buffer != null);

    if index_buffer.id != 0 {
        deinit(index_buffer);
    }

    glDeleteVertexArrays(1, *id);
    vertex_array.* = .{};
}

bind :: (using vertex_array : *Vertex_Array) {
    glBindVertexArray(id);
}

unbind :: (vertex_array : *Vertex_Array) {
    glBindVertexArray(0);
}

add_index_buffer :: (vertex_array : *Vertex_Array, index_buffer : *Index_Buffer) {
    if vertex_array.index_buffer != null {
        assert(false);
        return;
    }
    vertex_array.index_buffer = index_buffer;
    bind(vertex_array);
    bind(index_buffer);
}

add_vertex_buffer :: (using vertex_array : *Vertex_Array, vertex_buffer : *Vertex_Buffer) {
    assert(vertex_buffer.layout.elements.count > 0);
    bind(vertex_array);
    bind(vertex_buffer);
    index : u32 = 0;
    for *element : vertex_buffer.layout.elements {
        glEnableVertexAttribArray(index);
        if element.type == {
            case .None;
                assert(false);

            case .Float;  #through;
            case .Float2; #through;
            case .Float3; #through;
            case .Float4; #through;
            case .Mat3;   #through;
            case .Mat4;   #through;
            case .Sampler2D;
                glVertexAttribPointer(
                    index, 
                    shader_data_type_to_count(element.type), 
                    shader_data_type_to_gl(element.type), 
                    ifx element.normalized then GL_TRUE else GL_FALSE,
                    xx vertex_buffer.layout.stride,
                    xx element.offset
                );

            case .Int;  #through;
            case .Int2; #through;
            case .Int3; #through;
            case .Int4; #through;
            case .Bool; 
                glVertexAttribIPointer(
                    index, 
                    shader_data_type_to_count(element.type), 
                    shader_data_type_to_gl(element.type), 
                    xx vertex_buffer.layout.stride,
                    xx element.offset
                );
        }
        index += 1;
    }
}