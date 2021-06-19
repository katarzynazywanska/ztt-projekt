function [outsamples] = ofdm_mod(symbols, sysp)
%ODFM_MOD Summary of this function goes here
%  [outsamples] = odfm_mod(symbols, sysp)
%  default valuses
%    sysp.ofdmsize = 64;
%    sysp.ofdmdatasubsize = 52;
%    sysp.guardsamples = 10;

% symbols rearange
ofdmsymbols = reshape(symbols,sysp.ofdmdatasubsize,[] );
% put data on subcarriers
ofdminput = cat( 1, zeros(1,size(ofdmsymbols,2)), ofdmsymbols(1:(sysp.ofdmdatasubsize/2),: ), zeros((sysp.ofdmsize-sysp.ofdmdatasubsize)-1,size(ofdmsymbols,2)), ofdmsymbols(((sysp.ofdmdatasubsize/2)+1):sysp.ofdmdatasubsize,: ) );
% OFDM modulation -> IFFT operation on cols 
ofdmtimesymbols = ifft( ofdminput, sysp.ofdmsize, 1); 
%
% Add guard interval and reshape to sample stream and normalize signal energy for transmition
%
outsamples = enorm( reshape( cat(1, ofdmtimesymbols, ofdmtimesymbols(1:sysp.guardsamples,:) ), 1, [] ) );

%

end

