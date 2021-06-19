function [ ber, fr, SNR, titlestr] = sym1( M, packetno )
%SYSPARAM Summary of this function goes here
% function [ ber, fr ] = sym1( M, packetno )


%------------------------------
% system configuration
%------------------------------
% psize - packet size selection
% M - bits per symbol
% snr - SNR value

%packetno = 1000;
%M = 2;
SNR=(1:1:(20+floor(1.3 * M)));

sysp = sysparam('psize',2,'M',M,'snr',SNR(1));

fr = zeros(size(SNR));
ber = zeros(size(SNR));

for ind = 1:length(SNR)

    sysp.snr=SNR(ind);
    ferror=0;
    errors=0;
    psize = sysp.packet_lenght(sysp.psize)-sysp.tailbits;
    for n=1:packetno
        [fe,err] = sendpacket(sysp);
        if fe
            ferror=ferror+1;
            errors=errors+err;
        end
    end
    if errors==0
        break;
    end
    fr(ind) = ferror/packetno;
    ber(ind) = errors/(packetno*psize);
    fprintf('snr: %4.2f, packets: %d, bits: %d\n', sysp.snr, packetno, packetno*psize );
    fprintf('Frame errors: \t%d,\tlevel: %4.2e\n', ferror, ferror/packetno);
    fprintf('Bit errors: \t%d,\tlevel: %4.2e\n\n',errors, errors/(packetno*psize));
end
if M<4
    titlestr = sprintf( '%d-PSK ',2^M);
else    
    titlestr = sprintf( '%d-QAM ',2^M);
end    
 
%figure(1);
%semilogy(SNR,ber,'-*');grid;title(sprintf('%s BER vs SNR', titlestr));xlabel('SNR [dB]');ylabel('BER');
%axis([2 30 1e-7 1]);
%figure(2);
%semilogy(SNR,fr,'-*');grid;title(sprintf('%s FER vs SNR', titlestr));xlabel('SNR [dB]');ylabel('FER');
%axis([2 30 1e-3 1]);
end
