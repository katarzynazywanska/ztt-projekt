function [symbols] = ofdm_demod(samples, sysp)
%ODFM_DEMOD Summary of this function goes here
%  [symbols] = ofdm_demod(samples, sysp)
%  default valuses
%    sysp.ofdmsize = 64;
%    sysp.ofdmdatasubsize = 52;
%    sysp.guardsamples = 10;

% time delay
delay = sysp.ofdm_delay;

% samples rearange for OFDM symbols
timesamples = reshape(samples, sysp.ofdmsize + sysp.guardsamples, [] );
frqsamples = fft( timesamples((delay+1):(delay+sysp.ofdmsize+1),:), sysp.ofdmsize, 1); 

% remove GI and reshape
ofdmoutput = cat( 1, frqsamples(2:((sysp.ofdmdatasubsize/2)+1),: ), frqsamples( ((sysp.ofdmsize-(sysp.ofdmdatasubsize/2))+1):sysp.ofdmsize,: ) );

symbols = enorm( reshape( ofdmoutput, [], 1 ) );

%

end

