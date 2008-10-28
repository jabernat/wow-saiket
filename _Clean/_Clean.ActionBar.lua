--[[****************************************************************************
  * _Clean by Saiket                                                           *
  * _Clean.ActionBar.lua - Slide the action bars along the corners of the      *
  *   screen so that they still align when the scaling changes. Also, the      *
  *   backgrounds are removed to free more screen real-estate.                 *
  *                                                                            *
  * + Removes spacing between the action button grids.                         *
  * + Shrinks all action bars and makes them slightly transparent.             *
  * + Gets rid of backgrounds on action bars.                                  *
  * + Moves the aura bar to where the cluster of UI panel buttons was, and     *
  *   removes those panel buttons from view.                                   *
  * + Repositions the pet action bar to just below the center of the screen.   *
  * + Only shows the backgrounds of buttons when actions are being dragged.    *
  * + Colors action buttons red when out of range.                             *
  ****************************************************************************]]


local _Clean = _Clean;
local me = {};
_Clean.ActionBar = me;

local ActionBarLeft = CreateFrame( "Frame" );
me.ActionBarLeft = ActionBarLeft;
local ActionBarRight = CreateFrame( "Frame" );
me.ActionBarRight = ActionBarRight;

local BackdropBottomLeft = _Clean.Backdrop.Create( UIParent );
me.BackdropBottomLeft = BackdropBottomLeft;
local BackdropBottomRight = _Clean.Backdrop.Create( UIParent );
me.BackdropBottomRight = BackdropBottomRight;
local BackdropRight = _Clean.Backdrop.Create( UIParent );
me.BackdropRight = BackdropRight;

local Bars = {
	ActionBarLeft,
	ActionBarRight,
	MultiBarBottomLeft,
	MultiBarBottomRight,
	MultiBarLeft,
	MultiBarRight
};
me.Bars = Bars;

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
  * Function: _Clean.ActionBar.ActionBarManager                                *
  * Description: Manages the left and right action bars' positions.            *
  ****************************************************************************]]
function me.ActionBarManager ()
	-- Move the whole UI up to accomodate reputation and experience bars
	local Offset = ( ( ReputationWatchBar:IsShown() or 0 ) + ( MainMenuExpBar:IsShown() or 0 ) ) * _Clean.MainMenuBar.StatusBarHeight;

	_Clean:RunProtectedFunction( function ()
		ActionButton1:ClearAllPoints();
		ActionButton1:SetPoint( "BOTTOMLEFT", UIParent, 0, Offset );

		MainMenuBarBackpackButton:ClearAllPoints();
		MainMenuBarBackpackButton:SetPoint( "BOTTOM", ActionButton1 );
		MainMenuBarBackpackButton:SetPoint( "RIGHT", UIParent );
	end, ActionButton1:IsProtected() or MainMenuBarBackpackButton:IsProtected() );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	local ButtonSize = ActionButton1:GetWidth();
	local BarSize = ButtonSize * NUM_MULTIBAR_BUTTONS;

	-- Make the bars less obtrusive
	MainMenuBarArtFrame:SetAlpha( 0.75 );
	for _, Frame in ipairs( Bars ) do
		Frame:SetAlpha( 0.75 );
	end
	MainMenuBar:SetScale( 0.75 );
	for _, Frame in ipairs( Bars ) do
		Frame:SetScale( 0.75 );
	end


	-- Remove spacing between buttons
	ActionButton1:SetParent( ActionBarLeft );
	for Index = 2, NUM_MULTIBAR_BUTTONS do
		local Last = Index - 1;
		local ActionButton = _G[ "ActionButton"..Index ];
		ActionButton:SetParent( ActionBarLeft );
		ActionButton:SetPoint( "LEFT", "ActionButton"..Last, "RIGHT" );
		_G[ "MultiBarBottomLeftButton"..Index ]:SetPoint( "LEFT", "MultiBarBottomLeftButton"..Last, "RIGHT" );
		_G[ "MultiBarBottomRightButton"..Index ]:SetPoint( "LEFT", "MultiBarBottomRightButton"..Last, "RIGHT" );
		_G[ "MultiBarLeftButton"..Index ]:SetPoint( "TOP", "MultiBarLeftButton"..Last, "BOTTOM" );
		_G[ "MultiBarRightButton"..Index ]:SetPoint( "TOP", "MultiBarRightButton"..Last, "BOTTOM" );
	end
	-- Remove icon borders on buttons
	for Index = 1, NUM_MULTIBAR_BUTTONS do
		me.ActionButtonModify( "ActionButton", Index );
		me.ActionButtonModify( "MultiBarBottomLeftButton", Index );
		me.ActionButtonModify( "MultiBarBottomRightButton", Index );
		me.ActionButtonModify( "MultiBarLeftButton", Index );
		me.ActionButtonModify( "MultiBarRightButton", Index );
	end

	-- Shapeshift bar
	ShapeshiftBarFrame:SetScript( "OnShow", nil ); -- Note: Prevents managed frames handling on SetParent
	ShapeshiftBarFrame:SetScript( "OnHide", nil );
	ShapeshiftBarFrame:SetParent( ActionBarRight );
	ShapeshiftBarFrame:EnableMouse( false );
	ShapeshiftBarFrame:ClearAllPoints();
	ShapeshiftBarFrame:SetPoint( "TOPLEFT", ActionBarRight );
	ShapeshiftBarFrame:SetPoint( "BOTTOM", ActionBarRight );
	ShapeshiftButton1:SetPoint( "LEFT", ShapeshiftBarFrame );
	for Index = NUM_SHAPESHIFT_SLOTS, 1, -1 do
		local Button = _G[ "ShapeshiftButton"..Index ];
		Button:SetWidth( ButtonSize );
		Button:SetHeight( ButtonSize );
		Button:SetScale( 0.75 );
		_Clean.RemoveButtonIconBorder( _G[ "ShapeshiftButton"..Index.."Icon" ] );
		_G[ "ShapeshiftButton"..Index.."NormalTexture" ]:SetTexture();
		if ( Index > 1 ) then
			Button:SetPoint( "LEFT", "ShapeshiftButton"..( Index - 1 ), "RIGHT", 4, 0 );
		end
	end

	-- Bag buttons
	local LastButton = MainMenuBarBackpackButton;
	LastButton:SetParent( ActionBarRight );
	LastButton:SetWidth( ButtonSize );
	LastButton:SetHeight( ButtonSize );
	_Clean.RemoveButtonIconBorder( MainMenuBarBackpackButtonIconTexture );
	MainMenuBarBackpackButtonNormalTexture:SetTexture();
	for Index = 0, NUM_BAG_SLOTS - 1 do
		local Button = _G[ "CharacterBag"..Index.."Slot" ];
		Button:SetParent( ActionBarRight );
		Button:SetPoint( "RIGHT", LastButton, "LEFT" );
		Button:SetWidth( ButtonSize );
		Button:SetHeight( ButtonSize );
		_Clean.RemoveButtonIconBorder( _G[ "CharacterBag"..Index.."SlotIconTexture" ] );
		_G[ "CharacterBag"..Index.."SlotNormalTexture" ]:SetTexture();
		LastButton = Button;
	end
	-- Keyring
	KeyRingButton:ClearAllPoints();
	KeyRingButton:SetPoint( "LEFT", LastButton );
	KeyRingButton:SetParent( LastButton );
	KeyRingButton:SetWidth( 12 );
	KeyRingButton:GetNormalTexture():SetTexCoord( 0.15, 0.45, 0.1, 0.52 );


	-- Resize bar frames
	ActionBarLeft:SetWidth( BarSize );
	ActionBarLeft:SetHeight( ButtonSize );
	ActionBarRight:SetWidth( BarSize );
	ActionBarRight:SetHeight( ButtonSize );
	MultiBarBottomLeft:SetWidth( BarSize );
	MultiBarBottomLeft:SetHeight( ButtonSize );
	MultiBarBottomRight:SetWidth( BarSize );
	MultiBarBottomRight:SetHeight( ButtonSize );
	MultiBarLeft:SetHeight( BarSize );
	MultiBarLeft:SetWidth( ButtonSize );
	MultiBarRight:SetHeight( BarSize );
	MultiBarRight:SetWidth( ButtonSize );

	-- Anchor bars together
	ActionBarLeft:SetPoint( "BOTTOMLEFT", ActionButton1 );
	ActionBarRight:SetPoint( "BOTTOMRIGHT", MainMenuBarBackpackButton );

	MultiBarBottomLeft:ClearAllPoints();
	MultiBarBottomLeft:SetPoint( "BOTTOMLEFT", ActionBarLeft, "TOPLEFT" );

	MultiBarBottomRight:ClearAllPoints();
	MultiBarBottomRight:SetPoint( "BOTTOMRIGHT", ActionBarRight, "TOPRIGHT" );

	MultiBarRight:ClearAllPoints();
	MultiBarRight:SetPoint( "BOTTOMRIGHT", MultiBarBottomRight, "TOPRIGHT" );

	MultiBarLeft:ClearAllPoints();
	MultiBarLeft:SetPoint( "BOTTOMRIGHT", MultiBarRight, "BOTTOMLEFT" );


	-- Add backdrops
	ActionBarLeft:SetParent( BackdropBottomLeft );
	MultiBarBottomLeft:SetParent( BackdropBottomLeft );
	BackdropBottomLeft:SetPoint( "BOTTOMLEFT", ActionBarLeft );
	BackdropBottomLeft:SetPoint( "TOPRIGHT", MultiBarBottomLeft, _Clean.Backdrop.Padding, _Clean.Backdrop.Padding );

	ActionBarRight:SetParent( BackdropBottomRight );
	MultiBarBottomRight:SetParent( BackdropBottomRight );
	BackdropBottomRight:SetPoint( "BOTTOMRIGHT", ActionBarRight );
	BackdropBottomRight:SetPoint( "TOPLEFT", MultiBarBottomRight, -_Clean.Backdrop.Padding, _Clean.Backdrop.Padding );

	MultiBarRight:SetParent( BackdropRight );
	MultiBarLeft:SetParent( BackdropRight );
	BackdropRight:SetPoint( "BOTTOMRIGHT", BackdropBottomRight, "TOPRIGHT" );
	BackdropRight:SetPoint( "TOPLEFT", MultiBarLeftButton4, -_Clean.Backdrop.Padding, _Clean.Backdrop.Padding );


	-- Remove art
	ShapeshiftBarLeft:SetTexture();
	ShapeshiftBarLeft:Hide();
	ShapeshiftBarRight:SetTexture();
	ShapeshiftBarRight:Hide();
	ShapeshiftBarMiddle:SetTexture();
	ShapeshiftBarMiddle:Hide();

	PetActionBarFrame:EnableMouse( false );
	for Index = 0, 1 do
		local Texture = _G[ "SlidingActionBarTexture"..Index ];
		Texture:SetTexture();
		Texture:Hide();
	end


	-- Hooks
	UIPARENT_MANAGED_FRAME_POSITIONS[ "MultiBarBottomLeft" ] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS[ "MultiBarRight" ] = nil;
	UIPARENT_MANAGED_FRAME_POSITIONS[ "ShapeshiftBarFrame" ] = nil;
	hooksecurefunc( "ActionButton_OnUpdate", me.ActionButtonOnUpdate );
	hooksecurefunc( "ActionButton_UpdateUsable", me.ActionButtonUpdateUsable );
	_Clean:AddPositionManager( me.ActionBarManager );

	--NOTE(Temporary hook to catch what moves the bar.)
	hooksecurefunc( MultiBarRight, "SetPoint", function ( self, ... )
		error( "Something moved MultiBarRight!" );
	end );
end
