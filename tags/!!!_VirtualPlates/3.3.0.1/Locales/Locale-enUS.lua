--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


do
	local Title = "_|cffCCCC88VirtualPlates|r";


	local Metatable = {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	};
	_VirtualPlatesLocalization = setmetatable( {
		CONFIG_TITLE = Title;
		CONFIG_DESC = "Configure the way _VirtualPlates scales nameplates.";

		CONFIG_SLIDER_FORMAT = "%.2f";
		CONFIG_SLIDERYARD_FORMAT = "%dyd";

		CONFIG_LIMITS = "Nameplate Scale Limits";

		CONFIG_MINSCALE = "Minimum";
		CONFIG_MINSCALE_DESC = "Limits how small nameplates can shrink, from 0 meaning no limit, to 1 meaning they won't shrink smaller than their default size.";

		CONFIG_MAXSCALEENABLED = "Limit maximum scale";
		CONFIG_MAXSCALEENABLED_DESC = "Prevents nameplates from growing too large when they're near the screen.";

		CONFIG_MAXSCALE = "Maximum";
		CONFIG_MAXSCALE_DESC = false; -- Self explanatory


		CONFIG_SCALEFACTOR1 = "Scale Factor";
		CONFIG_SCALEFACTOR1_DESC = "Nameplates this far from the camera will be normal sized.";

		CONFIG_SCALEFACTOR2ENABLED = "Change scale factor with camera zoom";
		CONFIG_SCALEFACTOR2ENABLED_DESC = "Allows nameplates to grow larger when zoomed far out.  When enabled, the slider above determines the starting scale used in first-person view.";

		CONFIG_SCALEFACTOR2 = "Scale Factor When Zoomed Out";
		CONFIG_SCALEFACTOR2_DESC = "As you zoom your camera further out towards 50 yards, the nameplate scale factor will change to this value.";
	}, Metatable );
end
