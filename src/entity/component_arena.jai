Component_Arena_Base :: struct {
    data      : *void;    
    count     : s64;
    capacity  : s64;
    type      : *Type_Info;
    used_ids  : Sparse_Set;
}

Component_Arena :: struct($T : Type, n : s64) {
    #as using base : Component_Arena_Base;
    CAPACITY :: n;
    components : []T;
}

init :: (arena : *Component_Arena($T, $N)) {
    print("inited component arena!\n");    
}

deinit :: (arena : *Component_Arena($T, $N)) {
    print("deinited component arena!\n");
}

//---------------------------

Some_Component :: struct @Component @Max(100) {
    dummy : float;
}

Some_Other_Component :: struct @Component @Max(100) {
    dummy : float;
}