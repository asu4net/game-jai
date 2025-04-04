print_matrix :: (builder: *String_Builder, any: Any, user_data: *void) -> bool {
    ti := any.type;
    assert(ti.type == .STRUCT);

    tis := cast(*Type_Info_Struct) ti;

    coef_member: *Type_Info_Struct_Member;
    is_matrix := false;
    for * tis.members {
        if it.name == "IsMatrixFromMathModule"  is_matrix = true;  // @Robustness: Could do this better!
        else if it.name == "coef"  coef_member = it;
    }

    if !is_matrix   return false;
    if !coef_member return false;

    if coef_member.type.type != .ARRAY return false;

    tia_outer := cast(*Type_Info_Array) coef_member.type;
    if tia_outer.element_type.type != .ARRAY return false;

    tia_inner := cast(*Type_Info_Array) tia_outer.element_type;

    I := tia_inner.array_count;
    J := tia_outer.array_count;

    if I < 0 return false;
    if J < 0 return false;

    p := cast(*float) any.value_pointer;
    for j: 0..J-1 {
        append(builder, "(");

        for i: 0..I-1 {
            print_to_builder(builder, "%", << p);
            if i < I-1 append(builder, ", ");
            p += 1;
        }

        append(builder, ")");
        if j < J-1 append(builder, ", ");
    }

    return true;
}

math_struct_printer :: (builder: *String_Builder, any: Any, user_data: *void) -> bool {
    ti := any.type;
    if ti == type_info(Vector2) {
        v := cast(*Vector2) any.value_pointer;
        print_to_builder(builder, "(%, %)", v.x, v.y);
        return true;
    } else if ti == type_info(Vector3) {
        v := cast(*Vector3) any.value_pointer;
        print_to_builder(builder, "(%, %, %)", v.x, v.y, v.z);
        return true;
    } else if ti == type_info(Vector4) {
        v := cast(*Vector4) any.value_pointer;
        print_to_builder(builder, "(%, %, %, %)", v.x, v.y, v.z, v.w);
        return true;
    } else if (ti.type == .STRUCT) && print_matrix(builder, any, user_data) {
        return true;
    }

    return false;
}

#scope_file

using,only(String_Builder, print_to_builder, assert, append) Basic;
