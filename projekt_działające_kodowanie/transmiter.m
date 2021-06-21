function [ symbols, labels ] = transmiter( data, sysp )
%TRANSMITER Summary of this function goes here
%   

% CRC generator ( from lib communication )
% for a new Matlab: eg. R2020
%     CRCgen = comm.CRCGenerator('Polynomial', CRCpoly);
%     crcdata = CRCgen(data);
%
% for an old Matlab: eg. R2009b v.7.9
% generator 0x04C11DB7
% CRCgen = crc.generator('Polynomial', sysp.CRCpoly, 'InitialState', '0xFFFFFFFF');
% CRCdet = crc.detector('Polynomial', sysp.CRCpoly, 'InitialState', '0xFFFFFFFF');
crcdata = generate(sysp.CRCgen, data);

% forward protection encoding
%
trellis = poly2trellis(7,[171 133]);
zero_vec = zeros(1, length(crcdata))';
crcdata = [crcdata ;zero_vec]; %dodanie zer na koncu wektora

%kodowanie 1
crcdata = convenc(crcdata,trellis);

% bits to labels
labels = bi2de( reshape( crcdata, sysp.M, [] )' );

% modulation
% labels to complex symbols (M-PSK or M-QAM modulation)
% constelation is normalized to energy 1
symbols = sysp.constelation( labels + 1 ).';
   
end

