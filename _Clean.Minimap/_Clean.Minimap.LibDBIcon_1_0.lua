--[[****************************************************************************
  * _Clean.Minimap by Saiket                                                   *
  * _Clean.Minimap.LibDBIcon_1_0.lua - Skins LibDBIcon-1.0 minimap buttons.    *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.Minimap.LibDBIcon_1_0 = me;

me.Meta = {};

local IconSize = 20;




--[[****************************************************************************
  * Function: _Clean.Minimap.LibDBIcon_1_0.Meta:__newindex                     *
  * Description: Hooks creation of new buttons.                                *
  ****************************************************************************]]
function me.Meta:__newindex ( Name, Button )
	rawset( self, Name, Button );
	me.Skin( Button, Button:GetRegions() );
end
--[[****************************************************************************
  * Function: _Clean.Minimap.LibDBIcon_1_0:Skin                                *
  * Description: Skins a new minimap button.                                   *
  ****************************************************************************]]
function me:Skin ( ... )
	self:SetWidth( IconSize );
	self:SetHeight( IconSize );
	self:SetFrameStrata( "BACKGROUND" );
	self:SetFrameLevel( MinimapCluster:GetFrameLevel() - 1 );
	self:SetAlpha( 0.8 );
	_Clean.RemoveIconBorder( self.icon );
	self.icon:SetAllPoints( self );
	self.icon.SetTexCoord = _Clean.NilFunction;

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
  * Function: _Clean.Minimap.LibDBIcon_1_0:ADDON_LOADED                        *
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




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", _Clean.OnEvent );
	me:RegisterEvent( "ADDON_LOADED" );
end
