--[[****************************************************************************
  * _Arena by Saiket                                                           *
  * _Arena.Buttons.lua - Adds buttons to the top of the list frame.            *
  ****************************************************************************]]


local _Arena = _Arena;
local L = _ArenaLocalization;
local me = {
	ResetButton = CreateFrame( "Button", nil, _Arena, "GameMenuButtonTemplate" );
	CameraCheckbox = CreateFrame( "CheckButton", nil, _Arena, "UICheckButtonTemplate" );
};
_Arena.Buttons = me;

local WellButtons = {};
me.WellButtons = WellButtons;




--[[****************************************************************************
  * Function: _Arena.Buttons.Update                                            *
  * Description: Updates all button displays.                                  *
  ****************************************************************************]]
do
	local pairs = pairs;
	function me.Update ()
		if ( _Arena.List:NumLines() == 0 ) then
			me.ResetButton:Disable();
		else
			me.ResetButton:Enable();
		end
	
		for _, Button in pairs( WellButtons ) do
			local Wells = _Arena.Scan.Results[ Button.Class ].Wells;
			Button.CountText:SetText( Wells > 0 and Wells or nil );
			SetDesaturation( Button.Texture, Wells == 0 );
		end
	end
end
--[[****************************************************************************
  * Function: _Arena.Buttons.AddWell                                           *
  * Description: Adds a class well button.                                     *
  ****************************************************************************]]
do
	local LastWellButton = nil;
	function me.AddWell ( Class, Title, IconPath )
		local Button = CreateFrame( "Button", "_ArenaWellButton"..Class, _Arena, "ItemButtonTemplate" );
		Button.Class = Class;
		WellButtons[ Class ] = Button;
	
		local ClassColor = RAID_CLASS_COLORS[ Class ];
		Button.Title = format( L.WELL_TITLE_FORMAT, Title,
			floor( ClassColor.r * 255 ),
			floor( ClassColor.g * 255 ),
			floor( ClassColor.b * 255 ),
			L[ Class ] );
	
		Button:SetScript( "OnClick", me.WellOnClick );
		Button:SetScript( "OnEnter", me.OnEnter );
		Button:SetScript( "OnLeave", me.OnLeave );
	
		Button:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
		Button:SetWidth( 20 );
		Button:SetHeight( 20 );
		local NormalTexture = Button:GetNormalTexture();
		NormalTexture:SetWidth( 40 );
		NormalTexture:SetHeight( 40 );
	
		Button.Texture = _G[ "_ArenaWellButton"..Class.."IconTexture" ];
		Button.Texture:SetTexture( IconPath );
	
		Button.CountText = _G[ "_ArenaWellButton"..Class.."Count" ];
		Button.CountText:SetFontObject( NumberFontNormalLarge );
		Button.CountText:Show();
	
		if ( LastWellButton ) then
			Button:SetPoint( "LEFT", LastWellButton, "RIGHT" );
		else
			Button:SetPoint( "TOPLEFT", _Arena, 6, -23 );
		end
		LastWellButton = Button;
	end
end


--[[****************************************************************************
  * Function: _Arena.Buttons:WellOnClick                                       *
  * Description: Adds or removes a well for the given button's class.          *
  ****************************************************************************]]
function me:WellOnClick ( Button )
	local ClassResults = _Arena.Scan.Results[ self.Class ];
	local Change = Button == "RightButton" and -1 or 1;

	PlaySound( Change == -1
		and "igMainMenuOptionCheckBoxOff" or "igMainMenuOptionCheckBoxOn" );
	if ( not ( ClassResults.Wells == 0 and Change == -1 ) ) then
		ClassResults.Wells = ClassResults.Wells + Change;
		_Arena.List.Update();
	end
end

--[[****************************************************************************
  * Function: _Arena.Buttons:ResetOnClick                                      *
  * Description: Resets saved data.                                            *
  ****************************************************************************]]
function me:ResetOnClick ()
	PlaySound( "igMainMenuOption" );
	_Arena.Scan.ResetResults();
	_Arena.List.Update();
end

--[[****************************************************************************
  * Function: _Arena.Buttons:CameraOnClick                                     *
  * Description: Toggles the floating camera.                                  *
  ****************************************************************************]]
function me:CameraOnClick ()
	PlaySound( "igMainMenuOption" );
	self:SetChecked( not self:GetChecked() );
	_Arena.Camera.Toggle();
end




--[[****************************************************************************
  * Function: _Arena.Buttons:OnEnter                                           *
  * Description: Adds the button's tooltip.                                    *
  ****************************************************************************]]
function me:OnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
	GameTooltip:ClearLines();
	GameTooltip:SetText( self.Title );
	GameTooltip:Show();
end
--[[****************************************************************************
  * Function: _Arena.Buttons:OnLeave                                           *
  * Description: Removes the button's tooltip.                                 *
  ****************************************************************************]]
function me:OnLeave ()
	GameTooltip:Hide();
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.AddWell( "MAGE", L.WELL_REFRESHMENT_TABLE, "Interface\\Icons\\Spell_Misc_Food" );
	me.AddWell( "WARLOCK", L.WELL_SOULWELL, "Interface\\Icons\\INV_Stone_04" );

	me.ResetButton:SetWidth( 16 );
	me.ResetButton:SetHeight( 20 );
	me.ResetButton:SetPoint( "TOPRIGHT", -5, -23 );
	me.ResetButton:SetText( L.BUTTON_RESET );
	me.ResetButton.Title = L.BUTTON_RESET_TITLE;
	me.ResetButton:SetScript( "OnClick", me.ResetOnClick );
	me.ResetButton:SetScript( "OnEnter", me.OnEnter );
	me.ResetButton:SetScript( "OnLeave", me.OnLeave );

	me.CameraCheckbox:SetWidth( 18 );
	me.CameraCheckbox:SetHeight( 18 );
	me.CameraCheckbox:SetPoint( "RIGHT", me.ResetButton, "LEFT", -2, 0 );
	me.CameraCheckbox.Title = L.BUTTON_CAMERA_TITLE;
	me.CameraCheckbox:SetScript( "OnClick", me.CameraOnClick );
	me.CameraCheckbox:SetScript( "OnEnter", me.OnEnter );
	me.CameraCheckbox:SetScript( "OnLeave", me.OnLeave );
end
