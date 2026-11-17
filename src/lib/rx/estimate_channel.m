% =========================================================================
% Function name: estimate_channel
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Least-squares (LS) estimate of the channel frequency response on the
% pilot subcarriers of every OFDM symbol: received pilot / known pilot.
%
% Inputs:
%   config  - configuration structure, uses: used_subcarriers, pilot_idx
%   grid_rx - used_subcarriers x n_sym complex matrix (extract_subcarriers)
%   pilots  - 1 x pilots_per_symbol vector of known pilot values
%             (generate_pilots, the same as on the TX)
%
% Outputs:
%   h_pilots - pilots_per_symbol x n_sym complex matrix, row j = channel
%              estimate on used subcarrier config.pilot_idx(j),
%              column k = OFDM symbol k
%
% Notes:
%   Estimation is done separately in every OFDM symbol (comb pilots), so
%   a residual frequency offset (phase drift between symbols) is also
%   tracked. Values between pilots are found by interpolate_channel.
% =========================================================================

function h_pilots = estimate_channel(config, grid_rx, pilots)

    fprintf("    (f) estimate_channel: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 3
        error("    (f) estimate_channel: expected 3 inputs (config, grid_rx, pilots)");
    end

    required = ["used_subcarriers", "pilot_idx"];
    for f = required
        if ~isfield(config, f)
            error("    (f) estimate_channel: missing config.%s", f);
        end
    end

    if isempty(grid_rx) || size(grid_rx, 1) ~= config.used_subcarriers
        error("    (f) estimate_channel: grid_rx must have %d rows, has %d", ...
            config.used_subcarriers, size(grid_rx, 1));
    end

    n_pilots = length(config.pilot_idx);
    if ~isvector(pilots) || length(pilots) ~= n_pilots
        error("    (f) estimate_channel: pilots must have %d elements", n_pilots);
    end

    if any(pilots == 0)
        error("    (f) estimate_channel: pilot values must be nonzero");
    end

    if min(config.pilot_idx) < 1 || max(config.pilot_idx) > config.used_subcarriers
        error("    (f) estimate_channel: pilot_idx outside 1..%d", config.used_subcarriers);
    end

    % Force a column vector (one value per pilot subcarrier)
    pilots = pilots(:);

    % ---- LS estimation ---------------------------------------------------
    n_sym = size(grid_rx, 2);
    fprintf("    (f) estimate_channel: %d pilots x %d OFDM symbol(s)\n", n_pilots, n_sym);

    % Element-wise division of every column by the known pilot vector
    h_pilots = grid_rx(config.pilot_idx, :) ./ (pilots * ones(1, n_sym));

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(h_pilots), [n_pilots, n_sym])
        error("    (f) estimate_channel: unexpected output size");
    end

    fprintf("    (f) estimate_channel: mean |H| on pilots = %.4f\n", ...
        sum(abs(h_pilots(:))) / numel(h_pilots));
    fprintf("    (f) estimate_channel: finished successfully\n");

end
