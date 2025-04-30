# TODO


- Display and save enabled / disabled state for entities. (Maybe just use bools for convenience)
- Allow imgui drag and drop in editor to edit children stuff.
- Allow serialize / deserialize for children.
- Fix u64 imgui crash (see what does nit/bb).

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