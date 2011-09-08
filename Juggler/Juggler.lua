--[[****************************************************************************
  * Juggler by Saiket                                                          *
  * Juggler.lua - Lets you spam torches by spinning your mouse wheel.          *
  ****************************************************************************]]


local AddOnName, NS = ...;
Juggler = NS;
NS.Button = CreateFrame( "Button", "JugglerButton", nil, "SecureActionButtonTemplate,ActionButtonTemplate" );
NS.Bar = CreateFrame( "StatusBar", nil, NS.Button );
NS.Timer = CreateFrame( "Frame", nil, NS.Bar );
NS.Machine = NS.NewStateMachine();


NS.Item = "item:34599"; -- Juggling Torch
NS.CriteriaID = 6937; -- Torch Juggler: Juggle 40 torches in 15 seconds in Dalaran.
NS.Bindings = { -- Spammable bindings to override while active
	"MOUSEWHEELUP",
	"MOUSEWHEELDOWN",
};




--- Print a message to the default chat frame in a given color.
-- @param Message  Message to print.
-- @param Color  Color table to use for the message, or nil to use the normal font color.
function NS.Print ( Message, Color )
	if ( not Color ) then
		Color = NORMAL_FONT_COLOR;
	end
	DEFAULT_CHAT_FRAME:AddMessage( NS.L.PRINT_FORMAT:format( Message ), Color.r, Color.g, Color.b );
end




--- State to use an item and begin spell-targetting.
local Use = NS.Machine:NewState();
NS.Machine.Use = Use;
--- Overrides bindings to click the item button.
function Use:OnActivate ()
	for _, Binding in ipairs( NS.Bindings ) do
		SetOverrideBindingClick( NS.Button, nil, Binding, NS.Button:GetName() );
	end
	NS.Button:Enable();
end
--- Clears binding overrides.
function Use:OnDeactivate ()
	NS.Button:Disable();
	ClearOverrideBindings( NS.Button );
end


--- State to target the cursor's active spell on the ground.
local Target = NS.Machine:NewState();
NS.Machine.Target = Target;
--- Overrides bindings to right-click the game world.
function Target:OnActivate ()
	for _, Binding in ipairs( NS.Bindings ) do
		SetOverrideBinding( NS.Button, nil, Binding, "CAMERAORSELECTORMOVE" );
	end
end
-- Clears binding overrides.
function Target:OnDeactivate ()
	ClearOverrideBindings( NS.Button );
end


--- Begins spell targetting immediately after using the item.
function NS.Button:PostClick ()
	if ( Use:IsActive() ) then -- Just used item
		Target:Activate();
	end
end
--- Re-enables the item button after the last cast has been targetted.
function NS.CameraOrSelectOrMoveStop ()
	if ( Target:IsActive() ) then -- Just targetted item
		Use:Activate();
	end
end




--- Updates the timer display.
function NS.Timer:OnUpdate ( Elapsed )
	self.Remaining = self.Remaining - Elapsed;
	if ( self.Remaining <= 0 ) then
		self:Hide();
	else
		self.Label:SetFormattedText( NS.L.TIMER_FORMAT, self.Remaining );
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
function NS.Timer:SetTime ( Elapsed, Duration )
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

		local _, _, Completed, Quantity, MaxQuantity, _, _, _, String = GetAchievementCriteriaInfo( NS.CriteriaID );
		self:SetMinMaxValues( 0, MaxQuantity );
		self:SetValue( Quantity );
		if ( not Completed ) then
			self.Label:SetText( String );
			self:SetStatusBarColor( 0.6, 0.6, 0 );
		else
			self.Label:SetText( NS.L.BAR_DONE );
			self:SetStatusBarColor( 0, 0.6, 0 );

			NS.Timer:Hide();
			NS.Timer:SetAlpha( 0 ); -- In case tracked timer fires later
			NS.Button:UnregisterEvent( "CRITERIA_UPDATE" );
			NS.Button:UnregisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
		end
	end
	function NS.Bar:Update ()
		self:SetScript( "OnUpdate", OnUpdate );
	end
end


--- Displays a tooltip with instructions.
function NS.Button:OnEnter ()
	GameTooltip:SetOwner( self, "ANCHOR_TOPLEFT" );
	GameTooltip:SetText( NS.L.BUTTON_DESC, nil, nil, nil, nil, 1 );
end
--- Enables and resets the state machine.
function NS.Button:OnShow ()
	NS.Print( NS.L.ENABLED, GREEN_FONT_COLOR );
	NS.Button:RegisterEvent( "BAG_UPDATE" );
	NS.Button:RegisterEvent( "CRITERIA_UPDATE" );
	NS.Button:RegisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
	NS.Button:BAG_UPDATE(); -- Update immediately
	NS.Button:CRITERIA_UPDATE();
	Use:Activate();
end
--- Disables the state machine to quit spamming items.
function NS.Button:OnHide ()
	NS.Machine:SetActiveState( nil );
	NS.Timer:Hide();
	NS.Button:UnregisterEvent( "BAG_UPDATE" );
	NS.Button:UnregisterEvent( "CRITERIA_UPDATE" );
	NS.Button:UnregisterEvent( "TRACKED_ACHIEVEMENT_UPDATE" );
	NS.Print( NS.L.DISABLED );
end
--- Hides and disables itself when entering combat.
function NS.Button:PLAYER_REGEN_DISABLED ()
	self:Hide();
end
--- Updates the progress bar's text when criteria update.
function NS.Button:CRITERIA_UPDATE ()
	NS.Bar:Update();
end
--- Updates the progress bar's text when criteria update.
function NS.Button:TRACKED_ACHIEVEMENT_UPDATE ( _, _, CriteriaID, Elapsed, Duration )
	if ( CriteriaID == NS.CriteriaID and Elapsed and Duration ) then
		if ( Elapsed >= Duration ) then -- Failed
			NS.Timer:Hide();
		else
			NS.Timer:SetTime( Elapsed, Duration );
		end
	end
end
do
	local GetItemCount = GetItemCount;
	--- Updates item count when bag contents change.
	function NS.Button:BAG_UPDATE ()
		self.Count:SetText( GetItemCount( NS.Item ) );
	end
end
--- Global event handler.
function NS.Button:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end

--- Slash command to open or close the button.
function NS.SlashCommand ()
	if ( InCombatLockdown() ) then
		NS.Print( NS.L.ERROR_COMBAT, RED_FONT_COLOR );
	elseif ( NS.Button:IsShown() ) then
		NS.Button:Hide();
	else
		NS.Button:Show();
	end
end




local Button = NS.Button;
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
_G[ Name.."Icon" ]:SetTexture( GetItemIcon( NS.Item ) or [[Interface\Icons\INV_Misc_QuestionMark]] );
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

local Bar = NS.Bar;
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

local Timer = NS.Timer;
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
Title:SetText( NS.L.BUTTON_TITLE );




Button:SetAttribute( "type", "item" );
Button:SetAttribute( "item", NS.Item );

Button:SetScript( "PostClick", Button.PostClick );
hooksecurefunc( "CameraOrSelectOrMoveStop", NS.CameraOrSelectOrMoveStop );

Button:SetScript( "OnEnter", Button.OnEnter );
Button:SetScript( "OnLeave", GameTooltip_Hide );
Button:SetScript( "OnShow", Button.OnShow );
Button:SetScript( "OnHide", Button.OnHide );
Button:SetScript( "OnEvent", Button.OnEvent );
Button:RegisterEvent( "PLAYER_REGEN_DISABLED" );


SlashCmdList[ "JUGGLER" ] = NS.SlashCommand;