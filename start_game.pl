% start_game.pl
% Menginisialisasi state awal permainan.

% use_module should be at the beginning of the file.
% If 'unknown directive use_module/1' warning persists, your gprolog might
% have random built-in or needs a different way to load libraries.
% For now, we keep it as its standard.
:- use_module(library(random)).

% --- Main Start Game Predicate ---
start_game :-
    cleanup_previous_game_state,
    setup_player_name,
    setup_map_layout,
    setup_player_location_and_starters,
    setup_wild_pokemon,
    setup_map_objects,
    setup_initial_player_items,
    initial_moves(IM), assertz(moves_left(IM)),
    assertz(heal_count(0)),
    assertz(game_state(exploring)),
    player_name(Player),
    format('Welcome, Trainer ~w! Your Pokémon adventure begins.~n', [Player]).

cleanup_previous_game_state :-
    retractall(player_name(_)),
    retractall(player_location(_, _)),
    retractall(player_party(_)),
    retractall(player_bag(_)),
    retractall(map_layout(_, _, _)),
    retractall(wild_pokemon_at(_, _, _, _)),
    retractall(game_state(_)),
    retractall(moves_left(_)),
    retractall(heal_count(_)).

setup_player_name :-
    write('Enter your name, Trainer: '), flush_output,
    read_line_to_string(user_input, PlayerName),
    assertz(player_name(PlayerName)).

setup_map_layout :-
    map_width(W), map_height(H),
    forall(between(0, W-1, X),
           forall(between(0, H-1, Y),
                  assertz(map_layout(X,Y,'.'))
                 )
          ).

setup_player_location_and_starters :-
    map_width(W), map_height(H),
    random_between(0, W-1, PlayerX),
    random_between(0, H-1, PlayerY),
    assertz(player_location(PlayerX, PlayerY)),
    format('You start your journey at map coordinates (~w, ~w).~n', [PlayerX, PlayerY]),
    writeln('You will start with 2 common Pokémon at Level 1.'),
    findall(S, (pokemon_data(S, common, _, _, _, _, _, _, _, EvoTo, _), \+ member(EvoTo, ['Charmeleon', 'Wartortle']), S \== 'Charmeleon', S \== 'Wartortle'), CommonStarterPool),
    ( CommonStarterPool == [] -> writeln('Error: No valid common starter Pokemon defined in facts.pl! Check conditions.'), halt ; true ),
    random_permutation(CommonStarterPool, RandomizedStarters),
    ( length(RandomizedStarters, Len), Len >= 2 ->
        nth0(0, RandomizedStarters, Starter1Species),
        nth0(1, RandomizedStarters, Starter2Species),
        ChosenStarters = [Starter1Species, Starter2Species]
    ; writeln('Error: Not enough unique common non-evolving starters! Need at least 2.'),
      writeln('Available: '), writeln(CommonStarterPool), halt
    ),
    maplist(init_pokemon_instance(1), ChosenStarters, InitialParty),
    assertz(player_party(InitialParty)),
    format('Your starting Pokémon are: ~w and ~w.~n', ChosenStarters).

init_pokemon_instance(Level, Species, pokemon(Species, Level, MaxHP, MaxHP, ATK, DEF, 0, Skill1, Skill2, [])) :-
    calculate_stats_for_level(Species, Level, MaxHP, ATK, DEF),
    get_active_skills(Species, Level, Skill1, Skill2).

setup_wild_pokemon :-
    map_width(W), map_height(H),
    place_wild_pokemon_category(legendary, W, H),
    place_wild_pokemon_category(epic, W, H),
    place_wild_pokemon_category(rare, W, H),
    place_wild_pokemon_category(common, W, H).

place_wild_pokemon_category(Rarity, W, H) :-
    wild_pokemon_counts(Rarity, NumToPlace),
    findall(S, pokemon_data(S, Rarity, _, _, _, _, _, _, _, _, _), PokemonPool),
    ( PokemonPool == [] -> format('Warning: No Pokemon defined for rarity ~w in facts.pl.~n', [Rarity])
    ; place_specific_wild_pokemon_loop(NumToPlace, Rarity, PokemonPool, W, H)
    ).

place_specific_wild_pokemon_loop(0, _, _, _, _) :- !.
place_specific_wild_pokemon_loop(N, Rarity, PokemonPool, W, H) :-
    random_member(Species, PokemonPool),
    random_between(3, 15, Level),
    find_spot_and_place_pokemon(1, Species, Level, Rarity, W, H), % Start attempt at 1
    N1 is N - 1,
    place_specific_wild_pokemon_loop(N1, Rarity, PokemonPool, W, H).

find_spot_and_place_pokemon(MaxAttempts, _, _, _, _, _) :- MaxAttempts > 200, !,
    writeln('Warning: Could not find a spot for a wild Pokemon after many attempts.').
find_spot_and_place_pokemon(_Attempt, Species, Level, Rarity, W, H) :- % _Attempt if not used in this clause logic directly
    random_between(0, W-1, X),
    random_between(0, H-1, Y),
    \+ player_location(X,Y),
    \+ wild_pokemon_at(X,Y,_,_),
    assertz(wild_pokemon_at(X,Y,Species,Level)),
    ( Rarity == common, map_layout(X,Y,'.') ->
        retract(map_layout(X,Y,'.')), assertz(map_layout(X,Y,'C'))
    ; true
    ), !.
find_spot_and_place_pokemon(Attempt, Species, Level, Rarity, W, H) :-
    NewAttempt is Attempt + 1,
    find_spot_and_place_pokemon(NewAttempt, Species, Level, Rarity, W, H).

setup_map_objects :-
    map_width(W), map_height(H),
    num_grass_patches(NumGrass),
    place_map_symbols_randomly(NumGrass, '#', W, H),
    place_map_symbols_randomly(1, 'H', W, H).

place_map_symbols_randomly(0, _, _, _) :- !.
place_map_symbols_randomly(N, Symbol, W, H) :-
    find_spot_and_place_symbol(1, Symbol, W, H), % Start attempt at 1
    N1 is N - 1,
    place_map_symbols_randomly(N1, Symbol, W, H).

find_spot_and_place_symbol(MaxAttempts, _, _, _) :- MaxAttempts > 200, !,
     writeln('Warning: Could not find a spot for a map symbol after many attempts.').
find_spot_and_place_symbol(_Attempt, Symbol, W, H) :- % _Attempt if not used in this clause logic directly
    random_between(0, W-1, X),
    random_between(0, H-1, Y),
    map_layout(X,Y,'.'),
    \+ player_location(X,Y),
    retract(map_layout(X,Y,'.')),
    assertz(map_layout(X,Y,Symbol)), !.
find_spot_and_place_symbol(Attempt, Symbol, W, H) :-
    NewAttempt is Attempt + 1,
    find_spot_and_place_symbol(NewAttempt, Symbol, W, H).

setup_initial_player_items :-
    initial_pokeballs(NumPokeballs),
    max_bag_slots(MaxSlots),
    ( NumPokeballs > 0 ->
        length(EmptyPokeballItemsProto, NumPokeballs), % Create a list of a certain length
        maplist(=(item(pokeball, empty)), EmptyPokeballItemsProto),
        ( length(EmptyPokeballItemsProto, ActualNum), ActualNum > MaxSlots ->
            length(LimitedPokeballs, MaxSlots),
            append(LimitedPokeballs, _, EmptyPokeballItemsProto) % Take only MaxSlots
        ; LimitedPokeballs = EmptyPokeballItemsProto
        ),
        assertz(player_bag(LimitedPokeballs)),
        length(LimitedPokeballs, Count),
        format('~w empty Pokeballs added to your bag.~n', [Count])
    ; assertz(player_bag([])), % No initial pokeballs if NumPokeballs is 0
      writeln('No initial Pokeballs added to your bag.')
    ).