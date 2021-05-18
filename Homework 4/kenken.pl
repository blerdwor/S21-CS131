% GENERAL HELPER RULES

% Wrapper predicate for length
list_length(N,L) :-
        length(L,N).

% Transpose an array 
% https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/blob/Winter2020/Prolog/sudoku_cell.pl
transpose([], []).
transpose([F|Fs], Ts) :-
    transpose(F, [F|Fs], Ts).
transpose([], _, []).
transpose([_|Rs], Ms, [Ts|Tss]) :-
        lists_firsts_rests(Ms, Ts, Ms1),
        transpose(Rs, Ms1, Tss).
lists_firsts_rests([], [], []).
lists_firsts_rests([[F|Os]|Rest], [F|Fs], [Os|Oss]) :-
        lists_firsts_rests(Rest, Fs, Oss).

% Given square coordinates, extract that number from the grid
get_numbers([],_,[]).
get_numbers([[R|C]|Tl],Grid,L) :-
	nth(R,Grid,Row),
	nth(C,Row,Col),
	get_numbers(Tl,Grid,L2),
	L = [Col|L2].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% KENKEN SOLVER

% Elements within list L are in the domain from 1 to N
domain_N(N,L) :-
        fd_domain(L,1,N).

% Sum up all the numbers in a list
sum([],X,X).
sum([Hd|Tl], Acc, S) :- 
	Acc2 #= Acc + Hd, 
	sum(Tl,Acc2,S).

% Handle + operator
process_add(+(S,L),Grid) :-
	get_numbers(L,Grid,Numlst),
	sum(Numlst,0,Sum),
	S #= Sum.

% Handle - operator
process_sub(-(D,[R1|C1],[R2|C2]),Grid) :-
	nth(R1,Grid,Row1),
        nth(C1,Row1,Col1),
	nth(R2,Grid,Row2),
        nth(C2,Row2,Col2),
	Diff1 = Col1 - Col2,
	Diff2 = Col2 - Col1,
	(D #= Diff1; D #= Diff2).

% Multiply all the numbers in a list
mult([],X,X).
mult([Hd|Tl], Acc, P) :-
        Acc2 #= Acc * Hd,
        mult(Tl,Acc2,P).

% Handle * operator
process_mult(*(P,L),Grid) :-
	get_numbers(L,Grid,Numlst),
	mult(Numlst,1,Prod),
	P #= Prod.

% Handle / operator
process_div(/(Q,[R1|C1],[R2|C2]),Grid) :-
	nth(R1,Grid,Row1),
        nth(C1,Row1,Col1),
        nth(R2,Grid,Row2),
        nth(C2,Row2,Col2),
        Quo1 = Col1 / Col2,
        Quo2 = Col2 / Col1,
        (Q #= Quo1; Q #= Quo2).

% Check every cage constraint  
satisfy_cages(_,[]).
satisfy_cages(Grid,[Hd|Tl]) :-
	(process_add(Hd,Grid); 
	process_sub(Hd,Grid); 
	process_mult(Hd,Grid); 
	process_div(Hd,Grid)),
	satisfy_cages(Grid,Tl).

% Actual kenken solver
kenken(N,C,T) :-
	% Restrain T to be an NxN grid
	length(T,N),
	maplist(list_length(N),T),
	% Restrain all rows in T to have unique elements
	maplist(fd_all_different,T),
	maplist(domain_N(N),T),
	% Restrain all cols in T to have unique elements
	transpose(T,Transposed),
	maplist(fd_all_different,Transposed),
	% Cage constraints
	satisfy_cages(T,C),
	% Label
	maplist(fd_labeling,T).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% PLAIN_KENKEN SOLVER

% all_unique from Amit's slides 
all_different([]).
all_different([Hd | Tl]) :-    
	member(Hd, Tl), !, fail.
all_different([_ | Tl]) :-    
	all_different(Tl).

% unordered_range from Amit's slides
unordered_range(N, Res) :-    
	length(Res, N),    
	maplist(between(1, N), Res),    
	all_different(Res).

% Sum up all the numbers in a list
plain_sum([],X,X).
plain_sum([Hd|Tl], Acc, S) :-
        Acc2 is Acc + Hd,
        plain_sum(Tl,Acc2,S).

% Handle + operator
plain_process_add(+(S,L),Grid) :-
        get_numbers(L,Grid,Numlst),
        plain_sum(Numlst,0,Sum),
        S =:= Sum.

% Handle - operator
plain_process_sub(-(D,[R1|C1],[R2|C2]),Grid) :-
        nth(R1,Grid,Row1),
        nth(C1,Row1,Col1),
        nth(R2,Grid,Row2),
        nth(C2,Row2,Col2),
        Diff1 = Col1 - Col2,
        Diff2 = Col2 - Col1,
        (D =:= Diff1; D =:= Diff2).

% Multiply all the numbers in a list
plain_mult([],X,X).
plain_mult([Hd|Tl], Acc, P) :-
        Acc2 is Acc * Hd,
        plain_mult(Tl,Acc2,P).

% Handle * operator
plain_process_mult(*(P,L),Grid) :-
        get_numbers(L,Grid,Numlst),
        plain_mult(Numlst,1,Prod),
        P =:= Prod.

% Handle / operator
plain_process_div(/(Q,[R1|C1],[R2|C2]),Grid) :-
        nth(R1,Grid,Row1),
        nth(C1,Row1,Col1),
        nth(R2,Grid,Row2),
        nth(C2,Row2,Col2),
        Quo1 = Col1 / Col2,
        Quo2 = Col2 / Col1,
        (Q =:= Quo1; Q =:= Quo2).

% Check every cage constraint
plain_satisfy_cages(_,[]).
plain_satisfy_cages(Grid,[Hd|Tl]) :-
        (plain_process_add(Hd,Grid);
        plain_process_sub(Hd,Grid);
        plain_process_mult(Hd,Grid);
        plain_process_div(Hd,Grid)),
        plain_satisfy_cages(Grid,Tl).

% From the TA hint code github repo
% https://github.com/CS131-TA-team/UCLA_CS131_CodeHelp/blob/master/Prolog/plain_domain.pl
within_domain(N, Domain) :- 
    findall(X, between(1, N, X), Domain).

fill_2d([], _).
fill_2d([Head | Tail], N) :-
    within_domain(N, Domain),
    permutation(Domain, Head),
    fill_2d(Tail, N).

% Create an NxN grid filled with elements 1-N
% The rows and columns do not contain repeaing numbers
create_grid(Grid, N) :-
    length(Grid, N),
    fill_2d(Grid, N),
    % All rows are different
    all_different(Grid),
    maplist(all_different,Grid),
    % All columns are different
    transpose(Grid,Transposed),
    maplist(all_different,Transposed).

% Actual plain_kenken solver
plain_kenken(N,C,T) :-
	create_grid(T,N),
	plain_satisfy_cages(T,C).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% TESTCASES

kenken_testcase(
  6,
  [
   +(11, [[1|1], [2|1]]),
   /(2, [1|2], [1|3]),
   *(20, [[1|4], [2|4]]),
   *(6, [[1|5], [1|6], [2|6], [3|6]]),
   -(3, [2|2], [2|3]),
   /(3, [2|5], [3|5]),
   *(240, [[3|1], [3|2], [4|1], [4|2]]),
   *(6, [[3|3], [3|4]]),
   *(6, [[4|3], [5|3]]),
   +(7, [[4|4], [5|4], [5|5]]),
   *(30, [[4|5], [4|6]]),
   *(6, [[5|1], [5|2]]),
   +(9, [[5|6], [6|6]]),
   +(8, [[6|1], [6|2], [6|3]]),
   /(2, [6|4], [6|5])
  ]
).

kenken6_grid(
    [[5,6,3,4,1,2],
     [6,1,4,5,2,3],
     [4,5,2,3,6,1],
     [3,4,1,2,5,6],
     [2,3,6,1,4,5],
     [1,2,5,6,3,4]]).

test_3(
  3,
  [
   /(2, [1|1], [1|2]),
   -(1, [1|3], [2|3]),
   *(9, [[2|1], [3|1], [2|2]]),
   /(2, [3|2], [3|3])
  ]
).

test_4(
  4,
  [
   -(3, [1|1], [2|1]),
   *(6, [[1|2], [1|3], [1|4]]),
   /(2, [2|2], [2|3]),
   +(8, [[3|1], [4|1], [4|2]]),
   -(3, [3|2], [3|3]),
   -(3, [4|3], [4|4]),
   *(6, [[2|4], [3|4]])
  ]
).


test_5(
  5,
  [
   -(4, [1|1], [1|2]),
   -(1, [1|3], [2|3]),
   /(2, [1|4], [1|5]),
   -(2, [2|1], [2|2]),
   *(2, [[2|4], [2|5], [3|5]]),
   +(3, [[3|1], [4|1]]),
   *(96, [[3|2], [4|2], [5|2], [5|1]]),
   -(2, [3|3], [3|4]),
   +(8, [[4|3], [5|3], [5|4]]),
   +(12, [[4|4], [4|5], [5|5]])
  ]
).
