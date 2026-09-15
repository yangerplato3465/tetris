class_name EventData
extends RefCounted

# Schema for `?` events. One GDScript file per event lives under Data/Events/,
# named for its id, holding a single `const EVENT` dictionary with every page of
# the event nested inside it. Events loads the folder at startup and
# DataValidator checks each file against the lists below.
#
# Event:
#   "id": String                        must match the filename
#   "title": String                     shown on every page unless a page overrides it
#   "start": String                     id of the first page
#   "pages": {page id: Page}            page ids are local to this event
#   "requires": Array of conditions     the event can only be rolled while every
#                                       condition holds (optional)
#
# Page:
#   "title": String                     optional, overrides the event title
#   "body": String                      flavor / situation text (optional if "lines")
#   "lines": Array of Line              dialogue shown after the body, one beat per
#                                       Next press, before the options (optional)
#   "options": Array of Option
#
# Line:
#   "text": String
#   "speaker": String                   name shown above the line (optional)
#
# Option:
#   "text": String                      button label
#   "requires": Array of conditions     hidden unless every condition holds (optional)
#   "locked_text": String               with requires: instead of hiding, show this
#                                       on a disabled button while they don't hold
#   "cost": Array of cost descriptors   paid when picked; the button is grayed out
#                                       while unaffordable (optional)
#   -- either a single fixed outcome, flat on the option: --
#   "result": String                    aftermath text (optional)
#   "effects": Array of descriptors     applied in order (optional)
#   "next": String                      page id in this event; Continue opens it
#                                       instead of ending the event (optional)
#   -- or weighted random outcomes: --
#   "outcomes": [{"weight": int, "result"?, "effects"?, "next"?}, ...]
#
# Effect descriptor: {"type": String, ...}. Effects use the out-of-battle
# vocabulary in RunEffects.EFFECT_KEYS — the same one keepsake "acquire" effects
# use — and can grant keepsakes (gain_keepsake, gain_random_keepsake) or change
# the piece pool (add_piece, remove_piece). Cost descriptors ({"type", "amount"})
# are separate, below, and handled by EventScene._canAfford / _payCost.
#
# Conditions: one-key Dictionaries from RunConditions.KEYS, all of which must
# hold — {"min_floor": 4}, {"has_keepsake": "ember_charm"}, {"class": "monk"},
# {"flag": "robbed_merchant"}. Flags are set and cleared by the set_flag /
# clear_flag effects, so one event can leave something behind for a later one.
# If nothing on a page is usable, EventScene adds a Leave button.
#
# Custom logic: an event file may define its own functions, and
# {"type": "call", "method": "name"} runs one on a fresh instance of the file when
# the option resolves. Return a String to append it to the result text. Use it
# for the one-off effect no descriptor covers, not as a way around adding a type.
#
# Why a .gd file rather than a .tres: an event is a tree of prose, and nested
# sub-resources are painful to write and review in the Inspector — and a .gd file
# can carry its own custom functions next to the pages that use them.

# Keys each part may carry; a trailing "?" marks a key optional.
const EVENT_KEYS := ["id", "title", "start", "pages", "requires?"]
const PAGE_KEYS := ["title?", "body?", "lines?", "options"]
const LINE_KEYS := ["text", "speaker?"]
const OPTION_KEYS := ["text", "requires?", "locked_text?", "cost?", "result?", "effects?", "next?", "outcomes?"]
const OUTCOME_KEYS := ["weight", "result?", "effects?", "next?"]

# Cost types EventScene._canAfford / _payCost implement. An HP cost can hurt but
# never kill: the option is unaffordable at or below that much HP.
const COST_KEYS := {
	"coins": ["amount"],
	"magic": ["amount"],
	"hp": ["amount"],
}
