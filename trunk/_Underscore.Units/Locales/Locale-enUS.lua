--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


select( 2, ... ).L = setmetatable( {
	DEAD    = "DEAD";
	GHOST   = "GHOST";
	OFFLINE = "OFFLINE";

	GRID_LAYOUT_GROUP = "_|cffcccc88Underscore|r.Units: Groups";
	GRID_LAYOUT_CLASS = "_|cffcccc88Underscore|r.Units: Classes";

	OUF_GROUP_FORMAT = "(G%d)";
	OUF_CLASSIFICATION_FORMAT = "(%s%s|r)"; -- ColorCode, Classification
	OUF_NAME_FORMAT = "%s%s|r"; -- ColorCode, Name


	NumberFormats = { -- Health/power value formats used by oUF layout
		--- Formats values as a fraction with no abbreviations.
		-- @param Value  Current health value.
		-- @param ValueMax  Maximum health value.
		-- @return A format with arguments to be passed to string.format or FontString:SetFormattedText.
		Full = function ( Value, ValueMax )
			return "%d/%d", Value, ValueMax;
		end;
		--- Formats values as a fraction with large numbers abbreviated and rounded to one decimal place.
		Small = function ( Value, ValueMax )
			local Format;
			if ( Value >= 1e6 ) then -- 7 or more digits
				Format, Value = "%.1fm", Value / 1e6;
			elseif ( Value >= 1e3 ) then -- 4 or more digits
				Format, Value = "%.1fk", Value / 1e3;
			else -- 3 or less digits
				Format = "%d";
			end

			if ( ValueMax >= 1e6 ) then
				Format, ValueMax = Format.."/%.1fm", ValueMax / 1e6;
			elseif ( ValueMax >= 1e3 ) then
				Format, ValueMax = Format.."/%.1fk", ValueMax / 1e3;
			else
				Format = Format.."/%d";
			end

			return Format, Value, ValueMax;
		end;
		--- Formats values as a fraction with large numbers abbreviated and rounded to no decimal places.
		Tiny = function ( Value, ValueMax )
			local Format;
			if ( Value >= 1e6 ) then
				Format, Value = "%.0fm", Value / 1e6;
			elseif ( Value >= 1e3 ) then
				Format, Value = "%.0fk", Value / 1e3;
			else
				Format = "%d";
			end

			if ( ValueMax >= 1e6 ) then
				Format, ValueMax = Format.."/%.0fm", ValueMax / 1e6;
			elseif ( ValueMax >= 1e3 ) then
				Format, ValueMax = Format.."/%.0fk", ValueMax / 1e3;
			else
				Format = Format.."/%d";
			end

			return Format, Value, ValueMax;
		end;
	};
}, getmetatable( _UnderscoreLocalization ) );