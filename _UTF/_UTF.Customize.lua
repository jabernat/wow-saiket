--[[****************************************************************************
  * _UTF by Saiket                                                             *
  * _UTF.Customize.lua - Frame for adding to replacement lookup tables.        *
  ****************************************************************************]]


local _UTF = _UTF;
local L = _UTFLocalization;
local me = CreateFrame( "Frame" );
_UTF.Customize = me;

local Panes = {};
me.Panes = Panes;
local Tabs = {};
me.Tabs = Tabs;
me.TableContainer = CreateFrame( "Frame", nil, me );

me.PaneID = nil;




--[[****************************************************************************
  * Function: _UTF.Customize.SetPane                                           *
  * Description: Sets the visible pane in the window.                          *
  ****************************************************************************]]
function me.SetPane ( ID )
	local NewPane = Panes[ ID ];
	if ( NewPane and NewPane ~= Panes[ me.PaneID ] ) then
		if ( not me.Table ) then
			local Table = LibStub( "LibTextTable-1.0" ).New( nil, me.TableContainer, nil, "ChatFontNormal" );
			me.Table = Table;
			Table.OnSelect = me.TableOnSelect;
			Table:SetAllPoints( me.TableContainer );
		end
		-- Hide the old pane
		if ( Panes[ me.PaneID ] ) then
			Panes[ me.PaneID ]:Hide();
			PanelTemplates_DeselectTab( Tabs[ me.PaneID ] );
		end
		-- Show the new pane
		me.PaneID = ID;
		me.UpdateEditBoxLabels( NewPane.Label1, NewPane.Label2 );
		me.SetEditBoxText();
		me.ValidateButtons();
		NewPane:Show();
		NewPane.Update();
		PanelTemplates_SelectTab( Tabs[ ID ] );
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.AddPane                                           *
  * Description: Adds a tab for a given table of options.                      *
  ****************************************************************************]]
function me.AddPane ( Pane, Title )
	local ID = #Panes + 1;
	local Tab = CreateFrame( "Button", "_UTFCustomizeTab"..ID, me.TableContainer, "TabButtonTemplate" );
	tinsert( Panes, Pane );
	tinsert( Tabs, Tab );

	Pane:SetID( ID );
	Pane:SetParent( me );

	Tab:SetID( ID );
	Tab:SetText( Title );
	Tab:SetHitRectInsets( 6, 6, 6, 0 );
	Tab:SetScript( "OnClick", me.TabOnClick );
	Tab:SetScript( "OnShow", Tab:GetScript( "OnLoad" ) );

	Pane:Hide();
	PanelTemplates_DeselectTab( Tab );
	if ( ID == 1 ) then
		Tab:SetPoint( "BOTTOMLEFT", me.TableContainer, "TOPLEFT" );
	else
		Tab:SetPoint( "LEFT", Tabs[ ID - 1 ], "RIGHT", -4, 0 );
	end
end

--[[****************************************************************************
  * Function: _UTF.Customize:TabOnClick                                        *
  * Description: Called when a pane's tab is clicked to select the pane.       *
  ****************************************************************************]]
function me:TabOnClick ()
	PlaySound( "igCharacterInfoTab" );
	me.SetPane( self:GetID() );
end


--[[****************************************************************************
  * Function: _UTF.Customize.UpdateEditBoxLabels                               *
  * Description: Updates the label text on the two edit boxes.                 *
  ****************************************************************************]]
function me.UpdateEditBoxLabels ( Label1, Label2 )
	me.Label1:SetText( Label1 );
	me.Label2:SetText( Label2 );
	me.EditBox2:SetPoint( "LEFT",
		me.Label1:GetStringWidth() > me.Label2:GetStringWidth()
			and me.Label1 or me.Label2,
		"RIGHT", 8, 0 );
end
--[[****************************************************************************
  * Function: _UTF.Customize.SetEditBoxText                                    *
  * Description: Sets the edit boxes' text.                                    *
  ****************************************************************************]]
function me.SetEditBoxText ( Value1, Value2 )
	me.EditBox1:SetText( Value1 or "" );
	me.EditBox2:SetText( Value2 or "" );
end
--[[****************************************************************************
  * Function: _UTF.Customize.ValidateButtons                                   *
  * Description: Validates ability to use add and remove buttons.              *
  ****************************************************************************]]
function me.ValidateButtons ()
	local Pane = Panes[ me.PaneID ];

	local CanRemove = Pane and Pane.CanRemove( me.EditBox1:GetText() ) or nil;
	if ( me.Table ) then
		me.Table:SetSelectionByKey( CanRemove );
	end

	me.AddButton[ ( Pane and Pane.CanAdd( me.EditBox1:GetText(), me.EditBox2 ) )
		and "Enable" or "Disable" ]( me.AddButton );
	me.RemoveButton[ CanRemove and "Enable" or "Disable" ]( me.RemoveButton );
end
--[[****************************************************************************
  * Function: _UTF.Customize.Add                                               *
  * Description: Adds a list element.                                          *
  ****************************************************************************]]
function me.Add ()
	local Pane = Panes[ me.PaneID ];
	if ( Pane ) then
		if ( Pane.Add( me.EditBox1:GetText(), me.EditBox2 ) ) then
			me.SetEditBoxText();
			Panes[ me.PaneID ].Update();
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize.Remove                                            *
  * Description: Removes a list element.                                       *
  ****************************************************************************]]
function me.Remove ()
	local Pane = Panes[ me.PaneID ];
	if ( Pane ) then
		if ( Pane.Remove( me.EditBox1:GetText() ) ) then
			me.SetEditBoxText();
			Panes[ me.PaneID ].Update();
		end
	end
end
--[[****************************************************************************
  * Function: _UTF.Customize:TableOnSelect                                     *
  * Description: Updates the edit boxes when a table row is selected.          *
  ****************************************************************************]]
function me:TableOnSelect ( Key )
	if ( Panes[ me.PaneID ] and Panes[ me.PaneID ].OnSelect and Key ~= nil ) then
		local Value1, Value2 = Panes[ me.PaneID ].OnSelect( Key );
		me.SetEditBoxText( Value1, Value2 );
	end
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	me.name = L.CUSTOMIZE_TITLE;
	me.parent = L.OPTIONS_TITLE;
	me:SetScript( "OnShow", function ( self )
		self:SetScript( "OnShow", nil );
		if ( #Panes > 0 ) then
			me.SetPane( 1 );
		end
	end );

	-- Pane title
	me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
	me.Title:SetPoint( "TOPLEFT", 16, -16 );
	me.Title:SetText( L.CUSTOMIZE_TITLE );
	local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
	me.SubText = SubText;
	SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
	SubText:SetPoint( "RIGHT", -32, 0 );
	SubText:SetHeight( 32 );
	SubText:SetJustifyH( "LEFT" );
	SubText:SetJustifyV( "TOP" );
	SubText:SetText( L.CUSTOMIZE_DESC );


	-- Create add and remove buttons
	local RemoveButton = CreateFrame( "Button", nil, me, "GameMenuButtonTemplate" );
	me.RemoveButton = RemoveButton;
	RemoveButton:SetSize( 16, 20 );
	RemoveButton:SetPoint( "BOTTOMRIGHT", -16, 16 );
	RemoveButton:SetText( L.CUSTOMIZE_REMOVE );
	RemoveButton:SetScript( "OnClick", me.Remove );
	local AddButton = CreateFrame( "Button", nil, me, "GameMenuButtonTemplate" );
	me.AddButton = AddButton;
	AddButton:SetSize( 16, 20 );
	AddButton:SetPoint( "BOTTOMRIGHT", RemoveButton, "TOPRIGHT", 0, 4 );
	AddButton:SetText( L.CUSTOMIZE_ADD );
	AddButton:SetScript( "OnClick", me.Add );


	-- Create edit boxes
	local Label2 = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.Label2 = Label2;
	Label2:SetPoint( "BOTTOMLEFT", 16, 16 );
	Label2:SetPoint( "TOP", RemoveButton );
	local Label1 = me:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	me.Label1 = Label1;
	Label1:SetPoint( "BOTTOMLEFT", Label2, "TOPLEFT", 0, 4 );
	Label1:SetPoint( "TOP", AddButton );

	local EditBox1 = CreateFrame( "EditBox", "_UTFCustomizeEditBox1", me, "InputBoxTemplate" );
	me.EditBox1 = EditBox1;
	local EditBox2 = CreateFrame( "EditBox", "_UTFCustomizeEditBox2", me, "InputBoxTemplate" );
	me.EditBox2 = EditBox2;

	EditBox2:SetPoint( "TOP", Label2 );
	EditBox2:SetPoint( "BOTTOMRIGHT", RemoveButton, "BOTTOMLEFT", -4, 0 );
	EditBox2:SetAutoFocus( false );
	EditBox2:SetScript( "OnTabPressed", function () EditBox1:SetFocus(); end );
	EditBox2:SetScript( "OnEnterPressed", me.Add );
	EditBox2:SetScript( "OnTextChanged", me.ValidateButtons );

	EditBox1:SetPoint( "TOP", Label1 );
	EditBox1:SetPoint( "LEFT", EditBox2 );
	EditBox1:SetPoint( "BOTTOMRIGHT", EditBox2, "TOPRIGHT" );
	EditBox1:SetAutoFocus( false );
	EditBox1:SetScript( "OnTabPressed", function () EditBox2:SetFocus(); end );
	EditBox1:SetScript( "OnEnterPressed", me.Add );
	EditBox1:SetScript( "OnTextChanged", me.ValidateButtons );

	me.UpdateEditBoxLabels();

	me.TableContainer:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -32 );
	me.TableContainer:SetPoint( "RIGHT", -16, 0 );
	me.TableContainer:SetPoint( "BOTTOM", AddButton, "TOP", 0, 4 );
	me.TableContainer:SetBackdrop( { bgFile = [[Interface\DialogFrame\UI-DialogBox-Background]]; } );


	InterfaceOptions_AddCategory( me );
end
