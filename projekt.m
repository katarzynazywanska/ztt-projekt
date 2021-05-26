clc
clear
fftsize = 1024;
crcsize = 32;
sim_num = 100; %liczba symulacji
% parametr R = k/n,
% Sprawność kodowania R = k/n,
% k =liczba danych wejściowych, 
% n - liczba danych wejściowych + bity nadmiarowe,   
 
M=4; 
sps=1;
%Nadajnik 

%SNR:
EbN0=1:1:13;
SNR = EbN0 + 10*log10(log2(M)) - 10*log10(sps)

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
for j = 1:sim_num
    
    %Wylosowanie wektora binarnego
    users_data = randi([0 1],packet_length(psize),1); %wektor m losowych wartości binarnych 

    % 2. Kodowanie detekcyjne CRC
    % Na wektorze danych należy wyliczyć 32 bitową sumę kontrolna CRC za pomocą standardowego wielomianu 
    % sumy kontrolnej (CRC-32: 0x04C11DB7). Sumę dołączyć na końcu wektora danych

    crc32_gen = comm.CRCGenerator('Polynomial',...
        'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
        'InitialConditions',1,'DirectMethod',true,'FinalXOR',1); %32-bit CRC
    crc32_detector = comm.CRCDetector('Polynomial',...
        'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1',...
        'InitialConditions',1,'DirectMethod',true,'FinalXOR',1)
    
    us_data_with_crc32 = crc32_gen(users_data); %wektor danych wejściowych + 32 bity crc
    us_data_with_crc32_detector = crc32_detector(users_data);
    
    R = length(users_data)/length(us_data_with_crc32);

    % 4. Zamiana bitów na symbole oraz modulacja 16-QAM
    % Zamiana bitów na symbole – na tym etapie w zależności od rodzaju modulacji następuje 
    % grupowanie bitów w symbole (np. po 2 przy modulacji 4PSK, 3 przy 8 PSK , 4 przy 16 QAM 
    % itd.) o takiej wartościowości jaka jest wartościowość konstelacji sygnałów. Otrzymujemy 
    % wektor etykiet.

    exchange_bytes_to_symbols = nrSymbolModulate(us_data_with_crc32,'16QAM'); %efektem tej funkcji jest punkt 5. z opisu
    %scatterplot(exchange_bytes_to_symbols);
    %title('Konstelacja po modulacji QAM-16')

    % oversampling
    over_sampling = 16;
    
      if(j == 2 || j == 7 || j == 12) %dla snr = 5, 10 i 15
          % filtr podniesionego cosinusa
        txs = rcosflt(exchange_bytes_to_symbols.', 1, over_sampling );
        % uciecie ogona
        txs = txs( (3*over_sampling+1):( size(exchange_bytes_to_symbols.',2)*over_sampling + (3*over_sampling) ) );
        % normalizacja energii
        txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

        % Trajektoria zespolona sygnalu nadawanego
        h1 = plot(txs)
        grid;
        title(['Trajektoria zespolona sygnalu nadawanego dla SNR = ', num2str(SNR(j))]);
        xlabel('Re');
        ylabel('Im');
        figure

        % Sygnał 16-QAM, filtr podniesionego cosinusa
        h2 = plot( 1:(50*over_sampling), real(txs(1:(50*over_sampling))),'-b',1:(50*over_sampling), imag(txs(1:(50*over_sampling))),'-r' )
        grid;
        title(['Nadajnik, Sygnał 16-QAM, filtr podniesionego cosinusa, SNR = ', num2str(SNR(j))])
        xlabel('czas');
        ylabel('U');
        legend('Re','Im');
     
        % Wykres widma sygnalu nadawanego
        %drspectrum(txs,0,fftsize,'Nadajnik, widmo sygnalu, 16-QAM - ')
        drspectrum2(txs ./(over_sampling^2),0,fftsize,'16-QAM - ',j);

        %eye diagram
        eyediagram(real(txs),32,32,0)
        title(['Eyediagram sygnalu nadawanego, SNR = ', num2str(SNR(j))])
        grid;
     end
end
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

for i = 1:length(SNR)

    %Kanał transmisyjny

    % 1. AWGN
    % Najprostszą odmiana kanału transmisyjnego jest kanał AWGN o zadanym poziomie SNR.
    % Kanał taki jest realizowany poprzez dodawanie do każdej kolejnej zespolonej próbki sygnału 
    % w dziedzinie czasu wylosowanej próbki zespolonej z generatora o zespolonym rozkładzie 
    % Gausa o wartości średniej 0 i wariancji 1, przeskalowanej liniowo do zadanego poziomu SNR.

    awgnchannel = comm.AWGNChannel;
    awgnchannel.NoiseMethod = 'Signal to noise ratio (SNR)';
    awgnchannel.SNR = SNR(i); 

    outsignal = awgnchannel(exchange_bytes_to_symbols);

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
        [errors_number,errors_rate] = biterr(us_data_with_crc32,demod_bits_HARD)

    % b) 
        % i) Symbolowy
        demod_symbols_SOFT = nrSymbolDemodulate(outsignal,'16QAM','DecisionType','Soft');
        %BER_soft_symbols = biterr(us_data_with_crc32,demod_symbols_SOFT);

    % ii) bitowy ???
        %demodbitsSOFTbites = nrSymbolDemodulate(demodbitsSOFT,'16QAM','DecisionType','Hard')
        %demod_bits_SOFT = qamdemod(outsignal,16,'OutputType','bit'); 
    
        %demod_bits_SOFT = reshape(de2bi(demod_symbols_SOFT,M)', [], 1 );
    
        %demod_bits_SOFT = qamdemod(outsignal,16,'OutputType','approxllr', 'UnitAveragePower',true,'NoiseVariance',noiseVar)
        %BER_soft_bits = biterr(us_data_with_crc32,demod_bits_SOFT);
        
     %widma sygnalu na wejsciu odbiornika   
     if(i == 2 || i == 7 || i == 12) %dla snr = 5, 10 i 15
        % filtr podniesionego cosinusa
        txs = rcosflt(outsignal.', 1, over_sampling );
        % uciecie ogona
        txs = txs( (3*over_sampling+1):( size(outsignal.',2)*over_sampling + (3*over_sampling) ) );
        % normalizacja energii
        txs = txs .* (1/sqrt(mean(abs(txs).^2)));
        
        % Trajektoria zespolona sygnalu nadawanego
        h1 = plot(txs);
        grid;
        title(['Trajektoria zespolona sygnalu odebranego dla SNR = ', num2str(SNR(i))]);
        xlabel('Re');
        ylabel('Im');
        figure
        
        % Sygnał 16-QAM, filtr podniesionego cosinusa
        h2 = plot( 1:(50*over_sampling), real(txs(1:(50*over_sampling))),'-b',1:(50*over_sampling), imag(txs(1:(50*over_sampling))),'-r' )
        grid;
        title(['Przed odbiornikiem, Sygnał 16-QAM, filtr podniesionego cosinusa, SNR =', num2str(SNR(i))])
        xlabel('czas');
        ylabel('U');
        legend('Re','Im');
        
        % Wykres widma sygnalu nadawanego
        %drspectrum(txs,0,fftsize,'Przed odbiornikiem, widmo sygnalu, 16-QAM - ');
        drspectrum2(txs ./(over_sampling^2),0,fftsize,'16-QAM - ',i);

        %eye diagram
        eyediagram(real(txs),32,32,0);
        title(['Eyediagram po przejsciu kanalu AWGN, SNR = ', num2str(SNR(i))])
        grid;
     end
end

%Wykres BER vs. SNR(EbN0)
berTheory = berawgn(SNR,'qam',M,'diff');

title('Konstelacja sygnału po demodulacji twardej')
semilogy(SNR,berTheory,'*')
hold on
semilogy(SNR,berTheory)
grid
title('BER vs SNR')
legend('Przybliżone BER','Teoretyczne BER')
xlabel('SNR (dB)')
ylabel('Bit Error Rate')
figure

%FER vs. SNR(EbN0)
FER = berTheory./packet_length(psize);
semilogy(SNR,FER,'*')
hold on
semilogy(SNR,FER)
grid
title('FER vs SNR')
legend('FER','Teoretyczne FER')
xlabel('SNR (dB)')
ylabel('Frame Error Rate')
