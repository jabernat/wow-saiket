--[[****************************************************************************
  * _DevPad.GUI by Saiket                                                      *
  * _DevPad.GUI.Editor.Color.lua - Adds text color selection to the editor.    *
  ****************************************************************************]]


local _DevPad, GUI = _DevPad, select( 2, ... );

local NS = {};
GUI.Editor.Color = NS;

NS.ButtonContainer = CreateFrame( "Frame", nil, GUI.Editor );
NS.Swatch = CreateFrame( "Button", nil, NS.ButtonContainer );
NS.Dropper = GUI.Editor:NewButton( [[Interface\AddOns\]]..( ... )..[[\Skin\ColorDropper]] );
NS.Dropdown = CreateFrame( "Frame", nil, NS.Swatch );
NS.Dropdown.Custom = CreateFrame( "Button", nil, NS.Dropdown, "UIPanelButtonTemplate" );




do
	-- Hides or shows the title button when enabled or disabled.
	local function UpdateEnabled ( self )
		if ( self.Enabled ) then
			self.ButtonContainer:Show();
		else
			self.ButtonContainer:Hide();
		end
	end
	--- Enables coloring only when Lua mode is disabled.
	function NS:ScriptSetLua ( _, Script )
		if ( Script == self.Script ) then
			self.Enabled = not Script._Lua;
			UpdateEnabled( self );
		end
	end
	--- Updates the color button's visibility when changing scripts.
	function NS:EditorSetScriptObject ( _, Script )
		self.Script = Script;
		if ( Script ) then
			_DevPad.RegisterCallback( self, "ScriptSetLua" );
			self:ScriptSetLua( nil, Script );
		else
			self.Enabled = false;
			_DevPad.UnregisterCallback( self, "ScriptSetLua" );
			UpdateEnabled( self );
		end
	end
end


--- @return True if selected font color set to (R, G, B).
function NS:SetSwatchColor ( R, G, B )
	R, G, B = tonumber( R ), tonumber( G ), tonumber( B );
	if ( not R or not G or not B ) then
		R, G, B = GetItemQualityColor( 2 ); -- Uncommon (green)
	end
	if ( self.R ~= R or self.G ~= G or self.B ~= B ) then
		self.R, self.G, self.B = R, G, B;

		self.Swatch:GetNormalTexture():SetVertexColor( R, G, B );
		return true;
	end
end
--- Saves the swatch color for saved variables.
function NS:Pack ()
	return { R = self.R; G = self.G; B = self.B; };
end
--- Loads the swatch color from saved variables.
function NS:Unpack ( Options )
	return self:SetSwatchColor( Options.R, Options.G, Options.B );
end


do
	--- @return Active color code (lowercase) at Position in Text, or nil if none.
	local function GetActiveColor ( Text, Position )
		-- Find last color code before Position
		local Color, ColorEnd;
		local CodeEnd, _, Escapes, Code = 0;
		while ( true ) do
			_, CodeEnd, Escapes, Code = Text:find( "(|*)(|[Cc]%x%x%x%x%x%x%x%x)", CodeEnd + 1 );
			if ( not CodeEnd or CodeEnd > Position ) then
				break;
			end
			if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
				Color, ColorEnd = Code, CodeEnd;
			end
		end
		if ( not Color ) then
			return; -- No colors found
		end

		-- Check if color gets terminated before Position
		CodeEnd = 0;
		while ( true ) do
			_, CodeEnd, Escapes = Text:find( "(|*)|[Rr]", CodeEnd + 1 );
			if ( not CodeEnd or CodeEnd > Position ) then
				break;
			end
			if ( CodeEnd > ColorEnd and #Escapes % 2 == 0 ) then
				return; -- Color terminated
			end
		end
		return Color:lower();
	end

	--- @return R, G, B of text color at the cursor.
	function NS:GetCursorColor ()
		if ( self.Enabled ) then
			local Color = GetActiveColor( self.Script._Text, GUI.Editor.Edit:GetCursorPosition() );
			if ( Color ) then
				local R, G, B = Color:match( "|[Cc]%x%x(%x%x)(%x%x)(%x%x)" );
				return tonumber( R, 16 ) / 255, tonumber( G, 16 ) / 255, tonumber( B, 16 ) / 255;
			else
				return GUI.Editor.Edit:GetTextColor();
			end
		end
	end

	--- @return StartPos, EndPos of highlight in this editbox.
	local function GetTextHighlight ( self )
		local Text, Cursor = self:GetText(), self:GetCursorPosition();
		-- Note: If cursor is in a link, this technique fails; Move out of potential links first.
		self:SetCursorPosition( 0 );
		self:Insert( "" ); -- Delete selected text
		local TextNew, CursorNew = self:GetText(), self:GetCursorPosition();
		local Start, End = CursorNew, #Text - ( #TextNew - CursorNew );
		-- Restore previous text
		self:SetText( Text );
		self:SetCursorPosition( Cursor );
		self:HighlightText( Start, End );
		return Start, End;
	end

	local StripColors;
	do
		local CursorPosition, CursorDelta;
		--- Callback for gsub to remove unescaped codes.
		local function StripCodeGsub ( Escapes, Code, End )
			if ( #Escapes % 2 == 0 ) then -- Doesn't escape Code
				if ( CursorPosition and CursorPosition >= End - 1 ) then
					CursorDelta = CursorDelta - #Code;
				end
				return Escapes;
			end
		end
		--- Removes a single escape sequence.
		local function StripCode ( Pattern, Text, OldCursor )
			CursorPosition, CursorDelta = OldCursor, 0;
			return Text:gsub( Pattern, StripCodeGsub ),
				OldCursor and CursorPosition + CursorDelta;
		end
		--- Strips Text of all color escape sequences.
		-- @param Cursor  Optional cursor position to keep track of.
		-- @return Stripped text, and the updated cursor position if Cursor was given.
		function StripColors ( Text, Cursor )
			Text, Cursor = StripCode( "(|*)(|[Cc]%x%x%x%x%x%x%x%x)()", Text, Cursor );
			return StripCode( "(|*)(|[Rr])()", Text, Cursor );
		end
	end

	local TERMINATOR, BYTE_PIPE = "|r", ( "|" ):byte();
	--- Wraps this editbox's selected text with the given color.
	-- @return True if text was selected and colored.
	function NS:ColorSelection ( R, G, B )
		if ( not self.Enabled ) then
			return;
		end
		local Edit = GUI.Editor.Edit;
		local ColorStart = GUI.FormatColorCode( R, G, B );
		local ColorDefault = GUI.FormatColorCode( Edit:GetTextColor() );
		if ( ColorStart == ColorDefault ) then
			ColorStart = "";
		end

		local Start, End = GetTextHighlight( Edit );
		local Text, Cursor = self.Script._Text, Edit:GetCursorPositionUnescaped();
		if ( Start == End ) then -- Nothing selected
			return; -- Wrapping the cursor in a color code and hitting backspace crashes PTR clients!
		end
		-- Check for redundant color terminator before selection
		if ( Start >= #TERMINATOR and Text:find( "^|[Rr]", Start - #TERMINATOR + 1 ) ) then
			local Index, Pipes, Byte = Start - #TERMINATOR, 0, BYTE_PIPE;
			while ( Byte == BYTE_PIPE ) do
				Index, Pipes, Byte = Index - 1, Pipes + 1, Text:byte( Index );
			end
			if ( Pipes % 2 == 1 ) then -- Not escaped
				Start = Start - #TERMINATOR; -- Remove terminator and read active color from before it
			end
		end

		-- Find active color codes at the edges of the selection
		local ColorStartOld = End > 0 and GetActiveColor( Text, Start ) or "";
		local ColorEndOld = End < #Text and GetActiveColor( Text, End ) or "";
		local ColorEnd = ColorEndOld;
		-- Optimizations to avoid unnecessary color codes
		if ( ColorEndOld == ColorStart -- End of selection is already this color
			or Text:find( "^|[Cc]%x%x%x%x%x%x%x%x", End + 1 ) -- Color changes just after selection
		) then
			ColorEnd = "";
		elseif ( ColorEndOld == "" and ColorStart ~= "" ) then
			ColorEnd = TERMINATOR; -- Transitioning out of color
		end
		if ( ColorStartOld == ColorStart ) then
			ColorStart = ""; -- Beginning of selection is already this color
		elseif ( ColorStartOld ~= "" and ColorStart == "" ) then
			ColorStart = TERMINATOR; -- Transitioning out of color
		end

		local Selection = Text:sub( Start + 1, End );
		-- Remove color codes from the selection
		local Replacement, CursorReplacement = StripColors( Selection, Cursor - Start );

		self.Script:SetText( ( "" ):join(
			Text:sub( 1, Start ),
			ColorStart, Replacement, ColorEnd,
			Text:sub( End + 1 ) ) );

		-- Restore cursor and highlight, adjusting for color codes
		Cursor = Start + CursorReplacement;
		if ( CursorReplacement > 0 ) then -- Cursor beyond start of selection
			Cursor = Cursor + #ColorStart;
		end
		if ( CursorReplacement > #Replacement ) then -- Cursor beyond end of selection
			Cursor = Cursor + #ColorEnd;
		end
		Start = Edit:ValidateCursorPosition( Start );
		End = Edit:ValidateCursorPosition( End + #ColorStart + ( #Replacement - #Selection ) );

		Edit:ScrollToNextCursorPosition();
		Edit:SetCursorPositionUnescaped( Edit:ValidateCursorPosition( Cursor ) );
		Edit:HighlightTextUnescaped( Start, End );
		return true;
	end
end


--- Restores the container's size when shown.
function NS.ButtonContainer:OnShow ()
	self:SetWidth( self.Width );
end
--- Shrinks the container when hidden so other title buttons will collapse.
function NS.ButtonContainer:OnHide ()
	self:SetWidth( self.Padding ); -- Negates padding offset
	-- Cancel pending color selection
	NS.Dropdown:Hide();
	if ( ColorPickerFrame:IsShown()
		and ColorPickerFrame.cancelFunc == NS.Dropdown.Custom.OnCancel
	) then
		ColorPickerCancelButton:Click();
	end
end

--- Highlights selected text when left clicked, or opens dropdown on right click.
function NS.Swatch:OnClick ( Button )
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	if ( Button == "RightButton" ) then
		return ToggleFrame( NS.Dropdown );
	end
	NS:ColorSelection( NS.R, NS.G, NS.B );
	NS.Dropdown:Hide();
end
--- Picks color at the cursor when clicked.
function NS.Dropper:OnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	NS:SetSwatchColor( NS:GetCursorColor() );
	NS.Dropdown:Hide();
end

--- Hides the dropdown once the mouse passes outside of it.
function NS.Dropdown:OnUpdate ()
	if ( not self:IsMouseOver( 8 + NS.Swatch:GetHeight(), -8, -8, 8 ) ) then
		self:Hide();
	end
end
do
	local FirstUpdate;
	--- Updates the swatch as a new color is being chosen.
	function NS.Dropdown.Custom.OnChanged ()
		if ( FirstUpdate ) then -- ColorPickerFrame isn't shown yet
			FirstUpdate = nil;
			return;
		end
		local R, G, B = ColorPickerFrame:GetColorRGB();
		NS:SetSwatchColor( R, G, B );
		if ( not ColorPickerFrame:IsShown() ) then -- Okay button pressed
			NS:ColorSelection( R, G, B );
		end
	end
	--- Restores the original color if cancelled.
	function NS.Dropdown.Custom.OnCancel ( Previous )
		NS:SetSwatchColor( Previous.r, Previous.g, Previous.b );
	end
	local Info = {
		swatchFunc = NS.Dropdown.Custom.OnChanged;
		cancelFunc = NS.Dropdown.Custom.OnCancel;
	};
	--- Opens a color selection dialog to choose a custom color.
	function NS.Dropdown.Custom:OnClick ()
		NS.Dropdown:Hide();
		PlaySound( "igMainMenuOptionCheckBoxOn" );
		Info.r, Info.g, Info.b = NS.R, NS.G, NS.B;
		FirstUpdate = true;
		OpenColorPicker( Info );
	end
end
--- Sets the default color to the editbox default text color, in case a script changes it.
function NS.Dropdown:DefaultOnShow ()
	self.R, self.G, self.B = GUI.Editor.Edit:GetTextColor();
	self:GetNormalTexture():SetVertexColor( self.R, self.G, self.B );
end
--- Selects this swatch's color.
function NS.Dropdown:SwatchOnClick ()
	PlaySound( "igMainMenuOptionCheckBoxOn" );
	NS:SetSwatchColor( self.R, self.G, self.B );
	NS:ColorSelection( self.R, self.G, self.B );
	NS.Dropdown:Hide();
end

--- Highlights this swatch's outline on enter.
function NS:SwatchOnEnter ()
	local Color = NORMAL_FONT_COLOR;
	self.Outline:SetTexture( Color.r, Color.g, Color.b );
	GUI.Dialog.ControlOnEnter( self );
end
--- Restores this swatch's outline on leave.
function NS:SwatchOnLeave ()
	local Color = HIGHLIGHT_FONT_COLOR;
	self.Outline:SetTexture( Color.r, Color.g, Color.b );
	GameTooltip:Hide();
end




-- Title buttons
local Container = NS.ButtonContainer;
Container:Hide();
Container:SetScript( "OnShow", Container.OnShow );
Container:SetScript( "OnHide", Container.OnHide );
Container:SetHeight( 1 );
--- Configures this button as a color swatch.
local function SetupSwatch ( self )
	self:SetSize( 16, 16 );
	self.Outline = self:CreateTexture( nil, "BACKGROUND" );
	self.Outline:SetPoint( "TOPLEFT", 1, -1 );
	self.Outline:SetPoint( "BOTTOMRIGHT", -1, 1 );
	self:SetNormalTexture( [[Interface\ChatFrame\ChatFrameColorSwatch]] );
	self:SetScript( "OnEnter", NS.SwatchOnEnter );
	self:SetScript( "OnLeave", NS.SwatchOnLeave );
	NS.SwatchOnLeave( self ); -- Initialize outline
	return self;
end
local Swatch = NS.Swatch;
SetupSwatch( Swatch );
Swatch:SetPoint( "RIGHT" );
Swatch:RegisterForClicks( "LeftButtonUp", "RightButtonUp" );
Swatch:SetScript( "OnClick", Swatch.OnClick );
Swatch.tooltipText = GUI.L.COLOR_SWATCH;
local Dropper = NS.Dropper;
Dropper:SetParent( Container );
Dropper:SetHitRectInsets( 2, 2, 2, 2 );
Dropper:SetPoint( "LEFT" );
Dropper:SetScript( "OnClick", Dropper.OnClick );
Dropper.tooltipText = GUI.L.COLOR_DROPPER;
Container.Padding, Container.Width = -8, Swatch:GetWidth() + Dropper:GetWidth();
Container:OnHide();
GUI.Editor:AddTitleButton( Container, Container.Padding );

-- Color dropdown
local Dropdown = NS.Dropdown;
Dropdown:Hide();
Dropdown:SetSize( 92, 74 );
Dropdown:SetPoint( "TOPLEFT", Swatch, "BOTTOMLEFT", -12, 2 );
Dropdown:SetBackdrop( {
	edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]];
	bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]];
	edgeSize = 20; tileSize = 20; tile = true;
	insets = { left = 4; right = 4; top = 4; bottom = 4; };
} );
local Background, Border = TOOLTIP_DEFAULT_BACKGROUND_COLOR, TOOLTIP_DEFAULT_COLOR;
Dropdown:SetBackdropColor( Background.r, Background.g, Background.b );
Dropdown:SetBackdropBorderColor( Border.r, Border.g, Border.b );
Dropdown:EnableMouse( true );
Dropdown:SetClampedToScreen( true );
Dropdown:SetFrameLevel( Dropdown:GetFrameLevel() + 10 ); -- Above editbox
Dropdown:SetScript( "OnUpdate", Dropdown.OnUpdate );
--- @return A color swatch button initialized to R, G, B.
local function CreatePreset ( Color )
	local Swatch = SetupSwatch( CreateFrame( "Button", nil, Dropdown ) );
	Swatch.R, Swatch.G, Swatch.B = Color.r, Color.g, Color.b;
	Swatch:GetNormalTexture():SetVertexColor( Color.r, Color.g, Color.b );
	Swatch:SetScript( "OnClick", Dropdown.SwatchOnClick );
	return Swatch;
end
local Default = CreatePreset( HIGHLIGHT_FONT_COLOR ); -- Changes to match editbox text color
Default:SetPoint( "TOPLEFT", 12, -12 );
Default:SetScript( "OnShow", Dropdown.DefaultOnShow );
local Gray = CreatePreset( ITEM_QUALITY_COLORS[ 0 ] );
Gray:SetPoint( "LEFT", Default, "RIGHT", 2, 0 );
local Purple = CreatePreset( ITEM_QUALITY_COLORS[ 4 ] );
Purple:SetPoint( "LEFT", Gray, "RIGHT", 2, 0 );
local Blue = CreatePreset( ITEM_QUALITY_COLORS[ 3 ] );
Blue:SetPoint( "LEFT", Purple, "RIGHT", 2, 0 );
-- Second row
local Green = CreatePreset( ITEM_QUALITY_COLORS[ 2 ] );
Green:SetPoint( "TOPLEFT", Default, "BOTTOMLEFT", 0, -2 );
local Yellow = CreatePreset( NORMAL_FONT_COLOR );
Yellow:SetPoint( "LEFT", Green, "RIGHT", 2, 0 );
local Orange = CreatePreset( ITEM_QUALITY_COLORS[ 5 ] );
Orange:SetPoint( "LEFT", Yellow, "RIGHT", 2, 0 );
local Red = CreatePreset( RED_FONT_COLOR );
Red:SetPoint( "LEFT", Orange, "RIGHT", 2, 0 );
-- Third row
local Custom = Dropdown.Custom;
Custom:SetText( GUI.L.COLOR_CUSTOM );
Custom:SetPoint( "BOTTOMLEFT", 6, 6 );
Custom:SetPoint( "RIGHT", -6, 0 );
Custom:SetHeight( 20 );
Custom:SetScript( "OnClick", Custom.OnClick );


GUI.RegisterCallback( NS, "EditorSetScriptObject" );

NS:Unpack( {} ); -- Default swatch color