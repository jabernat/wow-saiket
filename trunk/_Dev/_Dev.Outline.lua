--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Outline.lua - Outline a frame with bright transparent borders.        *
  ****************************************************************************]]


_DevOptions.Outline = {
	BorderAlpha = 0.75;
	BoundsThreshold = 10;
};


local _Dev = _Dev;
local L = _DevLocalization;
local NS = CreateFrame( "Frame" );
_Dev.Outline = NS;

NS.TemplateName = "_DevOutlineTemplate";
NS.UnusedOutlines = {}; -- Pool of unused outline frames
NS.Targets = {}; -- Keys are target frames, values are their outline frames
local Colors = { -- Random colors used for outlines
	GREEN_FONT_COLOR,
	RAID_CLASS_COLORS.WARLOCK,
	RAID_CLASS_COLORS.PRIEST,
	RAID_CLASS_COLORS.PALADIN,
	RAID_CLASS_COLORS.MAGE,
	RAID_CLASS_COLORS.ROGUE,
	RAID_CLASS_COLORS.DRUID,
	RAID_CLASS_COLORS.WARRIOR,
	RAID_CLASS_COLORS.HUNTER,
	RED_FONT_COLOR,
	GRAY_FONT_COLOR
};
NS.Colors = Colors;
NS.ColorIndex = 0;




--[[****************************************************************************
  * Function: _Dev.Outline:RemoveAll                                           *
  * Description: Remove existing borders from all frames and retuns the number *
  *   removed.                                                                 *
  ****************************************************************************]]
function NS:RemoveAll ()
	local Count = 0;
	for Region, OutlineFrame in pairs( self.Targets ) do
		OutlineFrame:Hide();
		OutlineFrame:ClearAllPoints();
		self.Targets[ Region ] = nil;
		self.UnusedOutlines[ OutlineFrame ] = true;
		if ( self.OnSetTarget ) then
			self.OnSetTarget( OutlineFrame, nil );
		end
		Count = Count + 1;
	end
	return Count;
end
--[[****************************************************************************
  * Function: _Dev.Outline:Remove                                              *
  * Description: Attempts to remove existing borders from the given frame and  *
  *   returns true if successful.                                              *
  ****************************************************************************]]
function NS:Remove ( Region )
	local OutlineFrame = self.Targets[ Region ];
	if ( OutlineFrame ) then
		OutlineFrame:Hide();
		OutlineFrame:ClearAllPoints();
		self.Targets[ Region ] = nil;
		self.UnusedOutlines[ OutlineFrame ] = true;
		if ( self.OnSetTarget ) then
			self.OnSetTarget( OutlineFrame, nil );
		end

		return true;
	end
end
--[[****************************************************************************
  * Function: _Dev.Outline:Add                                                 *
  * Description: Attempts to outline the given frame with a set of transparent *
  *   borders and returns true if successful.                                  *
  ****************************************************************************]]
function NS:Add ( Region )
	if ( self.Targets[ Region ] or not _Dev.IsUIObject( Region ) ) then
		return;
	end
	if ( Region.IsForbidden and Region:IsForbidden() ) then
		return; -- Cannot highlight forbidden frames
	end
	if ( not Region:IsObjectType( "Region" ) ) then
		return;
	end
	local OutlineFrame = next( self.UnusedOutlines ) or CreateFrame( "Frame", nil, self, self.TemplateName );

	self.Targets[ Region ] = OutlineFrame;
	self.UnusedOutlines[ OutlineFrame ] = nil;
	OutlineFrame:SetAllPoints( Region );
	if ( self.OnSetTarget ) then
		self.OnSetTarget( OutlineFrame, Region );
	end
	OutlineFrame:Show();

	return true;
end


--[[****************************************************************************
  * Function: _Dev.Outline:OnSetTarget                                         *
  * Description: Called for outlines when they are anchored to a target frame. *
  ****************************************************************************]]
function NS:OnSetTarget ( Target )
	if ( Target ) then
		self.NameText:SetText( Target:GetName() );
	end
end


--[[****************************************************************************
  * Function: _Dev.Outline:ArrowOnLoad                                         *
  * Description: Registers the new outline's arrow and initializes it.         *
  ****************************************************************************]]
function NS:ArrowOnLoad ()
	self:SetPosition( 0.0125, 0.0125, 0 );
	self:GetParent().Arrow = self;
end
--[[****************************************************************************
  * Function: _Dev.Outline:ArrowOnHide                                         *
  * Description: Resets the arrow flash animation for next show.               *
  ****************************************************************************]]
function NS:ArrowOnHide ()
	self:SetSequenceTime( 0, 0 );
end
--[[****************************************************************************
  * Function: _Dev.Outline:OutlineOnUpdate                                     *
  * Description: When the frame is off-screen, shows the arrow and points it   *
  *   at the frame.                                                            *
  ****************************************************************************]]
do
	local GetScreenHeight = GetScreenHeight;
	local GetScreenWidth = GetScreenWidth;
	local atan2 = math.atan2;
	local PI = math.pi;
	function NS:OutlineOnUpdate ()
		local CenterX2, CenterY2 = self:GetCenter();
		local Threshold = _DevOptions.Outline.BoundsThreshold;
		local Scale = UIParent:GetEffectiveScale();
		local Arrow = self.Arrow;

		if ( CenterX2 and (
			self:GetTop() < Threshold -- Off bottom
			or self:GetRight() < Threshold -- Off left
			or self:GetBottom() > GetScreenHeight() * Scale - Threshold
			or self:GetLeft() > GetScreenWidth() * Scale - Threshold
		) ) then
			local CenterX1, CenterY1 = Arrow:GetCenter();

			Arrow:SetFacing( atan2( CenterY2 - CenterY1, CenterX2 - CenterX1 ) - PI / 2 );
			Arrow:Show();
		else
			Arrow:Hide();
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Outline:OutlineOnLoad                                       *
  * Description: Registers the new outline and initializes it.                 *
  ****************************************************************************]]
function NS:OutlineOnLoad ()
	local Borders = { self:GetRegions() };
	self.Borders = Borders;
	-- Remove name text from borders list
	for Index, Region in ipairs( Borders ) do
		if ( Region:GetObjectType() == "FontString" ) then
			self.NameText = Region;
			tremove( Borders, Index );
			break;
		end
	end
	tinsert( Borders, self.Arrow:GetRegions() ); -- Add dot on arrow

	NS.ColorIndex = mod( NS.ColorIndex, #Colors ) + 1;
	NS.SetColor( self, Colors[ NS.ColorIndex ] );
end




--[[****************************************************************************
  * Function: _Dev.Outline:SetColor                                            *
  * Description: Set the color of the outline borders.                         *
  ****************************************************************************]]
function NS:SetColor ( Color )
	self.Color = Color;
	for _, Border in ipairs( self.Borders ) do
		Border:SetVertexColor( Color.r, Color.g, Color.b );
	end
	self.NameText:SetTextColor( Color.r, Color.g, Color.b );
end
--[[****************************************************************************
  * Function: _Dev.Outline.Update                                              *
  * Description: Syncs options with actual saved settings.                     *
  ****************************************************************************]]
function NS.Update ()
	NS:SetAlpha( _DevOptions.Outline.BorderAlpha );
end
--[[****************************************************************************
  * Function: _Dev.Outline:OnLoad                                              *
  * Description: Loads saved variables.                                        *
  ****************************************************************************]]
function NS:OnLoad ()
	self.Update();
end




--[[****************************************************************************
  * Function: _Dev.Outline.Toggle                                              *
  * Description: Simplified handler that prints status to the chat frame.      *
  ****************************************************************************]]
function NS.Toggle ( Region, DefaultName )
	if ( NS.Targets[ Region ] ) then
		if ( NS:Remove( Region ) ) then
			_Dev.Print( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_REMOVE_FORMAT:format( Region:GetName() or tostring( DefaultName ) ) ) );
			return true;
		end
	else -- Not already outlined
		if ( NS:Add( Region ) ) then
			-- Display the color of the added borders in the message
			local Color = NS.Targets[ Region ].Color;
			_Dev.Print( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_ADD_FORMAT:format(
				Color.r * 255 + 0.5, Color.g * 255 + 0.5, Color.b * 255 + 0.5,
				Region:GetName() or tostring( DefaultName ) ) ) );
			if ( Region:GetWidth() == 0 or Region:GetHeight() == 0 ) then
				_Dev.Error( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_INVALID_DIMENSIONS ), true );
			elseif ( not Region:GetLeft() or not Region:GetBottom() ) then
				_Dev.Error( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_INVALID_POSITION ), true );
			end
			return true;
		else
			_Dev.Error( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_INVALID ), true );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Outline.SlashCommand                                        *
  * Description: Slash command chat handler for the _Dev.Outline functions.    *
  ****************************************************************************]]
function NS.SlashCommand ( Input )
	if ( Input and not Input:find( "^%s*$" ) ) then
		local Success, Region = _Dev.Exec( Input );

		if ( not Success ) then
			_Dev.Error( L.OUTLINE_MESSAGE_FORMAT:format( tostring( Region ) ) );
		else
			NS.Toggle( Region, Input );
		end
	else
		_Dev.Print( L.OUTLINE_MESSAGE_FORMAT:format( L.OUTLINE_REMOVEALL_FORMAT:format( NS:RemoveAll() ) ) );
	end
end




NS:SetFrameStrata( "TOOLTIP" );
NS.Update();

outline = NS.Toggle;

SlashCmdList[ "_DEV_OUTLINE" ] = NS.SlashCommand;