--[[****************************************************************************
  * _VirtualMap by Saiket                                                      *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88VirtualMap|r";

	_VirtualMapLocalization = setmetatable( {
		TITLE = Title;
		DESC = Title.." is a virtual 3D map HUD with support for GatherMate nodes.\nOriginal addon GatherHud by Grum and Xinhuan.";

		-- Top level options
		ENABLE = "Enable "..Title;
		ENABLE_DESC = "Enable or disable "..Title;

		-- HUD Options
		HUDGROUP = "HUD Options";
		HUDGROUP_DESC = Title.." HUD Options";
		HUDX = "Hud X-Position";
		HUDX_DESC = "The X offset coordinate of the hud from the center of the screen";
		HUDY = "Hud Y-Position";
		HUDY_DESC = "The Y offset coordinate of the hud from the center of the screen";
		HUDWIDTH = "Hud Width";
		HUDWIDTH_DESC = "The pixel width of the hud. In effect, this controls the scaling of the entire hud";
		HUDALPHA = "Hud Alpha";
		HUDALPHA_DESC = "The alpha transparency of the hud";
		RADIUS = "Hud map radius";
		RADIUS_DESC = "The radius in yards the hud will draw nodes for from your position";

		-- Icon Options
		ICONGROUP = "Icon Options";
		ICONGROUP_DESC = Title.." Icon Options";
		ICONSIZE = "Icon size";
		ICONSIZE_DESC = "The size of the icons displayed in the hud";
		ICONDEPTH = "Icon depth effect";
		ICONDEPTH_DESC = "A depth effect that controls how much the size of the icons changes for nodes in the near and far distance";
		ICONALPHA = "Icon alpha";
		ICONALPHA_DESC = "The alpha transparency of the icons";

		NORTH_INDICATOR = "N";
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Slash commands
	SLASH__VIRTUALMAP1 = "/virtualmap";
	SLASH__VIRTUALMAP2 = "/vmap";

	-- Keybinds
	BINDING_HEADER__VIRTUALMAP = Title;
	BINDING_NAME__VIRTUALMAP_TOGGLE = "Toggles "..Title;
end
