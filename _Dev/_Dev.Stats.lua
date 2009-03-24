--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Stats.lua - Provides a more detailed report on your client, which     *
  *   replaces the default framerate monitor.                                  *
  *                                                                            *
  * + Shows the framerate, latency, and UI memory consumption in the top left  *
  *   corner of the screen.                                                    *
  ****************************************************************************]]


_DevOptions.Stats = {
	Enabled = true;
};


local _Dev = _Dev;
local L = _DevLocalization;
local me = CreateFrame( "Frame", nil, UIParent );
_Dev.Stats = me;

me.Framerate = me:CreateFontString( nil, "ARTWORK", "_DevFont" );
me.Memory    = me:CreateFontString( nil, "ARTWORK", "_DevFont" );
me.Latency   = me:CreateFontString( nil, "ARTWORK", "_DevFont" );

me.UpdateRate = 0.2;
me.NextUpdate = 0;

me.LowLatency  =  50;
me.HighLatency = 450;




--[[****************************************************************************
  * Function: _Dev.Stats.ToggleFramerate                                       *
  * Description: Hides or shows the stats display.                             *
  ****************************************************************************]]
function me.ToggleFramerate ( Enable )
	if ( Enable == nil ) then
		Enable = not _DevOptions.Stats.Enabled;
	end
	_DevOptions.Stats.Enabled = Enable;

	if ( Enable ) then
		me:Show();
	else
		me:Hide();
	end
end


--[[****************************************************************************
  * Function: _Dev.Stats:OnUpdate                                              *
  * Description: Refreshes the stats display's information.                    *
  ****************************************************************************]]
do
	local Round = _Dev.Round;
	local GetNetStats = GetNetStats;
	local GetFramerate = GetFramerate;
	local gcinfo = gcinfo;
	local select = select;
	local min, max = min, max;
	function me:OnUpdate ( Elapsed )
		self.NextUpdate = self.NextUpdate - Elapsed;
		if ( self.NextUpdate <= 0 ) then
			self.NextUpdate = self.UpdateRate;

			local Latency = select( 3, GetNetStats() );
			local Red = min( max( ( Latency - self.LowLatency ) / self.HighLatency, 0 ), 1 );
			self.Latency:SetFormattedText( L.STATS_MILLISECOND_FORMAT, Latency );
			self.Latency:SetTextColor( Red, 1 - Red, 0 );
			self.Framerate:SetFormattedText( L.STATS_HERTZ_FORMAT, GetFramerate() );
			self.Memory:SetFormattedText( L.STATS_MEGABYTE_FORMAT, Round( gcinfo() / 1024, 3 ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Stats:OnLoad                                                *
  * Description: Reload user settings.                                         *
  ****************************************************************************]]
function me:OnLoad ()
	ToggleFramerate( _DevOptions.Stats.Enabled );
end




--------------------------------------------------------------------------------
-- Function Hooks / Execution
-----------------------------

do
	-- Set up frame
	me:SetWidth( 1 );
	me:SetHeight( 1 );
	me:SetPoint( "TOPLEFT" );
	me:SetFrameStrata( "BACKGROUND" );
	me:SetAlpha( 0.5 );

	me.Framerate:SetPoint( "TOPLEFT" );
	me.Framerate:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
	me.Latency:SetPoint( "LEFT", me.Framerate, "RIGHT" );
	me.Memory:SetPoint( "LEFT", me.Latency, "RIGHT" );

	-- Events
	me:SetScript( "OnUpdate", me.OnUpdate );

	-- Hook original framerate function
	ToggleFramerate = me.ToggleFramerate;
	ToggleFramerate( _DevOptions.Stats.Enabled );
end
