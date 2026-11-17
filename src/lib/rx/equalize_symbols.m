% =========================================================================
% Function name: equalize_symbols
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Zero-forcing equalizer: divides the received values on the data
% subcarriers by the interpolated channel estimate and reads the data
% symbols out of the resource grid in transmission order.
%
% Inputs:
%   config  - configuration structure, uses: used_subcarriers, data_idx
%   grid_rx - used_subcarriers x n_sym complex matrix (extract_subcarriers)
%   h_est   - used_subcarriers x n_sym complex matrix (interpolate_channel)
%
% Outputs:
%   data_symbols_rx - 1 x (n_sym * data_per_symbol) complex row vector of
%                     equalized QAM symbols (same order as data_symbols
%                     given to map_resource_grid on the TX)
%
% Notes:
%   Inverse of map_resource_grid for the data part: columns are read one
%   after another, within a column in increasing subcarrier order.
% =========================================================================

function data_symbols_rx = equalize_symbols(config, grid_rx, h_est)

    fprintf("    (f) equalize_symbols: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 3
        error("    (f) equalize_symbols: expected 3 inputs (config, grid_rx, h_est)");
    end

    required = ["used_subcarriers", "data_idx"];
    for f = required
        if ~isfield(config, f)
            error("    (f) equalize_symbols: missing config.%s", f);
        end
    end

    if isempty(grid_rx) || size(grid_rx, 1) ~= config.used_subcarriers
        error("    (f) equalize_symbols: grid_rx must have %d rows, has %d", ...
            config.used_subcarriers, size(grid_rx, 1));
    end

    if ~isequal(size(h_est), size(grid_rx))
        error("    (f) equalize_symbols: h_est (%d x %d) and grid_rx (%d x %d) differ in size", ...
            size(h_est, 1), size(h_est, 2), size(grid_rx, 1), size(grid_rx, 2));
    end

    h_data = h_est(config.data_idx, :);
    if any(h_data(:) == 0)
        error("    (f) equalize_symbols: zero channel estimate on a data subcarrier");
    end

    % ---- Zero-forcing equalization ---------------------------------------
    n_sym = size(grid_rx, 2);
    fprintf("    (f) equalize_symbols: ZF on %d data subcarriers x %d OFDM symbol(s)\n", ...
        length(config.data_idx), n_sym);

    eq = grid_rx(config.data_idx, :) ./ h_data;

    % Column after column -> row vector (transmission order)
    data_symbols_rx = reshape(eq, 1, []);

    % ---- Output validation -----------------------------------------------
    if length(data_symbols_rx) ~= n_sym * length(config.data_idx)
        error("    (f) equalize_symbols: unexpected output length");
    end

    fprintf("    (f) equalize_symbols: %d symbols, mean power %.4f\n", ...
        length(data_symbols_rx), sum(abs(data_symbols_rx).^2) / length(data_symbols_rx));
    fprintf("    (f) equalize_symbols: finished successfully\n");

end
