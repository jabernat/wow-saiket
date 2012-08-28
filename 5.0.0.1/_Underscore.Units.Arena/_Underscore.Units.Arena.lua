--[[****************************************************************************
  * _Underscore.Units.Arena by Saiket                                          *
  * _Underscore.Units.Arena.lua - Adds arena frames when entering a match.     *
  ****************************************************************************]]


local _Underscore = _Underscore;
local Units = _Underscore.Units.oUF;
assert( Units.StyleMeta.__call, "_Underscore.Units.oUF Initializer already destroyed!" );
local NS = CreateFrame( "Frame" );
Units.Arena = NS;

NS.Enabled = false;
NS.ArenaTargets = {}; -- [ ArenaFrame ] = ArenaTargetFrame;




--- Enables or disables unit watch state drivers when entering or leaving arenas.
function NS:PLAYER_ENTERING_WORLD ()
	local Enabled = select( 2, IsInInstance() ) == "arena";
	if ( self.Enabled == Enabled ) then
		return;
	end
	self.Enabled = Enabled;

	for Frame, Target in pairs( self.ArenaTargets ) do
		if ( Enabled ) then
			Frame:Enable();
			-- Show only when target is friendly
			RegisterStateDriver( Target, "visibility", "[target="..Target.unit..",help]show;hide" );
		else
			Frame:Disable();
			Target:Disable();
		end
	end
end




oUF:RegisterStyle( "_UnderscoreUnitsArena", setmetatable( {
	Width = 110;
	Height = 36;
	HealthText = "Tiny";
	PowerText  = "Tiny";
	NameFont = Units.FontTiny;
	CastTime = false;
	Auras = false;
	DebuffHighlight = false;
	PowerHeight = 0.2;
	ProgressHeight = 0.2;
}, Units.StyleMeta ) );
oUF:RegisterStyle( "_UnderscoreUnitsArenaTarget", setmetatable( {
	Width = 80;
	Height = 36;
	PortraitSide = "LEFT";
	HealthText = false;
	PowerText  = false;
	NameFont = Units.FontTiny;
	CastTime = false;
	Auras = false;
	PowerHeight = 0.2;
	ProgressHeight = 0.2;
}, Units.StyleMeta ) );

local LastFrame;
for Index = 1, 5 do
	oUF:SetActiveStyle( "_UnderscoreUnitsArena" );
	local Frame = oUF:Spawn( "arena"..Index, "_UnderscoreUnitsArena"..Index );
	Frame:Disable();
	if ( LastFrame ) then
		Frame:SetPoint( "TOPLEFT", LastFrame, "BOTTOMLEFT", 0, -_Underscore.Backdrop.Padding * 2 );
	else
		Frame:SetPoint( "LEFT", UIParent );
		Frame:SetPoint( "TOP", Units.Pet, "BOTTOM", 0, -185 );
	end
	LastFrame = Frame;

	-- Arena target
	oUF:SetActiveStyle( "_UnderscoreUnitsArenaTarget" );
	local Target = oUF:Spawn( Frame.unit.."target", Frame:GetName().."Target" );
	Target:SetPoint( "TOPLEFT", Frame, "TOPRIGHT", _Underscore.Backdrop.Padding * 2, 0 );
	Target:Disable();

	NS.ArenaTargets[ Frame ] = Target;
end

-- Garbage collect _Underscore.Units.oUF's initialization code
Units.StyleMeta.__call = nil;

NS:SetScript( "OnEvent", _Underscore.Frame.OnEvent );
NS:RegisterEvent( "PLAYER_ENTERING_WORLD" );
NS:PLAYER_ENTERING_WORLD();