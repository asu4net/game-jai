#load "engine/core.jai";
#load "engine/graphics.jai";

#import "Basic"()(MEMORY_DEBUGGER = DEBUG);

System     :: #import "System";
File       :: #import "File";
File_Utils :: #import "File_Utilities";
String     :: #import "String";

#import "Hash_Table";
#import "Math";

#if IMGUI then ImGui :: #import "ImGui";

// Defaults
DEF_APP_NAME      :: "game";
DEF_SCREEN_WIDTH  :: 1280;
DEF_SCREEN_HEIGHT :: 720;
DEF_FONT_PATH     :: "assets/fonts/AlbertSans-VariableFont_wght.ttf"; 

OPEN_GL_MINOR               :: 4;
OPEN_GL_MAJOR               :: 4;
VERTICES_PER_2D_PRIMITIVE   :: 4;
INDICES_PER_2D_PRIMITIVE    :: 6;
MAX_2D_PRIMITIVES_PER_BATCH :: 3000;
MAX_TEXTURE_SLOTS           :: 32;
GUI_QUAD_PIXEL_WIDTH        :: 200;
GUI_QUAD_PIXEL_HEIGHT       :: 200;
PIXEL_TO_WORLD              :: 1.0 / 500.0;

RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;

f64 :: float64;
f32 :: float32;

IDENTITY :: Matrix4_Identity;

ZERO_2D   :: Vector2.{ +0, +0 };
ONE_2D    :: Vector2.{ +1, +1 };
UP_2D     :: Vector2.{ +0, +1 };
DOWN_2D   :: Vector2.{ +0, -1 };
RIGHT_2D  :: Vector2.{ +1, +0 };
LEFT_2D   :: Vector2.{ -1, +0 };

ZERO_3D   :: Vector3.{ +0, +0, +0 };
ONE_3D    :: Vector3.{ +1, +1, +1 };
UP_3D     :: Vector3.{ +0, +1, +0 };
DOWN_3D   :: Vector3.{ +0, -1, +0 };
RIGHT_3D  :: Vector3.{ +1, +0, +0 };
LEFT_3D   :: Vector3.{ -1, +0, +0 };
FRONT_3D  :: Vector3.{ +0, +0, +1 };
BACK_3D   :: Vector3.{ +0, +0, -1 };

ZERO_4D   :: Vector4.{ +0, +0, +0, +0 };
ONE_4D    :: Vector4.{ +1, +1, +1, +1 };

WHITE        :: Vector4.{ 1, 1, 1, 1 };
WHITE_FADED  :: Vector4.{ 1, 1, 1, 0 };
BLACK        :: Vector4.{ 0, 0, 0, 1 };
BLUE         :: Vector4.{ 0, 0, 1, 1 };
LIGHT_BLUE   :: Vector4.{ 0.3, 0.3, 1, 1 };
CYAN         :: Vector4.{ 0, 1, 1, 1 };
GRAY         :: Vector4.{ 0.5, 0.5, 0.5, 1 };
DARK_GRAY    :: Vector4.{ 0.2, 0.2, 0.2, 1 };
GREEN        :: Vector4.{ 0, 1, 0, 1 };
LIGHT_GREEN  :: Vector4.{ 0.3, 1, 0.3, 1 };
GREY         :: Vector4.{ 0.5, 0.5, 0.5, 1 };
DARK_GREY    :: Vector4.{ 0.2, 0.2, 0.2, 1 };
MAGENTA      :: Vector4.{ 1, 0, 1, 1 };
RED          :: Vector4.{ 1, 0, 0, 1 };
LIGHT_RED    :: Vector4.{ 1, 0.3, 0.3, 1 };
YELLOW       :: Vector4.{ 1, 0.92, 0.016, 1 };
ORANGE       :: Vector4.{ 0.97, 0.6, 0.11, 1 };