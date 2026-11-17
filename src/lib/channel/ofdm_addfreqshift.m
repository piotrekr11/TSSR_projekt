function y=ofdm_addfreqshift(sig,ff,ts)
%function y=ofdm_addfreqshift(sig,ff,ts)
%sig - a signal vector
%ff - desired frequency shift in Hz
%ts - sampling interval in seconds

sig=sig(:);

if size(sig)~=[2,1], error('Sig must be a vector');end
if size(ff)~=[1,1], error('ff must be a single number');end
if size(ts)~=[1,1], error('ts must be a single number');end


u=exp(1i*2*pi*ff*ts*(0:length(sig)-1));
u=u(:);

y=sig.*u;