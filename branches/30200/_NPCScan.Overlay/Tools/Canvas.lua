-- Canvas.lua: A simple window with draggable points to test tri rendering functions.

local me = _NPCScan.Overlay;
local Window = CreateFrame( "Frame", nil, UIParent );

Window.Title = Window:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
-- Set up window
Window:SetWidth( 200 );
Window:SetHeight( 200 );
Window:SetPoint( "CENTER" );
Window:SetFrameStrata( "DIALOG" );
Window:EnableMouse( true );
Window:SetToplevel( true );
Window:SetBackdrop( {
	bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
	edgeFile = "Interface\\TutorialFrame\\TutorialFrameBorder";
	tile = true; tileSize = 32; edgeSize = 32;
	insets = { left = 7; right = 5; top = 3; bottom = 6; };
} );
-- Make dragable
Window:SetMovable( true );
Window:SetUserPlaced( true );
Window:SetClampedToScreen( true );
Window:CreateTitleRegion():SetAllPoints();
-- Close button
CreateFrame( "Button", nil, Window, "UIPanelCloseButton" ):SetPoint( "TOPRIGHT", 4, 4 );
-- Title
Window.Title:SetText( "_NPCScan.Overlay Test" );
Window.Title:SetPoint( "TOPLEFT", Window, 11, -6 );




local Canvas = CreateFrame( "Frame", "Canvas", Window );
Canvas:SetPoint( "BOTTOMLEFT", 8, 6 );
Canvas:SetPoint( "RIGHT", -4, 0 );
Canvas:SetPoint( "TOP", Window.Title, "BOTTOM", 0, -6 );

local Buttons = {};

Canvas:SetScript( "OnUpdate", function ( self, Elapsed )
	if ( self.Changed ) then
		self.Changed = nil;

		me.PolygonRemoveAll( self );
		me.TextureDraw( me.TextureAdd( self ), Buttons.A.X, Buttons.A.Y, Buttons.B.X, Buttons.B.Y, Buttons.C.X, Buttons.C.Y );


		for Point, Button in pairs( Buttons ) do
			Button:SetPoint( "CENTER", self, "TOPLEFT", Button.X * self:GetWidth(), -Button.Y * self:GetHeight() );
		end
	end
end );

local function OnChange ()
	Canvas.Changed = true;
end
local function SetPoint( Point, X, Y )
	local Button = Buttons[ Point ];
	if ( Button.X ~= X or Button.Y ~= Y ) then
		Button.X = X;
		Button.Y = Y;
		OnChange();
		return true;
	end
end
local function ButtonOnUpdate ( self, Elapsed )
	local X, Y = GetCursorPosition();
	local Scale = Canvas:GetEffectiveScale();
	X = ( X / Scale - Canvas:GetLeft() ) / Canvas:GetWidth();
	Y = 1 - ( Y / Scale - Canvas:GetBottom() ) / Canvas:GetHeight();

	--SetPoint( self.Point, max( 0, min( 1, X ) ), max( 0, min( 1, Y ) ) );
	SetPoint( self.Point, X, Y );
end
local function ButtonOnMouseDown ( self )
	self:SetScript( "OnUpdate", ButtonOnUpdate );
	self:SetFrameLevel( self:GetFrameLevel() + 1 );
	local Color = GREEN_FONT_COLOR;
	self.Text:SetVertexColor( Color.r, Color.g, Color.b );
end
local function ButtonOnMouseUp ( self )
	self:SetScript( "OnUpdate", nil );
	self:SetFrameLevel( self:GetFrameLevel() - 1 );
	local Color = NORMAL_FONT_COLOR;
	self.Text:SetVertexColor( Color.r, Color.g, Color.b );
end
local function CreateButton ( Point, DefaultX, DefaultY )
	local Button = CreateFrame( "Button", nil, Canvas );
	Button.Point = Point;
	Buttons[ Point ] = Button;
	Button:SetWidth( 14 );
	Button:SetHeight( 14 );
	Button:SetScript( "OnMouseDown", ButtonOnMouseDown );
	Button:SetScript( "OnMouseUp", ButtonOnMouseUp );

	Button.Text = Button:CreateFontString( nil, "ARTWORK", "NumberFontNormalSmall" );
	Button:SetFontString( Button.Text );
	Button.Text:SetVertexColor( 1.0, 1.0, 0.1 );
	Button.Text:SetPoint( "CENTER" );
	Button:SetText( Point );
	Button.Icon = Button:CreateTexture( nil, "BORDER" );
	Button.Icon:SetAllPoints();
	Button.Icon:SetTexture( [[Interface\Buttons\UI-ColorPicker-Buttons]] );
	Button.Icon:SetTexCoord( 0, 0.15625, 0, 0.625 );

	SetPoint( Point, DefaultX, DefaultY );
end
CreateButton( "A", 0, 1 );
CreateButton( "B", 0, 0 );
CreateButton( "C", 1, 0 );

OnChange();
