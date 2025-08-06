VERTICES_PER_2D_PRIMITIVE   :: 4;
INDICES_PER_2D_PRIMITIVE    :: 6;
MAX_2D_PRIMITIVES_PER_BATCH :: 3000;
MAX_TEXTURE_SLOTS           :: 32;
GUI_QUAD_PIXEL_WIDTH        :: 200;
GUI_QUAD_PIXEL_HEIGHT       :: 200;
PIXEL_TO_WORLD              :: 1.0 / 500.0;

#load "renderer2d/camera.jai";
#load "renderer2d/primitives.jai";
#load "renderer2d/renderer2d_state.jai";