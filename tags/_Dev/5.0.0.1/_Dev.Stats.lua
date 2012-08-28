--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * _Dev.Stats.lua - Provides a more detailed report on your client, which     *
  *   replaces the default framerate monitor.                                  *
  ****************************************************************************]]


_DevOptions.Stats = {
	Enabled = true;
};


local _Dev = _Dev;
local L = _DevLocalization;
local NS = CreateFrame( "Frame", nil, UIParent );
_Dev.Stats = NS;

NS.Framerate = NS:CreateFontString( nil, "ARTWORK", "_DevFont" );
NS.Memory    = NS:CreateFontString( nil, "ARTWORK", "_DevFont" );
NS.Latency   = NS:CreateFontString( nil, "ARTWORK", "_DevFont" );

NS.UpdateRate = 0.2;
NS.NextUpdate = 0;

NS.LowLatency  =  50;
NS.HighLatency = 450;




--[[****************************************************************************
  * Function: _Dev.Stats.ToggleFramerate                                       *
  * Description: Hides or shows the stats display.                             *
  ****************************************************************************]]
function NS.ToggleFramerate ( Enable )
	if ( Enable == nil ) then
		Enable = not _DevOptions.Stats.Enabled;
	end
	_DevOptions.Stats.Enabled = Enable;

	if ( Enable ) then
		NS:Show();
	else
		NS:Hide();
	end
end


--[[****************************************************************************
  * Function: _Dev.Stats:OnUpdate                                              *
  * Description: Refreshes the stats display's information.                    *
  ****************************************************************************]]
do
	local GetNetStats = GetNetStats;
	local GetFramerate = GetFramerate;
	local gcinfo = gcinfo;
	local select = select;
	local min, max = min, max;
	function NS:OnUpdate ( Elapsed )
		self.NextUpdate = self.NextUpdate - Elapsed;
		if ( self.NextUpdate <= 0 ) then
			self.NextUpdate = self.UpdateRate;

			local Latency = select( 4, GetNetStats() );
			local Red = min( max( ( Latency - self.LowLatency ) / self.HighLatency, 0 ), 1 );
			self.Latency:SetFormattedText( L.STATS_MILLISECOND_FORMAT, Latency );
			self.Latency:SetTextColor( Red, 1 - Red, 0 );
			self.Framerate:SetFormattedText( L.STATS_HERTZ_FORMAT, GetFramerate() );
			self.Memory:SetFormattedText( L.STATS_MEGABYTE_FORMAT, _Dev.Round( gcinfo() / 1024, 3 ) );
		end
	end
end
--[[****************************************************************************
  * Function: _Dev.Stats:OnLoad                                                *
  * Description: Reload user settings.                                         *
  ****************************************************************************]]
function NS:OnLoad ()
	ToggleFramerate( _DevOptions.Stats.Enabled );
end




NS:SetSize( 1, 1 );
NS:SetPoint( "TOPLEFT" );
NS:SetFrameStrata( "BACKGROUND" );
NS:SetAlpha( 0.5 );

NS.Framerate:SetPoint( "TOPLEFT" );
NS.Framerate:SetTextColor( NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b );
NS.Latency:SetPoint( "LEFT", NS.Framerate, "RIGHT" );
NS.Memory:SetPoint( "LEFT", NS.Latency, "RIGHT" );

NS:SetScript( "OnUpdate", NS.OnUpdate );

-- Hook original framerate function
ToggleFramerate = NS.ToggleFramerate;
ToggleFramerate( _DevOptions.Stats.Enabled );