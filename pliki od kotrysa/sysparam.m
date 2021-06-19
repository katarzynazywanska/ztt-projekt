function [ sysparams ] = sysparam( varargin )
%SYSPARAM Summary of this function goes here
% System params  

    ip = inputParser;
    ip.FunctionName = mfilename;
    ip.CaseSensitive = false;
    %ip.addRequired('v', @isvector);
    ip.addParamValue('psize', 2, @isnumeric);
    ip.addParamValue('M', 2, @isnumeric);
    ip.addParamValue('snr', 10, @isnumeric);
    ip.addParamValue('packet_lenght', '[500 5000 50000]', @ischar);
    ip.addParamValue('ofdmsize', 64, @isnumeric);
    ip.addParamValue('ofdmdatasubsize', 52, @isnumeric);
    ip.addParamValue('guardsamples', 10, @isnumeric);
    ip.addParamValue('crcsize', 32, @isnumeric);
    ip.addParamValue('fftsize', 1024, @isnumeric);
    ip.addParamValue('OFDM', true, @islogical);
    ip.addParamValue('CRCpoly', '0x04C11DB7', @ischar);
    ip.addParamValue('scater', '.', @ischar);
    ip.addParamValue('oversampling', 16, @isnumeric);
    ip.addParamValue('ofdm_delay', 0, @isnumeric);
    ip.addParamValue('fig', 0, @isnumeric);
    ip.parse( varargin{:} );
    r = ip.Results;

% Suppress Warnings
warning ('off','all');
    
% System params
    sysparams.psize = r.psize;
    sysparams.crcsize = r.crcsize;
    sysparams.M = r.M;
    sysparams.fftsize = r.fftsize;
    sysparams.OFDM = r.OFDM;
    sysparams.ofdmsize = r.ofdmsize;
    sysparams.ofdmdatasubsize = r.ofdmdatasubsize;
    sysparams.guardsamples = r.guardsamples;
    sysparams.snr = r.snr;
    sysparams.packet_lenght = eval(r.packet_lenght);
    sysparams.CRCpoly = r.CRCpoly;
    sysparams.scater = r.scater;
    sysparams.fig = r.fig;
    sysparams.CRCgen = crc.generator('Polynomial', sysparams.CRCpoly, 'InitialState', '0xFFFFFFFF');
    sysparams.CRCdet = crc.detector('Polynomial', sysparams.CRCpoly, 'InitialState', '0xFFFFFFFF');
    % For Matlab R2020
    % sysparams.CRCpoly = 'z^32 + z^26 + z^23 + z^22 + z^16 + z^12 + z^11 + z^10 + z^8 + z^7 + z^5 + z^4 + z^2 + z + 1';
    % 
    sysparams.oversampling = r.oversampling;
    sysparams.ofdm_delay = r.ofdm_delay;
    
    % load constelations form 'cns.mat' file 
    load('cns.mat','cns');
    sysparams.constelation = cell2mat(cns(sysparams.M));
    %sysparams.constelation = [ -1+1i -1-1i 1+1i 1-1i ] * (1/sqrt(2));

    % tail bits calculation
    % tailbits is not user data, tail bits wil be set to random value
    % symbols data tail size
    bits = sysparams.packet_lenght(sysparams.psize) + sysparams.crcsize;
    if mod( bits, sysparams.M ) == 0
       symbolsno = bits / sysparams.M;
       tailbits = 0;
    else   
       symbolsno = floor( bits / sysparams.M ) + 1;
       tailbits = sysparams.M - mod( bits, sysparams.M );
    end
    sysparams.symbolsno  = symbolsno;
    sysparams.tailbits = tailbits;
    %
    % ofdm data tail size
    if sysparams.OFDM
        if mod(symbolsno, sysparams.ofdmdatasubsize) ~= 0
            ofdmtailbits = (sysparams.ofdmdatasubsize - mod(symbolsno, sysparams.ofdmdatasubsize)) * sysparams.M;
            sysparams.tailbits = sysparams.tailbits + ofdmtailbits;
            sysparams.symbolsno = (bits + sysparams.tailbits) / sysparams.M;
        end
        sysparams.packet_lenght(sysparams.psize) = sysparams.symbolsno * sysparams.M - sysparams.crcsize;
    end
   
    % demodulation matrix
    sysparams.constm = repmat(sysparams.constelation, sysparams.symbolsno, 1);
    

end

