function y=ofdm_wbchannel(sig,delays, amps, ts)
%function y=wbchannel(sig,delays, amps, ts)
%sig - a signal vector
%delays - [delay of the 1st path; delay of the second path] in seconds
%amps - [complex amplitude of the 1st path; complex amplitude of the second path]
%ts - sampling interval in seconds



delays=delays(:); %make column vector
amps=amps(:); %make column vector
sig=sig(:);

if size(delays)~=[2,1], error('Delay must be a 2-element vector');end
if size(amps)~=[2,1], error('Amps must be a 2-element vector');end
if size(sig)~=[2,1], error('Sig must be a vector');end
if size(ts)~=[1,1], error('ts must be a single number');end

if delays(2)<delays(1), error('The delay of the 2nd path must >= the delay of the 1st path');end

margin=round((delays(2)-delays(1))/ts);

z=zeros(margin,1);

y=[sig;z]*amps(1); % the 1st path

q=[z;sig]*amps(2); %the 2nd path

y=y+q;

y=[zeros(round(delays(1)/ts),1);y];

end
