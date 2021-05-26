clc
clear
fftsize = 1024;
crcsize = 32;
% parametr R = k/n,
% Sprawność kodowania R = k/n,
% k =liczba danych wejściowych, 
% n - liczba danych wejściowych + bity nadmiarowe,   
 
M=4; 
sps=1;
%Nadajnik 

% 1. Źródło danych użytkowych (alternatywnie: a albo b):
%       a) należy wylosować wektor binarny o zadanym rozmiarze.
%       b) należy z wskazanego pliku danych wczytać taką liczbę bajtów by zapełnić żądany 
%          rozmiar wektora binarnego danych użytkowych
%               i) na wczytanym wektorze danych należy przeprowadzić operacje wybielania 
%                  (XOR ze znaną sekwencja pseudolosową o własnościach zbliżonych do szumu białego) 
%                   Additive (synchronous) scramblers: https://en.wikipedia.org/wiki/Scrambler

% a):
psize = 2;
packet_length = [500 5000 50000];
  
users_data = randi([0 1],packet_length(psize),1); %wektor m losowych wartości binarnych 

% 2. Kodowanie detekcyjne CRC
% Na wektorze danych należy wyliczyć 32 bitową sumę kontrolna CRC za pomocą standardowego wielomianu 
% sumy kontrolnej (CRC-32: 0x04C11DB7). Sumę dołączyć na końcu wektora danych
% (https://en.wikipedia.org/wiki/Cyclic_redundancy_check ) 
% !! długość wektora zwiększa się o 32 bity sumy kontrolnej

crc32 = comm.CRCGenerator('Polynomial',...
    'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
    'InitialConditions',1,'DirectMethod',true,'FinalXOR',1); %32-bit CRC
us_data_with_crc32 = crc32(users_data); %wektor danych wejściowych + 32 bity crc

R = length(users_data)/length(us_data_with_crc32);

% 4. Zamiana bitów na symbole oraz modulacja 16-QAM
% Zamiana bitów na symbole – na tym etapie w zależności od rodzaju modulacji następuje 
% grupowanie bitów w symbole (np. po 2 przy modulacji 4PSK, 3 przy 8 PSK , 4 przy 16 QAM 
% itd.) o takiej wartościowości jaka jest wartościowość konstelacji sygnałów. Otrzymujemy 
% wektor etykiet.

exchange_bytes_to_symbols = nrSymbolModulate(us_data_with_crc32,'16QAM'); %efektem tej funkcji jest punkt 5. z opisu
scatterplot(exchange_bytes_to_symbols);
title('Konstelacja po modulacji QAM-16')

% oversampling
over_sampling = 16;

% filtr podniesionego cosinusa
txs = rcosflt(exchange_bytes_to_symbols.', 1, over_sampling );

% uciecie ogona
txs = txs( (3*over_sampling+1):( size(exchange_bytes_to_symbols.',2)*over_sampling + (3*over_sampling) ) );

% normalizacja energii
txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

drspectrum(txs,0,fftsize,'Widmo sygnalu przed AWGN, 16-QAM - ');

%eye diagram
eyediagram(real(txs),32,32,0);
title('Eyediagram przed AWGN')
grid;

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

%Modulacja OFDM
% https://www.mathworks.com/help/comm/ref/comm.ofdmmodulator-system-object.html

%-----------------------------------------------------------------------------------------------------------

%Kanał transmisyjny

% 1. AWGN
% Najprostszą odmiana kanału transmisyjnego jest kanał AWGN o zadanym poziomie SNR.
% Kanał taki jest realizowany poprzez dodawanie do każdej kolejnej zespolonej próbki sygnału 
% w dziedzinie czasu wylosowanej próbki zespolonej z generatora o zespolonym rozkładzie 
% Gausa o wartości średniej 0 i wariancji 1, przeskalowanej liniowo do zadanego poziomu SNR.

%SNR:
EbN0=3:1:13;
snr = EbN0 + 10*log10(log2(M)) - 10*log10(sps)


awgnchannel = comm.AWGNChannel;
awgnchannel.NoiseMethod = 'Signal to noise ratio (SNR)';
awgnchannel.SNR = 8; 

outsignal = awgnchannel(exchange_bytes_to_symbols);

scatterplot(outsignal);
title('Konstelacja sygnału po podaniu szumu w kanale AWGN')

%Obserwacja widma sygnału nadawanego i odbieranego w pasmie podstawowym.

% wyświetlanie fft
% oversampling
over_sampling = 16;
% filtr podniesionego cosinusa
txs = rcosflt( outsignal.', 1, over_sampling );
% tail cating
txs = txs( (3*over_sampling+1):( size(outsignal.',2)*over_sampling + (3*over_sampling) ) );
% normalizacja energii
txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

% signal plot
% figure(1);
% h1 = plot(txs);grid;
% 
% figure(2);
% h2 = plot(real(txs(1:(50*over_sampling))));grid;

drspectrum(txs,0,fftsize,'Widmo sygnalu po AWGN, 16-QAM - ');

%eye diagram
eyediagram(real(txs),32,32,0);
title('Eyediagram po AWGN');
grid;

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
% SPRAWDZIĆ https://www.mathworks.com/help/5g/ref/nrsymboldemodulate.html#mw_c0794fcb-cfe3-43dd-9310-4e22dd106c82
% a)

demod_bits_HARD = nrSymbolDemodulate(outsignal,'16QAM','DecisionType', 'Hard');
BER_hard = biterr(us_data_with_crc32,demod_bits_HARD)

% b) 
% i) Symbolowy

demod_symbols_SOFT = nrSymbolDemodulate(outsignal,'16QAM','DecisionType','Soft');
%BER_soft_symbols = biterr(us_data_with_crc32,demod_symbols_SOFT);

% ii) bitowy ???
%demodbitsSOFTbites = nrSymbolDemodulate(demodbitsSOFT,'16QAM','DecisionType','Hard')
%demod_bits_SOFT = qamdemod(outsignal,16,'OutputType','bit'); 

%demod_bits_SOFT = qamdemod(outsignal,16,'OutputType','approxllr', 'UnitAveragePower',true,'NoiseVariance',noiseVar)
%BER_soft_bits = biterr(us_data_with_crc32,demod_bits_SOFT);

%Wykres BER vs. SNR(EbN0)
berTheory = berawgn(snr,'qam',M);

title('Konstelacja sygnału po demodulacji twardej')
semilogy(snr,berTheory,'*')
hold on
semilogy(snr,berTheory)
grid
title('BER vs SNR')
legend('Przybliżone BER','Teoretyczne BER')
xlabel('SNR (dB)')
ylabel('Bit Error Rate')
figure

%FER vs. SNR(EbN0)
FER = berTheory./packet_length(psize);
semilogy(snr,FER,'*')
hold on
semilogy(snr,FER)
grid
title('FER vs SNR')
legend('FER','Teoretyczne FER')
xlabel('SNR (dB)')
ylabel('Frame Error Rate')

%------------------------------
%  PROJEKT2
%-----------------------------

% OFDM modulation flag 
ODFM = true;
%ODFM = false;
% ofdm size
ofdmsize = 64;
% data subcarriers size
ofdmdatasubsize = 52;
% guard samples
guardsamples = 10;

%%%% Numer wywalić po połączeni z Bartkiem
sim_number=10;
%!!!!!!!!!!!!!!!!!!!!!!!!



crcsize = 32;
% bits on symbol label
M = 4;
% fft size for spectrum view
fftsize = 1024;
% user data packet size

psize = 2;
packet_lenght = [500 5000 50000];

snr = 5;
% ofdm data tail size
if mod( (packet_lenght(psize) + crcsize), M ) == 0
   symbolsno = (packet_lenght(psize) + crcsize) / M;
   symbolbittail = 0;
else   
   symbolsno = floor((packet_lenght(psize) + crcsize) / M)+ 1;
   symbolbittail = M - mod( (packet_lenght(psize) + crcsize), M );
   packet_lenght(psize) = packet_lenght(psize) + symbolbittail;
end   
if ODFM
if mod(symbolsno, ofdmdatasubsize)==0
   ofdmtailsize = 0;
else
   ofdmtailsize = ofdmdatasubsize - mod(symbolsno, ofdmdatasubsize);
   packet_lenght(psize) = packet_lenght(psize) + ofdmtailsize * M;
   symbolsno = floor((packet_lenght(psize) + crcsize) / M);
end   
end

% CRC polynominal
CRCpoly = 'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1';

% constalation of symbols for 2^M (16-QAM)
constelation = qammod([0 1 2 3],2^M,'gray','UnitAveragePower',true);



%------------------------------
% transmiter
%------------------------------

% random data vector
data = randsrc( packet_lenght(psize), 1, [0 1] );


CRCgen = crc.generator('Polynomial', '0x04C11DB7', 'InitialState', '0xFFFFFFFF');
CRCdet = crc.detector('Polynomial', '0x04C11DB7', 'InitialState', '0xFFFFFFFF');
crcdata = generate(CRCgen, data);



% bits to labels
labels = bi2de( reshape( crcdata, M, [] )' );

% labels to complex symbols (M-PSK or M-QAM modulation)

symbols = qammod(labels,2^M,'gray','UnitAveragePower',true);

%------------------------------
% signal/spectrum plot
%------------------------------
% oversampling factor
over_sampling = 16;
% rised cosinus transmit filter
txs = rcosflt( symbols, 1, over_sampling );
% tail cating
txs = txs( (3*over_sampling+1):( size(symbols,1)*over_sampling + (3*over_sampling) ) );
% energy normalization 
txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

% signal plot
figure(1);
h1 = plot(txs);grid;xlabel('Re');ylabel('Im');title('Complex signal tajectory');
figure(2);
h2 = plot( 1:(50*over_sampling), real(txs(1:(50*over_sampling))),'-b',1:(50*over_sampling), imag(txs(1:(50*over_sampling))),'-r' );grid;

xlabel('time');ylabel('U');title('Signal 16-QAM, rised cosinus filter, oversampling 16');
legend('Re','Im');

% fft spectrum
drspectrum2(txs ./(over_sampling^2),0,fftsize,'16-QAM - ',1);

% eye diagram
eyediagram(real(txs),32,32,0);grid;

% ---------------------------------------------
% modulator OFDM 64 points 52 data subcarriers 
%----------------------------------------------

% symbols rearange
ofdmsymbols = reshape(symbols,ofdmdatasubsize,[] );
% put data on subcarriers
ofdminput = cat( 1, zeros(1,size(ofdmsymbols,2)), ofdmsymbols(1:(ofdmdatasubsize/2),: ), zeros((ofdmsize-ofdmdatasubsize)-1,size(ofdmsymbols,2)), ofdmsymbols(((ofdmdatasubsize/2)+1):ofdmdatasubsize,: ) );
% OFDM modulation -> IFFT operation on cols 
ofdmtimesymbols = ifft( ofdminput,ofdmsize,1); 

% Add guard interval and reshape to sample stream and normalize signal energy for transmition
%
chanellinput = reshape( cat(1, ofdmtimesymbols, ofdmtimesymbols(1:guardsamples,:) ), 1, [] );

% OFDM signal spectrum
drspectrum2(chanellinput' ./(over_sampling^2),0,fftsize, 'OFDM 16-QAM - ',2);

%--------------------------
% Transmit channel
%--------------------------

out = awgn(chanellinput,snr,'measured');


%--------------------------
% Receiver
%--------------------------
drspectrum2(out' ./(over_sampling^2),0,fftsize, 'OFDM 16-QAM - ',3);

% Remove Guard interval and reshape for demodulation

% OFDM demodulation -> FFT opration on cols
ofdmoutsymbols = fft( ofdmtimesymbols,ofdmsize,1); 
% data symbols sepatation
ofdmoutdatasymbols = reshape( cat( 1, ofdmoutsymbols(2:(ofdmdatasubsize)/2+1,:), ofdmoutsymbols( ((ofdmsize-(ofdmdatasubsize)/2)+1):ofdmsize,:)),1,[] );


