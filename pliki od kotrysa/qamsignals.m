function [fig] = qamsignals(symbols, sysp)
%QAMSIGNALS Summary of this function goes here
% [h] = qamsignals(symbols, oversampling)
%
%------------------------------
% QAM time signal plot
%------------------------------
% rised cosinus transmit filter
% b = rcosdesign(0.25, 6, sysp.oversampling );
txs = rcosflt( symbols, 1, sysp.oversampling );
% tail cating
txs = txs( (3*sysp.oversampling+1):( size(symbols,1)*sysp.oversampling + (3*sysp.oversampling) ) );
% energy normalization 
txs = txs .* (1/sqrt(mean(abs(txs).^2))); 

fig = figure();
%------------------------------
% signal plots
%------------------------------
% complex trajectory
h(1) = subplot(2,2,1);
if length(txs) < ( sysp.oversampling*300 )
    plot(txs);axis([-1.5 1.5 -1.5 1.5]);grid;xlabel('Real');ylabel('Image');title('Complex signal tajectory');
else
    plot(txs(1:sysp.oversampling*300));axis([-1.5 1.5 -1.5 1.5]);grid;xlabel('Real');ylabel('Image');title('Complex signal tajectory');
end
%
% time series
h(2) = subplot(2,2,[3,4]);
if length(txs) > (50 * sysp.oversampling)
    timesamples = 50 * sysp.oversampling;
else 
    timesamples = length(txs);
end
if sysp.M>3
    name='QAM';
else
    name='PSK';
end
plot( 1:timesamples, real(txs(1:timesamples)),'-b',1:timesamples, imag(txs(1:timesamples)),'-r' );grid;
xlabel('time');ylabel('U');title(sprintf('Signal %d-%s, rised cosinus filter, oversampling %d',2^sysp.M,name,sysp.oversampling ));
legend('Real','Image');
%
% QAM spectrum plot
%------------------------------
h(3) = subplot(2,2,2);
%drspectrum(txs ./(over_sampling^2),1,fftsize,'4-PSK - ',3);
plotspectrum( txs ./(sysp.oversampling^2), 'header', sprintf('%d-%s - ',2^sysp.M,name));
%
end

