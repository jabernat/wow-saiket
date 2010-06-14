--[[****************************************************************************
  * _Underscore.Minimap by Saiket                                              *
  * _Underscore.Minimap.LibDBIcon_1_0.lua - Skins LibDBIcon-1.0 minimap icons. *
  ****************************************************************************]]


if ( not _Underscore.Minimap ) then -- Wasn't loaded because Carbonite is enabled
	return;
end
local _Underscore = _Underscore;
local me = CreateFrame( "Frame" );
_Underscore.Minimap.LibDBIcon_1_0 = me;

me.Meta = {};

local IconSize = 20;
local IconBorder = 1;




--[[****************************************************************************
  * Function: _Underscore.Minimap.LibDBIcon_1_0.Meta:__newindex                *
  * Description: Hooks creation of new buttons.                                *
  ****************************************************************************]]
function me.Meta:__newindex ( Name, Button )
	rawset( self, Name, Button );
	me.Skin( Button, Button:GetRegions() );
end
--[[****************************************************************************
  * Function: _Underscore.Minimap.LibDBIcon_1_0:Skin                           *
  * Description: Skins a new minimap button.                                   *
  ****************************************************************************]]
function me:Skin ( ... )
	self:SetSize( IconSize, IconSize );
	self:SetFrameStrata( "BACKGROUND" );
	self:SetClampedToScreen( true );
	local Inset = -IconSize / 6; -- 1/6th of button allowed off screen
	self:SetClampRectInsets( Inset, Inset, Inset, Inset );
	self:SetAlpha( 0.8 );
	_Underscore.SkinButton( self, self.icon );
	self.icon:SetAllPoints( self );
	self.icon:SetDrawLayer( "ARTWORK" );
	self.icon.SetTexCoord = _Underscore.NilFunction;
	_Underscore.Backdrop.Create( self, IconBorder );

	for Index = 1, select( "#", ... ) do
		local Region = select( Index, ... );
		if ( Region:IsObjectType( "Texture" ) ) then
			local Path = Region:GetTexture();
			if ( Path and Path:lower() == [[interface\minimap\minimap-trackingborder]] ) then
				Region:SetTexture();
				Region:Hide();
				break;
			end
		end
	end
end


--[[****************************************************************************
  * Function: _Underscore.Minimap.LibDBIcon_1_0:ADDON_LOADED                   *
  ****************************************************************************]]
function me:ADDON_LOADED ()
	local LibDBIcon = LibStub( "LibDBIcon-1.0", true ); -- No error if missing
	if ( LibDBIcon ) then
		me.ADDON_LOADED = nil;
		me:UnregisterAllEvents();

		-- Skin buttons made before event
		for Name, Button in pairs( LibDBIcon.objects ) do
			me.Skin( Button, Button:GetRegions() );
		end
		-- Hook creation of new buttons
		setmetatable( LibDBIcon.objects, me.Meta );
	end
end




me:SetScript( "OnEvent", _Underscore.OnEvent );
me:RegisterEvent( "ADDON_LOADED" );