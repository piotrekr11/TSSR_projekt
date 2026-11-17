% =========================================================================
% Function: ofdm_moving_segment_correlation
% Responsible person: ADAM
%
% Inputs:
%   vec  - Input received signal
%   win  - Length of each correlation segment in samples
%   jump - Distance between the starting positions of both segments
%
% Outputs:
%   corr_vals - Complex correlation values calculated for each valid
%               pair of segments
%
% Description:
%   Calculates moving-segment autocorrelation by multiplying the
%   conjugate of the first segment with the second segment and summing
%   the results. The second segment is shifted by the specified jump.
% =========================================================================

function corr_vals = ofdm_moving_segment_correlation(vec, win, jump)

    vec = vec(:);
    N = length(vec);

    max_shift = N - win - jump + 1;

    if max_shift < 1
        error("No valid segment pairs");
    end

    corr_vals = zeros(max_shift, 1);

    for i = 1:max_shift

        A = vec(i:i+win-1);
        B = vec(i+jump:i+jump+win-1);
        corr_vals(i) = sum(conj(A) .* B);

    end

end