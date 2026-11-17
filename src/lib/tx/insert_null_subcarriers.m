% =========================================================================
% Function name: insert_null_subcarriers
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Adds zero subcarriers (frequency guard bands) at both band edges:
% left_zero_subcarriers below and right_zero_subcarriers above the used
% subcarriers. Result has fft_size rows (nominal transform size N).
%
% Inputs:
%   config - configuration structure, uses:
%            used_subcarriers, left_zero_subcarriers,
%            right_zero_subcarriers, fft_size
%   grid   - used_subcarriers x n_sym complex matrix (map_resource_grid)
%
% Outputs:
%   spectrum - fft_size x n_sym complex matrix, row 1 = lowest frequency
%              (not yet shifted for the IFFT)
% =========================================================================

function spectrum = insert_null_subcarriers(config, grid)

    fprintf("    (f) insert_null_subcarriers: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) insert_null_subcarriers: expected 2 inputs (config, grid)");
    end

    required = ["used_subcarriers", "left_zero_subcarriers", ...
                "right_zero_subcarriers", "fft_size"];
    for f = required
        if ~isfield(config, f)
            error("    (f) insert_null_subcarriers: missing config.%s", f);
        end
    end

    if isempty(grid) || size(grid, 1) ~= config.used_subcarriers
        error("    (f) insert_null_subcarriers: grid must have %d rows, has %d", ...
            config.used_subcarriers, size(grid, 1));
    end

    n_left = config.left_zero_subcarriers;
    n_right = config.right_zero_subcarriers;
    if n_left + config.used_subcarriers + n_right ~= config.fft_size
        error("    (f) insert_null_subcarriers: zeros + used subcarriers ~= fft_size");
    end

    % ---- Zero padding at band edges --------------------------------------
    n_sym = size(grid, 2);
    fprintf("    (f) insert_null_subcarriers: adding %d (left) + %d (right) zero subcarriers\n", ...
        n_left, n_right);

    spectrum = [zeros(n_left, n_sym); grid; zeros(n_right, n_sym)];

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(spectrum), [config.fft_size, n_sym])
        error("    (f) insert_null_subcarriers: unexpected output size");
    end

    fprintf("    (f) insert_null_subcarriers: output size %d x %d\n", size(spectrum, 1), n_sym);
    fprintf("    (f) insert_null_subcarriers: finished successfully\n");

end
