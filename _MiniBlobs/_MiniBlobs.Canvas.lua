--[[****************************************************************************
  * _MiniBlobs by Saiket                                                       *
  * _MiniBlobs.Canvas.lua - Minimap canvas rendering logic.                    *
  ****************************************************************************]]


local _MiniBlobs = select( 2, ... );
if ( IsAddOnLoaded( "Carbonite" ) ) then
	return _MiniBlobs.Print( _MiniBlobs.L.CARBONITE_NOTICE, ORANGE_FONT_COLOR );
end


local me = CreateFrame( "Frame" );
_MiniBlobs.Canvas = me;
local BlobAnchor = CreateFrame( "Frame", nil, me );
me.BlobAnchor = BlobAnchor;

local UPDATE_INTERVAL = 1 / 25; -- Minimum time between repaints
local UPDATE_DISTANCE2 = 1 ^ 2; -- Minimum change in yards (squared) before the map will repaint

local ColumnSizeMax;
local BlobTypeData = {
	[ "Archaeology" ] = { ObjectType = "ArchaeologyDigSiteFrame"; };
	[ "Quests" ] = { ObjectType = "QuestPOIFrame"; };
};

local Minimap = Minimap;




local TypeEnabledQueue = {};
--- Prints a warning message if "Rotate Minimap" is enabled on login.
function me:PLAYER_LOGIN ()
	if ( GetCVarBool( "rotateMinimap" ) ) then
		_MiniBlobs.Print( _MiniBlobs.L.ROTATE_MINIMAP_NOTICE, ORANGE_FONT_COLOR );
	end
end
--- Removes the blobs in combat since they're protected.
function me:PLAYER_REGEN_DISABLED ()
	self:Hide();
	self:SetParent( nil ); -- Unprotect the minimap during combat
	self:ClearAllPoints();
	BlobAnchor:ClearAllPoints();
end
--- Shows the blobs after combat ends.
function me:PLAYER_REGEN_ENABLED ()
	self:SetParent( Minimap );
	self:SetFrameLevel( Minimap:GetFrameLevel() );
	self:SetAllPoints();
	-- Run settings changes that happened during combat
	for Type, Enabled in pairs( TypeEnabledQueue ) do
		TypeEnabledQueue[ Type ] = nil;
		self:MiniBlobs_TypeEnabled( nil, Type, Enabled );
	end
	return self:Show();
end

--- Re-draws blobs when the viewed map changes.
function me:WORLD_MAP_UPDATE ()
	return self:UpdateMap();
end
--- Re-draws archaeology blobs when they get added or removed.
function me:ARTIFACT_DIG_SITE_UPDATED ()
	return self:Update();
end
--- Re-draws quest blobs when they get added or removed.
function me:QUEST_POI_UPDATE ()
	return self:Update();
end
--- Hides completed quest blobs and updates blobs when objectives change.
function me:UNIT_QUEST_LOG_CHANGED ( _, UnitID )
	if ( UnitID == "player" ) then
		return self:Update();
	end
end
do
	--- Hook to force a repaint when a quest watch is added or removed.
	local function UpdateQuestsWatched ()
		if ( BlobTypeData[ "Quests" ].Enabled and _MiniBlobs:GetQuestsWatched() ) then
			return me:Update();
		end
	end
	hooksecurefunc( "AddQuestWatch", UpdateQuestsWatched );
	hooksecurefunc( "RemoveQuestWatch", UpdateQuestsWatched );
end
--- Hook to force a repaint when a watched quest is selected.
hooksecurefunc( "SetSuperTrackedQuestID", function ()
	if ( BlobTypeData[ "Quests" ].Enabled and _MiniBlobs:GetQuestsSelected() ) then
		return me:Update();
	end
end );
--- Force a repaint when the minimap swaps between indoor and outdoor zoom.
function me:MINIMAP_UPDATE_ZOOM ()
	local Zoom;
	if ( GetCVar( "minimapZoom" ) == GetCVar( "minimapInsideZoom" ) ) then -- Indeterminate case
		Zoom = Minimap:GetZoom();
		Minimap:SetZoom( Zoom > 0 and Zoom - 1 or Zoom + 1 ); -- Any change to make the cvars unequal
	end
	self.IsInside = Minimap:GetZoom() == GetCVar( "minimapInsideZoom" ) + 0;
	self.Radius = nil;
	if ( Zoom ) then -- Restore
		Minimap:SetZoom( Zoom );
	end
end
--- Hook to force a repaint when minimap zoom changes.
hooksecurefunc( Minimap, "SetZoom", function ()
	me.Radius = nil;
end );

--- Reposition blobs immediately after being shown.
function me:OnShow ()
	return self:Update();
end
--- Repositions blob slices when the minimap changes size.
function me:OnSizeChanged ()
	return self:UpdateClip();
end
--- Re-draws blobs when the minimap moves, since rendered blobs are static to the screen.
function me:OnPositionChanged ()
	return me:Update();
end




do
	--- Applies the given Quality value to this blob.
	local function UpdateQuality ( Blob, Quality )
		Blob:EnableSmoothing( Quality > 1e-3 ); -- Disable for values near 0
		Blob:SetNumSplinePoints( 8 + 22 * Quality ); -- Max points per polygon, between [8-30]
	end
	--- Adjusts the render quality of all blobs when settings change.
	function me:MiniBlobs_Quality ( _, Quality )
		for _, Column in ipairs( BlobAnchor ) do
			for Type in pairs( BlobTypeData ) do
				if ( Column[ Type ] ) then
					UpdateQuality( Column[ Type ], Quality );
				end
			end
		end

		ColumnSizeMax = 1 + ( 1 - Quality ) * 3; -- Columns will round towards this many pixels wide
		return self:UpdateClip();
	end
	--- Applies the given Style to this blob.
	local function UpdateBlobStyle ( Blob, Style )
		Blob:SetFillTexture( Style.Fill );
		Blob:SetBorderTexture( Style.Border );
		Blob:SetBorderScalar( Style.BorderScalar );
		Blob:SetBorderAlpha( 255 * Style.BorderAlpha );
	end
	--- Sets the alpha for a given blob type when settings change.
	function me:MiniBlobs_TypeStyle ( _, Type, StyleName, Style )
		for _, Column in ipairs( BlobAnchor ) do
			local Blob = Column[ Type ];
			if ( not Blob ) then
				return; -- This type isn't allocated
			end
			UpdateBlobStyle( Blob, Style );
		end
		if ( BlobTypeData[ Type ].Enabled ) then
			return self:Update();
		end
	end
	--- Applies the given fill alpha to this blob.
	local function UpdateBlobAlpha ( Blob, Alpha )
		return Blob:SetFillAlpha( 255 * Alpha );
	end
	--- Sets the alpha for a given blob type when settings change.
	function me:MiniBlobs_TypeAlpha ( _, Type, Alpha )
		for _, Column in ipairs( BlobAnchor ) do
			local Blob = Column[ Type ];
			if ( not Blob ) then
				return; -- This type isn't allocated
			end
			UpdateBlobAlpha( Blob, Alpha );
		end
		if ( BlobTypeData[ Type ].Enabled ) then
			return self:Update();
		end
	end
	--- Shows or hides blobs for this column to match settings.
	local function UpdateTypeEnabled ( Column, Type, Enabled )
		local Blob = Column[ Type ];
		if ( Enabled ) then
			if ( Blob ) then
				return Blob:Show();
			else
				-- Create and setup new blob
				Blob = CreateFrame( BlobTypeData[ Type ].ObjectType, nil, Column:GetScrollChild() );
				Column[ Type ] = Blob;
				Blob:SetAllPoints( BlobAnchor );

				UpdateQuality( Blob, _MiniBlobs:GetQuality( Type ) );
				UpdateBlobAlpha( Blob, _MiniBlobs:GetTypeAlpha( Type ) );
				return UpdateBlobStyle( Blob, _MiniBlobs.Styles[ _MiniBlobs:GetTypeStyle( Type ) ] );
			end
		elseif ( Blob ) then
			return Blob:Hide();
		end
	end
	--- Handler to setup tracking of this type's blob data.
	function BlobTypeData.Archaeology.OnEnable ()
		me:RegisterEvent( "ARTIFACT_DIG_SITE_UPDATED" );
	end
	function BlobTypeData.Archaeology.OnDisable ()
		me:UnregisterEvent( "ARTIFACT_DIG_SITE_UPDATED" );
	end
	function BlobTypeData.Quests.OnEnable ()
		me:RegisterEvent( "QUEST_POI_UPDATE" );
		me:RegisterEvent( "UNIT_QUEST_LOG_CHANGED" );
		_MiniBlobs.RegisterCallback( me, "MiniBlobs_QuestsWatched", "Update" );
		_MiniBlobs.RegisterCallback( me, "MiniBlobs_QuestsSelected", "Update" );
	end
	function BlobTypeData.Quests.OnDisable ()
		me:UnregisterEvent( "QUEST_POI_UPDATE" );
		me:UnregisterEvent( "UNIT_QUEST_LOG_CHANGED" );
		_MiniBlobs.UnregisterCallback( me, "MiniBlobs_QuestsWatched" );
		_MiniBlobs.UnregisterCallback( me, "MiniBlobs_QuestsSelected" );
	end
	--- Creates or hides blob frames when settings change.
	function me:MiniBlobs_TypeEnabled ( _, Type, Enabled )
		if ( InCombatLockdown() ) then -- Queue to update after combat
			TypeEnabledQueue[ Type ] = Enabled;
		else
			BlobTypeData[ Type ].Enabled = Enabled; -- Keep track of active enabled status separately
			BlobTypeData[ Type ][ Enabled and "OnEnable" or "OnDisable" ]();
			for _, Column in ipairs( BlobAnchor ) do
				UpdateTypeEnabled( Column, Type, Enabled );
			end
			return self:Update();
		end
	end
	--- @return An unused blob column at BlobAnchor[ Index ].
	function me:GetColumn ( Index )
		local Column = BlobAnchor[ Index ];
		if ( Column ) then
			Column:Show();
		else
			Column = CreateFrame( "ScrollFrame", nil, BlobAnchor );
			BlobAnchor[ Index ] = Column;
			Column:SetScrollChild( CreateFrame( "Frame" ) );
			-- Add enabled blobs
			for Type in pairs( BlobTypeData ) do
				UpdateTypeEnabled( Column, Type, BlobTypeData[ Type ].Enabled );
			end
		end
		return Column;
	end
end

local Shape;
do
	local ceil, sin, acos = math.ceil, math.sin, math.acos;
	--- Fills one side with blob slices clipped to the minimap.
	local function AddSide ( self, NumVisible, Offset, IsRounded )
		local Width, Height = self:GetSize();
		if ( IsRounded ) then
			-- Note: Too many columns (on large minimaps, i.e. Iriel's BigMinimap) dramatically reduces performance.
			-- Use the un-scaled size unless at max quality.
			local Scale = _MiniBlobs:GetQuality() < 0.999 and 1 or self:GetEffectiveScale();
			local ColumnsPerSide = ceil( Width * Scale / 2 / ColumnSizeMax );
			local ColumnWidth = Width / 2 / ColumnsPerSide;

			for Index = NumVisible + 1, NumVisible + ColumnsPerSide do
				local Column = self:GetColumn( Index );
				-- Find intersections with square or circular minimap corners
				local X = ( Offset + ColumnWidth / 2 ) / Width * 2 - 1;
				local Top = Shape[ X < 0 and 2 or 1 ] and sin( acos( X ) ) or 1;
				local Bottom = Shape[ X < 0 and 3 or 4 ] and -sin( acos( X ) ) or -1;
				Column:SetSize( ColumnWidth, ( Top - Bottom ) / 2 * Height );
				Column:SetPoint( "TOPLEFT", self, Offset, ( Top / 2 - 0.5 ) * Height );
				Offset = Offset + Column:GetWidth(); -- Avoids small gaps caused by floating point errors
			end
			return NumVisible + ColumnsPerSide, Offset;
		else -- Square side
			local Column = self:GetColumn( NumVisible + 1 )
			Column:SetSize( Width / 2, Height );
			Column:SetPoint( "TOPLEFT", self, Offset, 0 );
			return NumVisible + 1, Offset + Column:GetWidth();
		end
	end
	--- Sets up blob frames clipped to the minimap.
	function me:Clip ()
		local NumVisible = 0;
		-- Optimize number of columns used for square parts
		if ( Shape[ 1 ] or Shape[ 2 ] or Shape[ 3 ] or Shape[ 4 ] ) then
			local Offset = 0;
			NumVisible, Offset = AddSide( self, NumVisible, Offset, Shape[ 2 ] or Shape[ 3 ] );
			NumVisible, Offset = AddSide( self, NumVisible, Offset, Shape[ 1 ] or Shape[ 4 ] );
		else -- Square
			local Column = self:GetColumn( 1 );
			Column:SetSize( self:GetSize() );
			Column:SetPoint( "TOPLEFT", self );
			NumVisible = 1;
		end

		-- Hide unused columns
		for Index = NumVisible + 1, BlobAnchor.NumVisible or 0 do
			BlobAnchor[ Index ]:Hide();
		end
		BlobAnchor.NumVisible = NumVisible;
		return self:UpdateZoom();
	end
end

do
	-- Note: Must be parented to Frame so handlers run in the right order.
	local Updater, Width = CreateFrame( "Frame", nil, me ), 1;
	Updater:SetPoint( "TOPLEFT" );
	Updater:SetSize( Width, 1 );
	local pairs = pairs;
	--- Renders blobs after the layout engine is ready.
	-- Attempting to DrawBlob right after changing a blob's size will render using the previous size.
	-- This handler fires after OnUpdates but before the screen is painted.
	local function OnSizeChanged ( self )
		self:SetScript( "OnSizeChanged", nil );
		if ( BlobAnchor:IsVisible() ) then
			for Index = 1, BlobAnchor.NumVisible do
				for Type, TypeData in pairs( BlobTypeData ) do
					if ( BlobTypeData[ Type ].Enabled ) then
						local Blob = BlobAnchor[ Index ][ Type ];
						Blob:DrawNone();
						for Index = 1, #TypeData do
							Blob:DrawBlob( TypeData[ Index ], true );
						end
					end
				end
			end
		end
	end
	--- Repaints all blobs in their new locations.
	function me:DrawBlobs ()
		Updater:SetScript( "OnSizeChanged", OnSizeChanged );
		Width = Width % 2 + 1; -- 2,1,2,1
		return Updater:SetWidth( Width ); -- Force the handler to run
	end
end
--- Resizes blobs relative to the minimap's view.
function me:ResizeBlobs ()
	local Width, Height = self:GetSize();
	local Size = 2 * self.Radius;
	BlobAnchor:SetSize( self.ZoneWidth / Size * Width, self.ZoneHeight / Size * Height );
	return self:Update();
end




local UpdateForce;
--- Attempt to re-draw blobs before the next frame.
function me:Update ()
	UpdateForce = true;
end
--- Clip blobs to the minimap before the next frame.
function me:UpdateClip ()
	Shape = nil;
end
local UpdateZoom;
--- Updates the relative size of blobs before the next frame.
function me:UpdateZoom ()
	UpdateZoom = true;
end
local UpdateMap;
--- Updates the display when the viewed map changes.
function me:UpdateMap ()
	UpdateMap = true;
end


do
	local MINIMAP_SHAPES = { -- Credit to MobileMinimapButtons as seen at <http://www.wowpedia.com/GetMinimapShape>
		-- [ Shape ] = { Q1, Q2, Q3, Q4 }; where true = rounded and false = squared
		[ "ROUND" ]                 = {  true,  true,  true,  true };
		[ "SQUARE" ]                = { false, false, false, false };
		[ "CORNER-TOPRIGHT" ]       = {  true, false, false, false };
		[ "CORNER-TOPLEFT" ]        = { false,  true, false, false };
		[ "CORNER-BOTTOMLEFT" ]     = { false, false,  true, false };
		[ "CORNER-BOTTOMRIGHT" ]    = { false, false, false,  true };
		[ "SIDE-TOP" ]              = {  true,  true, false, false };
		[ "SIDE-LEFT" ]             = { false,  true,  true, false };
		[ "SIDE-BOTTOM" ]           = { false, false,  true,  true };
		[ "SIDE-RIGHT" ]            = {  true, false, false,  true };
		[ "TRICORNER-BOTTOMLEFT" ]  = { false,  true,  true,  true };
		[ "TRICORNER-BOTTOMRIGHT" ] = {  true, false,  true,  true };
		[ "TRICORNER-TOPRIGHT" ]    = {  true,  true, false,  true };
		[ "TRICORNER-TOPLEFT" ]     = {  true,  true,  true, false };
	};
	local RADII_INSIDE = { 150, 120, 90, 60, 40, 25 };
	local RADII_OUTSIDE = { 233 + 1 / 3, 200, 166 + 2 / 3, 133 + 1 / 3, 100, 66 + 2 / 3 };

	local ArchaeologyMapUpdateAll = ArchaeologyMapUpdateAll;
	local ArcheologyGetVisibleBlobID = ArcheologyGetVisibleBlobID;
	local GetCurrentMapZone = GetCurrentMapZone;
	local GetCVarBool = GetCVarBool;
	local GetPlayerMapPosition = GetPlayerMapPosition;
	local GetQuestLogTitle = GetQuestLogTitle;
	local IsQuestWatched = IsQuestWatched;
	local GetSuperTrackedQuestID = GetSuperTrackedQuestID;
	local QuestMapUpdateAllQuests = QuestMapUpdateAllQuests;
	local QuestPOIGetQuestIDByVisibleIndex = QuestPOIGetQuestIDByVisibleIndex;

	local HUGE = math.huge;
	local ShapeNew, X, Y, DigSiteCount, QuestCount;
	local QuestID, QuestIndex, IsComplete;
	local _, X1, Y1, X2, Y2, Width, Height;
	local LastX, LastY, YardsX, YardsY;
	local UpdateNext = 0;
	--- Repositions blob slices.
	function me:OnUpdate ( Elapsed )
		-- Re-clip if shape or size changes
		ShapeNew = MINIMAP_SHAPES[ GetMinimapShape and GetMinimapShape() ] or MINIMAP_SHAPES.ROUND;
		if ( Shape ~= ShapeNew ) then
			Shape = ShapeNew;
			self:Clip();
		end

		-- Re-draw if zoom changes
		if ( not self.Radius ) then
			self.Radius = ( self.IsInside and RADII_INSIDE or RADII_OUTSIDE )[ Minimap:GetZoom() + 1 ];
			self:UpdateZoom();
		end
		-- Cache zone size when map changes
		if ( UpdateMap ) then
			UpdateMap = nil;
			_, X1, Y1, X2, Y2 = GetCurrentMapZone();
			Width, Height = X1 and X1 - X2 or 0, Y1 and Y1 - Y2 or 0;
			if ( self.ZoneWidth ~= Width or self.ZoneHeight ~= Height ) then
				self.ZoneWidth, self.ZoneHeight = Width, Height;
				if ( Width ~= 0 and Height ~= 0 ) then
					self:UpdateZoom();
				end
			end
		end

		-- Limit refresh rate
		UpdateNext = UpdateNext - Elapsed;
		if ( UpdateNext > 0 and not ( UpdateForce or UpdateZoom ) ) then
			return;
		end
		UpdateNext = UPDATE_INTERVAL;

		-- Bail if we don't have enough information to position blobs
		X, Y = GetPlayerMapPosition( "player" );
		if ( ( X == 0 and Y == 0 )
			or self.ZoneWidth == 0 or self.ZoneHeight == 0
			or GetCVarBool( "rotateMinimap" ) -- Can't rotate a blob!
		) then
			UpdateForce = nil;
			LastX, LastY = HUGE, HUGE; -- When we can render blobs again, override distance check
			return BlobAnchor:Hide();
		end

		-- Bail if the player didn't move
		YardsX, YardsY = X * self.ZoneWidth, Y * self.ZoneHeight;
		if ( not ( UpdateForce or UpdateZoom )
			and ( YardsX - LastX ) ^ 2 + ( YardsY - LastY ) ^ 2 < UPDATE_DISTANCE2
		) then -- Didn't move far enough
			return;
		end

		-- Cache blob data IDs
		DigSiteCount, QuestCount = 0, 0;
		if ( BlobTypeData[ "Archaeology" ].Enabled ) then
			local BlobData = BlobTypeData[ "Archaeology" ];
			DigSiteCount = ArchaeologyMapUpdateAll();
			for Index = 1, DigSiteCount do
				BlobData[ Index ] = ArcheologyGetVisibleBlobID( Index );
			end
			for Index = DigSiteCount + 1, #BlobData do
				BlobData[ Index ] = nil;
			end
		end
		if ( BlobTypeData[ "Quests" ].Enabled ) then
			local BlobData = BlobTypeData[ "Quests" ];
			local WatchedOnly = _MiniBlobs:GetQuestsWatched();
			local SelectedOnly = _MiniBlobs:GetQuestsSelected();
			for Index = 1, QuestMapUpdateAllQuests() do
				QuestID, QuestIndex = QuestPOIGetQuestIDByVisibleIndex( Index );
				if ( ( not WatchedOnly or IsQuestWatched( QuestIndex ) )
					and ( not SelectedOnly or QuestID == GetSuperTrackedQuestID() )
				) then
					_, _, _, _, _, _, IsComplete = GetQuestLogTitle( QuestIndex );
					if ( not IsComplete ) then
						QuestCount = QuestCount + 1;
						BlobData[ QuestCount ] = QuestID;
					end
				end
			end
			for Index = QuestCount + 1, #BlobData do
				BlobData[ Index ] = nil;
			end
		end
		if ( DigSiteCount + QuestCount == 0 ) then
			return BlobAnchor:Hide();
		end

		-- Rescale blobs based on zoom and zone size
		if ( UpdateZoom ) then
			UpdateZoom = nil;
			self:ResizeBlobs();
		end

		-- Reposition all of the blobs
		UpdateForce = nil;
		LastX, LastY = YardsX, YardsY;
		BlobAnchor:SetPoint( "TOPLEFT", Minimap, "CENTER",
			-X * BlobAnchor:GetWidth(), Y * BlobAnchor:GetHeight() );
		BlobAnchor:Show();
		return self:DrawBlobs(); -- Re-paints blobs at their new positions
	end
end




me:Hide();
me:SetScript( "OnUpdate", me.OnUpdate );
me:SetScript( "OnSizeChanged", me.OnSizeChanged );
me:SetScript( "OnShow", me.OnShow );
me:SetScript( "OnEvent", _MiniBlobs.Frame.OnEvent );
me:RegisterEvent( "PLAYER_LOGIN" );
me:RegisterEvent( "PLAYER_REGEN_ENABLED" );
me:RegisterEvent( "PLAYER_REGEN_DISABLED" );
me:RegisterEvent( "WORLD_MAP_UPDATE" );
me:RegisterEvent( "MINIMAP_UPDATE_ZOOM" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_Quality" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeEnabled" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeAlpha" );
_MiniBlobs.RegisterCallback( me, "MiniBlobs_TypeStyle" );

-- Raise round minimap border over top of the overlays to hide jagged edges
local Level = Minimap:GetFrameLevel() + 3; -- Leave room for scrollframes and blobs
if ( MinimapBackdrop:GetFrameLevel() < Level ) then
	MinimapBackdrop:SetFrameLevel( Level );
end

-- Makeshift "OnPositionChanged" handler
local BottomLeft = CreateFrame( "Frame", nil, me );
BottomLeft:SetPoint( "BOTTOMLEFT", nil );
BottomLeft:SetPoint( "TOPRIGHT", me, "BOTTOMLEFT" );
BottomLeft:SetScript( "OnSizeChanged", me.OnPositionChanged );

if ( IsLoggedIn() ) then
	me:PLAYER_LOGIN();
end
if ( not InCombatLockdown() ) then
	me:PLAYER_REGEN_ENABLED(); -- Show
end
me:WORLD_MAP_UPDATE();