function y=drspectrum(stream,upsampledfactor,fftsize,header)
% OFDM signal spectrum
% function dspectrum(stream,upsampledfactor)

   if upsampledfactor>1
       x = interp(stream,upsampledfactor);
   else
       x = stream;
   end    
   fftwindows = floor(size(x,1)/fftsize);
   window = blackmanharris(fftsize);
   fftdata = reshape(x(1:(fftsize*fftwindows)),fftsize,fftwindows);
   wx = fftshift( fft( fftdata .* repmat(window, 1, size(fftdata,2)), fftsize) );
   y = 20*log10( mean(abs(wx')) );
   x = (-0.5):(1/(fftsize-1)):(0.5);
   figure;
   h5 = plot( x, y, '-' );
   %hold;plot( x, y, 'or' );hold;
   grid;ylabel('dB');
   xlabel('frequency rlative to 2Pi');
   title(sprintf('%s Blackman-Haris window',header));
end