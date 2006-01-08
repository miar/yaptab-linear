
:- object(sort(_Type)).

	:- info([
		author is 'Paulo Moura',
		version is 1.0,
		date is 2000/4/22,
		comment is 'List sorting parameterized by the type of the list elements.',
		parnames is ['Type'],
		source is 'Example adopted from the SICStus Objects documentation.']).

	:- uses(list).
	:- calls(comparingp).

	:- public(sort/2).
	:- mode(sort(+list, -list), one).
	:- info(sort/2, [
		comment is 'Sorts a list in ascending order.',
		argnames is ['List', 'Sorted']]).

	:- private(partition/4).
	:- mode(partition(+list, +nonvar, -list, -list), one).
	:- info(partition/4, [
		comment is 'List partition in two sub-lists using a pivot.',
		argnames is ['List', 'Pivot', 'Lowers', 'Biggers']]).

	sort([], []).
	sort([P| L], S) :-
		partition(L, P, Small, Large),
		sort(Small, S0),
		sort(Large, S1),
		list::append(S0, [P| S1], S).

	partition([], _, [], []).
	partition([X| L1], P, Small, Large) :-
		parameter(1, Type),
		(	Type::(X < P) ->
			Small = [X| Small1], Large = Large1
		;	Small = Small1, Large = [X| Large1]
		),
		partition(L1, P, Small1, Large1).

:- end_object.


:- object(rational,
	implements(comparingp)).

	:- info([
		author is 'Paulo Moura',
		version is 1.0,
		date is 2000/4/22,
		comment is 'Implements comparison between rational numbers represented as Num/Den.']).

	N1/D1 < N2/D2 :-
		{N1*D2 < N2*D1}.

	N1/D1 =< N2/D2 :-
		{N1*D2 =< N2*D1}.

	N1/D1 > N2/D2 :-
		{N1*D2 > N2*D1}.

	N1/D1 >= N2/D2 :-
		{N1*D2 >= N2*D1}.

	N1/D1 =:= N2/D2 :-
		{N1*D2 =:= N2*D1}.

	N1/D1 =\= N2/D2 :-
		{N1*D2 =\= N2*D1}.

:- end_object.


:- object(colours,
	implements(comparingp)).

	:- info([
		author is 'Paulo Moura',
		version is 1.0,
		date is 2000/4/22,
		comment is 'Implements comparison between visible colors.']).

	Colour1 < Colour2 :-
		order(Colour1, N1),
		order(Colour2, N2),
		{N1 < N2}.

	Colour1 =< Colour2 :-
		order(Colour1, N1),
		order(Colour2, N2),
		{N1 =< N2}.

	Colour1 > Colour2 :-
		order(Colour1, N1),
		order(Colour2, N2),
		{N1 > N2}.

	Colour1 >= Colour2 :-
		order(Colour1, N1),
		order(Colour2, N2),
		{N1 >= N2}.

	Colour1 =:= Colour2 :-
		{Colour1 == Colour2}.

	Colour1 =\= Colour2 :-
		{Colour1 \== Colour2}.

	order(red, 1).
	order(orange, 2).
	order(yellow, 3).
	order(green, 4).
	order(blue, 5).
	order(indigo, 6).
	order(violet, 7).

:- end_object.