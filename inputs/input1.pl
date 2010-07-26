
edge1(1,2).
edge1(2,3).

path1(X,Z):-edge1(X,Y),path1(Y,Z).   
path1(X,Z):-edge1(X,Z).   

path2(X,Z):-edge(X,Z).
path2(X,Z):-path2(X,Y),path2(Y,Z).   



go1(Z):- path1(1,Z).
%go1.

%go2:- path2(1,Y),write(1),write(','),write(Y),nl.
%go2.

%:-go2. 
