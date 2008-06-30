--[[****************************************************************************
  * _Nameplates by Saiket                                                      *
  * _Nameplates.lua - Enhances the default nameplate frames and adds an        *
  *   emergency monitor list of nearby friendly/hostile units.                 *
  *                                                                            *
  ****************************************************************************]]


_NameplatesOptions = {
	Friendly = { Locked = false; TextSide = "LEFT";  VerticalSide = "BOTTOM"; };
	Hostile  = { Locked = false; TextSide = "RIGHT"; VerticalSide = "BOTTOM"; };
};


_Nameplates = {
	ShowNameplatesBackup       = ShowNameplates;
	HideNameplatesBackup       = HideNameplates;
	ShowFriendNameplatesBackup = ShowFriendNameplates;
	HideFriendNameplatesBackup = HideFriendNameplates;

	ShowFriendly = FRIENDNAMEPLATES_ON;
	ShowHostile  = NAMEPLATES_ON;

	ChildCount = 0; -- Counts children of WorldFrame, determines when to scan them
	Frames = {}; -- Keys are nameplates, values are buttons


--[[****************************************************************************
  * Function: _Nameplates.ShowNameplates                                       *
  * Description: Shows the hostile nameplate tracking frame and nameplates.    *
  ****************************************************************************]]
ShowNameplates = function ()
	_Nameplates.ShowHostile = 1;
	_Nameplates.UpdateEnabled();
	_Nameplates.ShowNameplatesBackup();
end;
--[[****************************************************************************
  * Function: _Nameplates.HideNameplates                                       *
  * Description: Hides the hostile nameplate tracking frame and nameplates.    *
  ****************************************************************************]]
HideNameplates = function ()
	_Nameplates.ShowHostile = nil;
	_Nameplates.UpdateEnabled();
	_Nameplates.HideNameplatesBackup();
end;
--[[****************************************************************************
  * Function: _Nameplates.ShowFriendNameplates                                 *
  * Description: Shows the friendly nameplate tracking frame and friendly      *
  *   nameplates.                                                              *
  ****************************************************************************]]
ShowFriendNameplates = function ()
	_Nameplates.ShowFriendly = 1;
	_Nameplates.UpdateEnabled();
	_Nameplates.ShowFriendNameplatesBackup();
end;
--[[****************************************************************************
  * Function: _Nameplates.HideFriendNameplates                                 *
  * Description: Hides the friendly nameplate tracking frame and friendly      *
  *   nameplates.                                                              *
  ****************************************************************************]]
HideFriendNameplates = function ()
	_Nameplates.ShowFriendly = nil;
	_Nameplates.UpdateEnabled();
	_Nameplates.HideFriendNameplatesBackup();
end;
--[[****************************************************************************
  * Function: _Nameplates.UpdateEnabled                                        *
  * Description: Shows or hides the nameplate tracking frame if nameplates are *
  *   on or off, and optionally synchronizes settings with the default UI.     *
  ****************************************************************************]]
UpdateEnabled = function ( Synchronize )
	if ( Synchronize ) then
		_Nameplates.ShowFriendly = FRIENDNAMEPLATES_ON;
		_Nameplates.ShowHostile  = NAMEPLATES_ON;
	end

	_Nameplates.Column.Hostile[ _Nameplates.ShowHostile and "Show" or "Hide" ]( _Nameplates.Column.Hostile );
	_Nameplates.Column.Friendly[ _Nameplates.ShowFriendly and "Show" or "Hide" ]( _Nameplates.Column.Friendly );

	_NameplatesFrame[ ( _Nameplates.ShowHostile or _Nameplates.ShowFriendly ) and "Show" or "Hide" ]( _NameplatesFrame );
end;


--[[****************************************************************************
  * Function: _Nameplates.OnUpdate                                             *
  * Description: Monitors children of WorldFrame to initialize new nameplates, *
  *   updates visible buttons to match their nameplates, and sorts them into   *
  *   the Friendly/Other columns.                                              *
  ****************************************************************************]]
OnUpdate = function ()
	NewChildCount = WorldFrame:GetNumChildren();
	if ( NewChildCount > _Nameplates.ChildCount ) then -- A frame was added
		_Nameplates.ChildCount = NewChildCount;

		for _, Frame in ipairs( { WorldFrame:GetChildren() } ) do
			_Nameplates.Nameplate.Initialize( Frame );
		end
	end

	for Nameplate, Button in pairs( _Nameplates.Frames ) do
		if ( Nameplate:IsShown() ) then
			_Nameplates.Button.Update( Button );
			_Nameplates.Nameplate.Update( Nameplate );
		else
			_Nameplates.Column.RemoveButton( Button );
		end
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.OnEvent                                              *
  * Description: Synchronizes nameplate settings on variables loaded.          *
  ****************************************************************************]]
OnEvent = function ()
	if ( event == "VARIABLES_LOADED" ) then
		_Nameplates.UpdateEnabled( true ); -- Synchronize
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.OnLoad                                               *
  * Description: Function hooks and event registers.                           *
  ****************************************************************************]]
OnLoad = function ()
	-- Hook the nameplate show/hide functions
	ShowNameplates       = _Nameplates.ShowNameplates;
	HideNameplates       = _Nameplates.HideNameplates;
	ShowFriendNameplates = _Nameplates.ShowFriendNameplates;
	HideFriendNameplates = _Nameplates.HideFriendNameplates;

	_Nameplates.Nameplate.Font:SetFont( NAMEPLATE_FONT, 10 );

	-- Calculate colors for button text based on nameplate bar color
	for Index, Color in ipairs( _Nameplates.Nameplate.Colors ) do
		_Nameplates.Button.TextColors[ Index ]          = { r = 1 - ( 1 - Color.r ) / 2; g = 1 - ( 1 - Color.g ) / 2; b = 1 - ( 1 - Color.b ) / 2; };
		_Nameplates.Button.TextHighlightColors[ Index ] = { r = 1 - ( 1 - Color.r ) / 3; g = 1 - ( 1 - Color.g ) / 3; b = 1 - ( 1 - Color.b ) / 3; };
	end

	_Nameplates.UpdateEnabled( true ); -- Synchronize
	this:RegisterEvent( "VARIABLES_LOADED" );
end;




--------------------------------------------------------------------------------
-- _Nameplates.Nameplate
------------------------

	Nameplate = {
		Font = CreateFont( "_NameplatesNameplateFont" ); -- Set up in _Nameplates.OnLoad
		Colors = { -- Used only to calculate colors for button text
			{ r = 0, g = 0, b = 1 }, -- Blue
			{ r = 0, g = 1, b = 0 }, -- Green
			{ r = 1, g = 1, b = 0 }, -- Yellow
			{ r = 1, g = 0, b = 0 }  -- Red
		};

--[[****************************************************************************
  * Function: _Nameplates.Nameplate.Initialize                                 *
  * Description: Takes a potential nameplate frame and initializes it if       *
  *   recognized. Child frames and regions are identified, and a button is     *
  *   created to complement the nameplate in the nearby units list.            *
  ****************************************************************************]]
Initialize = function ( Nameplate )
	if ( Nameplate:GetObjectType() ~= "Button" or Nameplate:GetName() or _Nameplates.Frames[ Nameplate ] ) then
		return;
	end
	local Name, Level, Bar, Icon, Border, Glow;

	-- Search the frame for its components
	for _, Region in ipairs( { Nameplate:GetRegions() } ) do
		local Type = Region:GetObjectType();
		if ( Type == "FontString" ) then
			local Point, _, RelativePoint = Region:GetPoint();
			if ( Point == "BOTTOM" and RelativePoint == "CENTER" ) then
				Name = Region;
			elseif ( Point == "CENTER" and RelativePoint == "BOTTOMRIGHT" ) then
				Level = Region;
			end
		elseif ( Type == "Texture" ) then
			local Path = Region:GetTexture();
			if ( Path == "Interface\\TargetingFrame\\UI-RaidTargetingIcons" ) then
				Icon = Region;
			elseif ( Path == "Interface\\Tooltips\\Nameplate-Border" ) then
				Border = Region;
			elseif ( Path == "Interface\\Tooltips\\Nameplate-Glow" ) then
				Glow = Region;
			end
		end
	end
	for _, Frame in ipairs( { Nameplate:GetChildren() } ) do
		if ( Frame:GetObjectType() == "StatusBar" ) then
			Bar = Frame;
		end
	end

	if ( Name and Level and Bar and Border and Glow ) then -- Valid nameplate
		Nameplate.Name = Name;
		Nameplate.Level = Level;
		Nameplate.Bar = Bar;
		Nameplate.Icon = Icon;

		-- Set up the new button
		local Button = CreateFrame( "Button", nil, UIParent, "_NameplatesButtonTemplate" );
		Button.Nameplate = Nameplate;
		_Nameplates.Frames[ Nameplate ] = Button;

		-- Modify the nameplate
		Nameplate:SetScript( "OnEnter", _Nameplates.Nameplate.OnEnter );
		Nameplate:SetScript( "OnLeave", _Nameplates.Nameplate.OnLeave );
		-- Adjust the name and icon
		Name:SetAllPoints( Bar );
		Name:SetFontObject( _Nameplates.Nameplate.Font );
		Icon:SetWidth( 14 );
		Icon:SetHeight( 14 );
		-- Fix the border and outline textures
		local TopCoord = 16 / Nameplate:GetHeight();
		local Highlight = Nameplate:CreateTexture( nil, "OVERLAY" );
		Highlight:SetAllPoints( Nameplate );
		Highlight:SetTexture( Glow:GetTexture() );
		Highlight:SetBlendMode( "ADD" );
		Highlight:SetTexCoord( 0, 1, TopCoord, 1 );
		Nameplate:SetHighlightTexture( Highlight );
		Border:SetTexCoord( 0, 1, TopCoord, 1 );
		Border:SetVertexColor( 1, 1, 1, 0.2 );
		Glow:SetTexture( nil ); -- Replaced by the highlight
		return true;
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Nameplate.GetColor                                   *
  * Description: Returns a color index that represents the nameplate's color,  *
  *   which should be used as an index in other color tables.                  *
  ****************************************************************************]]
GetColor = function ( Nameplate )
	local R, G, B = Nameplate.Bar:GetStatusBarColor();
	R, G, B = R > 0.9, G > 0.9, B > 0.9;

	if ( G ) then
		return R and 3 or 2; -- Yellow or green
	elseif ( B ) then
		return 1; -- Blue
	elseif ( R ) then
		return 4; -- Red
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Nameplate.Update                                     *
  * Description: Refreshes visual settings for the nameplate.                  *
  ****************************************************************************]]
Update = function ( Nameplate )
	Nameplate:SetHeight( 14 );
	Nameplate:EnableMouse( false );
	Nameplate.Bar:SetAlpha( 0.75 );
	Nameplate.Name:SetAlpha( 0.75 );
	Nameplate.Level:SetAlpha( 0.5 );
end;

--[[****************************************************************************
  * Function: _Nameplates.Nameplate.OnLeave                                    *
  * Description: Unhighlights the nameplate's representative button.           *
  ****************************************************************************]]
OnLeave = function ()
	_Nameplates.Frames[ this ]:UnlockHighlight();
end;
--[[****************************************************************************
  * Function: _Nameplates.Nameplate.OnEnter                                    *
  * Description: Highlights the nameplate's representative button.             *
  ****************************************************************************]]
OnEnter = function ()
	_Nameplates.Frames[ this ]:LockHighlight();
end;

	}; -- End _Nameplates.Nameplate




--------------------------------------------------------------------------------
-- _Nameplates.Button
---------------------

	Button = {
		Count = 0;
		TextColors = {}; -- Calculated in _Nameplates.OnLoad
		TextHighlightColors = {};

--[[****************************************************************************
  * Function: _Nameplates.Button.SetTextSide                                   *
  * Description: Aligns the button text to the specified side.                 *
  ****************************************************************************]]
SetTextSide = function ( Button, Side )
	local Point = Side == "LEFT" and "RIGHT" or "LEFT";
	local FontString = Button:GetFontString();

	FontString:ClearAllPoints();
	FontString:SetPoint( Point, Button, Side );
end;
--[[****************************************************************************
  * Function: _Nameplates.Button.Update                                        *
  * Description: Synchronizes the button's data with its nameplate.            *
  ****************************************************************************]]
Update = function ( Button )
	local ColorIndex = _Nameplates.Nameplate.GetColor( Button.Nameplate );
	local Color = _Nameplates.Button.TextColors[ ColorIndex ];
	Button:SetTextColor( Color.r, Color.g, Color.b );
	Color = _Nameplates.Button.TextHighlightColors[ ColorIndex ];
	Button:SetHighlightTextColor( Color.r, Color.g, Color.b );
	_Nameplates.Column.AddButton( Button, _Nameplates.Column[ ColorIndex == 4 and "Hostile" or "Friendly" ] );

	Button:SetText( Button.Nameplate.Name:GetText() );
	Button:SetAlpha( Button.Nameplate:GetAlpha() );
	if ( Button.Nameplate.Icon:IsShown() ) then
		Button.Icon:SetTexCoord( Button.Nameplate.Icon:GetTexCoord() );
		Button.Icon:Show();
	else
		Button.Icon:Hide();
	end

	Button.Bar:SetMinMaxValues( Button.Nameplate.Bar:GetMinMaxValues() );
	Button.Bar:SetValue( Button.Nameplate.Bar:GetValue() );
end;

--[[****************************************************************************
  * Function: _Nameplates.Button.OnLeave                                       *
  * Description: Unhighlights the button's nameplate.                          *
  ****************************************************************************]]
OnLeave = function ()
	_NameplatesHighlight:ClearAllPoints();
	_NameplatesHighlight:Hide();
	this.Nameplate:UnlockHighlight();
end;
--[[****************************************************************************
  * Function: _Nameplates.Button.OnEnter                                       *
  * Description: Highlights the button's nameplate.                            *
  ****************************************************************************]]
OnEnter = function ()
	_NameplatesHighlight:SetAllPoints( this.Nameplate );
	_NameplatesHighlight:Show();
	this.Nameplate:LockHighlight();
end;
--[[****************************************************************************
  * Function: _Nameplates.Button.OnClick                                       *
  * Description: Emulates clicking the button's nameplates.                    *
  ****************************************************************************]]
OnClick = function ()
	this.Nameplate:Click();
end;
--[[****************************************************************************
  * Function: _Nameplates.Button.OnLoad                                        *
  * Description: Initializes the button's components and assigns it a unique   *
  *   ID for sorting.                                                          *
  ****************************************************************************]]
OnLoad = function ()
	for _, Region in ipairs( { this:GetRegions() } ) do
		if ( Region:GetObjectType() == "Texture" and Region:GetTexture() == "Interface\\TargetingFrame\\UI-RaidTargetingIcons" ) then
			this.Icon = Region;
			break;
		end
	end
	this.Icon:SetAlpha( 0.75 );
	this:GetHighlightTexture():SetAlpha( 0.5 );
	_Nameplates.Button.Count = _Nameplates.Button.Count + 1;
	this:SetID( _Nameplates.Button.Count );
end;


--------------------------------------------------------------------------------
-- _Nameplates.Button.Bar
-------------------------

		Bar = {

--[[****************************************************************************
  * Function: _Nameplates.Button.Bar.OnValueChanged                            *
  * Description: Update the bar's text and color.                              *
  ****************************************************************************]]
OnValueChanged = function ()
	local _, Max = this:GetMinMaxValues();
	local Value = this:GetValue() / Max;
	this:SetStatusBarColor(
		Value > 0.5 and ( 1 - Value ) * 2 or 1,
		Value <= 0.5 and Value * 2 or 1,
		0 );
	Value = math.floor( Value * 100 + 0.5 );
	this.Label:SetText( Value );
	this:GetParent().Value = Value;
end;
--[[****************************************************************************
  * Function: _Nameplates.Button.Bar.OnLoad                                    *
  * Description: Initialize the status bar and its regions.                    *
  ****************************************************************************]]
OnLoad = function ()
	local Parent = this:GetParent();
	Parent.Bar = this;
	this:SetFrameLevel( Parent:GetFrameLevel() - 1 );
	this:SetBackdropColor( 0, 0, 0, 0.25 );
	for _, Region in ipairs( { this:GetRegions() } ) do
		if ( Region:GetObjectType() == "FontString" ) then
			this.Label = Region;
			break;
		end
	end
end;

		}; -- End _Nameplates.Button.Bar

	}; -- End _Nameplates.Button




--------------------------------------------------------------------------------
-- _Nameplates.Column
---------------------

	Column = {
		MaxButtons = 8;
		TooltipAnchorPoints = {
			[ "TOP" ] = {
				[ "LEFT" ]  = "ANCHOR_BOTTOMLEFT";
				[ "RIGHT" ] = "ANCHOR_BOTTOMRIGHT";
			};
			[ "BOTTOM" ] = {
				[ "LEFT" ]  = "ANCHOR_TOPRIGHT";
				[ "RIGHT" ] = "ANCHOR_TOPLEFT";
			}
		};
		VerticalAnchorPoints = {
			[ "TOP" ]    = { "BOTTOM", "TOP" };
			[ "BOTTOM" ] = { "TOP", "BOTTOM" };
		};
		BindingNames = {
			[ "Hostile" ]  = "NAMEPLATES";
			[ "Friendly" ] = "FRIENDNAMEPLATES";
		};

--[[****************************************************************************
  * Function: _Nameplates.Column.TableSort                                     *
  * Description: Comparison function used by table.sort to organize buttons.   *
  *   They are sorted by Health Percentage, if there is a raid target on the   *
  *   unit, the units' names, and by button ID.                                *
  ****************************************************************************]]
TableSort = function ( Button1, Button2 )
	if ( Button1.Value < Button2.Value ) then -- Sort by health percentage first
		return true;
	elseif ( Button1.Value == Button2.Value ) then -- If they match, place raid targets on top
		local Icon1, Icon2 = Button1.Icon:IsShown(), Button2.Icon:IsShown();
		if ( not ( Icon1 and Icon2 ) and ( Icon1 or Icon2 ) ) then
			return Icon1;
		else -- No icon or both have icons
			local Text1, Text2 = string.lower( Button1:GetText() ), string.lower( Button2:GetText() );
			if ( Text1 < Text2 or ( Text1 == Text2 and Button1:GetID() < Button2:GetID() ) ) then -- Sort alphabetically and then by button ID
				return true;
			end
		end
	end
end;

--[[****************************************************************************
  * Function: _Nameplates.Column.UpdateSettings                                *
  * Description: Synchronizes the column with present settings.                *
  ****************************************************************************]]
UpdateSettings = function ( Column )
	_Nameplates.Column.SetTextSide( Column, _NameplatesOptions[ Column.Type ].TextSide );
	_Nameplates.Column.SetVerticalSide( Column, _NameplatesOptions[ Column.Type ].VerticalSide );
	_Nameplates.Column.SetLocked( Column, _NameplatesOptions[ Column.Type ].Locked );
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.UpdateTooltip                                 *
  * Description: Arranges the tooltip with a description of how the user can   *
  *   interact with the column.                                                *
  ****************************************************************************]]
UpdateTooltip = function ( Column )
	if ( GameTooltip:IsOwned( Column ) ) then
		local Options = _NameplatesOptions[ Column.Type ];
		local Key = GetBindingKey( _Nameplates.Column.BindingNames[ Column.Type ] );
		local Anchor = _Nameplates.Column.TooltipAnchorPoints[ Options.VerticalSide ][ Options.TextSide ];

		if ( GameTooltip:GetAnchorType() ~= Anchor ) then
			GameTooltip:SetOwner( Column, Anchor );
		end
		GameTooltip:ClearLines();
		GameTooltip:SetText( string.format( _NAMEPLATES_COLUMN_TOOLTIP_TITLE_FORMAT,
			_NAMEPLATES_COLUMN_TITLES[ Column.Type ],
			Key and string.format( _NAMEPLATES_BINDING_FORMAT, GetBindingText( Key, "KEY_" ) ) or "" ) );
		GameTooltip:AddLine( Options.Locked and _NAMEPLATES_COLUMN_TOOLTIP_LOCKED or _NAMEPLATES_COLUMN_TOOLTIP_UNLOCKED,
			GRAY_FONT_COLOR.r, GRAY_FONT_COLOR.g, GRAY_FONT_COLOR.b, 1 );
		GameTooltip:Show();
	end
end;

--[[****************************************************************************
  * Function: _Nameplates.Column.SetTextSide                                   *
  * Description: Moves nameplate button text to a side of the column.          *
  ****************************************************************************]]
SetTextSide = function ( Column, Side )
	if ( _NameplatesOptions[ Column.Type ].TextSide ~= Side ) then
		_NameplatesOptions[ Column.Type ].TextSide = Side;

		for _, Button in ipairs( Column.Buttons ) do
			_Nameplates.Button.SetTextSide( Button, Side );
		end
		_Nameplates.Column.UpdateTooltip( Column );
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.SetVerticalSide                               *
  * Description: Sets the direction that the column should grow towards.       *
  ****************************************************************************]]
SetVerticalSide = function ( Column, Side )
	if ( _NameplatesOptions[ Column.Type ].VerticalSide ~= Side ) then
		_NameplatesOptions[ Column.Type ].VerticalSide = Side;

		_Nameplates.Column.UpdateTooltip( Column );
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.SetLocked                                     *
  * Description: Locks or unlocks the position of the column.                  *
  ****************************************************************************]]
SetLocked = function ( Column, Locked )
	_NameplatesOptions[ Column.Type ].Locked = Locked;

	if ( Locked ) then
		Column:SetAlpha( 0.5 );
		Column:RegisterForDrag();
		Column:RegisterForClicks( "RightButtonUp" );
	else
		Column:SetAlpha( 1 );
		Column:RegisterForDrag( "LeftButton" );
		Column:RegisterForClicks( "RightButtonUp", "LeftButtonDown", "LeftButtonUp" );
	end
	_Nameplates.Column.UpdateTooltip( Column );
end;

--[[****************************************************************************
  * Function: _Nameplates.Column.RemoveButton                                  *
  * Description: Removes the given button from the column.                     *
  ****************************************************************************]]
RemoveButton = function ( Button )
	if ( Button.Column ) then
		for Index in ipairs( Button.Column.Buttons ) do
			if ( Button.Column.Buttons[ Index ] == Button ) then
				table.remove( Button.Column.Buttons, Index );
				break;
			end
		end
		Button.Column = nil;
		Button:Hide();
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.AddButton                                     *
  * Description: Adds the given button to the column.                          *
  ****************************************************************************]]
AddButton = function ( Button, Column )
	if ( Button.Column ~= Column ) then
		_Nameplates.Column.RemoveButton( Button );
		Button.Column = Column;
		_Nameplates.Button.SetTextSide( Button, _NameplatesOptions[ Column.Type ].TextSide );
		table.insert( Column.Buttons, Button );
	end
end;

--[[****************************************************************************
  * Function: _Nameplates.Column.OnLeave                                       *
  * Description: Hides the tooltip.                                            *
  ****************************************************************************]]
OnLeave = function ()
	GameTooltip:Hide();
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnEnter                                       *
  * Description: Shows the tooltip.                                            *
  ****************************************************************************]]
OnEnter = function ()
	GameTooltip:SetOwner( this, "ANCHOR_NONE" );
	_Nameplates.Column.UpdateTooltip( this );
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnDragStop                                    *
  * Description: Stops dragging.                                               *
  ****************************************************************************]]
OnDragStop = function ()
	this:StopMovingOrSizing();
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnDragStart                                   *
  * Description: Starts dragging.                                              *
  ****************************************************************************]]
OnDragStart = function ()
	this:StartMoving();
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnDoubleClick                                 *
  * Description: Switches the text side.                                       *
  ****************************************************************************]]
OnDoubleClick = function ()
	if ( arg1 == "LeftButton" ) then
		local Options = _NameplatesOptions[ this.Type ];
		if ( IsShiftKeyDown() ) then
			_Nameplates.Column.SetVerticalSide( this, Options.VerticalSide == "BOTTOM" and "TOP" or "BOTTOM" );
		else
			_Nameplates.Column.SetTextSide( this, Options.TextSide == "LEFT" and "RIGHT" or "LEFT" );
		end
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnClick                                       *
  * Description: Toggles locked mode.                                          *
  ****************************************************************************]]
OnClick = function ()
	if ( arg1 == "RightButton" ) then
		_Nameplates.Column.SetLocked( this, not _NameplatesOptions[ this.Type ].Locked );
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnUpdate                                      *
  * Description: Arranges the buttons in the column.                           *
  ****************************************************************************]]
OnUpdate = function ()
	table.sort( this.Buttons, _Nameplates.Column.TableSort );
	local ButtonCount = table.getn( this.Buttons );
	local Points = _Nameplates.Column.VerticalAnchorPoints[ _NameplatesOptions[ this.Type ].VerticalSide ];

	for Index = 1, math.min( _Nameplates.Column.MaxButtons, ButtonCount ) do
		this.Buttons[ Index ]:ClearAllPoints();
		this.Buttons[ Index ]:SetPoint( Points[ 1 ], this.Buttons[ Index - 1 ] or this, Points[ 2 ] );
		this.Buttons[ Index ]:Show();
	end
	for Index = _Nameplates.Column.MaxButtons + 1, ButtonCount do
		this.Buttons[ Index ]:Hide();
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnEvent                                       *
  * Description: Reinitialize the column with saved settings.                  *
  ****************************************************************************]]
OnEvent = function ()
	if ( event == "UPDATE_BINDINGS" ) then
		_Nameplates.Column.UpdateTooltip( this );
	elseif ( event == "VARIABLES_LOADED" ) then
		_Nameplates.Column.UpdateSettings( this );
	end
end;
--[[****************************************************************************
  * Function: _Nameplates.Column.OnLoad                                        *
  * Description: Initializes a column frame.                                   *
  ****************************************************************************]]
OnLoad = function ()
	this.Buttons = {};
	_, _, this.Type = string.find( this:GetName(), "^_NameplatesColumn(.+)$" );

	this:SetText( string.format( _NAMEPLATES_COLUMN_LABEL_FORMAT, _NAMEPLATES_COLUMN_TITLES[ this.Type ] ) );
	_Nameplates.Column[ this.Type ] = this;
	_Nameplates.Column.UpdateSettings( this );
	this:RegisterEvent( "UPDATE_BINDINGS" );
	this:RegisterEvent( "VARIABLES_LOADED" );
end;

	}; -- End _Nameplates.Column


}; -- End _Nameplates




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

-- Temporary hack to fix a bug with the default UI
function UpdateNameplates ()
	if ( NAMEPLATES_ON ) then
		ShowNameplates();
	else
		HideNameplates();
	end
	if ( FRIENDNAMEPLATES_ON ) then
		ShowFriendNameplates();
	else
		HideFriendNameplates();
	end
end
