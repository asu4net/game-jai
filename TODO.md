# Game
- Hacer que el enemigo de la sierra sea destruible.
- Hacer la línea de la pointer line y meter que el enemigo haga daño y sea destrible.

## Player
- Hacer pools de proyectiles

## Waves

- N numero de enemigos de N tipos en X posiciones con N tiempo de cooldown entre spawns.
- N tiempo entre oleadas
- Se termina cuando mueren todos lo enemigos o (opcionalmente) después de que pase un máximo de tiempo.

# Editor
- Comando para reducir el time scale (ALT + up / down arrows).
- Representación en checkboxes de todos los comandos.
- Revisar interacción del flujo del editor de prefabs con el del juego.
- Sistema de logs en pantalla, que salgan, vayan fadeandose y se acumulen en una columna.

# Engine
- Terminar las pools.
- Componentes de UI.
- Compile time sprite sheet, quitar strings de los sprites.
- Revisar los flipbook
- Usar los bucket array para los componentes.
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).
- Picking
- Sistema de iluminación: Ambient y Point lights
- Leer shaders de ficheros
- Poder tener un material component
- Poder cambiar de shader