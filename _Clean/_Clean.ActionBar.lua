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

me.ButtonNormalTexture = "";




--[[****************************************************************************
  * Function: _Clean.ActionBar:ActionButtonModify                              *
  * Description: Modifies textures on an action button.                        *
  ****************************************************************************]]
do
	local Disabled = false;
	local function SetNormalTexture ( self, Texture )
		if ( not Disabled and type( Texture ) == "string" ) then
			if ( Texture:lower() == "interface\\buttons\\ui-quickslot" ) then
				-- Empty button texture
				self:GetNormalTexture():SetTexCoord( 0.2, 0.8, 0.2, 0.8 );
			else
				self:GetNormalTexture():SetTexCoord( 0, 1, 0, 1 );
				Disabled = true;
				self:SetNormalTexture( me.ButtonNormalTexture );
				Disabled = false;
			end
		end
	end
	function me:ActionButtonModify ()
		local NormalTexture = self:GetNormalTexture();
		NormalTexture:SetAllPoints( self );
		NormalTexture:SetAlpha( 1.0 );
		_Clean.RemoveButtonIconBorder( self:GetRegions() ); -- Note: Icon texture must be first!
		self:SetNormalTexture( me.ButtonNormalTexture );
		hooksecurefunc( self, "SetNormalTexture", SetNormalTexture );
	end
end


--[[****************************************************************************
  * Function: _Clean.ActionBar:ActionButtonOnUpdate                            *
  * Description: Tints action buttons red when out of range.                   *
  ****************************************************************************]]
function me:ActionButtonOnUpdate ( Elapsed )
	if ( self.rangeTimer == TOOLTIP_UPDATE_TIME ) then -- Just updated
		me.ActionButtonUpdateUsable( self );
	end
end
--[[****************************************************************************
  * Function: _Clean.ActionBar:ActionButtonUpdateUsable                        *
  * Description: Tints action buttons red when out of range.                   *
  ****************************************************************************]]
do
	-- Note: This gets called a ton; optimize anything and everything.
	local IsActionInRange = IsActionInRange;
	local IsUsableAction = IsUsableAction;
	local _G = _G;
	local Action, Icon, Usable, NotEnoughMana;
	local Icons = {};
	function me:ActionButtonUpdateUsable ()
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
		local OldProfile = Dominos.db:GetCurrentProfile();
		if ( OldProfile ~= me.DominosProfile ) then
			Dominos:SetProfile( me.DominosProfile );
			if ( OldProfile == UnitClass( "player" ) ) then -- Default created on initialization
				Dominos:DeleteProfile( OldProfile );
			end
		end

		local Padding = _Clean.Backdrop.Padding;
		local Backdrop = _Clean.ActionBar.BackdropBottomLeft;
		Backdrop:SetPoint( "BOTTOMLEFT", Dominos.Frame:Get( 1 ) );
		Backdrop:SetPoint( "TOPRIGHT", Dominos.Frame:Get( 6 ), Padding, Padding );

		Backdrop = _Clean.ActionBar.BackdropBottomRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", Dominos.Frame:Get( "bags" ) );
		Backdrop:SetPoint( "TOPLEFT", Dominos.Frame:Get( 5 ), -Padding, Padding );

		Backdrop = _Clean.ActionBar.BackdropRight;
		Backdrop:SetPoint( "BOTTOMRIGHT", BackdropBottomRight, "TOPRIGHT" );
		Backdrop:SetPoint( "TOPLEFT", MultiBarLeftButton4, -Padding, Padding );
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

	-- Skin Dominos' "class" buttons
	local ClassBar = Dominos.Frame:Get( "class" );
	if ( ClassBar ) then
		for _, Button in ipairs( ClassBar.buttons ) do
			me.ActionButtonModify( Button );
		end
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
		me.ActionButtonModify( _G[ "ActionButton"..Index ] );
		me.ActionButtonModify( _G[ "MultiBarBottomLeftButton"..Index ] );
		me.ActionButtonModify( _G[ "MultiBarBottomRightButton"..Index ] );
		me.ActionButtonModify( _G[ "MultiBarLeftButton"..Index ] );
		me.ActionButtonModify( _G[ "MultiBarRightButton"..Index ] );
	end

	-- Shapeshift bar (These get replaced by Dominos later)
	for Index = 1, NUM_SHAPESHIFT_SLOTS do
		me.ActionButtonModify( _G[ "ShapeshiftButton"..Index ] );
	end

	-- Bag buttons
	local LastBag = MainMenuBarBackpackButton;
	me.ActionButtonModify( LastBag );
	for Index = 0, NUM_BAG_SLOTS - 1 do
		LastBag = _G[ "CharacterBag"..Index.."Slot" ];
		me.ActionButtonModify( LastBag );
	end

	-- Keyring
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
