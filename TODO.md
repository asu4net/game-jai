# TODO
- mostrar automaticamente editor al crear prefab
- el menu de prefab hace stop automáticamente y si cuando está abierto le das a play hace unload del prefab 
- Hacer ingame log messages
- Hacer componentes para el GUI

// SPRITE ----------------------------

- HACER COMPILE TIME SPRITE SHEETS, SERÁ QUINIENTAS VECES MÁS CÓMODO.
- Podemos mirar de hacer funciones comp time que devuelvan el rect
  dado el índice del sprite. Nuestra vida sería más sencilla.

De momento deberíamos mirar de tener un invalidate en el sprite
y no estar haciendo un lookup constante en la tabla del sprite
sheet. 
Podemos usar una función set_sprite que haga el invalidate por nosotros.

// ----------------------------

// SPRITE SHEETS ----------------------------
- For some fucking reason no encontramos en el sprite sheet una de las keys. Probablemente porque
- Si cambiamos el sprite usando el flipbook no estamos dealocando el nombre.
comparar strings significa comparar los punteros?
- Deberíamos de dejar de usar strings para cambiar el sprite y el flipbook debería de tener un current.
- Luego tener una opción de invalidate para poder actualizar el current del sprite según un nombre?.
- El flipbook tampoco debería de almacenar string keys. Pero claro eso es complejo de manejar. Una    opción es generar el sprite-sheet y los id de los sprites por meta programación. La otra opción sería
al principio del motor setear las diferentes.
// ----------------------------

- Implementar bucket array para las pools de componentes
- Display Entity refs as drag and drop like unity
- Add read only attr for imgui
- texture options for sprite_sheet (maybe could be a struct??)
- Optimize the 2d version of make_transform
- Intentar generalizar un poco más las llamadas de draw, convertir en función el draw header
- Leer shaders de ficheros
- Poder tener un material component
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights
- Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).