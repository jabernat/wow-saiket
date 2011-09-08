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
function NS.Control:OnSelect ( NpcID, _, _, Name )
	NS.NpcID, NS.Name, NS.DisplayID = NpcID, Name, Tools.NPCDisplayIDs[ NpcID ];
	if ( NS.DisplayID and not InCombatLockdown() ) then
		self:Enable();
	else
		self:Disable();
	end
end
--- Shows the selected NPC in _NPCScan's alert button.
function NS.Control:OnClick ()
	Button:Update( NS.NpcID, NS.Name );
	Button.Model:SetDisplayInfo( NS.DisplayID );

	local Settings = Button.ModelCameras[ GetDisplayModel( NS.DisplayID ) ] or "";
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

NS.Backdrop = Button:CreateTexture( nil, "BACKGROUND" );
NS.Backdrop:Hide();
NS.Backdrop:SetAllPoints( Button.Model );
NS.Backdrop:SetTexture( [[textures\ShaneCube]] );
NS.Backdrop:SetVertexColor( 0.5, 0.5, 0.5 );


local Control = NS.Control;
Control:SetSize( 144, 21 );
Control:SetText( Tools.L.MODEL_CONTROL );
Control:SetScript( "OnClick", Control.OnClick );
Tools.Config.Controls:Add( Control );