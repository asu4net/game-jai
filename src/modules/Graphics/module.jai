//TODO:
/*
- Funciones matematicas para modificar fácilmente los transforms y mover las constantes
- Leer shaders de ficheros
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Generación de sprite-sheet
- Meter ImGUI
- Fuentes y renderizado de texto (Mirar SIMP)
- Pintado de primitivas de GUI (Mirar SIMP)
- Renombrar las funciones de begin & end (?)
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights
*/

#scope_module

#import "GL" (DUMP_GL_ERRORS = true);
#import "Math";
#import "Basic";
#import "stb_image";

#load "draw_2d.jai";
#load "api.jai";
#load "buffer_object.jai";
#load "primitives.jai";
#load "shader.jai";
#load "texture.jai";