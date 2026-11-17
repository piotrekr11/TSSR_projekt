% =========================================================================
% Function name: map_resource_grid
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Builds the time-frequency resource grid of the used subcarriers:
% pilots on config.pilot_idx, QAM data symbols on config.data_idx.
% Every column is one OFDM symbol.
%
% Inputs:
%   config       - configuration structure, uses:
%                  used_subcarriers, pilot_idx, data_idx, data_per_symbol
%   data_symbols - 1 x (n_ofdm_symbols * data_per_symbol) complex vector
%                  from qam_modulate
%   pilots       - 1 x pilots_per_symbol vector from generate_pilots
%
% Outputs:
%   grid - used_subcarriers x n_ofdm_symbols complex matrix,
%          row k = k-th used subcarrier (lowest frequency first)
%
% Notes:
%   Data fill the grid column by column (symbol 1 first), within a
%   column in increasing subcarrier order. Zero guard subcarriers are
%   NOT included - they are added by insert_null_subcarriers.
% =========================================================================

function grid = map_resource_grid(config, data_symbols, pilots)

    fprintf("    (f) map_resource_grid: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 3
        error("    (f) map_resource_grid: expected 3 inputs (config, data_symbols, pilots)");
    end

    required = ["used_subcarriers", "pilot_idx", "data_idx", "data_per_symbol"];
    for f = required
        if ~isfield(config, f)
            error("    (f) map_resource_grid: missing config.%s", f);
        end
    end

    if ~isvector(data_symbols) || isempty(data_symbols)
        error("    (f) map_resource_grid: data_symbols must be a nonempty vector");
    end

    if mod(length(data_symbols), config.data_per_symbol) ~= 0
        error("    (f) map_resource_grid: %d data symbols do not fill whole OFDM symbols (%d per symbol)", ...
            length(data_symbols), config.data_per_symbol);
    end

    if ~isvector(pilots) || length(pilots) ~= length(config.pilot_idx)
        error("    (f) map_resource_grid: pilots must have %d elements", ...
            length(config.pilot_idx));
    end

    if length(config.pilot_idx) + length(config.data_idx) ~= config.used_subcarriers
        error("    (f) map_resource_grid: pilot_idx + data_idx do not cover all used subcarriers");
    end

    % Force column vectors (one column = one OFDM symbol)
    data_symbols = data_symbols(:);
    pilots = pilots(:);

    % ---- Mapping ---------------------------------------------------------
    n_sym = length(data_symbols) / config.data_per_symbol;
    fprintf("    (f) map_resource_grid: %d OFDM symbol(s), %d data + %d pilots each\n", ...
        n_sym, config.data_per_symbol, length(pilots));

    grid = zeros(config.used_subcarriers, n_sym);

    % Data: reshape to data_per_symbol x n_sym, column k = OFDM symbol k
    grid(config.data_idx, :) = reshape(data_symbols, config.data_per_symbol, n_sym);

    % Pilots: the same vector in every OFDM symbol (outer product)
    grid(config.pilot_idx, :) = pilots * ones(1, n_sym);

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(grid), [config.used_subcarriers, n_sym])
        error("    (f) map_resource_grid: unexpected output size");
    end

    fprintf("    (f) map_resource_grid: grid size %d x %d\n", size(grid, 1), size(grid, 2));
    fprintf("    (f) map_resource_grid: finished successfully\n");

end
