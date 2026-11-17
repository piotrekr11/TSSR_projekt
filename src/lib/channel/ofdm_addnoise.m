function y=ofdm_addnoise(sig,snr)
%function y=ofdm_addnoise(sig,snr)
%sig - a signal vector
%snr - desired SNR value in dB

sig=sig(:);

if size(sig)~=[2,1], error('Sig must be a vector');end
if size(snr)~=[1,1], error('SNR must be a single number');end

ps=var(sig,1);

snrlin=10^(snr/10);

pnu=ps/snrlin;

nn=sqrt(pnu/2)*(complex(randn(size(sig)),randn(size(sig))));

pn=var(nn,1);

y=sig+nn;

disp(['Measured SNR [dB] :', num2str(10*log10(ps/pn))]);
