--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.Mapster.lua - Adjusts WorldMap module with Mapster.       *
  ****************************************************************************]]


if ( not IsAddOnLoaded( "Mapster" ) ) then
	return;
end

local AddOnName, Overlay = ...;
local Mapster = LibStub( "AceAddon-3.0" ):GetAddon( "Mapster" );
local me = Mapster:NewModule( AddOnName );
Overlay.Mapster = me;

me.Toggle = _NPCScan.Overlay.WorldMap.Toggle;




--[[****************************************************************************
  * Function: _NPCScan.Overlay.Mapster:UpdateMapsize                           *
  * Description: Moves the checkbox so it doesn't overlap Mapster's stuff.     *
  ****************************************************************************]]
function me:UpdateMapsize ( Mini )
	self.Toggle:ClearAllPoints();
	self.Toggle:SetPoint( "BOTTOM", WorldMapTrackQuest );
	if ( Mini ) then -- Right side so coordinates don't overlap
		local Label = _G[ self.Toggle:GetName().."Text" ];
		self.Toggle:SetPoint( "RIGHT", WorldMapDetailFrame, -Label:GetStringWidth() - 4, 0 );
	else -- Left side, between "Track Quests" and player coordinates
		local Label = _G[ WorldMapTrackQuest:GetName().."Text" ];
		self.Toggle:SetPoint( "LEFT", WorldMapTrackQuest, "RIGHT", Label:GetStringWidth() + 8, -4 );
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Mapster:OnEnable                                *
  ****************************************************************************]]
function me:OnEnable ()
	self:UpdateMapsize( Mapster.miniMap );
	self.Toggle:Show();
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Mapster:OnDisable                               *
  ****************************************************************************]]
function me:OnDisable ()
	self.Toggle:Hide();
end
--[[****************************************************************************
  * Function: _NPCScan.Overlay.Mapster:OnInitialize                            *
  ****************************************************************************]]
function me:OnInitialize ()
	self:SetEnabledState( true );
	self.Toggle:Hide();
end
