--[[****************************************************************************
  * _Unghost by Saiket                                                         *
  * Localization.lua - Localized string constants (en-US).                     *
  ****************************************************************************]]


--------------------------------------------------------------------------------
-- _Unghost
-----------

local Bullet = "        \226\151\143  ";
local LDQuo, RDQuo = GRAY_FONT_COLOR_CODE.."\226\128\156", "\226\128\157"..FONT_COLOR_CODE_CLOSE;

SLASH_UNGHOST1 = "/unghost";

_UNGHOST_UNGHOST = "|cffCCCC88Unghost"..FONT_COLOR_CODE_CLOSE;
_UNGHOST_TOOLTIP = "Releases your ghost on top of your corpse rather than at the nearest graveyard.";
_UNGHOST_PRINT_FORMAT = _UNGHOST_UNGHOST..": %s";

_UNGHOST_OPT_LEAD = "lead";
_UNGHOST_LEAD = "Extra lead time currently set to "..HIGHLIGHT_FONT_COLOR_CODE.."%d ms"..FONT_COLOR_CODE_CLOSE..".";

_UNGHOST_HELP1 = "Type "..LDQuo..SLASH_UNGHOST1.." <option>"..RDQuo.." with one of the following <option>s:"
_UNGHOST_HELP2 = Bullet.."Leave blank to toggle the logout timer when dead."
_UNGHOST_HELP3 = Bullet..LDQuo..SLASH_UNGHOST1.." ".._UNGHOST_OPT_LEAD..RDQuo.." to view or set your lead-time offset."
_UNGHOST_HELP4 = Bullet.."Anything else to view this help message.";

_UNGHOST_STARTED = "Logout timer "..GREEN_FONT_COLOR_CODE.."started"..FONT_COLOR_CODE_CLOSE..".";
_UNGHOST_STOPPED = "Logout timer "..RED_FONT_COLOR_CODE.."stopped"..FONT_COLOR_CODE_CLOSE..".";


_UNGHOST_ERROR_NOTCORPSE = "You must be a corpse to unghost!";
_UNGHOST_ERROR_RESTING = "Cannot unghost in town!";
