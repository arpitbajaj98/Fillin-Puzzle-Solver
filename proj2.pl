% You can use this code to get started with your fillin puzzle solver.
% Make sure you replace this comment with your own documentation.

:- ensure_loaded(library(clpfd)).

% https://stackoverflow.com/questions/27760689/sort-a-list-of-structures-by-the-size-of-a-list
el_keyed(El,N-El) :-
	
	length(El, N).
 
sort_wordlist(Els, ElsS) :-
	maplist(el_keyed, Els, KVs),
	keysort(KVs, KVsS),
	reverse(KVsS, RVsS),
	
	maplist(el_keyed, ElsS, RVsS).
 
main(PuzzleFile, WordlistFile, SolutionFile) :-
	read_file(PuzzleFile, Puzzle),
	read_file(WordlistFile, Wordlist),
	valid_puzzle(Puzzle),
	solve_puzzle(Puzzle, Wordlist, Solved),
	print_puzzle(SolutionFile, Solved).

read_file(Filename, Content) :-
	open(Filename, read, Stream),
	read_lines(Stream, Content),
	close(Stream).

read_lines(Stream, Content) :-
	read_line(Stream, Line, Last),
	(   Last = true
	->  (   Line = []
	    ->  Content = []
	    ;   Content = [Line]
	    )
	;  Content = [Line|Content1],
	    read_lines(Stream, Content1)
	).

read_line(Stream, Line, Last) :-
	get_char(Stream, Char),
	(   Char = end_of_file
	->  Line = [],
	    Last = true
	; Char = '\n'
	->  Line = [],
	    Last = false
	;   Line = [Char|Line1],
	    read_line(Stream, Line1, Last)
	).

print_puzzle(SolutionFile, Puzzle) :-
	open(SolutionFile, write, Stream),
	maplist(print_row(Stream), Puzzle),
	close(Stream).

print_row(Stream, Row) :-
	maplist(put_puzzle_char(Stream), Row),
	nl(Stream).

put_puzzle_char(Stream, Char) :-
	(   var(Char)
	->  put_char(Stream, '_')
	;   put_char(Stream, Char)
	).

valid_puzzle([]).
valid_puzzle([Row|Rows]) :-
	maplist(samelength(Row), Rows).


samelength([], []).
samelength([_|L1], [_|L2]) :-
	same_length(L1, L2).


% solve_puzzle(Puzzle0, WordList, Puzzle)
% should hold when Puzzle is a solved version of Puzzle0, with the
% empty slots filled in with words from WordList.  Puzzle0 and Puzzle
% should be lists of lists of characters (single-character atoms), one
% list per puzzle row.  WordList is also a list of lists of
% characters, one list per word.
%
% This code is obviously wrong: it just gives back the unfilled puzzle
% as result.  You'll need to replace this with a working
% implementation.
solve_puzzle(Puzzle0, WordList, Puzzle) :-
	% Eg. [_G15092255, _G15092258, #, #, _G15092285, _G15092300] -> 
    %   [[_G15092255, _G15092258],[_G15092285, _G15092300]]

	
	sort_wordlist(WordList, SortedWordList),
	fill_puzzle_logical(Puzzle0, PuzzleLogical),
	
	
	create_slots_horizontal(PuzzleLogical, [], SlotList),
	
	transpose(PuzzleLogical, PuzzleVertical),

	create_slots_horizontal(PuzzleVertical, SlotList, Slots),
	sort_wordlist(Slots, SortedSlots),
	
	fill_slot_list(SortedWordList, SortedSlots),


	!,
	

	Puzzle = PuzzleLogical.


	

fill_slot_list([],_).
fill_slot_list([Word|Words], Slots) :-
	member(Word, Slots),
	fill_slot_list(Words, Slots).



fill_puzzle_logical(Puzzle0, PuzzleLogical) :-
	once(fill_puzzle_acc_logical(Puzzle0,[],PuzzleLogical)).

fill_puzzle_acc_logical([], PuzzleLogical, PuzzleLogical).
fill_puzzle_acc_logical([Row|Rows], LogicalAcc, PuzzleLogical):-
	logical_row(Row, LogicalRow),
	
	append(LogicalAcc, [LogicalRow], PuzzleLogical0),
	fill_puzzle_acc_logical(Rows, PuzzleLogical0, PuzzleLogical).

logical_row(Row, LogicalRow) :-
	once(logical_acc_row(Row, [], LogicalRow)).

logical_acc_row([], LogicalRow, LogicalRow).
logical_acc_row([Char|Chars], LogicalRowAcc, LogicalRow) :-
	(
		Char = #
		->	
			append(LogicalRowAcc, [Char], LogicalRow0)
		;	
			(
				is_alpha(Char)
				->	append(LogicalRowAcc, [Char], LogicalRow0)
					
				;	length(Unbound, 1),
					append(LogicalRowAcc, Unbound, LogicalRow0)			
			
			)
	),
	logical_acc_row(Chars, LogicalRow0, LogicalRow).

create_slots_horizontal([],PuzzleSlots,PuzzleSlots).
create_slots_horizontal([Row|Rows],Slots,PuzzleSlots) :-
	slot_row(Row, RowAcc),
	length(Row, RowLen),
	(
			RowLen > 1
			->	append(Slots, RowAcc, PuzzleSlots0),
				create_slots_horizontal(Rows, PuzzleSlots0, PuzzleSlots)
			;	create_slots_horizontal(Rows, Slots, PuzzleSlots)
			
	).
	
% Eg. ['_','_',#,#,'_','_'] -> [_G15092255, _G15092258, #, #, _G15092285, _G15092300]
slot_row(Row, UnboundRow) :-
	% Only need to do it once per row
	once(slot_acc_row(Row, [], UnboundRow)).

slot_acc_row([],UnboundRow,UnboundRow).

slot_acc_row(Row, RowAcc, UnboundRow):-

	(	dif(Row, [])
		->
	
			slot_word(Row, UnboundWord),
			append(RowAcc,[UnboundWord],UnboundRow0),
			length(UnboundWord, WordLen),
			take2(WordLen,Row,Back),
			(
				Back == []
				->	HashNum = 0
				;	remove_hash(Back, HashNum)
			),
			take2(HashNum, Back, NewBack)
		
			
			% (	N > RowLen
			
			% 	->	slot_acc_row([], UnboundRow0, UnboundRow)
			% 	;	take2(N,Row, Back),
			% 		slot_acc_row(Back, UnboundRow0, UnboundRow)

			% )
		
		
	),
	slot_acc_row(NewBack, UnboundRow0, UnboundRow).



slot_word(Row, UnboundWord):-
	length(Row, RowLen),
	RowLen > 0,
	once(slot_acc_word(Row,[],UnboundWord)).

slot_acc_word([],UnboundWord,UnboundWord).

slot_acc_word([Char|Chars], WordAcc,UnboundWord) :-

	(
		Char == '#'
		->	
			(	length(WordAcc, Len),
				Len =:= 0
		
				->	slot_acc_word(Chars, WordAcc, UnboundWord)
				;	slot_acc_word([],WordAcc, UnboundWord)
			)
		;	
			(
				append(WordAcc, [Char], UnboundWord0),
				slot_acc_word(Chars,UnboundWord0,UnboundWord)
				% is_alpha(Char)
				% ->	
				% ;	length(Unbound, 1),
				% 	append(WordAcc, Unbound, UnboundWord0),
				% 	slot_acc_word(Chars,UnboundWord0,UnboundWord)
			
			
			)

	).

			
remove_hash([],_Hash).

remove_hash([Char|Chars], Hash) :-
	(
		Char == '#'
		->	once(remove_acc_hash(Chars,1, Hash))
		; Hash = 0
	).

remove_acc_hash([Char|Chars], HashAcc, TotalHash):-
	(
		Char == '#'
		->	TotalHash0 is HashAcc + 1,
			remove_acc_hash(Chars,TotalHash0,TotalHash)
		;	remove_acc_hash([],HashAcc, TotalHash)
		
	
	).
	
remove_acc_hash([], TotalHash,TotalHash).


	
take(N, List, Back) :-
	length(List, ListLen),
	(
		N =< ListLen
		->	length(Front,N),
			append(Front, Back, List)
		;
		
		take(ListLen, List, Back)
	).
take2(N, List, Back) :-
	length(Front,N),
	append(Front, Back, List).

