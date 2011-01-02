--[[****************************************************************************
  * _NPCScan.Tools by Saiket                                                   *
  * _NPCScan.Tools.Model.lua - Lets you adjust _NPCScan's alert button models. *
  ****************************************************************************]]


local Tools = select( 2, ... );
local Button = _NPCScan.Button;
local me = CreateFrame( "Frame" );
Tools.Model = me;

me.Control = CreateFrame( "Button", nil, nil, "UIPanelButtonTemplate" );
me.EditBox = CreateFrame( "EditBox", "_NPCScanToolsModelEditBox", Button, "InputBoxTemplate" );




--- Hides model controls when a real alert appears.
function me.ButtonUpdate ()
	me.EditBox:Hide();
	me.Backdrop:Hide();
end
--- Re-enables showing the model after leaving combat.
function me:PLAYER_REGEN_ENABLED ()
	if ( self.DisplayID ) then
		self.Control:Enable();
	end
end
--- Disables showing the model in combat.
function me:PLAYER_REGEN_DISABLED ()
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
function me.EditBox:OnEnterPressed ()
	local Model = assert( GetDisplayModel( me.DisplayID ), "Unknown model for DisplayID." );
	Button.ModelCameras[ Model ] = self:GetText():gsub( "||", "|" );
	Button.Model:Reset();
	Button.Model:SetDisplayInfo( me.DisplayID );
end


--- Validates that the selected NPC's model can be shown.
function me.Control:OnSelect ( NpcID, _, _, Name )
	me.NpcID, me.Name, me.DisplayID = NpcID, Name, Tools.NPCDisplayIDs[ NpcID ];
	if ( me.DisplayID and not InCombatLockdown() ) then
		self:Enable();
	else
		self:Disable();
	end
end
--- Shows the selected NPC in _NPCScan's alert button.
function me.Control:OnClick ()
	Button:Update( me.NpcID, me.Name );
	Button.Model:SetDisplayInfo( me.DisplayID );

	local Settings = Button.ModelCameras[ GetDisplayModel( me.DisplayID ) ] or "";
	me.EditBox:SetText( Settings:gsub( "|", "||" ) );
	me.EditBox:Show();
	me.Backdrop:Show();
	me.EditBox:SetFocus();
end




me:Hide();
me:SetScript( "OnEvent", _NPCScan.Frame.OnEvent );
me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
hooksecurefunc( Button, "Update", me.ButtonUpdate );

local EditBox = me.EditBox;
EditBox:SetPoint( "BOTTOMLEFT", 8, 4 );
EditBox:SetPoint( "RIGHT", -4, 0 );
EditBox:SetHeight( 16 );
EditBox:SetAutoFocus( false );
EditBox:SetScript( "OnEnterPressed", EditBox.OnEnterPressed );
EditBox:SetScript( "OnEditFocusGained", nil );

me.Backdrop = Button:CreateTexture( nil, "BACKGROUND" );
me.Backdrop:Hide();
me.Backdrop:SetAllPoints( Button.Model );
me.Backdrop:SetTexture( [[textures\ShaneCube]] );
me.Backdrop:SetVertexColor( 0.5, 0.5, 0.5 );


local Control = me.Control;
Control:SetSize( 144, 21 );
Control:SetText( Tools.L.MODEL_CONTROL );
Control:SetScript( "OnClick", Control.OnClick );
Tools.Config.Controls:Add( Control );