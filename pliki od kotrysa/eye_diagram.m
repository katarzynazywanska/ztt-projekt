function [fig] =  eye_diagram( symbols, sysp )
%EYE_DIAGRAM Summary of this function goes here
%   
%------------------------------
% QAM time signal plot
%------------------------------
% rised cosinus transmit filter
% 
txs = rcosflt( symbols, 1, sysp.oversampling );
% tail cating
txs = txs( (3*sysp.oversampling+1):( size(symbols,1)*sysp.oversampling + (3*sysp.oversampling) ) );
% energy normalization 
txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

% eye diagram
maxeyesymbols = 400;
if length(txs) > maxeyesymbols*sysp.oversampling 
    eyesize = maxeyesymbols*sysp.oversampling;
else
    eyesize = floor( length(txs) / sysp.oversampling ) * sysp.oversampling;
end
eyediagram(real(txs(1:eyesize)),sysp.oversampling*2,sysp.oversampling,0,'' );grid;

end

