% =========================================================================
% Function: detect_frame_start
% Responsible person: ADAM
%
% Inputs:
%   config - Configuration structure containing synchronization parameters
%   signal - Received signal
%
% Outputs:
%   frame_start - Detected starting sample of the frame
%   corr_vals   - Moving-segment correlation values
%
% Description:
%   Detects the beginning of an OFDM frame using moving-segment
%   autocorrelation. The maximum correlation is searched within a
%   restricted window starting at the first non-zero correlation value.
% =========================================================================

function [frame_start, corr_vals] = detect_frame_start(config, signal)

    fprintf("(f) detect_frame_start: started\n");

    corr_vals = ofdm_moving_segment_correlation( ...
        signal, config.sync_win, config.sync_jump);

    correlation_magnitude = abs(corr_vals);

    % Find the first non-zero correlation position
    first_position = find(correlation_magnitude > 0, 1, 'first');

    if isempty(first_position)
        error("(f) detect_frame_start: no correlation detected");
    end

    last_position = min(first_position + config.peak_search_window - 1, ...
                        length(correlation_magnitude));

    % Find maximum only inside the restricted window
    [~, local_position] = max( ...
        correlation_magnitude(first_position:last_position));

    frame_start = first_position + local_position - 1;

    fprintf("(f) detect_frame_start: detected frame at sample %d\n", ...
        frame_start);

    fprintf("(f) detect_frame_start: finished successfully\n");

end