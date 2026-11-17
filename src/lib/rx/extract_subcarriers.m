% =========================================================================
% Function name: extract_subcarriers
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Keeps only the used subcarriers of the received oversampled spectrum:
% removes the oversampling zeros (both sides) and the zero guard
% subcarriers at the band edges. Result is the received
% time-frequency resource grid (data + pilots).
%
% Inputs:
%   config         - configuration structure, uses: fft_size, ifft_size,
%                    left_zero_subcarriers, right_zero_subcarriers,
%                    used_subcarriers
%   spectrum_os_rx - ifft_size x n_sym complex matrix (ofdm_demodulate),
%                    row 1 = lowest frequency
%
% Outputs:
%   grid_rx - used_subcarriers x n_sym complex matrix, row k = k-th used
%             subcarrier (same layout as map_resource_grid on the TX)
%
% Notes:
%   Inverse of oversample_spectrum + insert_null_subcarriers. The power
%   left on the removed rows (noise, out-of-band leakage) is reported.
% =========================================================================

function grid_rx = extract_subcarriers(config, spectrum_os_rx)

    fprintf("    (f) extract_subcarriers: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) extract_subcarriers: expected 2 inputs (config, spectrum_os_rx)");
    end

    required = ["fft_size", "ifft_size", "left_zero_subcarriers", ...
                "right_zero_subcarriers", "used_subcarriers"];
    for f = required
        if ~isfield(config, f)
            error("    (f) extract_subcarriers: missing config.%s", f);
        end
    end

    if isempty(spectrum_os_rx) || size(spectrum_os_rx, 1) ~= config.ifft_size
        error("    (f) extract_subcarriers: spectrum must have %d rows, has %d", ...
            config.ifft_size, size(spectrum_os_rx, 1));
    end

    n_pad = (config.ifft_size - config.fft_size) / 2;
    if n_pad < 0 || n_pad ~= round(n_pad)
        error("    (f) extract_subcarriers: (ifft_size - fft_size) must be even and >= 0");
    end

    if config.left_zero_subcarriers + config.used_subcarriers + ...
            config.right_zero_subcarriers ~= config.fft_size
        error("    (f) extract_subcarriers: zeros + used subcarriers ~= fft_size");
    end

    % ---- Selection of used subcarriers -----------------------------------
    n_sym = size(spectrum_os_rx, 2);
    used_rows = n_pad + config.left_zero_subcarriers + (1:config.used_subcarriers);

    fprintf("    (f) extract_subcarriers: rows %d..%d of %d (dropping %d oversampling + %d/%d guard)\n", ...
        used_rows(1), used_rows(end), config.ifft_size, 2*n_pad, ...
        config.left_zero_subcarriers, config.right_zero_subcarriers);

    grid_rx = spectrum_os_rx(used_rows, :);

    % Mean power on used vs. removed rows (diagnostics)
    unused = spectrum_os_rx;
    unused(used_rows, :) = [];
    fprintf("    (f) extract_subcarriers: mean power used %.3e, removed %.3e\n", ...
        sum(abs(grid_rx(:)).^2) / numel(grid_rx), ...
        sum(abs(unused(:)).^2) / max(numel(unused), 1));

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(grid_rx), [config.used_subcarriers, n_sym])
        error("    (f) extract_subcarriers: unexpected output size");
    end

    fprintf("    (f) extract_subcarriers: grid size %d x %d\n", size(grid_rx, 1), n_sym);
    fprintf("    (f) extract_subcarriers: finished successfully\n");

end
