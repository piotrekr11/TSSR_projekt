% =========================================================================
% Function name: interpolate_channel
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Interpolates the channel estimate from the pilot subcarriers onto all
% used subcarriers (linear interpolation in frequency, in every OFDM
% symbol separately). Before interpolation the mean linear phase
% (common delay of the channel / FFT window offset) is removed and it is
% put back afterwards, so only a slowly varying response is interpolated.
%
% Inputs:
%   config   - configuration structure, uses: used_subcarriers, pilot_idx
%   h_pilots - pilots_per_symbol x n_sym complex matrix (estimate_channel)
%
% Outputs:
%   h_est - used_subcarriers x n_sym complex matrix, channel estimate on
%           every used subcarrier (pilots keep their LS values)
%
% Notes:
%   Pilots must be equally spaced and include the first and the last
%   used subcarrier (see configuration.m), so only interpolation is
%   needed, never extrapolation.
%   Delay (phase slope) estimate per symbol:
%     dphi = angle( sum_j H(j+1) * conj(H(j)) ) / pilot_spacing
%   unambiguous for delays below ifft_size / (2 * pilot_spacing) samples.
%   Implemented without interp1 - weights computed directly.
% =========================================================================

function h_est = interpolate_channel(config, h_pilots)

    fprintf("    (f) interpolate_channel: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) interpolate_channel: expected 2 inputs (config, h_pilots)");
    end

    required = ["used_subcarriers", "pilot_idx"];
    for f = required
        if ~isfield(config, f)
            error("    (f) interpolate_channel: missing config.%s", f);
        end
    end

    % Force a row vector of pilot positions
    p_idx = config.pilot_idx(:).';
    n_pilots = length(p_idx);
    n_used = config.used_subcarriers;

    if n_pilots < 2
        error("    (f) interpolate_channel: at least 2 pilots are needed");
    end

    if isempty(h_pilots) || size(h_pilots, 1) ~= n_pilots
        error("    (f) interpolate_channel: h_pilots must have %d rows, has %d", ...
            n_pilots, size(h_pilots, 1));
    end

    if p_idx(1) ~= 1 || p_idx(end) ~= n_used
        error("    (f) interpolate_channel: pilots must be on the first and last used subcarrier");
    end

    spacing_all = p_idx(2:end) - p_idx(1:end-1);
    spacing = spacing_all(1);
    if any(spacing_all ~= spacing) || spacing < 1
        error("    (f) interpolate_channel: pilots must be equally spaced");
    end

    n_sym = size(h_pilots, 2);

    % ---- Mean phase slope (common delay) per OFDM symbol -----------------
    % Product of neighbouring pilots, summed over the band -> phase step
    % between pilots; divided by spacing -> phase step per subcarrier
    corr_pilots = sum(h_pilots(2:end, :) .* conj(h_pilots(1:end-1, :)), 1);
    dphi = angle(corr_pilots) / spacing;                  % 1 x n_sym

    fprintf("    (f) interpolate_channel: mean phase slope %.4f rad/subcarrier (symbol 1)\n", dphi(1));

    % Remove the slope on the pilots: H * exp(-1i*dphi*(k-1))
    h_flat = h_pilots .* exp(-1i * (p_idx(:) - 1) * dphi);

    % ---- Linear interpolation between neighbouring pilots ----------------
    k = 1:n_used;                                        % all used subcarriers
    % Index of the left pilot of every subcarrier (last one -> last gap)
    left = floor((k - 1) / spacing) + 1;
    left(left > n_pilots - 1) = n_pilots - 1;
    % Position between left (0) and right (1) pilot
    w = (k - p_idx(left)) / spacing;

    fprintf("    (f) interpolate_channel: linear interpolation, %d pilots -> %d subcarriers\n", ...
        n_pilots, n_used);

    h_est = h_flat(left, :) .* ((1 - w(:)) * ones(1, n_sym)) + ...
            h_flat(left + 1, :) .* (w(:) * ones(1, n_sym));

    % Put the phase slope back
    h_est = h_est .* exp(1i * (k(:) - 1) * dphi);

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(h_est), [n_used, n_sym])
        error("    (f) interpolate_channel: unexpected output size");
    end

    if any(h_est(:) == 0)
        fprintf("    (f) interpolate_channel: WARNING - zero channel estimate on some subcarriers\n");
    end

    fprintf("    (f) interpolate_channel: output size %d x %d\n", n_used, n_sym);
    fprintf("    (f) interpolate_channel: finished successfully\n");

end
