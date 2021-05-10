function h=drspectrum(stream,upsampledfactor,fftsize,header,figureno)
% OFDM signal spectrum
% function drspectrum(stream,upsampledfactor)
   if figureno>0
       h=figure(figureno);
   else
       h=figure();
   end    
   if upsampledfactor>1
       x = interp(stream,upsampledfactor);
   else
       x = stream;
   end    
   fftwindows = floor(size(x,1)/fftsize);
   %window = blackmanharris(fftsize);
   window = blackman(fftsize);
   fftdata = reshape(x(1:(fftsize*fftwindows)),fftsize,fftwindows);
   wx = fftshift( fft( fftdata .* repmat(window, 1, size(fftdata,2)), fftsize) );
   x = (-1.0):(2/(fftsize-1)):(1.0);
   %y = 20*log10( mean(abs(wx')) );
   %plot( x, y, '-b' );
   y = 20*log10( abs(wx') );
   plot( x, y, '.b' );
   grid;ylabel('dB');
   xlabel('frequency rlative to 2Pi');
   title(sprintf('%s Blackman window',header));
   
end
