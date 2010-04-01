--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Model.lua - Lets you adjust _NPCScan's alert button models. *
  ****************************************************************************]]


local Tools = select( 2, ... );
local Button = _NPCScan.Button;
local L = _NPCScanLocalization.TOOLS;
local me = CreateFrame( "Frame", nil, Button );
Tools.Model = me;

me.Control = CreateFrame( "Button", nil, nil, "GameMenuButtonTemplate" );




--[[****************************************************************************
  * Function: _NPCScan.Tools.Model.ButtonUpdate                                *
  * Description: Hides model controls when a real alert appears.               *
  ****************************************************************************]]
function me.ButtonUpdate ()
	me:Hide();
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Model:PLAYER_REGEN_ENABLED                        *
  ****************************************************************************]]
function me:PLAYER_REGEN_ENABLED ()
	if ( self.Control.NpcID ) then
		self.Control:Enable();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Model:PLAYER_REGEN_DISABLED                       *
  ****************************************************************************]]
function me:PLAYER_REGEN_DISABLED ()
	self.Control:Disable();
end


--[[****************************************************************************
  * Function: _NPCScan.Tools.Model.Control:OnSelect                            *
  ****************************************************************************]]
function me.Control:OnSelect ( NpcID, _, _, Name, Model )
	self.NpcID, self.Name, self.Model = NpcID, Name, Model;
	if ( Tools.NPCModels[ NpcID ] and not InCombatLockdown() ) then
		self:Enable();
	else
		self:Disable();
	end
end
--[[****************************************************************************
  * Function: _NPCScan.Tools.Model.Control:OnClick                             *
  * Description: Shows the selected NPC in _NPCScan's alert button.            *
  ****************************************************************************]]
function me.Control:OnClick ()
	Button:Update( self.Name, self.NpcID );
	if ( type( Button.Model:GetModel() ) ~= "string" ) then -- Wasn't in cache
		Button.Model:SetModel( self.Model );
	end
	me:Show();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:Hide();
	me:SetScript( "OnEvent", _NPCScan.OnEvent );
	me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
	me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
	hooksecurefunc( Button, "Update", me.ButtonUpdate );


	me.Control:SetText( L.MODEL_CONTROL );
	me.Control:SetScript( "OnClick", me.Control.OnClick );

	Tools.Config.Controls:Add( me.Control );
end
