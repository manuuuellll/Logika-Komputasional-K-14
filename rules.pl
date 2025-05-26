% rules.pl
% Berisi rules dan logika inti permainan.

% --- Helper: Get Data ---
get_pokemon_base_stats_lvl5(Species, Rarity, Type, BaseHP, BaseATK, BaseDEF, S1, S2Unlock, S2Name, EvoTo, EvoLvl) :-
    pokemon_data(Species, Rarity, Type, BaseHP, BaseATK, BaseDEF, S1, S2Unlock, S2Name, EvoTo, EvoLvl).

get_skill_details(Name, Type, Power, Effect, Chance, Val, Dur, Target) :-
    skill_data(Name, Type, Power, Effect, Chance, Val, Dur, Target).

% --- Stat Calculation ---
calculate_stats_for_level(Species, Level, MaxHP, ATK, DEF) :-
    get_pokemon_base_stats_lvl5(Species, _, _, BaseHP5, BaseATK5, BaseDEF5, _, _, _, _, _),
    StatHPLvl1 is BaseHP5 - (2 * (5 - 1)),
    StatATKLvl1 is BaseATK5 - (1 * (5 - 1)),
    StatDEFLvl1 is BaseDEF5 - (1 * (5 - 1)),
    MaxHP is StatHPLvl1 + (2 * (Level - 1)),
    ATK is StatATKLvl1 + (1 * (Level - 1)),
    DEF is StatDEFLvl1 + (1 * (Level - 1)).

calculate_evolved_stats_lvl15(Species, MaxHP, ATK, DEF) :-
    ( Species == 'Charmeleon' -> MaxHP = 58, ATK = 22, DEF = 17
    ; Species == 'Wartortle' -> MaxHP = 63, ATK = 19, DEF = 22
    ; calculate_stats_for_level(Species, 15, MaxHP, ATK, DEF)
    ).

% --- Skill Acquisition ---
get_active_skills(Species, Level, Skill1, Skill2) :-
    get_pokemon_base_stats_lvl5(Species, _, _, _, _, _, BaseS1, S2UnlockLvlOrEvo, BaseS2Name, _, _),
    Skill1 = BaseS1,
    ( number(S2UnlockLvlOrEvo), Level >= S2UnlockLvlOrEvo -> Skill2 = BaseS2Name
    ; S2UnlockLvlOrEvo == 'evo', \+ number(BaseS2Name) -> Skill2 = BaseS2Name
    ; S2UnlockLvlOrEvo == 'evo', get_pokemon_base_stats_lvl5(Species, _, _, _, _, _, _, _, EvoSkillName, _, _), \+ number(EvoSkillName) -> Skill2 = EvoSkillName
    ; Skill2 = none
    ).

% --- Damage Calculation ---
calculate_damage(AttackerPokemonInstance, DefenderPokemonInstance, SkillNameToUse, Damage) :-
    AttackerPokemonInstance = pokemon(_, _, _, _, AttackerATK, _, _, _, _, _),
    DefenderPokemonInstance = pokemon(DefenderSpecies, _, _, _, _, DefenderDEF, _, _, _, _),
    get_pokemon_base_stats_lvl5(DefenderSpecies, _, DefenderType, _, _, _, _, _, _, _, _),
    ( SkillNameToUse == 'basic_attack' ->
        PowerSkill = 1,
        AttackingSkillType = normal
    ; get_skill_details(SkillNameToUse, AttackingSkillType, PowerFromTable, _, _, _, _, _),
      ( PowerFromTable =:= 0 -> PowerSkill = 1 ; PowerSkill = PowerFromTable )
    ),
    get_type_modifier(AttackingSkillType, DefenderType, Modifier),
    ( DefenderDEF > 0 ->
        Damage is round(((PowerSkill * AttackerATK) / DefenderDEF) * Modifier)
    ; Damage is round((PowerSkill * AttackerATK) * Modifier)
    ).

get_type_modifier(AttackType, DefendType, Modifier) :-
    ( type_effectiveness(AttackType, DefendType, Mod) -> Modifier = Mod
    ; Modifier = 1.0
    ).

% --- EXP and Level Up ---
exp_needed_for_next_level(PokemonInstance, ExpNeeded) :-
    PokemonInstance = pokemon(Species, Level, _, _, _, _, _, _, _, _),
    get_pokemon_base_stats_lvl5(Species, Rarity, _, _, _, _, _, _, _, _, _),
    base_exp_rarity_req(Rarity, BaseExpReq),
    ExpNeeded is BaseExpReq * Level.

exp_gained_on_defeat(DefeatedPokemonInstance, ExpGained) :-
    DefeatedPokemonInstance = pokemon(Species, LevelDefeated, _, _, _, _, _, _, _, _),
    get_pokemon_base_stats_lvl5(Species, Rarity, _, _, _, _, _, _, _, _, _),
    base_exp_given_defeat(Rarity, BaseExpGiven),
    ExpGained is BaseExpGiven + (LevelDefeated * 2).

apply_stat_increase_on_level_up(pokemon(S, L, CH, MH, A, D, E, S1, S2, Status), pokemon(S, NewL, NewCH, NewMH, NewA, NewD, E, S1, S2, Status)) :-
    NewL is L + 1,
    NewMH is MH + 2,
    NewA is A + 1,
    NewD is D + 1,
    HPIncrease is NewMH - MH,
    TempNewCH is CH + HPIncrease,
    (TempNewCH > NewMH -> NewCH = NewMH ; NewCH = TempNewCH).

handle_evolution(PokemonIn, PokemonOut) :-
    PokemonIn = pokemon(Species, Level, CurrentHP, MaxHP, _ATK, _DEF, EXP, _OldS1, _OldS2, StatusEffects), % ATK, DEF are recalculated for new species
    get_pokemon_base_stats_lvl5(Species, _, _, _, _, _, _, _, _, EvolveTo, EvolveLevel),
    ( EvolveTo \== none, Level >= EvolveLevel ->
        format('What? ~w is evolving!~n', [Species]),
        ( (EvolveTo == 'Charmeleon' ; EvolveTo == 'Wartortle'), Level == 15 ->
            calculate_evolved_stats_lvl15(EvolveTo, EvoMaxHP, EvoATK, EvoDEF)
        ; calculate_stats_for_level(EvolveTo, Level, EvoMaxHP, EvoATK, EvoDEF)
        ),
        NewCurrentHP is round((CurrentHP / MaxHP) * EvoMaxHP),
        (NewCurrentHP > EvoMaxHP -> FinalCurrentHP = EvoMaxHP ; FinalCurrentHP = NewCurrentHP),
        get_active_skills(EvolveTo, Level, NewSkill1, NewSkill2),
        PokemonOut = pokemon(EvolveTo, Level, FinalCurrentHP, EvoMaxHP, EvoATK, EvoDEF, EXP, NewSkill1, NewSkill2, StatusEffects),
        format('Congratulations! Your ~w evolved into ~w!~n', [Species, EvolveTo])
    ; PokemonOut = PokemonIn
    ).

% --- Map Display ---
show_map_command :-
    player_location(PlayerX, PlayerY),
    moves_left(Moves),
    map_width(W), map_height(H),
    format('Moves Left: ~w~n', [Moves]),
    forall(between(0, H-1, Y),
           ( forall(between(0, W-1, X),
                    ( (X == PlayerX, Y == PlayerY) -> write('P ')
                    ; map_layout(X,Y,'C') -> write('C ')
                    ; map_layout(X,Y,'#') -> write('# ')
                    ; map_layout(X,Y,'H') -> write('H ')
                    ; write('. ')
                    )
                   ),
             nl
           )
          ).

% --- Bag Display ---
show_bag_command :-
    player_bag(BagList),
    writeln('--- Your Bag ---'),
    ( BagList == [] -> writeln('  Bag is empty.')
    ; writeln('Items:'),
      display_bag_items(BagList, 1)
    ),
    writeln('------------------').

display_bag_items([], _).
display_bag_items([item(pokeball, empty) | T], N) :- !,
    format('  ~w. Pokeball (Empty)~n', [N]),
    N1 is N + 1,
    display_bag_items(T, N1).
display_bag_items([item(pokeball, filled(pokemon(S,L,CH,MH,_,_,_,_,_,_))) | T], N) :- !,
    format('  ~w. Pokeball (Filled: ~w Lvl:~w HP:~w/~w)~n', [N, S, L, CH, MH]),
    N1 is N + 1,
    display_bag_items(T, N1).
display_bag_items([_Item | T], N) :-
    N1 is N + 1,
    display_bag_items(T, N1).

% --- Game Over and Boss ---
check_game_over_conditions_and_halt :-
    ( player_party(Party), Party \== [], forall(member(pokemon(_,_,0,_,_,_,_,_,_,_), Party), true) ->
        game_state(CurrentState),
        ( CurrentState == boss_battle ->
            writeln('All your Pokemon fainted against the final boss... Game Over.'), halt
        ; writeln('All your Pokemon fainted! Game Over.'), halt
        )
    ; moves_left(M), M =< 0, \+ game_state(boss_battle), \+ game_state(game_over) ->
        writeln('--------------------------------------'),
        writeln('You have run out of moves!'),
        initiate_final_boss_battle,
        retractall(game_state(_)), assertz(game_state(boss_battle))
    ; true
    ).

initiate_final_boss_battle :-
    writeln('The air crackles with immense power...'),
    writeln('The Legendary MEWTWO appears for the final battle!'),
    _BossData = pokemon('Mewtwo', 20, 250, 250, 300, 250, 0, 'Psychic Blast', 'Mind Shock', [immune]), % _BossData for singleton
    writeln('Prepare yourself!').

% --- Player Actions ---
execute_move(Direction) :-
    game_state(exploring),
    player_location(OldX, OldY),
    map_width(W), map_height(H),
    ( Direction == up    -> NewX = OldX, NewY is OldY - 1
    ; Direction == down  -> NewX = OldX, NewY is OldY + 1
    ; Direction == left  -> NewX is OldX - 1, NewY = OldY
    ; Direction == right -> NewX is OldX + 1, NewY = OldY
    ; NewX = OldX, NewY = OldY % Default if direction unknown, prevents crash
    ),
    ( (Direction == up; Direction == down; Direction == left; Direction == right), % Check if direction was valid
      NewX >= 0, NewX < W, NewY >= 0, NewY < H ->
        retract(player_location(OldX, OldY)),
        assertz(player_location(NewX, NewY)),
        format('Moved ~w to (~w, ~w).~n', [Direction, NewX, NewY]),
        player_party(CurrentParty), maplist(heal_pokemon_percent(20), CurrentParty, UpdatedParty),
        retract(player_party(_)), assertz(player_party(UpdatedParty)),
        player_bag(CurrentBag), maplist(heal_filled_pokeball_percent(20), CurrentBag, UpdatedBag),
        retract(player_bag(_)), assertz(player_bag(UpdatedBag)),
        writeln('All your Pokemon healed for 20% of their Max HP.'),
        moves_left(M), M1 is M - 1, retract(moves_left(M)), assertz(moves_left(M1)),
        check_tile_encounter(NewX, NewY)
    ; \+ (Direction == up; Direction == down; Direction == left; Direction == right) -> writeln('Unknown move direction.')
    ; writeln('Cannot move there, you are at the edge of the map!')
    ), !.
execute_move(_) :- writeln('Cannot move right now.').

check_tile_encounter(X,Y) :-
    ( wild_pokemon_at(X, Y, Species, Level) ->
        format('You encountered a wild Lvl ~w ~w!~n', [Level, Species])
    ; map_layout(X,Y,'#') ->
        writeln('You stepped into tall grass... nothing seems to be here right now.')
    ; map_layout(X,Y,'H') ->
        writeln('You arrived at a PokeCenter!')
    ; true
    ).

heal_pokemon_percent(Percent, pokemon(S,L,CH,MH,A,D,E,Sk1,Sk2,St), pokemon(S,L,NewCH,MH,A,D,E,Sk1,Sk2,St)) :-
    HealAmount is round(MH * (Percent / 100)),
    TempCH is CH + HealAmount,
    ( TempCH > MH -> NewCH = MH ; NewCH = TempCH ).

heal_filled_pokeball_percent(Percent, item(pokeball, filled(PokemonIn)), item(pokeball, filled(PokemonOut))) :-
    !, heal_pokemon_percent(Percent, PokemonIn, PokemonOut).
heal_filled_pokeball_percent(_, Item, Item).

interact_command :-
    game_state(exploring),
    player_location(X,Y),
    ( wild_pokemon_at(X,Y,Species,Level) ->
        format('Interacting with Lvl ~w ~w.~n', [Level,Species]),
        writeln('Battle system placeholder: You chose to battle!'),
        retract(wild_pokemon_at(X,Y,Species,Level)),
        ( map_layout(X,Y,'C') -> retract(map_layout(X,Y,'C')), assertz(map_layout(X,Y,'.')) ; true )
    ; map_layout(X,Y,'H') ->
        writeln('This is a PokeCenter. Type ''heal'' to restore your Pokemon''s HP (max 2 times).')
    ; writeln('Nothing special to interact with here.')
    ).

set_party_command(_IdxParty, _IdxBag) :-
    writeln('Set party command is a placeholder. Needs implementation.').

heal_command :-
    game_state(exploring),
    player_location(X,Y), map_layout(X,Y,'H'), % Must be at H
    heal_count(HealCount), max_heal_pokecenter(MaxHeal),
    ( HealCount < MaxHeal ->
        player_party(OldParty),
        maplist(full_heal_pokemon, OldParty, NewParty),
        retract(player_party(OldParty)), assertz(player_party(NewParty)),
        player_bag(OldBag),
        maplist(full_heal_filled_pokeball, OldBag, NewBag),
        retract(player_bag(OldBag)), assertz(player_bag(NewBag)),
        NewHealCount is HealCount + 1,
        retract(heal_count(HealCount)), assertz(heal_count(NewHealCount)),
        RemainingHeals is MaxHeal - NewHealCount,
        writeln('All your Pokemon have been fully healed!'),
        format('You can heal ~w more time(s) at a PokeCenter.~n', [RemainingHeals])
    ; writeln('You have already used the PokeCenter the maximum number of times.')
    ).
heal_command :- writeln('You are not at a PokeCenter or cannot heal now.').

full_heal_pokemon(pokemon(S,L,_,MH,A,D,E,Sk1,Sk2,St), pokemon(S,L,MH,MH,A,D,E,Sk1,Sk2,St)).
full_heal_filled_pokeball(item(pokeball, filled(PokemonIn)), item(pokeball, filled(PokemonOut))) :-
    !, full_heal_pokemon(PokemonIn, PokemonOut).
full_heal_filled_pokeball(Item, Item).