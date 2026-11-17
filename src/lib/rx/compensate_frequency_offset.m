% =========================================================================
% Function: compensate_frequency_offset
% Responsible person: ADAM
%
% Inputs:
%   config  - Configuration structure containing the sampling period
%   signal  - Received signal with frequency offset
%   ferror  - Estimated frequency offset in Hz
%
% Outputs:
%   signal_corrected - Signal after frequency offset compensation
%
% Description:
%   Compensates the estimated frequency offset by multiplying the received
%   signal by a complex exponential with the opposite phase rotation.
% =========================================================================

function signal_corrected = compensate_frequency_offset(config, signal, ferror)

    fprintf("(f) compensate_frequency_offset: started\n");

    N = size(signal, 1);

    % Generate frequency compensation vector
    fvec = exp(-1i * 2 * pi * ferror * config.sample_period * (0:N-1)).';

    % Compensate frequency offset
    signal_corrected = signal .* fvec;

    fprintf("(f) compensate_frequency_offset: compensated %.6f Hz\n", ferror);

    fprintf("(f) compensate_frequency_offset: finished successfully\n");

end