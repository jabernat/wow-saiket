--[[****************************************************************************
  * _VirtualPlates by Saiket                                                   *
  * _VirtualPlates.lua - Adds depth to the default nameplate frames.           *
  ****************************************************************************]]


local AddOnName, me = ...;
_VirtualPlates = me;
me.Frame = CreateFrame( "Frame", nil, WorldFrame );

me.Version = GetAddOnMetadata( AddOnName, "Version" ):match( "^([%d.]+)" );

local Plates = {};
me.Plates = Plates;
local PlatesVisible = {};
me.PlatesVisible = PlatesVisible;


me.OptionsCharacter = {
	Version = me.Version;
};
me.OptionsCharacterDefault = {
	Version = me.Version;
	MinScale = 0;
	MaxScale = 3;
	MaxScaleEnabled = false;
	ScaleFactor = 10;
};


me.CameraClip = 4; -- Yards from camera when nameplates begin fading out
me.PlateLevels = 3; -- Frame level difference between plates so one plate's children don't overlap the next closest plate
me.UpdateRate = 0; -- Minimum time between plates are rescaled.


local InCombat = false;
local NextUpdate = 0;
local PlateOverrides = {}; -- [ MethodName ] = Function overrides for Visuals




-- Individual plate methods
do
	--- If an anchor ataches to the original plate (by WoW), re-anchor to the Visual.
	local function ResetPoint ( Plate, Region, Point, RelFrame, ... )
		if ( RelFrame == Plate ) then
			Region:SetPoint( Point, Plates[ Plate ], ... );
		end
	end

	--- Re-anchors regions when a plate is shown.
	-- WoW re-anchors most regions when it shows a nameplate, so restore those anchors to the Visual frame.
	function me:PlateOnShow ()
		NextUpdate = 0; -- Resize instantly
		local Visual = Plates[ self ];
		PlatesVisible[ self ] = Visual;
		Visual:Show();

		-- Reposition all regions
		for Index, Region in ipairs( self ) do
			for Point = 1, Region:GetNumPoints() do
				ResetPoint( self, Region, Region:GetPoint( Point ) );
			end
		end
	end
end
--- Removes the plate from the visible list when hidden.
function me:PlateOnHide ()
	PlatesVisible[ self ] = nil;
	Plates[ self ]:Hide(); -- Explicitly hide so IsShown returns false.
end




-- Main plate handling and updating
do
	local WorldFrameGetChildren = WorldFrame.GetChildren;
	local select = select;
	do
		local PlatesUpdate;
		do
			local SortOrder, Depths = {}, {};
			--- Subroutine for table.sort to depth-sort plate visuals.
			local function SortFunc ( PlateA, PlateB )
				return Depths[ PlateA ] > Depths[ PlateB ];
			end

			local SetAlpha = me.Frame.SetAlpha; -- Must backup since plate SetAlpha methods are overridden
			local SetFrameLevel = me.Frame.SetFrameLevel;
			local SetScale = me.Frame.SetScale;
			local sort, wipe = sort, wipe;
			local ipairs = ipairs;

			local Depth, Visual, Scale;
			local MinScale, MaxScale, ScaleFactor;
			--- Sorts, scales, and fades all nameplates based on depth.
			function PlatesUpdate ()
				for Plate, Visual in pairs( PlatesVisible ) do
					Depth = Visual:GetEffectiveDepth(); -- Note: Depth of the actual plate is blacklisted, so use child Visual instead
					if ( Depth <= 0 ) then -- Too close to camera; Completely hidden
						SetAlpha( Visual, 0 );
					else
						SortOrder[ #SortOrder + 1 ] = Plate;
						Depths[ Plate ] = Depth;
					end
				end

				if ( #SortOrder > 0 ) then
					MinScale, MaxScale = me.OptionsCharacter.MinScale, me.OptionsCharacter.MaxScaleEnabled and me.OptionsCharacter.MaxScale;
					ScaleFactor = me.OptionsCharacter.ScaleFactor;

					sort( SortOrder, SortFunc );
					for Index, Plate in ipairs( SortOrder ) do
						Depth, Visual = Depths[ Plate ], Plates[ Plate ];

						if ( Depth < me.CameraClip ) then -- Begin fading as nameplate passes behind screen
							SetAlpha( Visual, Depth / me.CameraClip );
						else
							SetAlpha( Visual, 1 );
						end

						SetFrameLevel( Visual, Index * me.PlateLevels );

						Scale = ScaleFactor / Depth;
						if ( Scale < MinScale ) then
							Scale = MinScale;
						elseif ( MaxScale and Scale > MaxScale ) then
							Scale = MaxScale;
						end
						SetScale( Visual, Scale );
						if ( not InCombat ) then
							local Width, Height = Visual:GetSize();
							Plate:SetSize( Width * Scale, Height * Scale );
						end
					end
					wipe( SortOrder );
				end
			end
		end

		--- Parents all plate children to the Visual, and saves references to them in the plate.
		-- @param Plate  Original nameplate children are being removed from.
		-- @param ...  Children of Plate to be reparented.
		local function ReparentChildren ( Plate, ... )
			local Visual = Plates[ Plate ];
			for Index = 1, select( "#", ... ) do
				local Child = select( Index, ... );
				if ( Child ~= Visual ) then
					local LevelOffset = Child:GetFrameLevel() - Plate:GetFrameLevel();
					Child:SetParent( Visual );
					Child:SetFrameLevel( Visual:GetFrameLevel() + LevelOffset ); -- Maintain relative frame levels
					Plate[ #Plate + 1 ] = Child;
				end
			end
		end
		--- Parents all plate regions to the Visual, similar to ReparentChildren.
		-- @see ReparentChildren
		local function ReparentRegions ( Plate, ... )
			local Visual = Plates[ Plate ];
			for Index = 1, select( "#", ... ) do
				local Region = select( Index, ... );
				Region:SetParent( Visual );
				Plate[ #Plate + 1 ] = Region;
			end
		end

		--- Adds and skins a new nameplate.
		-- @param Plate  Newly found default nameplate to be hooked.
		local function PlateAdd ( Plate )
			local Visual = CreateFrame( "Frame", nil, Plate );
			Plates[ Plate ] = Visual;

			Visual:Hide(); -- Gets explicitly shown on plate show
			Visual:SetPoint( "TOP" );
			Visual:SetSize( Plate:GetSize() );

			ReparentChildren( Plate, Plate:GetChildren() );
			ReparentRegions( Plate, Plate:GetRegions() );
			Visual:EnableDrawLayer( "HIGHLIGHT" ); -- Allows the highlight to show without enabling mouse events

			Plate:SetScript( "OnShow", me.PlateOnShow );
			Plate:SetScript( "OnHide", me.PlateOnHide );
			if ( Plate:IsVisible() ) then
				me.PlateOnShow( Plate );
			end

			-- Hook methods
			for Key, Value in pairs( PlateOverrides ) do
				Visual[ Key ] = Value;
			end

			-- Force recalculation of effective depth for all child frames
			local Depth = WorldFrame:GetDepth();
			WorldFrame:SetDepth( Depth + 1 );
			WorldFrame:SetDepth( Depth );
		end

		--- Scans children of WorldFrame and handles new nameplates.
		-- @param ...  Children of the WorldFrame.
		local function PlatesScan ( ... )
			for Index = 1, select( "#", ... ) do
				local Frame = select( Index, ... );
				if ( not Plates[ Frame ] ) then
					local Region = Frame:GetRegions();
					if ( Region and Region:GetObjectType() == "Texture" and Region:GetTexture() == [[Interface\TargetingFrame\UI-TargetingFrame-Flash]] ) then
						PlateAdd( Frame );
					end
				end
			end
		end

		local ChildCount, NewChildCount = 0;
		--- Adds new nameplates and updates the depth of found ones every frame.
		function me:WorldFrameOnUpdate ( Elapsed )
			-- Check for new nameplates
			NewChildCount = self:GetNumChildren();
			if ( ChildCount ~= NewChildCount ) then
				ChildCount = NewChildCount;

				PlatesScan( WorldFrameGetChildren( self ) );
			end

			-- Apply depth to found plates
			NextUpdate = NextUpdate - Elapsed;
			if ( NextUpdate <= 0 ) then
				NextUpdate = me.UpdateRate;
				return PlatesUpdate();
			end
		end
	end

	local unpack = unpack;
	local Children = {};
	--- Filters the results of WorldFrame:GetChildren to replace plates with their visuals.
	local function ReplaceChildren ( ... )
		local Count = select( "#", ... );
		for Index = 1, Count do
			local Frame = select( Index, ... );
			Children[ Index ] = Plates[ Frame ] or Frame;
		end
		for Index = Count + 1, #Children do -- Remove any extras from the last call
			Children[ Index ] = nil;
		end
		return unpack( Children );
	end
	--- Returns Visual frames in place of real nameplates.
	-- @return The results of WorldFrame:GetChildren with any reference to a plate replaced with its visual.
	function WorldFrame:GetChildren ( ... )
		return ReplaceChildren( WorldFrameGetChildren( self, ... ) );
	end
end




--- Initializes settings once loaded.
function me.Frame:ADDON_LOADED ( Event, AddOn )
	if ( AddOn == AddOnName ) then
		self:UnregisterEvent( Event );
		self[ Event ] = nil;

		local OptionsCharacter = _VirtualPlatesOptionsCharacter;
		_VirtualPlatesOptionsCharacter = me.OptionsCharacter;

		if ( OptionsCharacter and OptionsCharacter.Version ~= me.Version ) then -- Update settings of old versions
			local Version = OptionsCharacter.Version;
			if ( Version == "3.2.2.1" or Version == "3.2.2.2" or Version == "3.2.2.3" ) then
				Version = "3.2.2.4"; -- Added max scale option
				OptionsCharacter.MaxScale = 3;
				OptionsCharacter.MaxScaleEnabled = false;
			end
			if ( Version == "3.2.2.4" or Version == "3.2.2.5" or Version == "3.3.0.1" ) then
				Version = "3.3.5.1"; -- Removed support for LibCamera-1.0 and variable ScaleFactors
				OptionsCharacter.ScaleFactor = OptionsCharacter.ScaleFactor1;
			end
			OptionsCharacter.Version = me.Version;
		end

		me.Synchronize( OptionsCharacter ); -- Loads defaults if either are nil
	end
end
--- Caches in-combat status when leaving combat.
function me.Frame:PLAYER_REGEN_ENABLED ()
	InCombat = false;
end
--- Restores plates to their real size before entering combat.
function me.Frame:PLAYER_REGEN_DISABLED ()
	InCombat = true;

	for Plate, Visual in pairs( Plates ) do
		Plate:SetSize( Visual:GetSize() );
	end
end
--- Global event handler.
function me.Frame:OnEvent ( Event, ... )
	if ( self[ Event ] ) then
		return self[ Event ]( self, Event, ... );
	end
end




--- Sets the minimum scale plates will be shrunk to.
-- @param Value  New mimimum scale to use.
-- @return True if setting changed.
function me.SetMinScale ( Value )
	if ( Value ~= me.OptionsCharacter.MinScale ) then
		me.OptionsCharacter.MinScale = Value;

		me.Config.MinScale:SetValue( Value );
		return true;
	end
end
--- Sets the maximum scale plates will grow to.
-- @param Value  New maximum scale to use.
-- @return True if setting changed.
function me.SetMaxScale ( Value )
	if ( Value ~= me.OptionsCharacter.MaxScale ) then
		me.OptionsCharacter.MaxScale = Value;

		me.Config.MaxScale:SetValue( Value );
		return true;
	end
end
--- Enables clamping nameplates to a maximum scale.
-- @param Enable  Boolean to allow using the MaxScale setting.
-- @return True if setting changed.
function me.SetMaxScaleEnabled ( Enable )
	if ( Enable ~= me.OptionsCharacter.MaxScaleEnabled ) then
		me.OptionsCharacter.MaxScaleEnabled = Enable;

		me.Config.MaxScaleEnabled:SetChecked( Enable );
		me.Config.MaxScaleEnabled.setFunc( Enable and "1" or "0" );
		return true;
	end
end
--- Sets the scale factor apply to plates.
-- @param Value  When nameplates are this many yards from the screen, they'll be normal sized.
-- @return True if setting changed.
function me.SetScaleFactor ( Value )
	if ( Value ~= me.OptionsCharacter.ScaleFactor ) then
		me.OptionsCharacter.ScaleFactor = Value;

		me.Config.ScaleFactor:SetValue( Value );
		return true;
	end
end


--- Synchronizes addon settings with an options table.
-- @param OptionsCharacter  An options table to synchronize with, or nil to use defaults.
function me.Synchronize ( OptionsCharacter )
	-- Load defaults if settings omitted
	if ( not OptionsCharacter ) then
		OptionsCharacter = me.OptionsCharacterDefault;
	end

	me.SetMinScale( OptionsCharacter.MinScale );
	me.SetMaxScale( OptionsCharacter.MaxScale );
	me.SetMaxScaleEnabled( OptionsCharacter.MaxScaleEnabled );
	me.SetScaleFactor( OptionsCharacter.ScaleFactor );
end




WorldFrame:HookScript( "OnUpdate", me.WorldFrameOnUpdate ); -- First OnUpdate handler to run
me.Frame:SetScript( "OnEvent", me.Frame.OnEvent );
me.Frame:RegisterEvent( "ADDON_LOADED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_DISABLED" );
me.Frame:RegisterEvent( "PLAYER_REGEN_ENABLED" );


local GetParent = me.Frame.GetParent;
do
	--- Add method overrides to be applied to plates' Visuals.
	local function AddPlateOverride ( MethodName )
		PlateOverrides[ MethodName ] = function ( self, ... )
			local Plate = GetParent( self );
			return Plate[ MethodName ]( Plate, ... );
		end
	end
	AddPlateOverride( "GetParent" );
	AddPlateOverride( "SetAlpha" );
	AddPlateOverride( "GetAlpha" );
	AddPlateOverride( "GetEffectiveAlpha" );
end
-- Method overrides to use plates' OnUpdate script handlers instead of their Visuals' to preserve handler execution order
do
	--- Wrapper for plate OnUpdate scripts to replace their self parameter with the plate's Visual.
	local function OnUpdateOverride ( self, ... )
		self.OnUpdate( Plates[ self ], ... );
	end
	local type = type;

	local SetScript = me.Frame.SetScript;
	--- Redirects all SetScript calls for the OnUpdate handler to the original plate.
	function PlateOverrides:SetScript ( Script, Handler, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			local Plate = GetParent( self );
			Plate.OnUpdate = Handler;
			return Plate:SetScript( Script, Handler and OnUpdateOverride or nil, ... );
		else
			return SetScript( self, Script, Handler, ... );
		end
	end

	local GetScript = me.Frame.GetScript;
	--- Redirects calls to GetScript for the OnUpdate handler to the original plate's script.
	function PlateOverrides:GetScript ( Script, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			return GetParent( self ).OnUpdate;
		else
			return GetScript( self, Script, ... );
		end
	end

	local HookScript = me.Frame.HookScript;
	--- Redirects all HookScript calls for the OnUpdate handler to the original plate.
	-- Also passes the visual to the hook script instead of the plate.
	function PlateOverrides:HookScript ( Script, Handler, ... )
		if ( type( Script ) == "string" and Script:lower() == "onupdate" ) then
			local Plate = GetParent( self );
			if ( Plate.OnUpdate ) then
				-- Hook old OnUpdate handler
				local Backup = Plate.OnUpdate;
				function Plate:OnUpdate ( ... )
					Backup( self, ... ); -- Technically we should return Backup's results to match HookScript's hook behavior,
					return Handler( self, ... ); -- but the overhead isn't worth it when these results get discarded.
				end
			else
				Plate.OnUpdate = Handler;
			end
			return Plate:SetScript( Script, OnUpdateOverride, ... );
		else
			return HookScript( self, Script, Handler, ... );
		end
	end
end