clc
clear

%przykĹadowy wektor danych
x = [ 0 0 1 1  1 1 0 1]

constraint_length = 7; % 7 input bits : 171 and 133
trellis = poly2trellis(constraint_length,[171 133]);
zero_vec = zeros(1,constraint_length + 1);
x = [x zero_vec]; %dodanie zer na koĹcu wektora

%kodowanie 1
x = convenc(x,trellis);

%dekodowanie 1
% nie wiem jakÄ wartoĹÄ powinnam tutaj daÄ, na razie zostawiĹam 16
tb = 7;
x = vitdec(x,trellis,tb,'term','hard');

cut_here = length(x) - length(zero_vec);
x = x(1:cut_here)




