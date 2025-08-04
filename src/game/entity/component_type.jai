Component_Type :: struct {
    info: *Type_Info_Struct;
    procs: Component_Procs;
    cbkcs: Component_Callbacks;
}

init_component_type :: (c_type : *Component_Type, $T : Type) {
    c_type.info = type_info(T).(*Type_Info_Struct);
    init_component_procs(*c_type.procs, T);
    // Callbacks are optional, so can be setted at any point.
}

#load "component_procs.jai";
#load "component_cbcks.jai";