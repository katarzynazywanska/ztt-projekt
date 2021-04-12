clc
clear
%Nadajnik 

% 1. Źródło danych użytkowych, wariant a 
m = 1;
n = 5000;
users_data = randi([0 1],n,m); %wektor m losowych wartości binarnych 


% 2. Kodowanie detekcyjne CRC
poly = hexToBinaryVector('104C11DB7');
crc32 = comm.CRCGenerator('Polynomial',...
    'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
    'InitialConditions',1,'DirectMethod',true,'FinalXOR',1); %32-bit CRC
us_data_with_crc32 = crc32(users_data); %wektor danych wejściowych + 32 bity crc

% 4. Zamiana bitów na symbole (16QAM)
exchange_bytes_to_symbols = nrSymbolModulate(us_data_with_crc32,'16QAM'); %efektem tej funkcji jest punkt 5. z opisu
scatterplot(exchange_bytes_to_symbols);

%Kanał transmisyjny
awgnchannel = comm.AWGNChannel;
outsignal = awgnchannel(exchange_bytes_to_symbols);
scatterplot(outsignal);


% Sprawność kodowania R = k/n, 
% k =liczba danych wejściowych, 
% n - liczba danych wejściowych + bity nadmiarowe,   
R = length(users_data)/length(us_data_with_crc32); 
