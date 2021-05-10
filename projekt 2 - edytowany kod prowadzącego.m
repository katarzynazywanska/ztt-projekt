% Transmiter parameters

% packet size
psize = 2;
crcsize = 32;
% bits on symbol label
M = 4;
% fft size for spectrum view
fftsize = 1024;
% user data packet size
packet_lenght = [500 5000 50000];

% OFDM modulation flag 
ODFM = true;
%ODFM = false;
% ofdm size
ofdmsize = 64;
% data subcarriers size
ofdmdatasubsize = 52;
% guard samples
guardsamples = 10;

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
%
% CRC polynominal
CRCpoly = 'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1';

% constalation of symbols for 2^M (16-QAM)
%constelation = [ -1+1i -1-1i 1+1i 1-1i ] * (1/sqrt(2));
constelation = [-1+1i -1+3i -3+1i -3+3i -1-1i -1-3i -3-1i -3-3i 1+1i 1+3i 3+1i 3+3i 1-1i 1-3i 3-1i 3-3i ]*(1/sqrt(2));
% constelation = qammod([0 1 2 3],2^M,'gray','UnitAveragePower',true);



%------------------------------
% transmiter
%------------------------------

% random data vector
data = randsrc( packet_lenght(psize), 1, [0 1] );

% CRC generator ( z biblioteki communication )
% CRCgen = comm.CRCGenerator('Polynomial', CRCpoly);
% crcdata = CRCgen(data);

CRCgen = crc.generator('Polynomial', '0x04C11DB7', 'InitialState', '0xFFFFFFFF');
CRCdet = crc.detector('Polynomial', '0x04C11DB7', 'InitialState', '0xFFFFFFFF');
crcdata = generate(CRCgen, data);

% forward protection encoding

% bits to labels
labels = bi2de( reshape( crcdata, M, [] )' );

% labels to complex symbols (M-PSK or M-QAM modulation)
symbols = constelation( labels + 1)';
% symbols = qammod(labels,2^M,'gray','UnitAveragePower',true);

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
%xlabel('time');ylabel('U');title('Signal 4-PSK, rised cosinus filter, oversampling 16');
xlabel('time');ylabel('U');title('Signal 16-QAM, rised cosinus filter, oversampling 16');
legend('Re','Im');

% fft spectrum
% drspectrum(txs ./(over_sampling^2),0,fftsize,'4-PSK - ',3);
drspectrum(txs ./(over_sampling^2),0,fftsize,'16-QAM - ',3);

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
% drspectrum(chanellinput' ./(over_sampling^2),0,fftsize, 'OFDM 4-PSK - ',5);
drspectrum(chanellinput' ./(over_sampling^2),0,fftsize, 'OFDM 16-QAM - ',5);

%--------------------------
% Transmit channel
%--------------------------

out = awgn(chanellinput,snr,'measured');


%--------------------------
% Receiver
%--------------------------
% drspectrum(out' ./(over_sampling^2),0,fftsize, 'OFDM 4-PSK - ',6);
drspectrum(out' ./(over_sampling^2),0,fftsize, 'OFDM 16-QAM - ',6);

% Remove Guard interval and reshape for demodulation

% OFDM demodulation -> FFT opration on cols
ofdmoutsymbols = fft( ofdmtimesymbols,ofdmsize,1); 
% data symbols sepatation
ofdmoutdatasymbols = reshape( cat( 1, ofdmoutsymbols(2:(ofdmdatasubsize)/2+1,:), ofdmoutsymbols( ((ofdmsize-(ofdmdatasubsize)/2)+1):ofdmsize,:)),1,[] );

% demodulation
%rxlabels = qamdemod( ofdmoutdatasymbols, 2^M, 'gray', 'UnitAveragePower',true )'; 

% to bin format
%rxdatap = reshape(de2bi(rxlabels,M)', [], 1  );

%[rxdata error] = detect(CRCdet, rxdatap );

% count errors
%nErrors = biterr(data,rxdata);
%fprintf(sprintf('errors: %d\n',nErrors));

