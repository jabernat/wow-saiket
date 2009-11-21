--[[****************************************************************************
  * _Clean.ActionBars by Saiket                                                *
  * _Clean.ActionBars.lua - Modifies the action bars and their buttons.        *
  ****************************************************************************]]


local _Clean = _Clean;
local me = CreateFrame( "Frame" );
_Clean.ActionBars = me;

me.BackdropBottomLeft = _Clean.Backdrop.Create( UIParent );
me.BackdropBottomRight = _Clean.Backdrop.Create( UIParent );
me.BackdropRight = _Clean.Backdrop.Create( UIParent );

me.DominosProfile = "_Clean";

me.ButtonNormalTexture = [[Interface\AddOns\_Clean.ActionBars\Skin\ButtonNormalTexture]];




--[[****************************************************************************
  * Function: local ActionButtonModify                                         *
  * Description: Modifies textures on an action button.                        *
  ****************************************************************************]]
local ActionButtonModify;
do
	local RotateTexture;
	do
		local Root2, Angle45 = 2 ^ 0.5, math.pi / 4;
		local cos, sin = math.cos, math.sin;
		local function CalculateCorner ( Angle )
			return 0.5 + cos( Angle ) / Root2, 0.5 + sin( Angle ) / Root2;
		end
		RotateTexture = function ( self, Angle )
			local LRx, LRy = CalculateCorner( Angle + Angle45 );
			local LLx, LLy = CalculateCorner( Angle + Angle45 * 3 );
			local ULx, ULy = CalculateCorner( Angle - Angle45 * 3 );
			local URx, URy = CalculateCorner( Angle - Angle45 );
			
			self:SetTexCoord( ULx, ULy, LLx, LLy, URx, URy, LRx, LRy );
		end
	end
	local Disabled = false;
	local function SetNormalTexture ( self, Texture )
		if ( not Disabled and type( Texture ) == "string" ) then
			if ( Texture:lower() == [[Interface\Buttons\UI-Quickslot]] ) then
				-- Empty button texture
				self:GetNormalTexture():SetTexCoord( 0.2, 0.8, 0.2, 0.8 );
			else
				RotateTexture( self:GetNormalTexture(), self.Angle );
				Disabled = true;
				self:SetNormalTexture( me.ButtonNormalTexture );
				Disabled = false;
			end
		end
	end
	function ActionButtonModify ( self, Angle )
		if ( not self.Angle ) then
			self.Angle = Angle;

			local NormalTexture = self:GetNormalTexture();
			NormalTexture:SetAllPoints( self );
			NormalTexture:SetAlpha( 1.0 );
			_Clean.RemoveIconBorder( self:GetRegions() ); -- Note: Icon texture must be first!
			hooksecurefunc( self, "SetNormalTexture", SetNormalTexture );
			SetNormalTexture( self, "" ); -- Set texture and angle
			return true;
		end
	end
end




--[[****************************************************************************
  * Function: _Clean.ActionBar:PLAYER_LOGIN                                    *
  * Description: Positions parts of the UI around bars once they are created.  *
  ****************************************************************************]]
function me:PLAYER_LOGIN ()
	me.PLAYER_LOGIN = nil;

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
				Bar.Layout = _Clean.NilFunction; -- Prevent full updates on each call
				if ( not VariableButtons ) then
					Bar:SetNumButtons( NUM_ACTIONBAR_BUTTONS );
				end
				Bar:SetSpacing( Spacing or 0 );
				Bar:SetPadding( Padding or 0 );
				Bar.Layout = nil; -- Remove override
				Bar:SetFrameAlpha( 0.8 );
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
			ActionButtonModify( Button, math.pi );
		end
	end
	hooksecurefunc( Dominos.ClassBar, "AddButton", function ( self, ID )
		ActionButtonModify( _G[ "DominosClassButton"..ID ], math.pi );
	end );

	-- Add backdrops
	local Padding = _Clean.Backdrop.Padding;
	local Backdrop = _Clean.ActionBars.BackdropBottomLeft;
	Backdrop:SetPoint( "BOTTOMLEFT", Dominos.Frame:Get( 1 ) );
	Backdrop:SetPoint( "TOPRIGHT", Dominos.Frame:Get( 6 ), Padding, Padding );

	Backdrop = _Clean.ActionBars.BackdropBottomRight;
	Backdrop:SetPoint( "BOTTOMRIGHT", Dominos.Frame:Get( "bags" ) );
	Backdrop:SetPoint( "TOPLEFT", Dominos.Frame:Get( 5 ), -Padding, Padding );

	Backdrop = _Clean.ActionBars.BackdropRight;
	Backdrop:SetPoint( "BOTTOMRIGHT", _Clean.ActionBars.BackdropBottomRight, "TOPRIGHT" );
	Backdrop:SetPoint( "TOPLEFT", MultiBarLeftButton4, -Padding, Padding );

	-- Adjust bottom pane to match bar positions
	_Clean.BottomPane:SetPoint( "TOP", Backdrop, 0, -16.5 - Padding ); -- Room for chat tabs between pane and top of backdrop
	_Clean.BottomPane:SetPoint( "BOTTOM", Backdrop );

	-- Move pet bar to middle of screen
	local PetBar = Dominos.Frame:Get( "pet" );
	PetBar:SetFramePoint( "BOTTOM", UIParent, 0, Backdrop:GetTop() * Backdrop:GetEffectiveScale() / PetBar:GetEffectiveScale() );

	-- Prevent any profile changes in Dominos
	Dominos.SaveProfile = _Clean.NilFunction;
	Dominos.SetProfile = _Clean.NilFunction;
	Dominos.DeleteProfile = _Clean.NilFunction;
	Dominos.CopyProfile = _Clean.NilFunction;
	Dominos.ResetProfile = _Clean.NilFunction;
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me:SetScript( "OnEvent", _Clean.OnEvent );
	me:RegisterEvent( "PLAYER_LOGIN" );

	-- Remove icon borders on buttons
	for Index = 1, NUM_MULTIBAR_BUTTONS do
		ActionButtonModify( _G[ "ActionButton"..Index ], math.pi );
		ActionButtonModify( _G[ "MultiBarBottomLeftButton"..Index ], 0 );
		ActionButtonModify( _G[ "MultiBarBottomRightButton"..Index ], 0 );
		ActionButtonModify( _G[ "MultiBarLeftButton"..Index ], math.pi / 2 );
		ActionButtonModify( _G[ "MultiBarRightButton"..Index ], -math.pi / 2 );
	end

	-- Shapeshift bar (These get replaced by Dominos later)
	for Index = 1, NUM_SHAPESHIFT_SLOTS do
		ActionButtonModify( _G[ "ShapeshiftButton"..Index ], math.pi );
	end

	-- Bag buttons
	local LastBag = MainMenuBarBackpackButton;
	ActionButtonModify( LastBag, math.pi );
	for Index = 0, NUM_BAG_SLOTS - 1 do
		LastBag = _G[ "CharacterBag"..Index.."Slot" ];
		ActionButtonModify( LastBag, math.pi );
	end

	-- Keyring
	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint( "TOPLEFT", LastBag );
	KeyRingButton:SetPoint( "BOTTOM", LastBag );
	KeyRingButton:SetParent( LastBag );
	KeyRingButton:SetWidth( 8 );
	KeyRingButton:GetNormalTexture():SetTexCoord( 0.15, 0.45, 0.1, 0.52 );
	KeyRingButton:Show();

	-- Add a button for the help window to the main menu
	local Button = CreateFrame( "Button", nil, GameMenuFrame, "MainMenuBarMicroButton" );
	Button:SetPoint( "TOPRIGHT", -50, 28 );
	Button:SetScale( 0.7 );
	Button:SetFrameLevel( Button:GetFrameLevel() + 1 ); -- Raise above other buttons in the menu
	Button:SetScript( "OnClick", ToggleHelpFrame );
	LoadMicroButtonTextures( Button, "Help" );
	Button.tooltipText = HelpMicroButton.tooltipText;
	Button.newbieText = HelpMicroButton.newbieText;
end
