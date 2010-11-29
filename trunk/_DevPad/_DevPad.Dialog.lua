--[[****************************************************************************
  * _DevPad by Saiket                                                          *
  * _DevPad.Dialog.lua - Scrollable and resizable frame prototype.             *
  ****************************************************************************]]


local me = {};
select( 2, ... ).Dialog = me;

me.StickyFrames = {};

me.StuckColor = { 0.5, 0.5, 0.2 };

local StickTolerance = 16;




--- Builds a standard tooltip for a control.
function me:ControlOnEnter ()
	if ( self.tooltipText ) then
		GameTooltip:SetOwner( self, "ANCHOR_TOPRIGHT" );
		GameTooltip:SetText( self.tooltipText, nil, nil, nil, nil, 1 );
	end
end
--- @return A new standard button frame.
function me:NewButton ( Path )
	local Button = CreateFrame( "Button", nil, self );
	Button:SetSize( 16, 16 );
	Button:SetScript( "OnEnter", me.ControlOnEnter );
	Button:SetScript( "OnLeave", GameTooltip_Hide );

	Button:SetHighlightTexture( [[Interface\Buttons\UI-PlusButton-Hilight]] );
	Button:GetHighlightTexture():SetDesaturated( true );
	Button:SetNormalTexture( Path );
	Button:GetNormalTexture():SetVertexColor( 0.6, 0.6, 0.6 );
	Button:SetDisabledTexture( Path );
	local Disabled = Button:GetDisabledTexture();
	Disabled:SetDesaturated( true );
	Disabled:SetVertexColor( 0.5, 0.5, 0.5 );
	Button:SetPushedTexture( Path );
	local Pushed = Button:GetPushedTexture();
	Pushed:ClearAllPoints();
	Pushed:SetPoint( "TOPLEFT", 1, -1 );
	Pushed:SetPoint( "BOTTOMRIGHT", 1, -1 );
	return Button;
end


--- Starts resizing the frame.
function me:ResizeOnMouseDown ()
	self.Frame:StartSizing( "BOTTOMRIGHT" );
end
--- Stops resizing the frame.
function me:ResizeOnMouseUp ()
	local Frame = self.Frame;
	Frame:StopMovingOrSizing();
	-- Reattach if previously stuck
	FlyPaper.StickToPoint( Frame,
		me.StickyFrames[ Frame.StickTarget ], Frame.StickPoint )
end
--- Starts dragging the frame.
function me:OnMouseDown ()
	self:StartMoving();
	self:SetBackdropBorderColor( 1, 1, 1 );
end
--- Stops dragging the frame.
function me:OnMouseUp ()
	self:StopMovingOrSizing();
	-- Try to stick to other windows
	for Name, Frame in pairs( me.StickyFrames ) do
		if ( Frame ~= self and Frame:IsVisible() ) then
			local Point = FlyPaper.Stick( self, Frame, StickTolerance );
			if ( Point ) then
				self.StickTarget, self.StickPoint = Name, Point;
				self:SetBackdropBorderColor( unpack( me.StuckColor ) );
				return;
			end
		end
	end
	self.StickTarget, self.StickPoint = nil;
	self:SetBackdropBorderColor( 1, 1, 1 );
end

--- Updates clamp to allow dragging the frame mostly but not completely offscreen.
function me:OnSizeChanged ( Width, Height )
	self:SetClampRectInsets( Width - 32, 32 - Width, 32 - Height, Height - 32 );
end
--- Adds and adjusts scrollbars when necessary.
function me:ScrollFrameOnScrollRangeChanged ( XRange, YRange )
	local Bar = self.Bar;
	self:GetParent():EnableMouseWheel( YRange > 0 ); -- Enable only if scrollable

	if ( YRange > 0 ) then
		if ( not Bar:IsShown() ) then -- Show and position scrollbar
			Bar:Show();
			self:SetPoint( "RIGHT", -Bar:GetWidth(), 0 ); -- Note: Anchoring to bar causes slowdown while dragging
		end
		-- Setup scrollbar's range
		Bar:SetMinMaxValues( 0, YRange );
		Bar:SetValue( min( Bar:GetValue(), YRange ) );
	elseif ( Bar:IsShown() ) then
		Bar:SetValue( 0 ); -- Return to origin
		Bar:Hide();
		self:SetPoint( "RIGHT" );
	end
end
--- Synchronizes the scrollbar with the scroll range.
function me:ScrollFrameOnVerticalScroll ( Offset )
	return self.Bar:SetValue( Offset );
end
do
	--- Handler for scrollwheel and scroll button increment/decrement.
	local function BarIncrement ( Bar, Delta )
		Bar:SetValue( Bar:GetValue() + Delta * Bar:GetParent():GetHeight() / 2 );
	end
	--- Scrolls the view vertically with the mousewheel.
	function me:WindowOnMouseWheel ( Delta )
		BarIncrement( self:GetParent().ScrollFrame.Bar, -Delta );
	end
	--- Scrolls a bar when its button is clicked.
	function me:ScrollButtonOnClick ()
		PlaySound( "UChatScrollButton" );
		BarIncrement( self:GetParent(), self.Delta );
	end
end
--- Syncs view and scroll buttons when scrollbar moves.
function me:ScrollBarOnValueChanged ( Position )
	local Min, Max = self:GetMinMaxValues();
	self.Dec[ Position == Min and "Disable" or "Enable" ]( self.Dec );
	self.Inc[ Position == Max and "Disable" or "Enable" ]( self.Inc );
	return self.ScrollFrame:SetVerticalScroll( Position );
end


--- Saves position and size information for saved variables.
function me:Pack ()
	local Options, _ = {};
	Options.Width, Options.Height = self:GetSize();
	if ( self.StickTarget ) then
		Options.StickTarget, Options.StickPoint = self.StickTarget, self.StickPoint;
	else
		Options.Point, _, _, Options.X, Options.Y = self:GetPoint();
	end
	return Options;
end
--- Loads position and size from saved variables.
function me:Unpack ( Options )
	self:SetSize( Options.Width or self.DefaultWidth, Options.Height or self.DefaultHeight );
	if ( FlyPaper.StickToPoint( self,
		me.StickyFrames[ Options.StickTarget ], Options.StickPoint )
	) then
		self.StickTarget, self.StickPoint = Options.StickTarget, Options.StickPoint;
		self:SetBackdropBorderColor( unpack( me.StuckColor ) );
	else
		self:ClearAllPoints();
		self:SetPoint( Options.Point or "CENTER", nil, Options.Point or "CENTER", Options.X or 0, Options.Y or 0 );
		self:SetBackdropBorderColor( 1, 1, 1 );
	end
end




local ResizeTexture = [[Interface\AddOns\]]..( ... )..[[\Skin\ResizeGrip]];
--- @return A new frame.
function me:New ( Name )
	local Frame = CreateFrame( "Frame", Name, UIParent );
	Frame:Hide();
	Frame:SetScale( 0.9 );
	Frame:SetFrameStrata( "HIGH" );
	Frame:SetToplevel( true );
	Frame:SetBackdrop( {
		bgFile = [[Interface\TutorialFrame\TutorialFrameBackground]];
		edgeFile = [[Interface\TutorialFrame\TutorialFrameBorder]];
		tile = true; tileSize = 32; edgeSize = 32;
		insets = { left = 7; right = 5; top = 3; bottom = 6; };
	} );
	Frame:SetScript( "OnSizeChanged", me.OnSizeChanged );
	Frame.Pack, Frame.Unpack = self.Pack, self.Unpack;
	Frame.NewButton = self.NewButton;
	-- Make dragable
	Frame:EnableMouse( true );
	Frame:SetMovable( true );
	Frame:SetResizable( true );
	Frame:SetClampedToScreen( true );
	Frame:SetDontSavePosition( true );
	Frame:SetScript( "OnMouseDown", me.OnMouseDown );
	Frame:SetScript( "OnMouseUp", me.OnMouseUp );
	-- Close button
	Frame.Close = CreateFrame( "Button", nil, Frame, "UIPanelCloseButton" );
	Frame.Close:SetPoint( "TOPRIGHT", 4, 4 );
	-- Title
	Frame.Title = Frame:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
	Frame.Title:SetPoint( "TOPLEFT", 11, -6 );

	-- Bottom border
	local Bottom = CreateFrame( "Frame", nil, Frame );
	Frame.Bottom = Bottom;
	Bottom:SetPoint( "BOTTOMLEFT", 6, 3 );
	Bottom:SetPoint( "RIGHT", -2, 0 );
	Bottom:SetHeight( 8 );
	local Background = Bottom:CreateTexture( nil, "BORDER" );
	Background:SetAllPoints();
	Background:SetTexture( 0.4, 0.4, 0.4, 0.75 );

	-- Scroll window
	local Window = CreateFrame( "Frame", nil, Frame );
	Frame.Window = Window;
	Window:SetPoint( "TOPLEFT", 6, -24 );
	Window:SetPoint( "RIGHT", -2, 0 );
	Window:SetPoint( "BOTTOM", Bottom, "TOP" );
	Window:SetScript( "OnMouseWheel", me.WindowOnMouseWheel );
	Window:EnableMouseWheel( false );

	local ScrollFrame = CreateFrame( "ScrollFrame", nil, Window );
	Frame.ScrollFrame = ScrollFrame;
	ScrollFrame:SetPoint( "TOPLEFT" );
	ScrollFrame:SetPoint( "BOTTOM" );
	ScrollFrame:SetPoint( "RIGHT" ); -- Right anchor moved independently by scrollbar
	ScrollFrame:SetScript( "OnScrollRangeChanged", me.ScrollFrameOnScrollRangeChanged );
	ScrollFrame:SetScript( "OnVerticalScroll", me.ScrollFrameOnVerticalScroll );

	Frame.Background = ScrollFrame:CreateTexture( nil, "BACKGROUND" );
	Frame.Background:SetAllPoints();
	Frame.Background:SetTexture( 0.05, 0.05, 0.06 );

	-- Scrollbar
	local Bar = CreateFrame( "Slider", nil, ScrollFrame );
	ScrollFrame.Bar, Bar.ScrollFrame = Bar, ScrollFrame;
	Bar:Hide();

	local FrameLevel = Bar:GetFrameLevel();
	Bar.Dec = CreateFrame( "Button", nil, Bar, "UIPanelScrollUpButtonTemplate" );
	Bar.Dec:SetScript( "OnClick", me.ScrollButtonOnClick );
	Bar.Dec:SetPoint( "TOPRIGHT", Window );
	Bar.Dec:SetFrameLevel( FrameLevel );
	Bar.Dec.Delta = -1;
	Bar.Inc = CreateFrame( "Button", nil, Bar, "UIPanelScrollDownButtonTemplate" );
	Bar.Inc:SetScript( "OnClick", me.ScrollButtonOnClick );
	Bar.Inc:SetPoint( "BOTTOMRIGHT", Window );
	Bar.Inc:SetFrameLevel( FrameLevel );
	Bar.Inc.Delta = 1;

	Bar:SetThumbTexture( [[Interface\Buttons\UI-ScrollBar-Knob]] );
	local Thumb = Bar:GetThumbTexture();
	Thumb:SetSize( Bar.Dec:GetSize() );
	Thumb:SetTexCoord( 0.25, 0.75, 0.25, 0.75 ); -- Remove transparent border
	local Background = Bar:CreateTexture( nil, "BACKGROUND" );
	Background:SetTexture( 0, 0, 0, 0.5 );
	Background:SetAllPoints();

	Bar:SetPoint( "TOPRIGHT", Bar.Dec, "BOTTOMRIGHT" );
	Bar:SetPoint( "BOTTOMLEFT", Bar.Inc, "TOPLEFT" );
	Bar:SetScript( "OnValueChanged", me.ScrollBarOnValueChanged );

	-- Resize grip
	local Resize = CreateFrame( "Button", nil, ScrollFrame );
	Frame.Resize, Resize.Frame = Resize, Frame;
	Resize:SetSize( 30, 30 );
	Resize:SetPoint( "BOTTOMRIGHT", Frame, 6, -4 );
	Resize:SetHitRectInsets( 8, 8, 8, 8 );
	Resize:SetNormalTexture( ResizeTexture );
	Resize:SetHighlightTexture( ResizeTexture );
	Resize:SetScript( "OnMouseDown", me.ResizeOnMouseDown );
	Resize:SetScript( "OnMouseUp", me.ResizeOnMouseUp );

	return Frame;
end