--[[****************************************************************************
  * _NPCScan.Overlay by Saiket                                                 *
  * _NPCScan.Overlay.Config.lua - Adds a configuration pane to enable and      *
  *   disable display modules like the WorldMap and BattlefieldMinimap.        *
  ****************************************************************************]]


local Overlay = select( 2, ... );
local L = Overlay.L;
local me = CreateFrame( "Frame" );
Overlay.Config = me;

me.ShowAll = CreateFrame( "CheckButton", "_NPCScanOverlayConfigShowAllCheckbox", me, "InterfaceOptionsCheckButtonTemplate" );

local ModuleMethods = setmetatable( {}, getmetatable( me ) );
me.ModuleMeta = { __index = ModuleMethods; };

local IsChildAddOn = IsAddOnLoaded( "_NPCScan" );




--- Adds a control to the module to automatically be enabled and disabled.
function ModuleMethods:AddControl ( Control )
	self[ #self + 1 ] = Control;
	Control:SetEnabled( self.Module.Registered and self.Enabled:GetChecked() );
end
do
	--- Enables/disables all registered controls.
	local function SetControlsEnabled ( Config, Enabled )
		for _, Control in ipairs( Config ) do
			Control:SetEnabled( Enabled );
		end
	end
	--- Sets the module's enabled checkbox and enables/disables all child controls.
	function ModuleMethods:SetEnabled ( Enabled )
		self.Enabled:SetChecked( Enabled );
		if ( self.Module.Registered ) then
			SetControlsEnabled( self, Enabled );
		end
	end
	--- Disables the module's configuration when it gets unregistered.
	function ModuleMethods:Unregister ()
		self.Enabled:SetEnabled( false );
		local Color = GRAY_FONT_COLOR;
		_G[ self:GetName().."Title" ]:SetTextColor( Color.r, Color.g, Color.b );

		SetControlsEnabled( self, false );
	end
end




--- Shows the control's tooltip.
function me:ControlOnEnter ()
	if ( self.tooltipText ) then
		GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT" );
		GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
	end
end
--- Standard checkbox control SetEnabled method.
function me:ModuleCheckboxSetEnabled ( Enable )
	( Enable and BlizzardOptionsPanel_CheckButton_Enable or BlizzardOptionsPanel_CheckButton_Disable )( self );
end
--- Standard slider control SetEnabled method.
function me:ModuleSliderSetEnabled ( Enable )
	( Enable and BlizzardOptionsPanel_Slider_Enable or BlizzardOptionsPanel_Slider_Disable )( self );
end

--- Sets the ShowAll option when its checkbox is clicked.
function me.ShowAll.setFunc ( Enable )
	Overlay.SetShowAll( Enable == "1" );
end

--- Toggles the module when its checkbox is clicked.
function me:ModuleEnabledOnClick ()
	local Enable = self:GetChecked() == 1;

	PlaySound( Enable and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff" );
	Overlay.Modules[ Enable and "Enable" or "Disable" ]( self:GetParent().Module.Name );
end
--- Sets a module's alpha setting when its slider gets adjusted.
function me:ModuleAlphaOnValueChanged ( Value )
	Overlay.Modules.SetAlpha( self:GetParent().Module.Name, Value );
end




do
	local LastFrame;
	--- Creates a config entry for a module with basic controls.
	-- @return Settings frame for module.
	function me.ModuleRegister ( Module, Label )
		local Frame = CreateFrame( "Frame", "_NPCScanOverlayModule"..Module.Name, me.ScrollChild, "OptionsBoxTemplate" );
		Frame.Module = Module;
		setmetatable( Frame, me.ModuleMeta );

		_G[ Frame:GetName().."Title" ]:SetText( Label );
		Frame:SetPoint( "RIGHT", me.ScrollChild:GetParent(), -4, 0 );
		if ( LastFrame ) then
			Frame:SetPoint( "TOPLEFT", LastFrame, "BOTTOMLEFT", 0, -16 );
		else
			Frame:SetPoint( "TOPLEFT", 4, -14 );
		end
		LastFrame = Frame;

		local Enabled = CreateFrame( "CheckButton", "$parentEnabled", Frame, "UICheckButtonTemplate" );
		Frame.Enabled = Enabled;
		Enabled:SetPoint( "TOPLEFT", 6, -6 );
		Enabled:SetSize( 26, 26 );
		Enabled:SetScript( "OnClick", me.ModuleEnabledOnClick );
		local Label = _G[ Enabled:GetName().."Text" ];
		Label:SetText( L.CONFIG_ENABLE );
		Enabled:SetHitRectInsets( 4, 4 - Label:GetStringWidth(), 4, 4 );
		Enabled.SetEnabled = me.ModuleCheckboxSetEnabled;

		local Alpha = CreateFrame( "Slider", "$parentAlpha", Frame, "OptionsSliderTemplate" );
		Frame.Alpha = Alpha;
		Alpha:SetPoint( "TOP", 0, -16 );
		Alpha:SetPoint( "RIGHT", -8, 0 );
		Alpha:SetPoint( "LEFT", Label, "RIGHT", 16, 0 );
		Alpha:SetMinMaxValues( 0, 1 );
		Alpha:SetScript( "OnValueChanged", me.ModuleAlphaOnValueChanged );
		Alpha.SetEnabled = me.ModuleSliderSetEnabled;
		local AlphaName = Alpha:GetName();
		_G[ AlphaName.."Text" ]:SetText( L.CONFIG_ALPHA );
		_G[ AlphaName.."Low" ]:Hide();
		_G[ AlphaName.."High" ]:Hide();
		Frame:AddControl( Alpha );

		Frame:SetHeight( Alpha:GetHeight() + 16 + 4 );
		return Frame;
	end
end


--- Reverts to default options.
function me:default ()
	Overlay.Synchronize();
end




local TableCreateBackup;
if ( IsChildAddOn ) then
	local Args = {};
	local select = select;
	--- Appends a value to a vararg list.
	local function Append ( NewValue, ... )
		local Count = select( "#", ... );
		for Index = 1, Count do
			Args[ Index ] = select( Index, ... );
		end
		for Index = Count + 1, #Args do
			Args[ Index ] = nil;
		end
		Args[ Count + 1 ] = NewValue;
		return unpack( Args, 1, Count + 1 );
	end

	local SetHeaderBackup;
	--- Hook to add a zone name column to the NPC table header.
	function me:TableSetHeader ( ... )
		return SetHeaderBackup( self, Append( L.CONFIG_ZONE, ... ) );
	end
	local SetSortHandlersBackup;
	--- Hook to set the added zone name column as sortable.
	function me:TableSetSortHandlers ( ... )
		return SetSortHandlersBackup( self, Append( true, ... ) ); -- Make map row sortable
	end
	local AddRowBackup;
	--- Hook to add zone names to the last column of NPC table rows.
	function me:TableAddRow ( ... )
		local Map = Overlay.NPCMaps[ select( 4, ... ) ]; -- Arg 4 is NpcID
		if ( Map ) then
			return AddRowBackup( self, Append( Overlay.GetZoneName( Map ) or Map, ... ) ); -- AreaID if on an instance map
		else
			return AddRowBackup( self, ... );
		end
	end
	--- Adds table hooks if CreateTable returns a new table.
	local function HookTable ( Table, ... )
		if ( Table ) then -- Just created
			SetHeaderBackup, Table.SetHeader = Table.SetHeader, me.TableSetHeader;
			SetSortHandlersBackup, Table.SetSortHandlers = Table.SetSortHandlers, me.TableSetSortHandlers;
			AddRowBackup, Table.AddRow = Table.AddRow, me.TableAddRow;
		end
		return Table, ...;
	end
	--- Hooks _NPCScan's NPC table to add a zone column when created.
	function me:TableCreate ( ... )
		return HookTable( TableCreateBackup( self, ... ) );
	end
end




--- Slash command chat handler to open the options pane.
function me.SlashCommand ()
	InterfaceOptionsFrame_OpenToCategory( me );
end




local Label = L[ IsChildAddOn and "CONFIG_TITLE" or "CONFIG_TITLE_STANDALONE" ];
me.name = Label;
me:Hide();

-- Pane title
me.Title = me:CreateFontString( nil, "ARTWORK", "GameFontNormalLarge" );
me.Title:SetPoint( "TOPLEFT", 16, -16 );
me.Title:SetText( Label );
local SubText = me:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
me.SubText = SubText;
SubText:SetPoint( "TOPLEFT", me.Title, "BOTTOMLEFT", 0, -8 );
SubText:SetPoint( "RIGHT", -32, 0 );
SubText:SetHeight( 32 );
SubText:SetJustifyH( "LEFT" );
SubText:SetJustifyV( "TOP" );
SubText:SetText( L.CONFIG_DESC );


me.ShowAll:SetPoint( "TOPLEFT", SubText, "BOTTOMLEFT", -2, -8 );
_G[ me.ShowAll:GetName().."Text" ]:SetText( L.CONFIG_SHOWALL );
me.ShowAll.tooltipText = L.CONFIG_SHOWALL_DESC;


-- Module options scrollframe
local Background = CreateFrame( "Frame", nil, me, "OptionsBoxTemplate" );
Background:SetPoint( "TOPLEFT", me.ShowAll, "BOTTOMLEFT", 0, -8 );
Background:SetPoint( "BOTTOMRIGHT", -32, 16 );
local Texture = Background:CreateTexture( nil, "BACKGROUND" );
Texture:SetTexture( 0, 0, 0, 0.5 );
Texture:SetPoint( "BOTTOMLEFT", 5, 5 );
Texture:SetPoint( "TOPRIGHT", -5, -5 );

local ScrollFrame = CreateFrame( "ScrollFrame", "_NPCScanOverlayScrollFrame", Background, "UIPanelScrollFrameTemplate" );
ScrollFrame:SetPoint( "TOPLEFT", 4, -4 );
ScrollFrame:SetPoint( "BOTTOMRIGHT", -4, 4 );

me.ScrollChild = CreateFrame( "Frame" );
ScrollFrame:SetScrollChild( me.ScrollChild );
me.ScrollChild:SetSize( 1, 1 );


if ( IsChildAddOn ) then
	Overlay.SafeCall( function ()
		me.parent = assert( _NPCScan.Config.name );
		TableCreateBackup = assert( _NPCScan.Config.Search.TableCreate );
		_NPCScan.Config.Search.TableCreate = me.TableCreate;
	end );
end
InterfaceOptions_AddCategory( me );

SlashCmdList[ "_NPCSCAN_OVERLAY" ] = me.SlashCommand;