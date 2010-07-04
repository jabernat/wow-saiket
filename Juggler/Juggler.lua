--[[****************************************************************************
  * Juggler by Saiket                                                          *
  * Juggler.lua - Lets you spam torches by spinning your mouse wheel.          *
  ****************************************************************************]]


local AddOnName, me = ...;
Juggler = me;
me.Button = CreateFrame( "Button", "JugglerButton", nil, "SecureActionButtonTemplate,ActionButtonTemplate" );
me.Bar = CreateFrame( "StatusBar", nil, me.Button );
me.Timer = CreateFrame( "Frame", nil, me.Bar );
me.Machine = me.NewStateMachine();


me.Item = "item:34599"; -- Juggling Torch
me.CriteriaID = 6937; -- Torch Juggler: Juggle 40 torches in 15 seconds in Dalaran.
me.Bindings = { -- Spammable bindings to override while active
	"MOUSEWHEELUP",
	"MOUSEWHEELDOWN",
};




--- Print a message to the default chat frame in a given color.
-- @param Message  Message to print.
-- @param Color  Color table to use for the message, or nil to use the normal font color.
function me.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( me.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
end




--- State to use an item and begin spell-targetting.
local Use = me.Machine:NewState();
me.Machine.Use = Use;
--- Overrides bindings to click the item button.
function Use:OnActivate ()
	for _, Binding in ipairs( me.Bindings ) do
		SetOverrideBindingClick( me.Button, nil, Binding, me.Button:GetName() );
	end
	me.Button:Enable();
end
--- Clears binding overrides.
function Use:OnDeactivate ()
	me.Button:Disable();
	ClearOverrideBindings( me.Button );
end


--- State to target the cursor's active spell on the ground.
local Target = me.Machine:NewState();
me.Machine.Target = Target;
--- Overrides bindings to right-click the game world.
function Target:OnActivate ()
	for _, Binding in ipairs( me.Bindings ) do
		SetOverrideBinding( me.Button, nil, Binding, "CAMERAORSELECTORMOVE" );
	end
end
-- Clears binding overrides.
function Target:OnDeactivate ()
	ClearOverrideBindings( me.Button );
end


--- Begins spell targetting immediately after using the item.
function me.Button:PostClick ()
	if ( Use:IsActive() ) then -- Just used item
		Target:Activate();
	end
end
--- Re-enables the item button after the last cast has been targetted.
function me.CameraOrSelectOrMoveStop ()
	if ( Target:IsActive() ) then -- Just targetted item
		Use:Activate();
	end
end




--- Updates the timer display.
function me.Timer:OnUpdate ( Elapsed )
	self.Remaining = self.Remaining - Elapsed;
	if ( self.Remaining <= 0 ) then
		self:Hide();
	else
		self.Label:SetFormattedText( me.L.TIMER_FORMAT, self.Remaining );
		local Percent = self.Remaining / self.Duration;
		local R, G;
		if ( Percent > 0.5 ) then
			R, G = ( 1 - Percent ) * 2, 1;
		else
			R, G = 1, Percent * 2;
		end
		self.Label:SetTextColor( R, G, 0 );
	end
end
--- Updates the timer display.
function me.Timer:SetTime ( Elapsed, Duration )
	local Remaining = Duration - Elapsed;
	if ( not self:IsShown()
		or abs( self.Remaining - Remaining ) > 1 -- Timer changed
	) then
		self:Show();
		self.Remaining = Remaining;
		self.Duration = Duration;
	end
end


do
	local GetAchievementCriteriaInfo = GetAchievementCriteriaInfo;
	--- Updates the progress bar's value at most once per frame.
	local function OnUpdate ( self )
		self:SetScript( "OnUpdate", nil );

		local _, _, Completed, Quantity, MaxQuantity, _, _, _, String = GetAchievementCriteriaInfo( me.CriteriaID );
		self:SetMinMaxValues( 0, MaxQuantity );
		self:SetValue( Quantity );
		if ( not Completed ) then
			self.Label:SetText( String );
			self:SetStatusBarColor( 0.6, 0.6, 0 );
		else
			self.Label:SetText( me.L.BAR_DONE );
			self:SetStatusBarColor( 0, 0.6, 0 );

			me.Timer:Hide();
			me.Timer:SetAlpha( 0 ); -- In case tracked timer fires later
			me.Button:UnregisterEvent( "CRITERIA_UPDATE" );
			me.Button:UnregisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
		end
	end
	function me.Bar:Update ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Displays a tooltip with instructions.
function me.Button:OnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT" );
	GameTooltip:SetText( me.L.BUTTON_DESC, nil, nil, nil, nil, 1 );
end
--- Enables and resets the state machine.
function me.Button:OnShow ()
	me.Print( me.L.ENABLED, GREEN_FONT_COLOR );
	me.Button:RegisterEvent( "BAG_UPDATE" );
	me.Button:RegisterEvent( "CRITERIA_UPDATE" );
	me.Button:RegisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
	me.Button:BAG_UPDATE(); -- Update immediately
	me.Button:CRITERIA_UPDATE();
	Use:Activate();
end
--- Disables the state machine to quit spamming items.
function me.Button:OnHide ()
	me.Machine:SetActiveState( nil );
	me.Timer:Hide();
	me.Button:UnregisterEvent( "BAG_UPDATE" );
	me.Button:UnregisterEvent( "CRITERIA_UPDATE" );
	me.Button:UnregisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
	me.Print( me.L.DISABLED );
end
--- Hides and disables itself when entering combat.
function me.Button:PLAYER_REGEN_DISABLED ()
	self:Hide();
end
--- Updates the progress bar's text when criteria update.
function me.Button:CRITERIA_UPDATE ()
	me.Bar:Update();
end
--- Updates the progress bar's text when criteria update.
function me.Button:TRACKED_ACHIEVEMENT_UPDATE ( _, _, CriteriaID, Elapsed, Duration )
	if ( CriteriaID == me.CriteriaID and Elapsed and Duration ) then
		if ( Elapsed >= Duration ) then -- Failed
			me.Timer:Hide();
		else
			me.Timer:SetTime( Elapsed, Duration );
		end
	end
end
do
	local GetItemCount = GetItemCount;
	--- Updates item count when bag contents change.
	function me.Button:BAG_UPDATE ()
		self.Count:SetText( GetItemCount( me.Item ) );
	end
end
--- Global event handler.
function me.Button:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end

--- Slash command to open or close the button.
function me.SlashCommand ()
	if ( InCombatLockdown() ) then
		me.Print( me.L.ERROR_COMBAT, RED_FONT_COLOR );
	elseif ( me.Button:IsShown() ) then
		me.Button:Hide();
	else
		me.Button:Show();
	end
end




local Button = me.Button;
tinsert( UISpecialFrames, Button:GetName() ); -- Allow escape to close it
Button:Hide();
Button:Disable();
Button:SetMotionScriptsWhileDisabled( true );
Button:SetFrameStrata( "TOOLTIP" );
Button:SetClampedToScreen( true );
Button:SetMovable( true );
Button:SetUserPlaced( true );
Button:SetPoint( "CENTER" );

local Name = Button:GetName();
_G[ Name.."Icon" ]:SetTexture( GetItemIcon( me.Item ) or [[Interface\Icons\INV_Misc_QuestionMark]] );
Button.Count = _G[ Name.."Count" ];

local Background = Button:CreateTexture( nil, "BACKGROUND" );
Background:SetTexture( 0, 0, 0, 0.75 );
Background:SetPoint( "TOPLEFT", Button, "TOPRIGHT" );
Background:SetPoint( "BOTTOM" );
Background:SetWidth( Button:GetWidth() * 3 );

local Drag = Button:CreateTitleRegion();
Drag:SetPoint( "TOPLEFT" );
Drag:SetPoint( "BOTTOMRIGHT", Background );
Button:SetHitRectInsets( 0, -Background:GetWidth(), 0, 0 ); -- Drag region must intersect with button's hit rect

local Close = CreateFrame( "Button", nil, Button, "UIPanelCloseButton" );
Close:SetPoint( "TOPRIGHT", Background, 4, 4 );
Close:SetScale( 0.8 );
Close:SetHitRectInsets( 8, 8, 8, 8 );

local Bar = me.Bar;
Bar:SetPoint( "BOTTOMLEFT", Background, 4, 4 );
Bar:SetPoint( "RIGHT", Background, -4, 0 );
Bar:SetPoint( "TOP", Background, "CENTER" );
Bar:SetStatusBarTexture( [[Interface\TargetingFrame\UI-StatusBar]] );

local BarLeft = Bar:CreateTexture( nil, "OVERLAY" );
BarLeft:SetTexture( [[Interface\AchievementFrame\UI-Achievement-ProgressBar-Border]] );
BarLeft:SetTexCoord( 0, 0.0625, 0, 0.75 );
BarLeft:SetPoint( "TOPLEFT", -6, 5 );
BarLeft:SetPoint( "BOTTOM", 0, -5 );
BarLeft:SetWidth( 16 );
local BarRight = Bar:CreateTexture( nil, "OVERLAY" );
BarRight:SetTexture( [[Interface\AchievementFrame\UI-Achievement-ProgressBar-Border]] );
BarRight:SetTexCoord( 0.812, 0.8745, 0, 0.75 );
BarRight:SetPoint( "TOPRIGHT", 6, 5 );
BarRight:SetPoint( "BOTTOM", 0, -5 );
BarRight:SetWidth( 16 );
local BarCenter = Bar:CreateTexture( nil, "OVERLAY" );
BarCenter:SetTexture( [[Interface\AchievementFrame\UI-Achievement-ProgressBar-Border]] );
BarCenter:SetTexCoord( 0.0625, 0.812, 0, 0.75 );
BarCenter:SetPoint( "TOPLEFT", BarLeft, "TOPRIGHT" );
BarCenter:SetPoint( "BOTTOMRIGHT", BarRight, "BOTTOMLEFT" );

Bar.Label = Bar:CreateFontString( nil, "ARTWORK", "GameFontHighlightSmall" );
Bar.Label:SetPoint( "TOPLEFT", 4, 0 );
Bar.Label:SetPoint( "BOTTOMRIGHT", -4, 0 );
Bar.Label:SetJustifyH( "RIGHT" );

local Timer = me.Timer;
Timer:Hide();
Timer:SetAllPoints( Bar );
Timer:SetScript( "OnUpdate", Timer.OnUpdate );
Timer.Label = Timer:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );
Timer.Label:SetPoint( "TOPLEFT", 4, 0 );
Timer.Label:SetPoint( "BOTTOMRIGHT", -4, 0 );
Timer.Label:SetJustifyH( "LEFT" );

local Title = Button:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );
Title:SetPoint( "TOPLEFT", Background );
Title:SetPoint( "RIGHT", Close, "LEFT", 8, 0 );
Title:SetPoint( "BOTTOM", Bar, "TOP" );
Title:SetText( me.L.BUTTON_TITLE );




Button:SetAttribute( "type", "item" );
Button:SetAttribute( "item", me.Item );

Button:SetScript( "PostClick", Button.PostClick );
hooksecurefunc( "CameraOrSelectOrMoveStop", me.CameraOrSelectOrMoveStop );

Button:SetScript( "OnEnter", Button.OnEnter );
Button:SetScript( "OnLeave", GameTooltip_Hide );
Button:SetScript( "OnShow", Button.OnShow );
Button:SetScript( "OnHide", Button.OnHide );
Button:SetScript( "OnEvent", Button.OnEvent );
Button:RegisterEvent( "PLAYER_REGEN_DISABLED" );


SlashCmdList[ "JUGGLER" ] = me.SlashCommand;