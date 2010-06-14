--[[****************************************************************************
  * _Underscore.Units by Saiket                                                *
  * Locales/Locale-enUS.lua - Localized string constants (en-US).              *
  ****************************************************************************]]


local Title = "_|cffcccc88Underscore|r.Units";

_UnderscoreLocalization.Units = setmetatable( {
	DEAD    = "DEAD";
	GHOST   = "GHOST";
	OFFLINE = "OFFLINE";
	FEIGN   = "FEIGN";

	GRID_LAYOUT_GROUP = Title..": Groups";
	GRID_LAYOUT_CLASS = Title..": Classes";

	OUF_GROUP_FORMAT = "(G%d)";
	OUF_CLASSIFICATION_FORMAT = "(|cff%02x%02x%02x%s|r)"; -- R, G, B, Classification
	OUF_NAME_FORMAT = "|cff%02x%02x%02x%s|r"; -- R, G, B, Name
	OUF_SERVER_DELIMITER = "-";


	NumberFormats = { -- Health value formats used by oUF layout
		Full = function ( Value, ValueMax )
			return "%d/%d", Value, ValueMax;
		end;
		Small = function ( Value, ValueMax )
			local Format;
			if ( Value >= 1e6 ) then
				Format, Value = "%.1fm", Value / 1e6;
			elseif ( Value >= 1e3 ) then
				Format, Value = "%.1fk", Value / 1e3;
			else
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