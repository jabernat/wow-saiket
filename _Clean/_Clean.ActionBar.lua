--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.ActionBar.lua - Modifies the action bars and their buttons.         *
  *                                                                            *
  * + Colors action buttons red when out of range.                             *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame", nil, _Clean );
_Clean.ActionBar = me;

local BackdropBottomLeft = _Clean.Backdrop.Create( UIParent );
me.BackdropBottomLeft = BackdropBottomLeft;
local BackdropBottomRight = _Clean.Backdrop.Create( UIParent );
me.BackdropBottomRight = BackdropBottomRight;
local BackdropRight = _Clean.Backdrop.Create( UIParent );
me.BackdropRight = BackdropRight;

me.DominosProfile = "_Clean";

local Icons = {};




--[[****************************************************************************
  * Function: _Clean.ActionBar.ActionButtonModify                              *
  * Description: Modifies textures on an action button.                        *
  ****************************************************************************]]
function me.ActionButtonModify ( Prefix, Index )
	_G[ Prefix..Index ]:GetNormalTexture():SetAlpha( 1.0 );
	_Clean.RemoveButtonIconBorder( _G[ Prefix..Index.."Icon" ] );
	_G[ Prefix..Index.."Border" ]:SetAlpha( 0.8 );
end


--[[****************************************************************************
  * Function: _Clean.ActionBar.ActionButtonOnUpdate                            *
  * Description: Tints action buttons red when out of range.                   *
  ****************************************************************************]]
function me.ActionButtonOnUpdate ()
	if ( this.rangeTimer == TOOLTIP_UPDATE_TIME ) then -- Just updated
		me.ActionButtonUpdateUsable();
	end
end
--[[****************************************************************************
  * Function: _Clean.ActionBar.ActionButtonUpdateUsable                        *
  * Description: Tints action buttons red when out of range.                   *
  ****************************************************************************]]
do
	-- Note: This gets called a ton; optimize anything and everything.
	local IsActionInRange = IsActionInRange;
	local IsUsableAction = IsUsableAction;
	local _G = _G;
	local self, Action, Icon, Usable, NotEnoughMana;
	function me.ActionButtonUpdateUsable ()
		self = this;
		Action = self.action;
		if ( not Action ) then -- Note: Prevents error when saving sets in Dominos
			return;
		end
		Icon = Icons[ self ];
		if ( not Icon ) then
			Icon = _G[ self:GetName().."Icon" ];
			Icons[ self ] = Icon;
		end
		Usable, NotEnoughMana = IsUsableAction( Action );

		if ( Usable ) then -- Not out of mana or unusable
			if ( IsActionInRange( Action ) ~= 0 ) then
				Icon:SetVertexColor( 1.0, 1.0, 1.0 ); -- Usable
				self:SetAlpha( 1.0 );
			else
				Icon:SetVertexColor( 0.8, 0.1, 0.1 );
				self:SetAlpha( 0.6 );
			end
		elseif ( NotEnoughMana ) then -- Very distinct blue
			Icon:SetVertexColor( 0.1, 0.1, 1.0 );
			self:SetAlpha( 0.6 );
		end
	end
end




--[[****************************************************************************
  * Function: _Clean.ActionBar:OnEvent                                         *
  * Description: Positions parts of the UI around bars once they are created.  *
  ****************************************************************************]]
function me:OnEvent ()
	me:UnregisterEvent( "PLAYER_LOGIN" );
	me:SetScript( "OnEvent", nil );
	me.OnEvent = nil;

	-- Add backdrops
	if ( Dominos:MatchProfile( me.DominosProfile ) ) then
		if ( Dominos.db:GetCurrentProfile() ~= me.DominosProfile ) then
			Dominos:SetProfile( me.DominosProfile );
		end

		local Backdrop = _Clean.ActionBar.BackdropBottomLeft;
		Backdrop:SetPoint( "BOTTOMLEFT", Dominos.Frame:Get( 1 ) );
		Backdrop:SetPoint( "TOPRIGHT", Dominos.Frame:Get( 6 ), _Clean.Backdrop.Padding, _Clean.Backdrop.Padding );

		Backdrop = _Clean.ActionBar.BackdropBottomRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", Dominos.Frame:Get( "bags" ) );
		Backdrop:SetPoint( "TOPLEFT", Dominos.Frame:Get( 5 ), -_Clean.Backdrop.Padding, _Clean.Backdrop.Padding );

		Backdrop = _Clean.ActionBar.BackdropRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", BackdropBottomRight, "TOPRIGHT" );
		Backdrop:SetPoint( "TOPLEFT", MultiBarLeftButton4, -_Clean.Backdrop.Padding, _Clean.Backdrop.Padding );
	else -- Temporary setup so the game doesn't crash
		local Backdrop = _Clean.ActionBar.BackdropBottomLeft;
		Backdrop:SetPoint( "BOTTOMLEFT", UIParent );
		Backdrop:SetPoint( "TOPRIGHT", UIParent, "BOTTOMLEFT", 1, 72 );

		Backdrop = _Clean.ActionBar.BackdropBottomRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", UIParent );
		Backdrop:SetPoint( "TOPLEFT", UIParent, "BOTTOMRIGHT", -1, 72 );

		Backdrop = _Clean.ActionBar.BackdropRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", BackdropBottomRight, "TOPRIGHT" );
		Backdrop:SetWidth( 1 );
		Backdrop:SetHeight( 120 );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", me.OnEvent );
	me:RegisterEvent( "PLAYER_LOGIN" );

	-- Remove icon borders on buttons
	for Index = 1, NUM_MULTIBAR_BUTTONS do
		me.ActionButtonModify( "ActionButton", Index );
		me.ActionButtonModify( "MultiBarBottomLeftButton", Index );
		me.ActionButtonModify( "MultiBarBottomRightButton", Index );
		me.ActionButtonModify( "MultiBarLeftButton", Index );
		me.ActionButtonModify( "MultiBarRightButton", Index );
	end

	-- Shapeshift bar
	for Index = 1, NUM_SHAPESHIFT_SLOTS do
		_Clean.RemoveButtonIconBorder( _G[ "ShapeshiftButton"..Index.."Icon" ] );
		_G[ "ShapeshiftButton"..Index.."NormalTexture" ]:SetTexture();
	end

	-- Bag buttons
	local LastButton = MainMenuBarBackpackButton;
	_Clean.RemoveButtonIconBorder( MainMenuBarBackpackButtonIconTexture );
	MainMenuBarBackpackButtonNormalTexture:SetTexture();
	for Index = 0, NUM_BAG_SLOTS - 1 do
		_Clean.RemoveButtonIconBorder( _G[ "CharacterBag"..Index.."SlotIconTexture" ] );
		_G[ "CharacterBag"..Index.."SlotNormalTexture" ]:SetTexture();
	end

	-- Keyring
	local LastBag = _G[ "CharacterBag"..( NUM_BAG_SLOTS - 1 ).."Slot" ];
	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint( "TOPLEFT", LastBag );
	KeyRingButton:SetPoint( "BOTTOM", LastBag );
	KeyRingButton:SetParent( LastBag );
	KeyRingButton:SetWidth( 8 );
	KeyRingButton:GetNormalTexture():SetTexCoord( 0.15, 0.45, 0.1, 0.52 );
	KeyRingButton:Show();

	-- Hooks
	hooksecurefunc( "ActionButton_OnUpdate", me.ActionButtonOnUpdate );
	hooksecurefunc( "ActionButton_UpdateUsable", me.ActionButtonUpdateUsable );
end
