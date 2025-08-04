COMP_TIME_ATLAS :: true;
JAISON          :: true;
ATLAS_SRC_DIR   :: "assets/images";
ATLAS_DST_DIR   :: "assets/atlas";
ATLAS_NAME      :: "atlas";

#load "graphics/backend/opengl.jai";
#load "graphics/renderer2d.jai";

#load "graphics/font.jai";
#load "graphics/image.jai";
#load "graphics/atlas.jai";

#if COMP_TIME_ATLAS
then #load "graphics/atlas_comptime.jai";

// @Note: This partially depends on Jaison https://github.com/rluba/jaison.

// This means that if the COMP_TIME_ATLAS is enabled an atlas.json will be generated
// to avoid loading all images for each compile session. If you disable the Jaison import 
// flag but you keep the comp time atlas it will read each time the image folder.

#if JAISON
then Jaison :: #import "Jaison";