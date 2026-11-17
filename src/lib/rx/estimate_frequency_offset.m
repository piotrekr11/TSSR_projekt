% =========================================================================
% Function: estimate_frequency_offset
% Responsible person: ADAM
%
% Inputs:
%   config     - Configuration structure containing synchronization
%                parameters and sampling period
%   corr_vals  - Moving-segment correlation values
%   frame_start - Detected starting position of the frame
%
% Outputs:
%   ferror - Estimated frequency offset in Hz
%
% Description:
%   Estimates the frequency offset from the phase difference between
%   two repeated signal segments in the synchronization preamble.
% =========================================================================

function ferror = estimate_frequency_offset(config, corr_vals, frame_start)

    fprintf("(f) estimate_frequency_offset: started\n");

    if frame_start < 1 || frame_start > length(corr_vals)
        error("(f) estimate_frequency_offset: invalid frame_start");
    end

    % Extract phase difference between repeated segments
    ksi = angle(corr_vals(frame_start));

    % Calculate frequency offset in Hz
    ferror = ksi / (2 * pi * config.sync_jump * config.sample_period);

    fprintf("(f) estimate_frequency_offset: phase difference = %.6f rad\n", ksi);
    fprintf("(f) estimate_frequency_offset: frequency offset = %.6f Hz\n", ferror);

    fprintf("(f) estimate_frequency_offset: finished successfully\n");

end