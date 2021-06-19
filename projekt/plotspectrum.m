function plotspectrum( stream, varargin )
%PLOTSPECTRUM Summary of this function goes here
%   plotspectrum(stream,upsampledfactor,fftsize,header)
%   var args:
%   'upsampledfactor' = 1;
%   'fftsize' = 1024;
%   'header' = '';

ip = inputParser;
ip.FunctionName = mfilename;
ip.CaseSensitive = false;
ip.addParamValue('upsampledfactor', 1, @isnumeric);
ip.addParamValue('fftsize', 1024, @isnumeric);
ip.addParamValue('header', 'Power spectrum -', @ischar);
ip.parse( varargin{:} );
arg = ip.Results;

% 
   if arg.upsampledfactor > 1
       x = interp(stream,arg.upsampledfactor);
   else
       x = stream;
   end    
   fftwindows = floor(size(x,1)/arg.fftsize);
   window = blackman(arg.fftsize);
   fftdata = reshape(x(1:(arg.fftsize*fftwindows)),arg.fftsize,fftwindows);
   wx = fftshift( fft( fftdata .* repmat(window, 1, size(fftdata,2)), arg.fftsize) );
   x = (-1.0):(2/(arg.fftsize-1)):(1.0);
   
   y = 20*log10( abs(wx') );
   plot( x, y, '.b' );
   hold;
   y = 20*log10( mean(abs(wx')) );
   plot( x, y, '-r' );
   grid;ylabel('dB');
   xlabel('frequency rlative to 2Pi');
   title(sprintf('%s Blackman window',arg.header));
   hold;
   
end

