get_key_state :: (input : Key_Code) -> Key_Current_State {
    return input_button_states[input];
}

is_key_down :: (input : Key_Code) -> bool {
    return get_key_state(input) & .DOWN == 1;
}