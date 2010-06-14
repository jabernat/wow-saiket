--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


-- See http://wow.curseforge.com/addons/virtualplates/localization/enUS/
_VirtualPlatesLocalization = setmetatable( {
	CONFIG_DESC = "Configure the way _VirtualPlates scales nameplates.",
	CONFIG_LIMITS = "Nameplate Scale Limits",
	CONFIG_MAXSCALE = "Maximum",
	CONFIG_MAXSCALEENABLED = "Limit maximum scale",
	CONFIG_MAXSCALEENABLED_DESC = "Prevents nameplates from growing too large when they're near the screen.",
	CONFIG_MINSCALE = "Minimum",
	CONFIG_MINSCALE_DESC = "Limits how small nameplates can shrink, from 0 meaning no limit, to 1 meaning they won't shrink smaller than their default size.",
	CONFIG_SCALEFACTOR = "Scale Factor",
	CONFIG_SCALEFACTOR_DESC = "Nameplates this far from the camera will be normal sized.",
	CONFIG_SLIDER_FORMAT = "%.2f",
	CONFIG_SLIDERYARD_FORMAT = "%dyd",
	CONFIG_TITLE = "_|cffCCCC88VirtualPlates|r",
}, {
	__index = function ( self, Key )
		if ( Key ~= nil ) then
			rawset( self, Key, Key );
			return Key;
		end
	end;
} );