--[[****************************************************************************
  * _Underscore.Minimap by Saiket                                              *
  * _Underscore.Minimap.LibDBIcon_1_0.lua - Skins LibDBIcon-1.0 minimap icons. *
  ****************************************************************************]]


if ( not _Underscore.Minimap ) then -- Wasn't loaded because Carbonite is enabled
	return;
end
local Frame = select( 2, ... ).Frame;

local IconSize = 20;
local IconBorder = 1;




local Skin;
do
	local PathBlacklist = {
		[ [[interface\minimap\minimap-trackingborder]] ] = true;
		[ [[interface\minimap\ui-minimap-background]] ] = true;
	};
	--- Skins a new LDB minimap button.
	-- @param ...  Regions of Button.
	function Skin ( Button, ... )
		Button:SetSize( IconSize, IconSize );
		Button:SetFrameStrata( "BACKGROUND" );
		Button:SetClampedToScreen( true );
		local Inset = -IconSize / 6; -- 1/6th of button allowed off screen
		Button:SetClampRectInsets( Inset, Inset, Inset, Inset );
		Button:SetAlpha( 0.8 );
		_Underscore.SkinButton( Button, Button.icon );
		Button.icon:SetAllPoints( Button );
		Button.icon:SetDrawLayer( "ARTWORK" );
		Button.icon.SetTexCoord = _Underscore.NilFunction;
		_Underscore.Backdrop.Create( Button, IconBorder );

		-- Hide border and background
		for Index = 1, select( "#", ... ) do
			local Region = select( Index, ... );
			if ( Region:IsObjectType( "Texture" ) ) then
				local Path = Region:GetTexture();
				if ( Path and PathBlacklist[ Path:lower() ] ) then
					Region:SetTexture();
					Region:Hide();
				end
			end
		end
	end
end


local Meta = {};
--- Catches creation of new buttons to skin them.
function Meta:__newindex ( Name, Button )
	rawset( self, Name, Button );
	Skin( Button, Button:GetRegions() );
end


--- Checks for the lib as an embedded library after each addon loads.
function Frame:ADDON_LOADED ( Event )
	local LibDBIcon = LibStub( "LibDBIcon-1.0", true ); -- No error if missing
	if ( LibDBIcon ) then
		Frame[ Event ] = nil;
		Frame:UnregisterEvent( Event );

		-- Skin buttons made before event
		for Name, Button in pairs( LibDBIcon.objects ) do
			Skin( Button, Button:GetRegions() );
		end
		-- Hook creation of new buttons
		setmetatable( LibDBIcon.objects, Meta );
	end
end




Frame:RegisterEvent( "ADDON_LOADED" );