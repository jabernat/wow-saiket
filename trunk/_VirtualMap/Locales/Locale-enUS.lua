--[[****************************************************************************
  * _VirtualMap by Saiket                                                      *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local L = LibStub( "AceLocale-3.0" ):NewLocale( "_VirtualMap", "enUS", true );

local Title = "_|cffcccc88VirtualMap"..FONT_COLOR_CODE_CLOSE;


L.TITLE = Title;
L.DESC = Title.." is a virtual 3D map HUD with support for GatherMate nodes.\nOriginal addon GatherHud by Grum and Xinhuan.";

-- Top level options
L.ENABLE = "Enable "..Title;
L.ENABLE_DESC = "Enable or disable "..Title;

-- HUD Options
L.HUDGROUP = "HUD Options";
L.HUDGROUP_DESC = Title.." HUD Options";
L.HUDX = "Hud X-Position";
L.HUDX_DESC = "The X offset coordinate of the hud from the center of the screen";
L.HUDY = "Hud Y-Position";
L.HUDY_DESC = "The Y offset coordinate of the hud from the center of the screen";
L.HUDWIDTH = "Hud Width";
L.HUDWIDTH_DESC = "The pixel width of the hud. In effect, this controls the scaling of the entire hud";
L.HUDALPHA = "Hud Alpha";
L.HUDALPHA_DESC = "The alpha transparency of the hud";
L.RADIUS = "Hud map radius";
L.RADIUS_DESC = "The radius in yards the hud will draw nodes for from your position";

-- Icon Options
L.ICONGROUP = "Icon Options";
L.ICONGROUP_DESC = Title.." Icon Options";
L.ICONSIZE = "Icon size";
L.ICONSIZE_DESC = "The size of the icons displayed in the hud";
L.ICONDEPTH = "Icon depth effect";
L.ICONDEPTH_DESC = "A depth effect that controls how much the size of the icons changes for nodes in the near and far distance";
L.ICONALPHA = "Icon alpha";
L.ICONALPHA_DESC = "The alpha transparency of the icons";

L.NORTH_INDICATOR = "N";




-- Slash commands
SLASH__VIRTUALMAP1 = "/virtualmap";
SLASH__VIRTUALMAP2 = "/vmap";

-- Keybinds
BINDING_HEADER__VIRTUALMAP    = Title;
BINDING_NAME_TOGGLEVIRTUALMAP = "Toggles "..Title;
