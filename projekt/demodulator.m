function [labels] = demodulator(samples,sysp)
%DEMODULATOR Summary of this function goes here
%   [labels] = demodulator(samples,sysp)

    % matrix version
    [x,labels] = min( (sysp.constm - repmat(samples,1,2^sysp.M)).^2,[],2 );
    labels = labels - 1;
    
    % iteration version
    %labels = zeros( length(samples), 1);
    %for n=1:length(samples)
    %   [x,labels(n)] = min( sysp.constelation-samples(n) );
    %   labels(n) = labels(n) -1;
    %end   
end

