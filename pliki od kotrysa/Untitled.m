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

%przeplot
M = 16;
% czy taki rozmiar tablicy do przeplotu jest w porzÄdku? 
k = log2(M);
y = reshape(x, length(x)/k, k)'; %wpisane wierszami do macierzy
[m,n]=size(y);
x = reshape(y, m*n ,1)'; %z macerzy odczytane kolumnami i wpisane do vektora

%kodowanie 2
x = convenc(x,trellis);

%dekodowanie 1
% nie wiem jakÄ wartoĹÄ powinnam tutaj daÄ, na razie zostawiĹam 16
tb = 16;
x = vitdec(x,trellis,tb,'term','hard');

%rozplot 
x = reshape(x,k, length(x)/k)';
x = reshape(x,1,[]);

%dekodowanie 2
x = vitdec(x,trellis,tb,'term','hard');
cut_here = length(x) - length(zero_vec);
x = x(1:cut_here)




