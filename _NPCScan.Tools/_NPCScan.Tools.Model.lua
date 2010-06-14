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
me.EditBox = CreateFrame( "EditBox", "_NPCScanToolsModelEditBox", me, "InputBoxTemplate" );




--[[****************************************************************************
  * Function: _NPCScan.Tools.Model.ButtonUpdate                                *
  * Description: Hides model controls when a real alert appears.               *
  ****************************************************************************]]
function me.ButtonUpdate ()
	me:Hide();
	me.Backdrop:Hide();
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
  * Function: _NPCScan.Tools.Model.EditBox:Save                                *
  ****************************************************************************]]
function me.EditBox:Save ()
	Button.Model:Reset();
	Button.Model:SetCreature( self.NpcID );
	local Model = Button.Model:GetModel();
	if ( type( Model ) ~= "string" ) then
		Button.Model:SetModel( Tools.NPCModels[ self.NpcID ] );
		Model = Button.Model:GetModel(); -- Extension changes to *.m2
	end

	Button.ModelCameras[ Model:lower() ] = self:GetText():gsub( "||", "|" );
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
	Button:Update( self.NpcID, self.Name );

	local Model = Button.Model:GetModel();
	if ( type( Model ) ~= "string" ) then -- Wasn't in cache
		Button.Model:SetModel( self.Model );
		Model = Button.Model:GetModel(); -- Extension changes to *.m2
	end

	me.EditBox:SetText( ( Button.ModelCameras[ Model:lower() ] or "" ):gsub( "|", "||" ) );
	me.EditBox.NpcID = self.NpcID;
	me:Show();
	me.Backdrop:Show();
	me.EditBox:SetFocus();
end




me:Hide();
me:SetScript( "OnEvent", _NPCScan.OnEvent );
me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
hooksecurefunc( Button, "Update", me.ButtonUpdate );

me.EditBox:SetPoint( "TOPLEFT", Button, "BOTTOMLEFT", 8, 0 );
me.EditBox:SetPoint( "RIGHT", Button, -4, 0 );
me.EditBox:SetHeight( 16 );
me.EditBox:SetAutoFocus( false );
me.EditBox:SetScript( "OnEnterPressed", me.EditBox.Save );
me.EditBox:SetScript( "OnEditFocusGained", nil );

me.Backdrop = Button.Model:CreateTexture( nil, "BACKGROUND" );
me.Backdrop:Hide();
me.Backdrop:SetAllPoints();
me.Backdrop:SetTexture( [[textures\ShaneCube]] );
me.Backdrop:SetVertexColor( 0.5, 0.5, 0.5 );


me.Control:SetText( L.MODEL_CONTROL );
me.Control:SetScript( "OnClick", me.Control.OnClick );

Tools.Config.Controls:Add( me.Control );