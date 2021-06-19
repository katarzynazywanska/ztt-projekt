function signals(snr, M)
%SIGNALS drow signal diagrams
% signals(snr, M)

% diagrams od signals
%
packet = 3;
%M=5;
%snr = 15;
sysp = sysparam('psize',packet,'M',M,'snr',snr, 'fig', 1);
sendpacket(sysp);