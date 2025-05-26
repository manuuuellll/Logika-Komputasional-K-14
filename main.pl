% main.pl
% File utama untuk menjalankan permainan Pokemon.

% --- Deklarasi Dynamic Facts Utama ---
% PASTIKAN SETIAP BARIS INI DIAKHIRI DENGAN TITIK.
:- dynamic player_name/1.
:- dynamic player_location/2.
:- dynamic player_party/1.
:- dynamic player_bag/1.
:- dynamic map_layout/3.
:- dynamic wild_pokemon_at/4.
:- dynamic game_state/1.
:- dynamic moves_left/1.
:- dynamic heal_count/1.

% --- Memuat Modul-Modul Game dengan 'include' ---
% PASTIKAN SETIAP BARIS INI JUGA DIAKHIRI DENGAN TITIK.
:- include('facts.pl').
:- include('rules.pl').
:- include('start_game.pl').

% --- Main Game Predicate ---
run_pokemon_game :-
    write('Initializing Pokémon Logic Adventure...'), nl,
    start_game, % Ini akan memanggil start_game/0 dari start_game.pl (via include)
    nl, write('--- Game Started ---'), nl,
    game_loop.

% --- Game Loop ---
game_loop :-
    check_game_over_conditions_and_halt, % Jika game over, ini akan halt.
    game_state(CurrentState),
    ( CurrentState == exploring ->
        show_map_command,
        print_exploration_options,
        write('Enter command: '), flush_output,
        read_line_to_string(user_input, CommandString),
        ( CommandString == "halt" ->
            writeln('Exiting game. Thanks for playing!'), halt
        ; parse_and_execute_command(CommandString) -> true % Perintah berhasil dieksekusi
        ; writeln('Invalid command or action failed. Please try again.') % Perintah gagal atau tidak dikenal
        )
    ; CurrentState == battle -> % Placeholder
        writeln('--- In Battle! (Battle system not fully implemented) ---'),
        writeln('Battle ends. Returning to exploration.'),
        retractall(game_state(_)), assertz(game_state(exploring))
    ; CurrentState == boss_battle -> % Placeholder
        writeln('--- Final Boss Battle! (Boss battle system not fully implemented) ---'),
        writeln('Boss battle sequence placeholder.'),
        writeln('You were defeated by the Boss (placeholder). Game Over.'),
        retractall(game_state(_)), assertz(game_state(game_over)), halt
    ; CurrentState == game_over -> % Jika state diubah ke game_over oleh check_game_over_conditions_and_halt
        writeln('Game has ended.'), !, fail % Hentikan loop jika game_over (fail agar tidak rekursi)
    ; writeln('Error: Unknown game state! Halting.'), halt
    ),
    game_loop. % Rekursi untuk loop berikutnya, hanya jika tidak halt atau fail.

print_exploration_options :-
    writeln('Options: moveUp, moveDown, moveLeft, moveRight, showBag, interact, setParty(P_idx,B_idx).'),
    ( player_location(X,Y), map_layout(X,Y,'H') -> % Cek apakah di PokeCenter
        writeln('At PokeCenter? Type ''heal'' to heal your Pokemon.')
    ; true % Bukan di pokecenter, tidak ada opsi heal tambahan
    ),
    writeln('Type "halt" to exit.').

% --- Command Parsing and Execution ---
parse_and_execute_command(InputString) :-
    normalize_space(atom(CleanAtom), InputString), % Menghilangkan spasi ekstra, konversi ke atom
    downcase_atom(CleanAtom, CommandAtom), % Ubah ke huruf kecil
    ( CommandAtom == 'moveup' -> execute_move(up)
    ; CommandAtom == 'movedown' -> execute_move(down)
    ; CommandAtom == 'moveleft' -> execute_move(left)
    ; CommandAtom == 'moveright' -> execute_move(right)
    ; CommandAtom == 'showbag' -> show_bag_command
    ; CommandAtom == 'interact' -> interact_command
    ; CommandAtom == 'heal' -> heal_command % heal_command akan cek kondisinya sendiri
    ; term_to_atom(TermCommand, CommandAtom), % Mencoba mem-parse perintah dengan argumen
      ( TermCommand = setparty(PidxAtom,BidxAtom) ->
            catch(atom_number(PidxAtom, Pidx), _, fail), % Gagal jika bukan angka
            catch(atom_number(BidxAtom, Bidx), _, fail), % Gagal jika bukan angka
            set_party_command(Pidx,Bidx)
      ; fail % Jika bukan setparty atau format argumen salah
      )
    ; write('Unknown command: "'), write(InputString), writeln('"'), fail % Jika tidak ada yang cocok
    ).
parse_and_execute_command(_) :- fail. % Default fail jika parsing di atas gagal

% --- Alias untuk menjalankan game ---
main :-
    run_pokemon_game.