# TODO

// ENTITY ----------------------------

- MIRAR THOUGHTS DEL SERVIDOR DE BB de discord y aplicar.
- Debería el dlz de las entidades estar funcionando en temporary storage?
- Creo que no, dado que esa memoria nos la vamos a quedar.
- El archivo de string debería de estar en temporary, pero las alocaciones
que hace para generar los objetos al deserializarlos no.
- Vale sí que deber de ser así porque no queremos almacenar cada componente
en un heap separado.
- Podemos quitar el temporary pero quizás deberíamos liberar manualmente
la memoria de cada componente, pero no la de los punteros que contiene... Por ejemplo se aloca el componente al deserializarse. También se alocan todos sus miembros. Después, manualmente
tendríamos que borrar el  componente, tras haber copiado el valor de los miembros
en el nuevo componente. No tendría que ser un deep copy, y por tanto NO necesitaríamos
el copy callback.
- APROVECHAMOS PARA HACER DOS VERSIONES DE DLZ, UNA PARA PASARLE LA ENTIDAD EN STRING, Y OTRA EL PATH

- El copy callback pasaría ser el CLONE callback, solo usado para clonar entidades.

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

- Display Entity refs as drag and drop like unity
- Create entity viewer and work with the prefab
- Add read only attr for imgui
- Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).
- texture options for sprite_sheet (maybe could be a struct??)
- Optimize the 2d version of make_transform
- Intentar generalizar un poco más las llamadas de draw, convertir en función el draw header
- Leer shaders de ficheros
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights