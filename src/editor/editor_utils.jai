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

draw_editor :: (name: *u8, data: *void, info:*Type_Info) {
    default_size: ImGui.ImVec2;

    using Type_Info_Tag;
    if #complete info.type == {
        case INTEGER;
            info_int := cast(*Type_Info_Integer) info;
            ImGui.DragInt(name, data); // @@ Add support for unsigned, and larger int types.
        case FLOAT;
            ImGui.DragFloat(name, data, v_speed = 0.1, format = "%.5f");
        case BOOL;
            ImGui.Checkbox(name, data);
            //index : s32 = xx <<cast(*bool)data;
            //if ImGui.Combo(name, *index, "false\0true\0\0") { <<cast(*bool)data = xx index; };
        case STRING;
            draw_editor_string(name, data.(*string));
        case POINTER;
            // @@ Open in new window?
            ImGui.Text("pointer");
        case PROCEDURE;
            ImGui.Text("procedure");
        case VOID;
            ImGui.Text("void");
        case CODE;
            ImGui.Text("Code");
        case STRUCT;
            info_struct := cast(*Type_Info_Struct) info;
            if ImGui.TreeNode(name, "%: %", to_string(name), info_struct.name) {
                for member: info_struct.members {
                    draw_editor(temp_c_string(member.name), data + member.offset_in_bytes, member.type);
                }
                ImGui.TreePop();
            }
        case ARRAY;
            info_array := cast(*Type_Info_Array) info;
            array_count, array_data := get_array_count_and_data(data, info_array);
            array_name := to_string(name);
            element_size := info_array.element_type.runtime_size;
            if ImGui.TreeNode(name, "% (count = %)", array_name, array_count) {
                for 0..array_count-1 {
                    item_name := temp_c_string(tprint("%[%]", array_name, it));
                    draw_editor(item_name, array_data + it * element_size, info_array.element_type);
                }
                ImGui.TreePop();
            }
        case ANY;
            // @@ Display type and inspect value.
            ImGui.Text("Any!");
        case ENUM;
            info_enum := cast(*Type_Info_Enum) info;

            if info_enum.enum_type_flags & .FLAGS {
                // @@ How to handle flags?
            }
            else {
                value := get_enum_value(data, info_enum);
                value_name := "";
                for info_enum.names {
                    if value == info_enum.values[it_index]  value_name = it;
                }

                if ImGui.BeginCombo(name, temp_c_string(value_name)) {
                    for info_enum.names {
                        is_selected := value == info_enum.values[it_index];
                        if ImGui.Selectable(temp_c_string(it), is_selected, size=*default_size) {
                            set_enum_value(data, info_enum, info_enum.values[it_index]);
                        }
                        if is_selected ImGui.SetItemDefaultFocus();
                    }

                    ImGui.EndCombo();
                }
            }
        case POLYMORPHIC_VARIABLE;
            // @@ ??
        case TYPE;
            // @@
        case OVERLOAD_SET;
            // @@
        case VARIANT;
        // @Incomplete: Can do something better here.
            tiv := cast(*Type_Info_Variant) info;
            draw_editor(name, data, tiv.variant_of);
        case UNTYPED_LITERAL;
            ImGui.Text("(untyped literal)");
        case UNTYPED_ENUM;
            ImGui.Text("(untyped enum)");
    }
}