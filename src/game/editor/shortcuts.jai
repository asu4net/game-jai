Shortcut :: enum {
    TOGGLE_PLAY; TOGGLE_PAUSE; NEXT_FRAME; TOGGLE_SHOW_COLLIDERS;
    COUNT;
}

SHORTCUT_MAP :: Enumerated_Array(Shortcut, []SDL_Scancode).{values=.{
  TOGGLE_PLAY            = .[.LALT, ._1],
  TOGGLE_PAUSE           = .[.LALT, ._2],
  NEXT_FRAME             = .[.LALT, ._3],
  TOGGLE_SHOW_COLLIDERS  = .[.LALT, ._4],
}};

is_shortcut_down :: (s : Shortcut) -> bool {
    pressed : bool;
    keys := SHORTCUT_MAP[s];
    for keys {
        if !is_key_down(it)
        then return false;
    }
    return true;
}

shortcuts_prev    : [Shortcut.COUNT] bool;
shortcuts_down    : [Shortcut.COUNT] bool;
shortcuts_pressed : [Shortcut.COUNT] bool;

update_shortcuts :: () {
    for i : 0..Shortcut.COUNT - 1 {
        shortcuts_down[i] = is_shortcut_down(xx i);
    }

    for i : 0..Shortcut.COUNT - 1 {
        shortcuts_pressed[i] = shortcuts_down[i] && !shortcuts_prev[i];
    }

    memcpy(*shortcuts_prev, *shortcuts_down, Shortcut.COUNT.(s64) * size_of(bool));
}

is_shortcut_pressed :: inline (s : Shortcut) -> bool {
    return shortcuts_pressed[s];
}

/*

    ************** REFERENCE **************

    UNKNOWN              :: 0;
    A                    :: 4;
    B                    :: 5;
    C                    :: 6;
    D                    :: 7;
    E                    :: 8;
    F                    :: 9;
    G                    :: 10;
    H                    :: 11;
    I                    :: 12;
    J                    :: 13;
    K                    :: 14;
    L                    :: 15;
    M                    :: 16;
    N                    :: 17;
    O                    :: 18;
    P                    :: 19;
    Q                    :: 20;
    R                    :: 21;
    S                    :: 22;
    T                    :: 23;
    U                    :: 24;
    V                    :: 25;
    W                    :: 26;
    X                    :: 27;
    Y                    :: 28;
    Z                    :: 29;

    _1                   :: 30;
    _2                   :: 31;
    _3                   :: 32;
    _4                   :: 33;
    _5                   :: 34;
    _6                   :: 35;
    _7                   :: 36;
    _8                   :: 37;
    _9                   :: 38;
    _0                   :: 39;

    RETURN               :: 40;
    ESCAPE               :: 41;
    BACKSPACE            :: 42;
    TAB                  :: 43;
    SPACE                :: 44;

    MINUS                :: 45;
    EQUALS               :: 46;
    LEFTBRACKET          :: 47;
    RIGHTBRACKET         :: 48;
    BACKSLASH            :: 49;

    NONUSHASH            :: 50;

    SEMICOLON            :: 51;
    APOSTROPHE           :: 52;
    GRAVE                :: 53;

    COMMA                :: 54;
    PERIOD               :: 55;
    SLASH                :: 56;

    CAPSLOCK             :: 57;

    F1                   :: 58;
    F2                   :: 59;
    F3                   :: 60;
    F4                   :: 61;
    F5                   :: 62;
    F6                   :: 63;
    F7                   :: 64;
    F8                   :: 65;
    F9                   :: 66;
    F10                  :: 67;
    F11                  :: 68;
    F12                  :: 69;

    PRINTSCREEN          :: 70;
    SCROLLLOCK           :: 71;
    PAUSE                :: 72;
    INSERT               :: 73;

    HOME                 :: 74;
    PAGEUP               :: 75;
    DELETE               :: 76;
    END                  :: 77;
    PAGEDOWN             :: 78;
    RIGHT                :: 79;
    LEFT                 :: 80;
    DOWN                 :: 81;
    UP                   :: 82;

    NUMLOCKCLEAR         :: 83;

    KP_DIVIDE            :: 84;
    KP_MULTIPLY          :: 85;
    KP_MINUS             :: 86;
    KP_PLUS              :: 87;
    KP_ENTER             :: 88;
    KP_1                 :: 89;
    KP_2                 :: 90;
    KP_3                 :: 91;
    KP_4                 :: 92;
    KP_5                 :: 93;
    KP_6                 :: 94;
    KP_7                 :: 95;
    KP_8                 :: 96;
    KP_9                 :: 97;
    KP_0                 :: 98;
    KP_PERIOD            :: 99;

    NONUSBACKSLASH       :: 100;

    APPLICATION          :: 101;
    POWER                :: 102;

    KP_EQUALS            :: 103;
    F13                  :: 104;
    F14                  :: 105;
    F15                  :: 106;
    F16                  :: 107;
    F17                  :: 108;
    F18                  :: 109;
    F19                  :: 110;
    F20                  :: 111;
    F21                  :: 112;
    F22                  :: 113;
    F23                  :: 114;
    F24                  :: 115;
    EXECUTE              :: 116;
    HELP                 :: 117;
    MENU                 :: 118;
    SELECT               :: 119;
    STOP                 :: 120;
    AGAIN                :: 121;
    UNDO                 :: 122;
    CUT                  :: 123;
    COPY                 :: 124;
    PASTE                :: 125;
    FIND                 :: 126;
    MUTE                 :: 127;
    VOLUMEUP             :: 128;
    VOLUMEDOWN           :: 129;

    KP_COMMA             :: 133;
    KP_EQUALSAS400       :: 134;

    INTERNATIONAL1       :: 135;

    INTERNATIONAL2       :: 136;
    INTERNATIONAL3       :: 137;
    INTERNATIONAL4       :: 138;
    INTERNATIONAL5       :: 139;
    INTERNATIONAL6       :: 140;
    INTERNATIONAL7       :: 141;
    INTERNATIONAL8       :: 142;
    INTERNATIONAL9       :: 143;
    LANG1                :: 144;
    LANG2                :: 145;
    LANG3                :: 146;
    LANG4                :: 147;
    LANG5                :: 148;
    LANG6                :: 149;
    LANG7                :: 150;
    LANG8                :: 151;
    LANG9                :: 152;

    ALTERASE             :: 153;
    SYSREQ               :: 154;
    CANCEL               :: 155;
    CLEAR                :: 156;
    PRIOR                :: 157;
    RETURN2              :: 158;
    SEPARATOR            :: 159;
    OUT                  :: 160;
    OPER                 :: 161;
    CLEARAGAIN           :: 162;
    CRSEL                :: 163;
    EXSEL                :: 164;

    KP_00                :: 176;
    KP_000               :: 177;
    THOUSANDSSEPARATOR   :: 178;
    DECIMALSEPARATOR     :: 179;
    CURRENCYUNIT         :: 180;
    CURRENCYSUBUNIT      :: 181;
    KP_LEFTPAREN         :: 182;
    KP_RIGHTPAREN        :: 183;
    KP_LEFTBRACE         :: 184;
    KP_RIGHTBRACE        :: 185;
    KP_TAB               :: 186;
    KP_BACKSPACE         :: 187;
    KP_A                 :: 188;
    KP_B                 :: 189;
    KP_C                 :: 190;
    KP_D                 :: 191;
    KP_E                 :: 192;
    KP_F                 :: 193;
    KP_XOR               :: 194;
    KP_POWER             :: 195;
    KP_PERCENT           :: 196;
    KP_LESS              :: 197;
    KP_GREATER           :: 198;
    KP_AMPERSAND         :: 199;
    KP_DBLAMPERSAND      :: 200;
    KP_VERTICALBAR       :: 201;
    KP_DBLVERTICALBAR    :: 202;
    KP_COLON             :: 203;
    KP_HASH              :: 204;
    KP_SPACE             :: 205;
    KP_AT                :: 206;
    KP_EXCLAM            :: 207;
    KP_MEMSTORE          :: 208;
    KP_MEMRECALL         :: 209;
    KP_MEMCLEAR          :: 210;
    KP_MEMADD            :: 211;
    KP_MEMSUBTRACT       :: 212;
    KP_MEMMULTIPLY       :: 213;
    KP_MEMDIVIDE         :: 214;
    KP_PLUSMINUS         :: 215;
    KP_CLEAR             :: 216;
    KP_CLEARENTRY        :: 217;
    KP_BINARY            :: 218;
    KP_OCTAL             :: 219;
    KP_DECIMAL           :: 220;
    KP_HEXADECIMAL       :: 221;

    LCTRL                :: 224;
    LSHIFT               :: 225;
    LALT                 :: 226;
    LGUI                 :: 227;
    RCTRL                :: 228;
    RSHIFT               :: 229;
    RALT                 :: 230;
    RGUI                 :: 231;

    MODE                 :: 257;

    SLEEP                :: 258;
    WAKE                 :: 259;

    CHANNEL_INCREMENT    :: 260;
    CHANNEL_DECREMENT    :: 261;

    MEDIA_PLAY           :: 262;
    MEDIA_PAUSE          :: 263;
    MEDIA_RECORD         :: 264;
    MEDIA_FAST_FORWARD   :: 265;
    MEDIA_REWIND         :: 266;
    MEDIA_NEXT_TRACK     :: 267;
    MEDIA_PREVIOUS_TRACK :: 268;
    MEDIA_STOP           :: 269;
    MEDIA_EJECT          :: 270;
    MEDIA_PLAY_PAUSE     :: 271;
    MEDIA_SELECT         :: 272;

    AC_NEW               :: 273;
    AC_OPEN              :: 274;
    AC_CLOSE             :: 275;
    AC_EXIT              :: 276;
    AC_SAVE              :: 277;
    AC_PRINT             :: 278;
    AC_PROPERTIES        :: 279;

    AC_SEARCH            :: 280;
    AC_HOME              :: 281;
    AC_BACK              :: 282;
    AC_FORWARD           :: 283;
    AC_STOP              :: 284;
    AC_REFRESH           :: 285;
    AC_BOOKMARKS         :: 286;

    SOFTLEFT             :: 287;

    SOFTRIGHT            :: 288;

    CALL                 :: 289;
    ENDCALL              :: 290;

    RESERVED             :: 400;

    COUNT                :: 512;

    SDL_SCANCODE_UNKNOWN              :: UNKNOWN;

    SDL_SCANCODE_A                    :: A;
    SDL_SCANCODE_B                    :: B;
    SDL_SCANCODE_C                    :: C;
    SDL_SCANCODE_D                    :: D;
    SDL_SCANCODE_E                    :: E;
    SDL_SCANCODE_F                    :: F;
    SDL_SCANCODE_G                    :: G;
    SDL_SCANCODE_H                    :: H;
    SDL_SCANCODE_I                    :: I;
    SDL_SCANCODE_J                    :: J;
    SDL_SCANCODE_K                    :: K;
    SDL_SCANCODE_L                    :: L;
    SDL_SCANCODE_M                    :: M;
    SDL_SCANCODE_N                    :: N;
    SDL_SCANCODE_O                    :: O;
    SDL_SCANCODE_P                    :: P;
    SDL_SCANCODE_Q                    :: Q;
    SDL_SCANCODE_R                    :: R;
    SDL_SCANCODE_S                    :: S;
    SDL_SCANCODE_T                    :: T;
    SDL_SCANCODE_U                    :: U;
    SDL_SCANCODE_V                    :: V;
    SDL_SCANCODE_W                    :: W;
    SDL_SCANCODE_X                    :: X;
    SDL_SCANCODE_Y                    :: Y;
    SDL_SCANCODE_Z                    :: Z;

    SDL_SCANCODE_1                    :: _1;
    SDL_SCANCODE_2                    :: _2;
    SDL_SCANCODE_3                    :: _3;
    SDL_SCANCODE_4                    :: _4;
    SDL_SCANCODE_5                    :: _5;
    SDL_SCANCODE_6                    :: _6;
    SDL_SCANCODE_7                    :: _7;
    SDL_SCANCODE_8                    :: _8;
    SDL_SCANCODE_9                    :: _9;
    SDL_SCANCODE_0                    :: _0;

    SDL_SCANCODE_RETURN               :: RETURN;
    SDL_SCANCODE_ESCAPE               :: ESCAPE;
    SDL_SCANCODE_BACKSPACE            :: BACKSPACE;
    SDL_SCANCODE_TAB                  :: TAB;
    SDL_SCANCODE_SPACE                :: SPACE;

    SDL_SCANCODE_MINUS                :: MINUS;
    SDL_SCANCODE_EQUALS               :: EQUALS;
    SDL_SCANCODE_LEFTBRACKET          :: LEFTBRACKET;
    SDL_SCANCODE_RIGHTBRACKET         :: RIGHTBRACKET;
    SDL_SCANCODE_BACKSLASH            :: BACKSLASH;

    SDL_SCANCODE_NONUSHASH            :: NONUSHASH;

    SDL_SCANCODE_SEMICOLON            :: SEMICOLON;
    SDL_SCANCODE_APOSTROPHE           :: APOSTROPHE;
    SDL_SCANCODE_GRAVE                :: GRAVE;

    SDL_SCANCODE_COMMA                :: COMMA;
    SDL_SCANCODE_PERIOD               :: PERIOD;
    SDL_SCANCODE_SLASH                :: SLASH;

    SDL_SCANCODE_CAPSLOCK             :: CAPSLOCK;

    SDL_SCANCODE_F1                   :: F1;
    SDL_SCANCODE_F2                   :: F2;
    SDL_SCANCODE_F3                   :: F3;
    SDL_SCANCODE_F4                   :: F4;
    SDL_SCANCODE_F5                   :: F5;
    SDL_SCANCODE_F6                   :: F6;
    SDL_SCANCODE_F7                   :: F7;
    SDL_SCANCODE_F8                   :: F8;
    SDL_SCANCODE_F9                   :: F9;
    SDL_SCANCODE_F10                  :: F10;
    SDL_SCANCODE_F11                  :: F11;
    SDL_SCANCODE_F12                  :: F12;

    SDL_SCANCODE_PRINTSCREEN          :: PRINTSCREEN;
    SDL_SCANCODE_SCROLLLOCK           :: SCROLLLOCK;
    SDL_SCANCODE_PAUSE                :: PAUSE;
    SDL_SCANCODE_INSERT               :: INSERT;

    SDL_SCANCODE_HOME                 :: HOME;
    SDL_SCANCODE_PAGEUP               :: PAGEUP;
    SDL_SCANCODE_DELETE               :: DELETE;
    SDL_SCANCODE_END                  :: END;
    SDL_SCANCODE_PAGEDOWN             :: PAGEDOWN;
    SDL_SCANCODE_RIGHT                :: RIGHT;
    SDL_SCANCODE_LEFT                 :: LEFT;
    SDL_SCANCODE_DOWN                 :: DOWN;
    SDL_SCANCODE_UP                   :: UP;

    SDL_SCANCODE_NUMLOCKCLEAR         :: NUMLOCKCLEAR;

    SDL_SCANCODE_KP_DIVIDE            :: KP_DIVIDE;
    SDL_SCANCODE_KP_MULTIPLY          :: KP_MULTIPLY;
    SDL_SCANCODE_KP_MINUS             :: KP_MINUS;
    SDL_SCANCODE_KP_PLUS              :: KP_PLUS;
    SDL_SCANCODE_KP_ENTER             :: KP_ENTER;
    SDL_SCANCODE_KP_1                 :: KP_1;
    SDL_SCANCODE_KP_2                 :: KP_2;
    SDL_SCANCODE_KP_3                 :: KP_3;
    SDL_SCANCODE_KP_4                 :: KP_4;
    SDL_SCANCODE_KP_5                 :: KP_5;
    SDL_SCANCODE_KP_6                 :: KP_6;
    SDL_SCANCODE_KP_7                 :: KP_7;
    SDL_SCANCODE_KP_8                 :: KP_8;
    SDL_SCANCODE_KP_9                 :: KP_9;
    SDL_SCANCODE_KP_0                 :: KP_0;
    SDL_SCANCODE_KP_PERIOD            :: KP_PERIOD;

    SDL_SCANCODE_NONUSBACKSLASH       :: NONUSBACKSLASH;

    SDL_SCANCODE_APPLICATION          :: APPLICATION;
    SDL_SCANCODE_POWER                :: POWER;

    SDL_SCANCODE_KP_EQUALS            :: KP_EQUALS;
    SDL_SCANCODE_F13                  :: F13;
    SDL_SCANCODE_F14                  :: F14;
    SDL_SCANCODE_F15                  :: F15;
    SDL_SCANCODE_F16                  :: F16;
    SDL_SCANCODE_F17                  :: F17;
    SDL_SCANCODE_F18                  :: F18;
    SDL_SCANCODE_F19                  :: F19;
    SDL_SCANCODE_F20                  :: F20;
    SDL_SCANCODE_F21                  :: F21;
    SDL_SCANCODE_F22                  :: F22;
    SDL_SCANCODE_F23                  :: F23;
    SDL_SCANCODE_F24                  :: F24;
    SDL_SCANCODE_EXECUTE              :: EXECUTE;
    SDL_SCANCODE_HELP                 :: HELP;
    SDL_SCANCODE_MENU                 :: MENU;
    SDL_SCANCODE_SELECT               :: SELECT;
    SDL_SCANCODE_STOP                 :: STOP;
    SDL_SCANCODE_AGAIN                :: AGAIN;
    SDL_SCANCODE_UNDO                 :: UNDO;
    SDL_SCANCODE_CUT                  :: CUT;
    SDL_SCANCODE_COPY                 :: COPY;
    SDL_SCANCODE_PASTE                :: PASTE;
    SDL_SCANCODE_FIND                 :: FIND;
    SDL_SCANCODE_MUTE                 :: MUTE;
    SDL_SCANCODE_VOLUMEUP             :: VOLUMEUP;
    SDL_SCANCODE_VOLUMEDOWN           :: VOLUMEDOWN;

    SDL_SCANCODE_KP_COMMA             :: KP_COMMA;
    SDL_SCANCODE_KP_EQUALSAS400       :: KP_EQUALSAS400;

    SDL_SCANCODE_INTERNATIONAL1       :: INTERNATIONAL1;

    SDL_SCANCODE_INTERNATIONAL2       :: INTERNATIONAL2;
    SDL_SCANCODE_INTERNATIONAL3       :: INTERNATIONAL3;
    SDL_SCANCODE_INTERNATIONAL4       :: INTERNATIONAL4;
    SDL_SCANCODE_INTERNATIONAL5       :: INTERNATIONAL5;
    SDL_SCANCODE_INTERNATIONAL6       :: INTERNATIONAL6;
    SDL_SCANCODE_INTERNATIONAL7       :: INTERNATIONAL7;
    SDL_SCANCODE_INTERNATIONAL8       :: INTERNATIONAL8;
    SDL_SCANCODE_INTERNATIONAL9       :: INTERNATIONAL9;
    SDL_SCANCODE_LANG1                :: LANG1;
    SDL_SCANCODE_LANG2                :: LANG2;
    SDL_SCANCODE_LANG3                :: LANG3;
    SDL_SCANCODE_LANG4                :: LANG4;
    SDL_SCANCODE_LANG5                :: LANG5;
    SDL_SCANCODE_LANG6                :: LANG6;
    SDL_SCANCODE_LANG7                :: LANG7;
    SDL_SCANCODE_LANG8                :: LANG8;
    SDL_SCANCODE_LANG9                :: LANG9;

    SDL_SCANCODE_ALTERASE             :: ALTERASE;
    SDL_SCANCODE_SYSREQ               :: SYSREQ;
    SDL_SCANCODE_CANCEL               :: CANCEL;
    SDL_SCANCODE_CLEAR                :: CLEAR;
    SDL_SCANCODE_PRIOR                :: PRIOR;
    SDL_SCANCODE_RETURN2              :: RETURN2;
    SDL_SCANCODE_SEPARATOR            :: SEPARATOR;
    SDL_SCANCODE_OUT                  :: OUT;
    SDL_SCANCODE_OPER                 :: OPER;
    SDL_SCANCODE_CLEARAGAIN           :: CLEARAGAIN;
    SDL_SCANCODE_CRSEL                :: CRSEL;
    SDL_SCANCODE_EXSEL                :: EXSEL;

    SDL_SCANCODE_KP_00                :: KP_00;
    SDL_SCANCODE_KP_000               :: KP_000;
    SDL_SCANCODE_THOUSANDSSEPARATOR   :: THOUSANDSSEPARATOR;
    SDL_SCANCODE_DECIMALSEPARATOR     :: DECIMALSEPARATOR;
    SDL_SCANCODE_CURRENCYUNIT         :: CURRENCYUNIT;
    SDL_SCANCODE_CURRENCYSUBUNIT      :: CURRENCYSUBUNIT;
    SDL_SCANCODE_KP_LEFTPAREN         :: KP_LEFTPAREN;
    SDL_SCANCODE_KP_RIGHTPAREN        :: KP_RIGHTPAREN;
    SDL_SCANCODE_KP_LEFTBRACE         :: KP_LEFTBRACE;
    SDL_SCANCODE_KP_RIGHTBRACE        :: KP_RIGHTBRACE;
    SDL_SCANCODE_KP_TAB               :: KP_TAB;
    SDL_SCANCODE_KP_BACKSPACE         :: KP_BACKSPACE;
    SDL_SCANCODE_KP_A                 :: KP_A;
    SDL_SCANCODE_KP_B                 :: KP_B;
    SDL_SCANCODE_KP_C                 :: KP_C;
    SDL_SCANCODE_KP_D                 :: KP_D;
    SDL_SCANCODE_KP_E                 :: KP_E;
    SDL_SCANCODE_KP_F                 :: KP_F;
    SDL_SCANCODE_KP_XOR               :: KP_XOR;
    SDL_SCANCODE_KP_POWER             :: KP_POWER;
    SDL_SCANCODE_KP_PERCENT           :: KP_PERCENT;
    SDL_SCANCODE_KP_LESS              :: KP_LESS;
    SDL_SCANCODE_KP_GREATER           :: KP_GREATER;
    SDL_SCANCODE_KP_AMPERSAND         :: KP_AMPERSAND;
    SDL_SCANCODE_KP_DBLAMPERSAND      :: KP_DBLAMPERSAND;
    SDL_SCANCODE_KP_VERTICALBAR       :: KP_VERTICALBAR;
    SDL_SCANCODE_KP_DBLVERTICALBAR    :: KP_DBLVERTICALBAR;
    SDL_SCANCODE_KP_COLON             :: KP_COLON;
    SDL_SCANCODE_KP_HASH              :: KP_HASH;
    SDL_SCANCODE_KP_SPACE             :: KP_SPACE;
    SDL_SCANCODE_KP_AT                :: KP_AT;
    SDL_SCANCODE_KP_EXCLAM            :: KP_EXCLAM;
    SDL_SCANCODE_KP_MEMSTORE          :: KP_MEMSTORE;
    SDL_SCANCODE_KP_MEMRECALL         :: KP_MEMRECALL;
    SDL_SCANCODE_KP_MEMCLEAR          :: KP_MEMCLEAR;
    SDL_SCANCODE_KP_MEMADD            :: KP_MEMADD;
    SDL_SCANCODE_KP_MEMSUBTRACT       :: KP_MEMSUBTRACT;
    SDL_SCANCODE_KP_MEMMULTIPLY       :: KP_MEMMULTIPLY;
    SDL_SCANCODE_KP_MEMDIVIDE         :: KP_MEMDIVIDE;
    SDL_SCANCODE_KP_PLUSMINUS         :: KP_PLUSMINUS;
    SDL_SCANCODE_KP_CLEAR             :: KP_CLEAR;
    SDL_SCANCODE_KP_CLEARENTRY        :: KP_CLEARENTRY;
    SDL_SCANCODE_KP_BINARY            :: KP_BINARY;
    SDL_SCANCODE_KP_OCTAL             :: KP_OCTAL;
    SDL_SCANCODE_KP_DECIMAL           :: KP_DECIMAL;
    SDL_SCANCODE_KP_HEXADECIMAL       :: KP_HEXADECIMAL;

    SDL_SCANCODE_LCTRL                :: LCTRL;
    SDL_SCANCODE_LSHIFT               :: LSHIFT;
    SDL_SCANCODE_LALT                 :: LALT;
    SDL_SCANCODE_LGUI                 :: LGUI;
    SDL_SCANCODE_RCTRL                :: RCTRL;
    SDL_SCANCODE_RSHIFT               :: RSHIFT;
    SDL_SCANCODE_RALT                 :: RALT;
    SDL_SCANCODE_RGUI                 :: RGUI;

    SDL_SCANCODE_MODE                 :: MODE;

    SDL_SCANCODE_SLEEP                :: SLEEP;
    SDL_SCANCODE_WAKE                 :: WAKE;

    SDL_SCANCODE_CHANNEL_INCREMENT    :: CHANNEL_INCREMENT;
    SDL_SCANCODE_CHANNEL_DECREMENT    :: CHANNEL_DECREMENT;

    SDL_SCANCODE_MEDIA_PLAY           :: MEDIA_PLAY;
    SDL_SCANCODE_MEDIA_PAUSE          :: MEDIA_PAUSE;
    SDL_SCANCODE_MEDIA_RECORD         :: MEDIA_RECORD;
    SDL_SCANCODE_MEDIA_FAST_FORWARD   :: MEDIA_FAST_FORWARD;
    SDL_SCANCODE_MEDIA_REWIND         :: MEDIA_REWIND;
    SDL_SCANCODE_MEDIA_NEXT_TRACK     :: MEDIA_NEXT_TRACK;
    SDL_SCANCODE_MEDIA_PREVIOUS_TRACK :: MEDIA_PREVIOUS_TRACK;
    SDL_SCANCODE_MEDIA_STOP           :: MEDIA_STOP;
    SDL_SCANCODE_MEDIA_EJECT          :: MEDIA_EJECT;
    SDL_SCANCODE_MEDIA_PLAY_PAUSE     :: MEDIA_PLAY_PAUSE;
    SDL_SCANCODE_MEDIA_SELECT         :: MEDIA_SELECT;

    SDL_SCANCODE_AC_NEW               :: AC_NEW;
    SDL_SCANCODE_AC_OPEN              :: AC_OPEN;
    SDL_SCANCODE_AC_CLOSE             :: AC_CLOSE;
    SDL_SCANCODE_AC_EXIT              :: AC_EXIT;
    SDL_SCANCODE_AC_SAVE              :: AC_SAVE;
    SDL_SCANCODE_AC_PRINT             :: AC_PRINT;
    SDL_SCANCODE_AC_PROPERTIES        :: AC_PROPERTIES;

    SDL_SCANCODE_AC_SEARCH            :: AC_SEARCH;
    SDL_SCANCODE_AC_HOME              :: AC_HOME;
    SDL_SCANCODE_AC_BACK              :: AC_BACK;
    SDL_SCANCODE_AC_FORWARD           :: AC_FORWARD;
    SDL_SCANCODE_AC_STOP              :: AC_STOP;
    SDL_SCANCODE_AC_REFRESH           :: AC_REFRESH;
    SDL_SCANCODE_AC_BOOKMARKS         :: AC_BOOKMARKS;

    SDL_SCANCODE_SOFTLEFT             :: SOFTLEFT;

    SDL_SCANCODE_SOFTRIGHT            :: SOFTRIGHT;

    SDL_SCANCODE_CALL                 :: CALL;
    SDL_SCANCODE_ENDCALL              :: ENDCALL;

    SDL_SCANCODE_RESERVED             :: RESERVED;

    SDL_SCANCODE_COUNT                :: COUNT;
*/