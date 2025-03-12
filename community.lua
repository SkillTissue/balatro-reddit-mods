SMODS.optional_features.cardareas.unscored = true

SMODS.Joker {
	key = "greedy_king_joker",
	loc_txt = {
		name = "Greedy King",
		text = {
			"All Gold cards now give {X:mult,C:white} X#1# {} Mult when held in hand"
		}
	},
	config = { extra = {Xmult = 1.5} },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult } }
	end,
	rarity = 2,
	cost = 8,	
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.hand and context.main_scoring then
			if SMODS.has_enhancement(context.other_card, "m_gold") then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

SMODS.Joker {
	key = "joy_buzzer_joker",
	loc_txt = {
		name = "Joy Buzzer",
		text = {
			"Gives {X:mult,C:white} X#1# {} Mult",
			"{C:green}#2# in #3#{} chance that",
			"a random card is discarded upon playing hand",
			"Lose {X:mult,C:white} X#4# {} Mult when this happens"
		}
	},
	config = { extra = { Xmult = 4, odds = 4, reduce = 0.25 } },
	cost = 4,
	eternal_compat = false,
	rarity = 2,
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult, (G.GAME.probabilities.normal or 1), card.ability.extra.odds, card.ability.extra.reduce } }
	end,
	calculate = function(self, card, context)
		if context.joker_main then
			return {
				xmult = card.ability.extra.Xmult
			}
		end

		if context.before and not context.blueprint then
			if pseudorandom('joy_buzzer_joker') < G.GAME.probabilities.normal / card.ability.extra.odds then
				G.E_MANAGER:add_event(Event({
					trigger = "immediate",
					func = function()
					local any_selected = nil
					local _cards = {}
					for k, v in ipairs(G.hand.cards) do
						_cards[#_cards+1] = v
					end
					for i = 1, 1 do
						if G.hand.cards[i] then
							local selected_card, card_key = pseudorandom_element(_cards, pseudoseed("joy_buzzer"))
							G.hand:add_to_highlighted(selected_card, true)
							table.remove(_cards, card_key)
							any_selected = true
							play_sound('card1', 1)
							SMODS.calculate_effect({message = "Zap!"}, selected_card)
						end
					end
					if any_selected then 
						G.FUNCS.discard_cards_from_highlighted(nil, true) 
						card.ability.extra.Xmult = card.ability.extra.Xmult - card.ability.extra.reduce
					end
				return true end }))
			end
		end

		if card.ability.extra.Xmult == 0 then
			self:start_dissolve()
		end
	end
}

SMODS.Joker{
	key = "the_phantom_joker",
	loc_txt = {
		name = "The Phantom",
		text = {
			"Played face cards have a {C:green}#1# in #2#{} chance",
			"to become negative",
			"Negative cards grant +1 hand size"
		}
	},
	config = { extra = { odds = 2 } },
	cost = 4,
	eternal_compat = false,
	rarity = 2,
	loc_vars = function(self, info_queue, card)
		return { vars = { (G.GAME.probabilities.normal or 1), card.ability.extra.odds } }
	end,
	calculate = function(self, card, context)
		if context.before and context.cardarea == G.jokers then
			played_hand = G.play.cards
			for v, card_r in ipairs(played_hand) do
				if card_r:is_face() and pseudoseed("the_phantom_joker") > G.GAME.probabilities.normal / card.ability.extra.odds then
					card_r:set_edition('e_negative')
					SMODS.calculate_effect({message = "Spooky!"}, card_r)
				end
			end
		end
	end
}

SMODS.Joker {
	key = "graveyard_joker",
	loc_txt = {
		name = "The Graveyard",
		text = {
			"All Stone cards now give {X:mult,C:white} X#1# {} Mult when held in hand"
		}
	},
	config = { extra = {Xmult = 2} },
	loc_vars = function(self, info_queue, card)
		return { vars = { card.ability.extra.Xmult } }
	end,
	rarity = 2,
	cost = 8,
	calculate = function(self, card, context)
		if context.individual and context.cardarea == G.hand and context.main_scoring then
			if SMODS.has_enhancement(context.other_card, "m_stone") then
				return {
					xmult = card.ability.extra.Xmult
				}
			end
		end
	end
}

-- add joker_destroyed context
local card_remove_ref = Card.remove_from_deck
function Card:remove_from_deck()
    if self.ability.set == "Joker" and self.added_to_deck and not G.CONTROLLER.locks.selling_card then
        SMODS.calculate_context({joker_destroyed = true , card_destroyed = self})
    end
    return card_remove_ref(self)
end

local lcpref = Controller.L_cursor_press
function Controller:L_cursor_press(x, y)
	lcpref(self, x, y)
	if G and G.jokers and G.jokers.cards and not G.SETTINGS.paused then
		SMODS.calculate_context({cursor_click = true})
	end
end