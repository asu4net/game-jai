#if EDITOR {

// Quizás lo primero debería ser meter las partículas e implementar el resto del juego.
// Probarlo en otras plataformas también sería lo suyo...
// El argumento a favor para meter el resto del juego sería comprobar que todo es robusto
// y está preparado para funcionar con el editor...

// ----------------------------------------------------------------

// Tenemos que distinguir las entidades que son prefab de alguna manera.
// Lo más probable es que sea una marca en la propia entidad. No queremos tickear 
// los prefabs de forma normal, solo cuando estemos editando. Quizás tienen que estar
// en arrays de entidades específicos. Se podría construir un puntero a función en el 
// momento de crear el array de entidades por código. (Se hará algo similar para que el menu pueda crearlos) 
// Como no va a haber tantos prefabs lo que hay que priorizar es el acceso, no el alineamiento.

// Lo primero va a ser crear un popup modal para elegir el tipo de prefab y el nombre, con eso le damos
// a crear y tiene que instanciarse una entidad default de lo que hemos pedido. En ese punto si hay juego
// se tiene que detener el tickeo, y el pintado. Ya que no queremos que esté molestando por detrás.

// La ventana de prefabs también tiene que tener una entrada de load, para cuando queramos cargar un prefab
// existente y modificarlo. Editar las variables de editor podría hacerse con do y undos, para hacerlo más 
// amigable al usuario. Aquí los mensajes estos flotantes que tenía planeados serían de gran ayuda.

//-------------------------------------------------------------------

draw_prefab_menu :: (menu : *Menu, name : string) {
    
}

} //#if EDITOR