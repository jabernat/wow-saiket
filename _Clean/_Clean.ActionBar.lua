--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.ActionBar.lua - Modifies the action bars and their buttons.         *
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
	local Modified = {};
	function me:ActionButtonModify ()
		if ( not Modified[ self ] ) then
			Modified[ self ] = true;

			local NormalTexture = self:GetNormalTexture();
			NormalTexture:SetAllPoints( self );
			NormalTexture:SetAlpha( 1.0 );
			_Clean.RemoveButtonIconBorder( self:GetRegions() ); -- Note: Icon texture must be first!
			self:SetNormalTexture( me.ButtonNormalTexture );
			hooksecurefunc( self, "SetNormalTexture", SetNormalTexture );
			return true;
		end
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
	local NilFunction = _Dev and _Dev.NilFunction or function () end;

	local OldProfile = Dominos.db:GetCurrentProfile();
	if ( OldProfile ~= me.DominosProfile ) then
		-- Create _Clean bar profile if necessary
		if ( Dominos:MatchProfile( me.DominosProfile ) ) then
			Dominos:SetProfile( me.DominosProfile );
		else
			Dominos:ResetProfile();
			-- Configure new profile
			Dominos:SetShowMinimap( false );
			Dominos:SetSticky( true );

			local function InitializeBar ( Bar, AnchorString, Point, Scale, VariableButtons, Spacing, Padding )
				Bar = type( Bar ) == "table" and Bar or Dominos.Frame:Get( Bar );
				Bar.sets.anchor = AnchorString;
				if ( Point ) then
					Bar:SetFramePoint( Point );
				else
					Bar:SavePosition();
				end
				Bar.sets.scale = Scale or 0.75; -- Note: Must occur after SavePosition call.
				Bar.Layout = NilFunction; -- Prevent full updates on each call
				if ( not VariableButtons ) then
					Bar:SetNumButtons( NUM_ACTIONBAR_BUTTONS );
				end
				Bar:SetSpacing( Spacing or 0 );
				Bar:SetPadding( Padding or 0 );
				Bar.Layout = nil; -- Remove override
				Bar:ShowFrame();
				return Bar;
			end

			-- Left corner
			InitializeBar( 1, nil, "BOTTOMLEFT" ); -- Main action bar
			InitializeBar( 6, "1TL" ); -- MultiBarBottomLeft

			-- Right corner
			InitializeBar( "bags", nil, "BOTTOMRIGHT", 0.9, true ):SetShowKeyring( false ); -- Bags
			InitializeBar( 5, "bagsTR" ); -- MultiBarBottomRight
			InitializeBar( Dominos.Frame:Get( "class" ) or Dominos.ClassBar:New(), "5BL", nil, 0.65, true, 8, 6 ); -- Class bar
			InitializeBar( 3, "5TR" ):SetColumns( 1 ); -- MultiBarRight
			InitializeBar( 4, "3LB" ):SetColumns( 1 ); -- MultiBarLeft

			InitializeBar( "pet", nil, "CENTER", 1.5, true, 6 ); -- Pet bar (temporary position)

			-- Hide unused bars
			Dominos.Frame:Get( 2 ):HideFrame();
			for Index = 7, Dominos:NumBars() do
				Dominos.Frame:Get( Index ):HideFrame();
			end
			Dominos.Frame:Get( "menu" ):HideFrame();
			Dominos.Frame:Get( "vehicle" ):HideFrame();

			Dominos:SaveProfile( me.DominosProfile );
		end
		if ( OldProfile == UnitClass( "player" ) ) then -- Default created on initialization
			Dominos:DeleteProfile( OldProfile );
		end
	end

	-- Skin Dominos' "class" buttons
	local ClassBar = Dominos.Frame:Get( "class" );
	if ( ClassBar ) then
		for _, Button in ipairs( ClassBar.buttons ) do
			me.ActionButtonModify( Button );
		end
	end
	hooksecurefunc( Dominos.ClassBar, "AddButton", function ( self, ID )
		me.ActionButtonModify( _G[ "DominosClassButton"..ID ] );
	end );

	-- Add backdrops
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

	-- Move pet bar to middle of screen
	local PetBar = Dominos.Frame:Get( "pet" );
	PetBar:SetFramePoint( "BOTTOM", UIParent, 0, Backdrop:GetTop() * Backdrop:GetEffectiveScale() / PetBar:GetEffectiveScale() );

	-- Prevent any profile changes in Dominos
	Dominos.SaveProfile = NilFunction;
	Dominos.SetProfile = NilFunction;
	Dominos.DeleteProfile = NilFunction;
	Dominos.CopyProfile = NilFunction;
	Dominos.ResetProfile = NilFunction;
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
