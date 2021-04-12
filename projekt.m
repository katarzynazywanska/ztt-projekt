clc
clear

% parametr R = k/n,
% Sprawność kodowania R = k/n,
% k =liczba danych wejściowych, 
% n - liczba danych wejściowych + bity nadmiarowe,   
 

%Nadajnik 

% 1. Źródło danych użytkowych (alternatywnie: a albo b):
%       a) należy wylosować wektor binarny o zadanym rozmiarze.
%       b) należy z wskazanego pliku danych wczytać taką liczbę bajtów by zapełnić żądany 
%          rozmiar wektora binarnego danych użytkowych
%               i) na wczytanym wektorze danych należy przeprowadzić operacje wybielania 
%                  (XOR ze znaną sekwencja pseudolosową o własnościach zbliżonych do szumu białego) 
%                   Additive (synchronous) scramblers: https://en.wikipedia.org/wiki/Scrambler

% a):
n = 50000; % n = 500, 5000, 50000
users_data = randi([0 1],n,1); %wektor m losowych wartości binarnych 


% 2. Kodowanie detekcyjne CRC
% Na wektorze danych należy wyliczyć 32 bitową sumę kontrolna CRC za pomocą standardowego wielomianu 
% sumy kontrolnej (CRC-32: 0x04C11DB7). Sumę dołączyć na końcu wektora danych
% (https://en.wikipedia.org/wiki/Cyclic_redundancy_check ) 
% !! długość wektora zwiększa się o 32 bity sumy kontrolnej

crc32 = comm.CRCGenerator('Polynomial',...
    'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
    'InitialConditions',1,'DirectMethod',true,'FinalXOR',1); %32-bit CRC
us_data_with_crc32 = crc32(users_data) %wektor danych wejściowych + 32 bity crc

R = length(users_data)/length(us_data_with_crc32);

% 4. Zamiana bitów na symbole oraz modulacja 16-QAM
% Zamiana bitów na symbole – na tym etapie w zależności od rodzaju modulacji następuje 
% grupowanie bitów w symbole (np. po 2 przy modulacji 4PSK, 3 przy 8 PSK , 4 przy 16 QAM 
% itd.) o takiej wartościowości jaka jest wartościowość konstelacji sygnałów. Otrzymujemy 
% wektor etykiet.

exchange_bytes_to_symbols = nrSymbolModulate(us_data_with_crc32,'16QAM') %efektem tej funkcji jest punkt 5. z opisu
scatterplot(exchange_bytes_to_symbols)

% 5. Modulacja cyfrowa
% Na tym etapie mamy wektor liczb (etykiet) z których każda reprezentuje jeden elementów konstelacji sygnałów. 
% Etykiety sygnałów są zamieniane na zmodulowany sygnał, który wypełnia założony odstęp modulacji. 
% Sposób zamiany zależy od rodzaju modulacji. 
%       a) W przypadku prostej modulacji wąskopasmowej jak np. 4 PSK czy 16 QAM etykieta 
%          sygnału jest zastępowana przez pojedynczą wartość zespoloną reprezentującą 
%          zmodulowany sygnał w paśmie podstawowym x = a+jb gdzie a i b stanowa 
%          odpowiednio składowa syn-fazową i kwadraturowa sygnału. Czas trwania tego 
%          sygnału jest równy odstępowi modulacji. Przy założeniu zastosowania idealnych 
%          filtrów dopasowanych w odbiorniku sygnał w całym odstępie modulacji może być 
%          reprezentowany tą pojedynczą próbka sygnału zespolonego.

%-----------------------------------------------------------------------------------------------------------

%Kanał transmisyjny

% 1. AWGN
% Najprostszą odmiana kanału transmisyjnego jest kanał AWGN o zadanym poziomie SNR.
% Kanał taki jest realizowany poprzez dodawanie do każdej kolejnej zespolonej próbki sygnału 
% w dziedzinie czasu wylosowanej próbki zespolonej z generatora o zespolonym rozkładzie 
% Gausa o wartości średniej 0 i wariancji 1, przeskalowanej liniowo do zadanego poziomu SNR.

awgnchannel = comm.AWGNChannel
awgnchannel.NoiseMethod = 'Signal to noise ratio (SNR)'
awgnchannel.SNR = 20 %??? nie mam bladego pojęcia jakie to SNR powinno być

outsignal = awgnchannel(exchange_bytes_to_symbols)
scatterplot(outsignal)

%-----------------------------------------------------------------------------------------------------------

%Odbiornik

% 1. Demodulacja sygnału
% Celem demodulacji jest wyznaczenie etykiety nadawanego symbolu 
% z konstelacji sygnałów na podstawie odebranej próbki lub próbek sygnału. W najprostszym 
% przypadku demodulator podejmuje decyzje o etykiecie na podstawie kryterium największej 
% wiarygodności. Należy wyliczyć odległości w przestrzeni sygnału pomiędzy każdym z 
% sygnałów z konstelacji sygnałów a sygnałem odebranym i wskazać ten o najmniejszej 
% odległości jako odebrany i zwrócić jego cyfrowa etykietę. Taki demodulator jest nazywany 
% demodulatorem twardo decyzyjnym. Demodulator zamiast cyfrowej etykiety może zwrócić 
% wektor współczynników prawdopodobieństwa nadania każdego z elementów konstelacji. Ta 
% dodatkowa informacja może być używana w procesie dekodowania kodu protekcyjnego. 
% Mówimy wtedy o demodulatorze miękko decyzyjnym symbolowym. Inna odmiana takiego 
% demodulatora to demodulator miękko decyzyjny bitowy. Na podstawie odległości pomiędzy 
% sygnałem odebranym a sygnałem z konstelacji sygnałów, oraz znajomości etykiet tych 
% sygnałów można wyliczyć współczynniki prawdopodobieństwa dla poszczególnych bitów w 
% etykiecie sygnału z konstelacji sygnałów.
%             a) Demodulator twardo decyzyjny
%             b) Demodulator miękko decyzyjny
%                 i) Symbolowy
%                 ii) Bitowy

% a)
demodbits = nrSymbolDemodulate(outsignal,'16QAM','DecisionType','Hard')
numErr = biterr(us_data_with_crc32,demodbits)
