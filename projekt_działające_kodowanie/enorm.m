function [ y ] = enorm( x )
%ENORM Summary of this function goes here
%   Normalization the average energy of signal x to 1

y = x ./ sqrt(mean( abs(x).^2 ));

end

