--[[****************************************************************************
  * _Dev by Saiket                                                             *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


do
	local LDQuo, RDQuo = "\226\128\156", "\226\128\157";
	local Ellipsis = RED_FONT_COLOR_CODE.."\226\128\166"..FONT_COLOR_CODE_CLOSE;

	local Title = "_|cffcccc88Dev"..FONT_COLOR_CODE_CLOSE;


	_DevLocalization = setmetatable(
		{
			COLOR = { r = 0.8; g = 0.8; b = 8 / 15 }; -- Gold, same as title

			-- ToggleMod
			TOGGLEADDON_ERROR_FORMAT = Title..": Error loading AddOn "..LDQuo.."%s"..RDQuo
				..": %s."; -- AddonName, ErrorMessage


			-- Dump
			DUMP_MESSAGE_FORMAT = Title..".Dump: %s";
			DUMP_TIME_EXCEEDED = "Time limit exceeded.";
			-- Output formats
			DUMP_TYPE_FORMATS = {
				[ "string" ] = "|cffcccccc"..LDQuo.."%s".."|cffcccccc"..RDQuo..FONT_COLOR_CODE_CLOSE; -- StringVar (Light gray)
				[ "other" ] = HIGHLIGHT_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE; -- Var
				[ "table" ] = GREEN_FONT_COLOR_CODE.."<Table %s>"..FONT_COLOR_CODE_CLOSE; -- TableCount
				[ "function" ] = "|cff33ccff<Function %s>"..FONT_COLOR_CODE_CLOSE; -- FunctionCount (Teal)
				[ "userdata" ] = RED_FONT_COLOR_CODE.."<UserData %s>"..FONT_COLOR_CODE_CLOSE; -- UserDataCount
				[ "thread" ] = RED_FONT_COLOR_CODE.."<Thread %s>"..FONT_COLOR_CODE_CLOSE; -- ThreadCount
			};
			DUMP_LVALUE_DEFAULT = Title..".Dump";
			DUMP_INDENT = "    "; -- Tab-equivalent
			DUMP_GLOBALENV = "_G";
			DUMP_UIOBJECT_FORMAT = "%d: UIObject:%s %s"..GREEN_FONT_COLOR_CODE; -- TableCount, UIObjectType, UIObjectName
				-- Fed into the table format for UIObjects along with their frame name and type
			DUMP_MAXDEPTH_ABBR = Ellipsis; -- Printed when limits reached
			DUMP_MAXSTRLEN_ABBR = Ellipsis;
			DUMP_MAXTABLELEN_ABBR = Ellipsis;
			DUMP_MAXEXPLORETIME_ABBR = Ellipsis;


			-- Events
			ADDONCHAT_MESSAGES = "|cffCCCC88AddOn Messages"..FONT_COLOR_CODE_CLOSE; -- Tan
			ADDONCHAT_MSG_FORMAT = "["..GRAY_FONT_COLOR_CODE.."Mod"..FONT_COLOR_CODE_CLOSE
				.."%s] |Hplayer:%s|h[%s]|h: [%s] %s";
				-- Type, Sender, Sender, Prefix, Message
			ADDONCHAT_TYPES = {
				[ "GUILD" ]        = CHAT_MSG_GUILD;
				[ "RAID" ]         = CHAT_MSG_RAID;
				[ "PARTY" ]        = CHAT_MSG_PARTY;
				[ "BATTLEGROUND" ] = CHAT_MSG_BATTLEGROUND;
				[ "WHISPER" ]      = CHAT_MSG_WHISPER_INFORM;
			};


			-- Outline
			OUTLINE_MESSAGE_FORMAT = Title..".Outline: %s";
			OUTLINE_ADD_FORMAT = "[|cff%02x%02x%02x\226\150\136"..FONT_COLOR_CODE_CLOSE.."] Borders added to "..LDQuo..GREEN_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE..RDQuo.."."; -- R, G, B, ObjectName
			OUTLINE_REMOVE_FORMAT = "Borders removed from "..LDQuo..GREEN_FONT_COLOR_CODE.."%s"..FONT_COLOR_CODE_CLOSE..RDQuo.."."; -- ObjectName
			OUTLINE_REMOVEALL_FORMAT = "%d |4border:borders; removed."; -- OutlineCount
			OUTLINE_INVALID = "Input must evaluate to a valid Region UIObject.";
			OUTLINE_INVALID_DIMENSIONS = "Note - the target frame has a height or width of 0 and may show erroneous borders.";
			OUTLINE_INVALID_POSITION = "Note - the target frame has a nil position and may show no borders.";


			-- Frames
			FRAMES_MESSAGE_FORMAT = Title..".Frames: %s";
			FRAMES_ENABLED = "Focus frame browsing enabled.";
			FRAMES_DISABLED = "Focus frame browsing disabled.";
			FRAMES_MOUSEFOCUS = "Mouse Focus";
			FRAMES_UIOBJECT_FORMAT = GREEN_FONT_COLOR_CODE.."<%s %s"..GREEN_FONT_COLOR_CODE..">"..FONT_COLOR_CODE_CLOSE; -- UIObjectType, UIObjectName
				-- Intentionally similar to Dump's UIObject table format
			FRAMES_BRIEF_FORMAT = "Focus: %s, Parent: %s"; -- FocusName, ParentName

			-- Options
			OPTIONS_TITLE = Title;
			OPTIONS_DESC = "These options control the amount of information _Dev provides, as well as safety limits to protect against overflows and softlocks.";
			OPTIONS = setmetatable(
				{
					PRINTLUAERRORS = "Print Lua Errors";
					PRINTLUAERRORS_DESC = "Print Lua errors to the chat window rather than causing real errors.  Only protects _Dev-related commands.";

					DUMP = "Dump "..GRAY_FONT_COLOR_CODE.."("..LDQuo.."/dump"..RDQuo..")"..FONT_COLOR_CODE_CLOSE;
					DUMP_SKIPGLOBALENV = "Skip Global Env.";
					DUMP_SKIPGLOBALENV_DESC = "Prevents the global environment from being recursed.  When encountered, it uses the "..LDQuo.."_G"..RDQuo.." identifier rather than a table number.";
					DUMP_MAXEXPLORETIME = "Max Explore Time";
					DUMP_MAXEXPLORETIME_DESC = "Maximum number of seconds to spend printing before giving up.  If disabled, some operations such as printing the global environment will softlock the client until it gets disconnected.";
					DUMP_MAXDEPTH = "Max Depth";
					DUMP_MAXDEPTH_DESC = "Maximum number of tables to traverse.  For example, "..LDQuo.."1"..RDQuo.." will print the contents of a given table, but will not traverse any sub-tables it may contain.  Note that dump is already protected against recursive tables.";
					DUMP_MAXTABLELEN = "Max Table Length";
					DUMP_MAXTABLELEN_DESC = "Maximum number of elements per table to print before prematurely leaving that table.  For example, "..LDQuo.."5"..RDQuo.." will print the first five elements and then leave the table even if there is a sixth.";
					DUMP_MAXSTRLEN = "Max String Length";
					DUMP_MAXSTRLEN_DESC = "Number of characters to escape and print for strings before truncating them.  Can increase performance if full string escaping is enabled.";
					DUMP_ESCAPEMODE = "Escape Mode";
					DUMP_ESCAPEMODE_DESC = "What types of characters will be escaped from printed strings (each is progressively more thorough).";
					DUMP_ESCAPEMODE_ARGS = {
						[ 0 ] = "None"..NORMAL_FONT_COLOR_CODE.." - Raw, fastest.";
						[ 1 ] = "Escapes"..NORMAL_FONT_COLOR_CODE.." - Pipes ("..LDQuo.."||"..RDQuo..").";
						[ 2 ] = "Full"..NORMAL_FONT_COLOR_CODE.." - Pipes & non-ASCII.";
					};

					OUTLINE = "Outline "..GRAY_FONT_COLOR_CODE.."("..LDQuo.."/outline"..RDQuo..")"..FONT_COLOR_CODE_CLOSE;
					OUTLINE_BOUNDSTHRESHOLD = "Bounds Threshold";
					OUTLINE_BOUNDSTHRESHOLD_DESC = "Distance from the edge of the screen an outline can fall before showing a guide marker.  For example, "..LDQuo.."5"..RDQuo.." will show a guide when only five pixels of the outline remain on-screen in any direction.";
					OUTLINE_BORDERALPHA = "Border Alpha";
					OUTLINE_BORDERALPHA_DESC = "Opacity of outline borders, between zero for fully transparent and one for opaque.";
					OUTLINE_BORDERALPHA_FORMAT = "%01.01f";
				}, {
					__index = function ( self, Key )
						Key = Key:gsub( "%.", "_" ):upper();
						return rawget( self, Key ) or "OPTIONS."..Key;
					end;
				} );


			-- Stats
			STATS_HERTZ_FORMAT       = "%.1f"..HERTZ;
			STATS_MILLISECOND_FORMAT = "%d"..MILLISECONDS_ABBR;
			STATS_MEGABYTE_FORMAT    = "%.3fMB";
		}, {
			__index = function ( self, Key )
				rawset( self, Key, Key );
				return Key;
			end;
		} );




--------------------------------------------------------------------------------
-- Globals
----------

	-- Bindings
	BINDING_HEADER__DEV = Title;

	BINDING_NAME__DEV_RELOADUI = "Reload UI";
	BINDING_NAME__DEV_OPENCHATSCRIPT = "Open Script";

	-- Stats: Rename the old FPS binding instead of making a new one
	BINDING_NAME_TOGGLEFPS = "Toggle "..Title..".Stats";


	-- ToggleMod
	SLASH_DEV_TOGGLEADDON1 = "/toggleaddon";
	SLASH_DEV_TOGGLEADDON2 = "/togglemod";


	-- Dump
	SLASH_DEV_DUMP1 = "/dump";
	SLASH_DEV_DUMP2 = "/d";


	-- Outline
	SLASH_DEV_OUTLINE1 = "/outline";

	-- Frames
	SLASH_DEV_FRAMESTOGGLE1 = "/frames";
	BINDING_NAME__DEV_FRAMESTOGGLE = "Toggle Frames Browsing";
end
