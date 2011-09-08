--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Options.lua - Adds an options panel to the default UI's config menu.  *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local NS = CreateFrame( "Frame" );
_Dev.Options = NS;

local Callbacks = {};
NS.Callbacks = Callbacks;
local Controls = {};
NS.Controls = Controls;




--[[****************************************************************************
  * Function: _Dev.Options.GetVariableVararg                                   *
  * Description: Returns the table and key name for a saved variable string.   *
  ****************************************************************************]]
do
	local select = select;
	function NS.GetVariableVararg ( ... )
		local Table = _DevOptions;
		local Count = select( "#", ... );
		for Index = 1, Count - 1 do
			Table = Table[ select( Index, ... ) ];
		end
		return Table, select( Count, ... );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options.SetVariable                                         *
  * Description: Saves a value to a control's saved variable.                  *
  ****************************************************************************]]
function NS.SetVariable ( Variable, Value )
	local Table, Key = NS.GetVariableVararg( ( "." ):split( Variable ) );
	if ( Table[ Key ] ~= Value ) then
		Table[ Key ] = Value;
		if ( Callbacks[ Variable ] ) then
			Callbacks[ Variable ]( Value );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Options.SetVariableCallback                                 *
  * Description: Adds a callback to call when a given variable is changed.     *
  ****************************************************************************]]
function NS.SetVariableCallback ( Variable, Callback )
	Callbacks[ Variable ] = Callback;
end




--[[****************************************************************************
  * Function: _Dev.Options:ControlOnEnter                                      *
  * Description: Shows the control's tooltip.                                  *
  ****************************************************************************]]
function NS:ControlOnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
	GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
end

--[[****************************************************************************
  * Function: _Dev.Options:CheckButtonOnClick                                  *
  * Description: Updates the control's saved variable.                         *
  ****************************************************************************]]
function NS:CheckButtonOnClick ()
	local Checked = not not self:GetChecked();
	NS.SetVariable( self.Variable, Checked );
	PlaySound( Checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
end
--[[****************************************************************************
  * Function: _Dev.Options:CheckButtonUpdate                                   *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function NS:CheckButtonUpdate ( Value )
	self:SetChecked( Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:EditBoxOnTextChanged                                *
  * Description: Updates the control's saved variable and display.             *
  ****************************************************************************]]
function NS:EditBoxOnTextChanged ()
	if ( self.CanDisable ) then
		local Enabled = #self:GetText() > 0;
		NS.SetVariable( self.Variable, Enabled and self:GetNumber() or false );
		self.Icon:SetTexture( Enabled and "Interface\\Buttons\\UI-CheckBox-Check" or nil );
	else
		local Value = self:GetNumber();
		self:SetNumber( Value ); -- Fill blank box with 0
		NS.SetVariable( self.Variable, Value );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:EditBoxUpdate                                       *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function NS:EditBoxUpdate ( Value )
	if ( Value ) then
		self:SetNumber( Value );
	else
		self:SetText( "" );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:SliderOnValueChanged                                *
  * Description: Updates the control's saved variable.                         *
  ****************************************************************************]]
function NS:SliderOnValueChanged ( Value )
	NS.SetVariable( self.Variable, Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:SliderUpdate                                        *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function NS:SliderUpdate ( Value )
	self:SetValue( Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownOnSelect                                    *
  * Description: Called when a new value is chosen from the dropdown.          *
  ****************************************************************************]]
function NS:DropDownOnSelect ( Variable )
	local Index = self.value;
	UIDropDownMenu_SetSelectedValue( Controls[ Variable ], Index );
	NS.SetVariable( Variable, Index );
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownInitialize                                  *
  * Description: Puts together a control's dropdown menu.                      *
  ****************************************************************************]]
function NS:DropDownInitialize ()
	local Variable = self.Variable;
	local Info = UIDropDownMenu_CreateInfo();
	local Args = L.OPTIONS[ Variable.."_ARGS" ];
	local Table, Key = NS.GetVariableVararg( ( "." ):split( Variable ) );
	local Value = Table[ Key ];
	for Index = 0, #Args do
		Info.text = Args[ Index ];
		Info.value = Index;
		Info.arg1 = Variable;
		Info.func = NS.DropDownOnSelect;
		Info.checked = Index == Value;
		UIDropDownMenu_AddButton( Info );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownUpdate                                      *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function NS:DropDownUpdate ( Value )
	UIDropDownMenu_SetSelectedValue( self, Value );
end




--[[****************************************************************************
  * Function: _Dev.Options:CreateCheckButton                                   *
  * Description: Creates a boolean checkbutton control.                        *
  ****************************************************************************]]
function NS:CreateCheckButton ( Variable )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local CheckButton = CreateFrame( "CheckButton", Name, self, "InterfaceOptionsCheckButtonTemplate" );
	CheckButton.Variable = Variable;
	CheckButton.Update = NS.CheckButtonUpdate;
	Controls[ Variable ] = CheckButton;
	CheckButton:SetScript( "OnClick", NS.CheckButtonOnClick );

	CheckButton.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	_G[ Name.."Text" ]:SetText( L.OPTIONS[ Variable ] );
	return CheckButton;
end
--[[****************************************************************************
  * Function: _Dev.Options:CreateSlider                                        *
  * Description: Creates a ranged slider control.                              *
  ****************************************************************************]]
function NS:CreateSlider ( Variable, Min, Max, Step )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local Slider = CreateFrame( "Slider", Name, self, "OptionsSliderTemplate" );
	Slider.Variable = Variable;
	Slider.Update = NS.SliderUpdate;
	Controls[ Variable ] = Slider;
	Slider:SetPoint( "RIGHT", -16, 0 );
	Slider:SetMinMaxValues( Min, Max );
	if ( Step ) then
		Slider:SetValueStep( Step );
	end
	Slider:SetScript( "OnValueChanged", NS.SliderOnValueChanged );

	local Format = L.OPTIONS[ Variable.."_FORMAT" ];
	Slider.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	_G[ Name.."Text" ]:SetText( L.OPTIONS[ Variable ] );
	_G[ Name.."Low" ]:SetFormattedText( Format, Min );
	_G[ Name.."High" ]:SetFormattedText( Format, Max );
	return Slider;
end
--[[****************************************************************************
  * Function: _Dev.Options:CreateEditBox                                       *
  * Description: Creates an edit box control for positive integers.            *
  ****************************************************************************]]
function NS:CreateEditBox ( Variable, CanDisable )
	local EditBox = CreateFrame( "EditBox", "_DevOptions"..Variable:gsub( "%.", "" ), self, "InputBoxTemplate" );
	EditBox.Variable = Variable;
	EditBox.CanDisable = CanDisable;
	EditBox.Update = NS.EditBoxUpdate;
	Controls[ Variable ] = EditBox;
	EditBox:SetPoint( "RIGHT", -12, 0 );
	EditBox:SetHeight( 16 );
	EditBox:SetAutoFocus( false );
	EditBox:SetNumeric( true );
	EditBox:SetMaxLetters( 6 ); -- Prevent odd EditBox:GetNumber() overflows
	EditBox:SetScript( "OnEnter", NS.ControlOnEnter );
	EditBox:SetScript( "OnLeave", GameTooltip_Hide );
	EditBox:SetScript( "OnTextChanged", NS.EditBoxOnTextChanged );

	EditBox.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	local Label = EditBox:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
	Label:SetPoint( "BOTTOMLEFT", EditBox, "TOPLEFT", -6, 4 );
	Label:SetText( L.OPTIONS[ Variable ] );
	if ( CanDisable ) then
		EditBox.Icon = EditBox:CreateTexture( nil, "OVERLAY" );
		EditBox.Icon:SetSize( 16, 16 );
		EditBox.Icon:SetPoint( "RIGHT", -4, 0 );
	end
	return EditBox;
end
--[[****************************************************************************
  * Function: _Dev.Options:CreateDropDown                                      *
  * Description: Creates a dropdown menu control.                              *
  ****************************************************************************]]
function NS:CreateDropDown ( Variable )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local DropDown = CreateFrame( "Frame", Name, self, "UIDropDownMenuTemplate" );
	DropDown.Variable = Variable;
	DropDown.Update = NS.DropDownUpdate;
	Controls[ Variable ] = DropDown;
	DropDown:SetPoint( "RIGHT", -4, 0 );
	DropDown:EnableMouse( true );
	DropDown:SetScript( "OnEnter", NS.ControlOnEnter );
	DropDown:SetScript( "OnLeave", GameTooltip_Hide );
	UIDropDownMenu_JustifyText( DropDown, "LEFT" );
	_G[ Name.."Middle" ]:SetPoint( "RIGHT", -16, 0 );

	DropDown.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	local Label = DropDown:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
	Label:SetPoint( "BOTTOMLEFT", DropDown, "TOPLEFT", 16, 3 );
	Label:SetText( L.OPTIONS[ Variable ] );
	UIDropDownMenu_Initialize( DropDown, NS.DropDownInitialize );
	return DropDown;
end




--[[****************************************************************************
  * Function: _Dev.Options.Update                                              *
  * Description: Syncs the checkboxes to actual saved settings.                *
  ****************************************************************************]]
function NS.Update ()
	local Table, Key;
	for Variable, Control in pairs( Controls ) do
		Table, Key = NS.GetVariableVararg( ( "." ):split( Variable ) );
		Control:Update( Table[ Key ] );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:OnLoad                                              *
  * Description: Loads saved variables.                                        *
  ****************************************************************************]]
function NS:OnLoad ()
	self.Update();
end


--[[****************************************************************************
  * Function: _Dev.Options.SlashCommand                                        *
  * Description: Slash command chat handler to open the options pane.          *
  ****************************************************************************]]
function NS.SlashCommand ()
	InterfaceOptionsFrame_OpenToCategory( NS );
end




NS.name = L.OPTIONS_TITLE;
NS:Hide();

InterfaceOptions_AddCategory( NS );


-- Pane title
NS.Title = NS:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
NS.Title:SetPoint( "TOPLEFT", 16, -16 );
NS.Title:SetText( L.OPTIONS_TITLE );
local SubText = NS:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
NS.SubText = SubText;
SubText:SetPoint( "TOPLEFT", NS.Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.OPTIONS_DESC );




-- Print Lua errors option button
NS:CreateCheckButton( "PrintLuaErrors" ):SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );

-- Create two columns for Dump and Outline options
local Column1 = CreateFrame( "Frame", "_DevOptionsDump", NS, "OptionsBoxTemplate" );
_G[ Column1:GetName().."Title" ]:SetText( L.OPTIONS.DUMP );
Column1:SetPoint( "TOPLEFT", Controls[ "PrintLuaErrors" ], "BOTTOMLEFT", 0, -16 );
Column1:SetPoint( "BOTTOMRIGHT", NS, "BOTTOM", 0, 16 );
local Column2 = CreateFrame( "Frame", "_DevOptionsOutline", NS, "OptionsBoxTemplate" );
_G[ Column2:GetName().."Title" ]:SetText( L.OPTIONS.OUTLINE );
Column2:SetPoint( "TOPLEFT", Column1, "TOPRIGHT", 8, 0 );
Column2:SetPoint( "BOTTOMRIGHT", -14, 16 );


-- Dump options section
NS.CreateCheckButton( Column1, "Dump.SkipGlobalEnv" ):SetPoint( "TOPLEFT", 8, -8 );
NS.CreateEditBox( Column1, "Dump.MaxExploreTime", true ):SetPoint( "TOPLEFT", Controls[ "Dump.SkipGlobalEnv" ], "BOTTOMLEFT", 8, -16 );
NS.CreateEditBox( Column1, "Dump.MaxDepth", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxExploreTime" ], "BOTTOMLEFT", 0, -24 );
NS.CreateEditBox( Column1, "Dump.MaxTableLen", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxDepth" ], "BOTTOMLEFT", 0, -24 );
NS.CreateEditBox( Column1, "Dump.MaxStrLen", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxTableLen" ], "BOTTOMLEFT", 0, -24 );
NS.CreateDropDown( Column1, "Dump.EscapeMode" ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxStrLen" ], "BOTTOMLEFT", -22, -24 );


-- Outline options section
NS.CreateEditBox( Column2, "Outline.BoundsThreshold" ):SetPoint( "TOPLEFT", 16, -24 );
NS.CreateSlider( Column2, "Outline.BorderAlpha", 0.0, 1.0 ):SetPoint( "TOPLEFT", Controls[ "Outline.BoundsThreshold" ], "BOTTOMLEFT", 0, -18 );
NS.SetVariableCallback( "Outline.BorderAlpha", function () _Dev.Outline.Update(); end );


SlashCmdList[ "_DEV_OPTIONS" ] = NS.SlashCommand;