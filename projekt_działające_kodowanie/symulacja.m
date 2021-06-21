% all constelations on one diagram
%

clear;
%
packetno = 100;
M=4;
[ber, fe, SNR, titlestr] = sym1( M, packetno );
en = 10.^(SNR/10);
ebno = 10.*log10(en./M);
B{M}=ber;F{M}=fe;S{M}=ebno;T{M}=titlestr;

figure(1);
semilogy(S{4},B{4},'-d');grid;title('BER vs Eb/No');xlabel('Eb/No [dB]');ylabel('BER');
axis([1 25 1e-6 1]);
legend( T{4});
figure(2);
semilogy(S{4},F{4},'-d');grid;title('FER vs Eb/No');xlabel('Eb/No [dB]');ylabel('FER');
axis([1 25 1e-3 1]);
legend(T{4});


