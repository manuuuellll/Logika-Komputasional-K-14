% facts.pl
% Berisi semua fakta statis permainan.

% --- Pokémon Definitions ---
% pokemon_data(Species, Rarity, Type, BaseHP_Lvl5, BaseATK_Lvl5, BaseDEF_Lvl5, Skill1, Skill2_UnlockLevelOrEvo, Skill2_Name, EvolveTo, EvolveLevel).
pokemon_data('Charmander', common, fire, 35, 15, 10, 'Scratch', 5, 'Ember', 'Charmeleon', 15).
pokemon_data('Squirtle', common, water, 40, 12, 15, 'Tackle', 5, 'Water Gun', 'Wartortle', 15).
pokemon_data('Pidgey', common, flying, 30, 14, 10, 'Tackle', 5, 'Gust', 'none', 0).

pokemon_data('Charmeleon', common, fire, 58, 22, 17, 'Ember', 'evo', 'Fire Spin', 'none', 0).
pokemon_data('Wartortle', common, water, 63, 19, 22, 'Water Gun', 'evo', 'Bubble', 'none', 0).

pokemon_data('Pikachu', rare, electric, 30, 16, 10, 'Thunder Shock', 5, 'Quick Attack', 'none', 0).
pokemon_data('Geodude', rare, rock, 30, 20, 25, 'Tackle', 5, 'Rock Throw', 'none', 0).
pokemon_data('Snorlax', epic, normal, 70, 30, 20, 'Tackle', 5, 'Rest', 'none', 0).
pokemon_data('Articuno', legendary, ice, 60, 28, 35, 'Gust', 5, 'Ice Shard', 'none', 0).
pokemon_data('Mewtwo', legendary, psychic, 250, 300, 250, 'Psychic Blast', 0, 'Mind Shock', 'none', 0).

% --- Skill Definitions ---
% skill_data(Name, Type, Power, EffectName, EffectChance, EffectValue, EffectDuration, TargetStatChange).
skill_data('Scratch', normal, 35, none, 0, 0, 0, none).
skill_data('Tackle', normal, 35, none, 0, 0, 0, none).
skill_data('Ember', fire, 40, burn, 100, 3, 2, hp).
skill_data('Water Gun', water, 40, none, 0, 0, 0, none).
skill_data('Gust', flying, 30, none, 0, 0, 0, none).
skill_data('Fire Spin', fire, 35, burn, 100, 5, 2, hp).
skill_data('Bubble', water, 0, stat_change, 100, -3, 0, atk).
skill_data('Thunder Shock', electric, 40, failed_attack, 20, 0, 0, none).
skill_data('Quick Attack', normal, 30, first_strike, 100, 0, 0, none).
skill_data('Rock Throw', rock, 50, none, 0, 0, 0, none).
skill_data('Rest', normal, 0, heal_and_sleep, 100, 40, 1, hp).
skill_data('Ice Shard', ice, 40, first_strike, 100, 0, 0, none).
skill_data('Psychic Blast', psychic, 200, confused, 20, 0, 1, none).
skill_data('Mind Shock', psychic, 300, area_damage, 100, 0, 0, none).

% --- Type Effectiveness ---
% type_effectiveness(AttackType, DefendType, Modifier).
type_effectiveness(fire, ice, 1.5).
type_effectiveness(fire, water, 0.5).
type_effectiveness(fire, rock, 0.5).
type_effectiveness(fire, fire, 0.5).
type_effectiveness(water, fire, 1.5).
type_effectiveness(water, rock, 1.5).
type_effectiveness(water, electric, 0.5).
type_effectiveness(water, water, 0.5).
type_effectiveness(electric, water, 1.5).
type_effectiveness(electric, flying, 1.5).
type_effectiveness(electric, electric, 0.5).
type_effectiveness(electric, rock, 0.5).
type_effectiveness(flying, electric, 0.5).
type_effectiveness(flying, rock, 0.5).
type_effectiveness(flying, ice, 0.5).
type_effectiveness(rock, fire, 1.5).
type_effectiveness(rock, flying, 1.5).
type_effectiveness(rock, ice, 1.5).
type_effectiveness(rock, water, 0.5).
type_effectiveness(rock, rock, 0.5).
type_effectiveness(ice, flying, 1.5).
type_effectiveness(ice, fire, 0.5).
type_effectiveness(ice, rock, 0.5).
type_effectiveness(ice, water, 0.5).
type_effectiveness(ice, ice, 0.5).
type_effectiveness(normal, rock, 0.5).
type_effectiveness(psychic, _, 1.0).

% --- Rarity Based EXP ---
base_exp_rarity_req(common, 20).
base_exp_rarity_req(rare, 30).
base_exp_rarity_req(epic, 40).
base_exp_rarity_req(legendary, 50).

base_exp_given_defeat(common, 10).
base_exp_given_defeat(rare, 20).
base_exp_given_defeat(epic, 30).
base_exp_given_defeat(legendary, 40).

% --- Catch Rate Base by Rarity ---
catch_rate_base(common, 40).
catch_rate_base(rare, 30).
catch_rate_base(epic, 25).
catch_rate_base(legendary, 280).

% --- Map Constants ---
map_width(8).
map_height(8).
num_grass_patches(32).
wild_pokemon_counts(legendary, 1).
wild_pokemon_counts(epic, 3).
wild_pokemon_counts(rare, 5).
wild_pokemon_counts(common, 10).

% --- Player Constants ---
initial_pokeballs(20).
max_party_size(4).
max_bag_slots(40).
initial_moves(20).
max_heal_pokecenter(2).