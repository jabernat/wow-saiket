--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Model.lua - Lets you adjust _NPCScan's alert button models. *
  ****************************************************************************]]


local Tools = select( 2, ... );
local Button = _NPCScan.Button;
local NS = CreateFrame( "Frame" );
Tools.Model = NS;

NS.Control = CreateFrame( "Button", nil, nil, "UIPanelButtonTemplate" );
NS.EditBox = CreateFrame( "EditBox", "_NPCScanToolsModelEditBox", Button, "InputBoxTemplate" );




--- Hides model controls when a real alert appears.
function NS.ButtonUpdate ()
	NS.EditBox:Hide();
	NS.Backdrop:Hide();
end
--- Re-enables showing the model after leaving combat.
function NS:PLAYER_REGEN_ENABLED ()
	if ( self.DisplayID ) then
		self.Control:Enable();
	end
end
--- Disables showing the model in combat.
function NS:PLAYER_REGEN_DISABLED ()
	self.Control:Disable();
end


local GetDisplayModel;
do
	local Model = CreateFrame( "PlayerModel" );
	--- @return Model path for DisplayID.
	function GetDisplayModel ( DisplayID )
		Model:SetDisplayInfo( DisplayID );
		local Path = Model:GetModel();
		return type( Path ) == "string" and Path:lower();
	end
end
--- Saves modified model settings.
function NS.EditBox:OnEnterPressed ()
	local Model = assert( GetDisplayModel( NS.DisplayID ), "Unknown model for DisplayID." );
	Button.ModelCameras[ Model ] = self:GetText():gsub( "||", "|" );
	Button.Model:Reset();
	Button.Model:SetDisplayInfo( NS.DisplayID );
end


--- Validates that the selected NPC's model can be shown.
function NS:OnSelectNPC ( _, NpcID )
	if ( NpcID and Tools.NPCData.DisplayIDs[ NpcID ] and not InCombatLockdown() ) then
		self.Control:Enable();
	else
		self.Control:Disable();
	end
end
--- Shows the selected NPC in _NPCScan's alert button.
function NS.Control:OnClick ()
	local NpcID, Name = Tools:GetSelectedNPC();
	local DisplayID = Tools.NPCData.DisplayIDs[ NpcID ];
	Button:Update( NpcID, Name );
	Button.Model:SetDisplayInfo( DisplayID );

	local Settings = Button.ModelCameras[ GetDisplayModel( DisplayID ) ] or "";
	NS.EditBox:SetText( Settings:gsub( "|", "||" ) );
	NS.EditBox:Show();
	NS.Backdrop:Show();
	NS.EditBox:SetFocus();
end




NS:Hide();
NS:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
NS:RegisterEvent( "PLAYER_REGEN_ENABLED" );
NS:RegisterEvent( "PLAYER_REGEN_DISABLED" );
hooksecurefunc( Button, "Update", NS.ButtonUpdate );

local EditBox = NS.EditBox;
EditBox:SetPoint( "BOTTOMLEFT", 8, 4 );
EditBox:SetPoint( "RIGHT", -4, 0 );
EditBox:SetHeight( 16 );
EditBox:SetAutoFocus( false );
EditBox:SetScript( "OnEnterPressed", EditBox.OnEnterPressed );
EditBox:SetScript( "OnEditFocusGained", nil );

NS.Backdrop = Button.Model:CreateTexture( nil, "BACKGROUND" );
NS.Backdrop:Hide();
NS.Backdrop:SetAllPoints();
NS.Backdrop:SetTexture( [[textures\ShaneCube]] );
NS.Backdrop:SetVertexColor( 0.5, 0.5, 0.5 );

local Control = NS.Control;
Control:SetText( Tools.L.MODEL_CONTROL );
Control:SetSize( Control:GetTextWidth() + 16, 21 );
Control:SetScript( "OnClick", Control.OnClick );

Tools:AddControl( Control );
Tools.RegisterCallback( NS, "OnSelectNPC" );
NS:OnSelectNPC( nil, Tools:GetSelectedNPC() );
if ( InCombatLockdown() ) then
	NS:PLAYER_REGEN_DISABLED();
end