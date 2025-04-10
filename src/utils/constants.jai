f64 :: float64;
f32 :: float32;
v2  :: Vector2;
v3  :: Vector3;
v4  :: Vector4;
m4  :: Matrix4; 

IDENTITY :: Matrix4_Identity;

ZERO_2D   :: v2.{ +0, +0 };
ONE_2D    :: v2.{ +1, +1 };
UP_2D     :: v2.{ +0, +1 };
DOWN_2D   :: v2.{ +0, -1 };
RIGHT_2D  :: v2.{ +1, +0 };
LEFT_2D   :: v2.{ -1, +0 };

ZERO_3D   :: v3.{ +0, +0, +0 };
ONE_3D    :: v3.{ +1, +1, +1 };
UP_3D     :: v3.{ +0, +1, +0 };
DOWN_3D   :: v3.{ +0, -1, +0 };
RIGHT_3D  :: v3.{ +1, +0, +0 };
LEFT_3D   :: v3.{ -1, +0, +0 };
FRONT_3D  :: v3.{ +0, +0, +1 };
BACK_3D   :: v3.{ +0, +0, -1 };

ZERO_4D   :: v4.{ +0, +0, +0, +0 };
ONE_4D    :: v4.{ +1, +1, +1, +1 };

WHITE        :: v4.{ 1, 1, 1, 1 };
WHITE_FADED  :: v4.{ 1, 1, 1, 0 };
BLACK        :: v4.{ 0, 0, 0, 1 };
BLUE         :: v4.{ 0, 0, 1, 1 };
LIGHT_BLUE   :: v4.{ 0.3, 0.3, 1, 1 };
CYAN         :: v4.{ 0, 1, 1, 1 };
GRAY         :: v4.{ 0.5, 0.5, 0.5, 1 };
DARK_GRAY    :: v4.{ 0.2, 0.2, 0.2, 1 };
GREEN        :: v4.{ 0, 1, 0, 1 };
LIGHT_GREEN  :: v4.{ 0.3, 1, 0.3, 1 };
GREY         :: v4.{ 0.5, 0.5, 0.5, 1 };
DARK_GREY    :: v4.{ 0.2, 0.2, 0.2, 1 };
MAGENTA      :: v4.{ 1, 0, 1, 1 };
RED          :: v4.{ 1, 0, 0, 1 };
LIGHT_RED    :: v4.{ 1, 0.3, 0.3, 1 };
YELLOW       :: v4.{ 1, 0.92, 0.016, 1 };
ORANGE       :: v4.{ 0.97, 0.6, 0.11, 1 };