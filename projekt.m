clc
clear
%Nadajnik, 

% 1. wariant a 
m = 1;
n = 100;
users_data = randi([0 1],n,m) %wektor m losowych wartości binarnych 


%CRC
poly = hexToBinaryVector('104C11DB7');
crc32 = comm.CRCGenerator('Polynomial',...
    'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
    'InitialConditions',1,'DirectMethod',true,'FinalXOR',1); %32-bit CRC
us_data_with_crc32 = crc32(users_data); %wektor danych wejściowych + 32 bity crc

