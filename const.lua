--[[ This file contains the constants I use throughout the addon.
     To reduce global namespace polluting, the constants are kept in a table
     tacked on to the addon table.

     Strings are used as symbols in this setup,  and should never be displayed
     directly. If necessary, pass them through a locale table before displaying.
--]]

local addonName, addonTable = ...
addonTable.const = {
    SIGNED = "signed",
    UNSIGNED = "unsigned",
    UNSURE = "unsure",
    UNKNOWN = "unknown",
}
