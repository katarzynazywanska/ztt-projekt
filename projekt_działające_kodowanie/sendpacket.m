function [error,errorbits] = sendpacket(sysp)
%SENDPACKET Summary of this function goes here
%   [error,errorbits] = sendpacket(sysp)
%------------------------------
%
% Single packet symulation
%
%------------------------------
%------------------------------
% data source
%------------------------------
% random data vector
data = randsrc( sysp.packet_lenght(sysp.psize), 1, [0 1] );

%------------------------------
% transmiter
%------------------------------
% modulated symbols
[symbols] = transmiter( data, sysp);
%close all;
%sysp.fig = true
if sysp.fig
    %------------------------------
    % transmited signal/spectrum ploting
    %------------------------------
    %
    qamsignals(symbols, sysp);
end
% -----------------------------------------------
% modulator OFDM - 64 points 52 data subcarriers 
%------------------------------------------------

channelinput = ofdm_mod(symbols, sysp);

%--------------------------
% Transmit channel
%--------------------------

%channeloutput = awgn(channelinput,sysp.snr,'measured');
channeloutput = awgn( channelinput, sysp.snr );

if sysp.fig
    %
    % OFDM signal spectrum ploting
    %
    if sysp.M>3
        name='QAM';
    else
        name='PSK';
    end
    figure();
    subplot(2,1,1);
    %plotspectrum(channelinput' ./(sysp.oversampling^2),0,sysp.fftsize,sprintf('OFDM %d-QAM - ',2^sysp.M) );
    plotspectrum(channelinput', 'header', sprintf('OFDM %d-%s, transmited - ',2^sysp.M,name) );
    subplot(2,1,2);
    %plotspectrum(channeloutput' ./(sysp.oversampling^2), 'header', sprintf('OFDM %d-QAM, %d SNR - ',2^sysp.M, sysp.snr) );
    plotspectrum(channeloutput', 'header', sprintf('OFDM %d-%s, %d dB SNR - ',2^sysp.M, name, sysp.snr) );
    % eye diagram
    eye_diagram( symbols, sysp );
end


%--------------------------
% Receiver
%--------------------------
%
% OFDM demodulator
outsymbols = ofdm_demod( channeloutput, sysp );
%size(outsymbols)

if sysp.fig
    % receiver complex symbol samples scatter ploting 
    % (constelation ploting)
    figure();
    plot(outsymbols,'.');grid;axis([-1.5 1.5 -1.5 1.5]);title(sprintf('Received constelation, %d dB SNR',sysp.snr));
end

% demodulation R2020
% rxlabels = qamdemod( outsymbols, 2^sysp.M, 'gray', 'UnitAveragePower',true )'; 
% in elier Matlab versions: R2009
% rxlabels = qamdemod( outsymbols, 2^sysp.M, 0, 'gray' )'; 
% matrix demodulator
 rxlabels = demodulator( outsymbols, sysp );

% to bin vector format
rxdatap = reshape(de2bi(rxlabels,sysp.M)', [], 1  );

%--------------------------
% Decoder
%--------------------------
% Decoding of protection codes
%
tb = 7;
trellis = poly2trellis(7,[171 133]);
rxdatap = vitdec(rxdatap,trellis,tb,'term','hard');
cut_here = length(rxdatap)/2;
rxdatap = rxdatap(1:cut_here);
%
% END of decoding of protection codes

% packet error detection
sysp.CRCdet = crc.detector('Polynomial', sysp.CRCpoly, 'InitialState', '0xFFFFFFFF');
[rxdata, error] = detect(sysp.CRCdet, rxdatap );

% count errors
if error
    % drop tailbist and check errors
    errorbits = biterr(data(1:(sysp.packet_lenght(sysp.psize)-sysp.tailbits)),rxdata(1:(sysp.packet_lenght(sysp.psize)-sysp.tailbits)));
else    
    errorbits = 0;
end    

end

