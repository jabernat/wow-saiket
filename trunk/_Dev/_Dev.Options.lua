--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Options.lua - Adds an options panel to the default UI's config menu.  *
  ****************************************************************************]]


local _Dev = _Dev;
local L = _DevLocalization;
local me = CreateFrame( "Frame" );
_Dev.Options = me;

local Callbacks = {};
me.Callbacks = Callbacks;
local Controls = {};
me.Controls = Controls;




--[[****************************************************************************
  * Function: _Dev.Options.GetVariableVararg                                   *
  * Description: Returns the table and key name for a saved variable string.   *
  ****************************************************************************]]
do
	local select = select;
	function me.GetVariableVararg ( ... )
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
function me.SetVariable ( Variable, Value )
	local Table, Key = me.GetVariableVararg( ( "." ):split( Variable ) );
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
function me.SetVariableCallback ( Variable, Callback )
	Callbacks[ Variable ] = Callback;
end




--[[****************************************************************************
  * Function: _Dev.Options:ControlOnEnter                                      *
  * Description: Shows the control's tooltip.                                  *
  ****************************************************************************]]
function me:ControlOnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
	GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
end
--[[****************************************************************************
  * Function: _Dev.Options:ControlOnLeave                                      *
  * Description: Hides the control's tooltip.                                  *
  ****************************************************************************]]
function me:ControlOnLeave ()
	GameTooltip:Hide();
end

--[[****************************************************************************
  * Function: _Dev.Options:CheckButtonOnClick                                  *
  * Description: Updates the control's saved variable.                         *
  ****************************************************************************]]
function me:CheckButtonOnClick ()
	local Checked = not not self:GetChecked();
	me.SetVariable( self.Variable, Checked );
	PlaySound( Checked and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
end
--[[****************************************************************************
  * Function: _Dev.Options:CheckButtonUpdate                                   *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function me:CheckButtonUpdate ( Value )
	self:SetChecked( Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:EditBoxOnTextChanged                                *
  * Description: Updates the control's saved variable and display.             *
  ****************************************************************************]]
function me:EditBoxOnTextChanged ()
	if ( self.CanDisable ) then
		local Enabled = #self:GetText() > 0;
		me.SetVariable( self.Variable, Enabled and self:GetNumber() or false );
		self.Icon:SetTexture( Enabled and "Interface\\Buttons\\UI-CheckBox-Check" or nil );
	else
		local Value = self:GetNumber();
		self:SetNumber( Value ); -- Fill blank box with 0
		me.SetVariable( self.Variable, Value );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:EditBoxUpdate                                       *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function me:EditBoxUpdate ( Value )
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
function me:SliderOnValueChanged ( Value )
	me.SetVariable( self.Variable, Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:SliderUpdate                                        *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function me:SliderUpdate ( Value )
	self:SetValue( Value );
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownOnSelect                                    *
  * Description: Called when a new value is chosen from the dropdown.          *
  ****************************************************************************]]
function me:DropDownOnSelect ( Variable )
	local Index = self.value;
	UIDropDownMenu_SetSelectedValue( Controls[ Variable ], Index );
	me.SetVariable( Variable, Index );
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownInitialize                                  *
  * Description: Puts together a control's dropdown menu.                      *
  ****************************************************************************]]
function me:DropDownInitialize ()
	local Variable = self.Variable;
	local Info = UIDropDownMenu_CreateInfo();
	local Args = L.OPTIONS[ Variable.."_ARGS" ];
	local Table, Key = me.GetVariableVararg( ( "." ):split( Variable ) );
	local Value = Table[ Key ];
	for Index = 0, #Args do
		Info.text = Args[ Index ];
		Info.value = Index;
		Info.arg1 = Variable;
		Info.func = me.DropDownOnSelect;
		Info.checked = Index == Value;
		UIDropDownMenu_AddButton( Info );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:DropDownUpdate                                      *
  * Description: Syncronize the control from its saved variable.               *
  ****************************************************************************]]
function me:DropDownUpdate ( Value )
	UIDropDownMenu_SetSelectedValue( self, Value );
end




--[[****************************************************************************
  * Function: _Dev.Options:CreateCheckButton                                   *
  * Description: Creates a boolean checkbutton control.                        *
  ****************************************************************************]]
function me:CreateCheckButton ( Variable )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local CheckButton = CreateFrame( "CheckButton", Name, self, "InterfaceOptionsCheckButtonTemplate" );
	CheckButton.Variable = Variable;
	CheckButton.Update = me.CheckButtonUpdate;
	Controls[ Variable ] = CheckButton;
	CheckButton:SetScript( "OnClick", me.CheckButtonOnClick );

	CheckButton.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	_G[ Name.."Text" ]:SetText( L.OPTIONS[ Variable ] );
	return CheckButton;
end
--[[****************************************************************************
  * Function: _Dev.Options:CreateSlider                                        *
  * Description: Creates a ranged slider control.                              *
  ****************************************************************************]]
function me:CreateSlider ( Variable, Min, Max, Step )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local Slider = CreateFrame( "Slider", Name, self, "OptionsSliderTemplate" );
	Slider.Variable = Variable;
	Slider.Update = me.SliderUpdate;
	Controls[ Variable ] = Slider;
	Slider:SetPoint( "RIGHT", -16, 0 );
	Slider:SetMinMaxValues( Min, Max );
	if ( Step ) then
		Slider:SetValueStep( Step );
	end
	Slider:SetScript( "OnValueChanged", me.SliderOnValueChanged );

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
function me:CreateEditBox ( Variable, CanDisable )
	local EditBox = CreateFrame( "EditBox", "_DevOptions"..Variable:gsub( "%.", "" ), self, "InputBoxTemplate" );
	EditBox.Variable = Variable;
	EditBox.CanDisable = CanDisable;
	EditBox.Update = me.EditBoxUpdate;
	Controls[ Variable ] = EditBox;
	EditBox:SetPoint( "RIGHT", -12, 0 );
	EditBox:SetHeight( 16 );
	EditBox:SetAutoFocus( false );
	EditBox:SetNumeric( true );
	EditBox:SetMaxLetters( 6 ); -- Prevent odd EditBox:GetNumber() overflows
	EditBox:SetScript( "OnEnter", me.ControlOnEnter );
	EditBox:SetScript( "OnLeave", me.ControlOnLeave );
	EditBox:SetScript( "OnTextChanged", me.EditBoxOnTextChanged );

	EditBox.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	local Label = EditBox:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
	Label:SetPoint( "BOTTOMLEFT", EditBox, "TOPLEFT", -6, 4 );
	Label:SetText( L.OPTIONS[ Variable ] );
	if ( CanDisable ) then
		EditBox.Icon = EditBox:CreateTexture( nil, "OVERLAY" );
		EditBox.Icon:SetWidth( 16 );
		EditBox.Icon:SetHeight( 16 );
		EditBox.Icon:SetPoint( "RIGHT", -4, 0 );
	end
	return EditBox;
end
--[[****************************************************************************
  * Function: _Dev.Options:CreateDropDown                                      *
  * Description: Creates a dropdown menu control.                              *
  ****************************************************************************]]
function me:CreateDropDown ( Variable )
	local Name = "_DevOptions"..Variable:gsub( "%.", "" );
	local DropDown = CreateFrame( "Frame", Name, self, "UIDropDownMenuTemplate" );
	DropDown.Variable = Variable;
	DropDown.Update = me.DropDownUpdate;
	Controls[ Variable ] = DropDown;
	DropDown:SetPoint( "RIGHT", -4, 0 );
	DropDown:EnableMouse( true );
	DropDown:SetScript( "OnEnter", me.ControlOnEnter );
	DropDown:SetScript( "OnLeave", me.ControlOnLeave );
	UIDropDownMenu_JustifyText( DropDown, "LEFT" );
	_G[ Name.."Middle" ]:SetPoint( "RIGHT", -16, 0 );

	DropDown.tooltipText = L.OPTIONS[ Variable.."_DESC" ];
	local Label = DropDown:CreateFontString( nil, "ARTWORK", "GameFontNormalSmall" );
	Label:SetPoint( "BOTTOMLEFT", DropDown, "TOPLEFT", 16, 3 );
	Label:SetText( L.OPTIONS[ Variable ] );
	UIDropDownMenu_Initialize( DropDown, me.DropDownInitialize );
	return DropDown;
end




--[[****************************************************************************
  * Function: _Dev.Options.Update                                              *
  * Description: Syncs the checkboxes to actual saved settings.                *
  ****************************************************************************]]
function me.Update ()
	local Table, Key;
	for Variable, Control in pairs( Controls ) do
		Table, Key = me.GetVariableVararg( ( "." ):split( Variable ) );
		Control:Update( Table[ Key ] );
	end
end
--[[****************************************************************************
  * Function: _Dev.Options:OnLoad                                              *
  * Description: Loads saved variables.                                        *
  ****************************************************************************]]
function me:OnLoad ()
	self.Update();
end


--[[****************************************************************************
  * Function: _Dev.Options.SlashCommand                                        *
  * Description: Slash command chat handler to open the options pane.          *
  ****************************************************************************]]
function me.SlashCommand ()
	InterfaceOptionsFrame_OpenToCategory( me );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.OPTIONS_TITLE;
	me:Hide();

	InterfaceOptions_AddCategory( me );


	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.OPTIONS_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.OPTIONS_DESC );




	-- Print Lua errors option button
	me:CreateCheckButton( "PrintLuaErrors" ):SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );

	-- Create two columns for Dump and Outline options
	local Column1 = CreateFrame( "Frame", "_DevOptionsDump", me, "OptionsBoxTemplate" );
	_G[ Column1:GetName().."Title" ]:SetText( L.OPTIONS.DUMP );
	Column1:SetPoint( "TOPLEFT", Controls[ "PrintLuaErrors" ], "BOTTOMLEFT", 0, -16 );
	Column1:SetPoint( "BOTTOMRIGHT", me, "BOTTOM", 0, 16 );
	local Column2 = CreateFrame( "Frame", "_DevOptionsOutline", me, "OptionsBoxTemplate" );
	_G[ Column2:GetName().."Title" ]:SetText( L.OPTIONS.OUTLINE );
	Column2:SetPoint( "TOPLEFT", Column1, "TOPRIGHT", 8, 0 );
	Column2:SetPoint( "BOTTOMRIGHT", -14, 16 );


	-- Dump options section
	me.CreateCheckButton( Column1, "Dump.SkipGlobalEnv" ):SetPoint( "TOPLEFT", 8, -8 );
	me.CreateEditBox( Column1, "Dump.MaxExploreTime", true ):SetPoint( "TOPLEFT", Controls[ "Dump.SkipGlobalEnv" ], "BOTTOMLEFT", 8, -16 );
	me.CreateEditBox( Column1, "Dump.MaxDepth", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxExploreTime" ], "BOTTOMLEFT", 0, -24 );
	me.CreateEditBox( Column1, "Dump.MaxTableLen", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxDepth" ], "BOTTOMLEFT", 0, -24 );
	me.CreateEditBox( Column1, "Dump.MaxStrLen", true ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxTableLen" ], "BOTTOMLEFT", 0, -24 );
	me.CreateDropDown( Column1, "Dump.EscapeMode" ):SetPoint( "TOPLEFT", Controls[ "Dump.MaxStrLen" ], "BOTTOMLEFT", -22, -24 );


	-- Outline options section
	me.CreateEditBox( Column2, "Outline.BoundsThreshold" ):SetPoint( "TOPLEFT", 16, -24 );
	me.CreateSlider( Column2, "Outline.BorderAlpha", 0.0, 1.0 ):SetPoint( "TOPLEFT", Controls[ "Outline.BoundsThreshold" ], "BOTTOMLEFT", 0, -18 );
	me.SetVariableCallback( "Outline.BorderAlpha", function () _Dev.Outline.Update(); end );




	SlashCmdList[ "_DEV_OPTIONS" ] = me.SlashCommand;
end
