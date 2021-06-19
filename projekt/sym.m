% all constelations on one diagram
%

clear;
%
packetno = 100;
M=1;
for i=1:8
   [ber, fe, SNR, titlestr] = sym1( M, packetno );
   en = 10.^(SNR/10);
   ebno = 10.*log10(en./M);
   B{M}=ber;F{M}=fe;S{M}=ebno;T{M}=titlestr;
   M=M+1;
end
figure(1);
semilogy(S{1},B{1},'-*',S{2},B{2},'-o',S{3},B{3},'-+',S{4},B{4},'-d',S{5},B{5},'-x',S{6},B{6},'-s',S{7},B{7},'-.',S{8},B{8},'-^');grid;title('BER vs Eb/No');xlabel('Eb/No [dB]');ylabel('BER');
axis([1 25 1e-6 1]);
legend( T{1}, T{2}, T{3}, T{4}, T{5}, T{6}, T{7}, T{8} );
figure(2);
semilogy(S{1},F{1},'-*',S{2},F{2},'-o',S{3},F{3},'-+',S{4},F{4},'-d',S{5},F{5},'-x',S{6},F{6},'-s', S{7},F{7},'-.',S{8},F{8},'-^');grid;title('FER vs Eb/No');xlabel('Eb/No [dB]');ylabel('FER');
axis([1 25 1e-3 1]);
legend( T{1}, T{2}, T{3}, T{4}, T{5}, T{6}, T{7}, T{8} );


