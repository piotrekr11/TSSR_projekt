% =========================================================================
% Function name: remove_guard_interval
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Removes the guard interval (cyclic prefix) from every received OFDM
% symbol: the first gi_samples samples of each column are dropped and
% the ifft_size samples of the useful part are kept.
%
% Inputs:
%   config        - configuration structure, uses: ifft_size, gi_samples,
%                   ofdm_symbol_samples
%   symbols_gi_rx - ofdm_symbol_samples x n_sym complex matrix
%                   (extract_ofdm_symbols)
%
% Outputs:
%   symbols_t_rx - ifft_size x n_sym complex matrix, useful parts of the
%                  OFDM symbols (input of ofdm_demodulate)
%
% Notes:
%   Inverse of add_guard_interval. The GI absorbs the multipath delay
%   spread (ISI), so its samples are not used.
% =========================================================================

function symbols_t_rx = remove_guard_interval(config, symbols_gi_rx)

    fprintf("    (f) remove_guard_interval: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) remove_guard_interval: expected 2 inputs (config, symbols_gi_rx)");
    end

    required = ["ifft_size", "gi_samples", "ofdm_symbol_samples"];
    for f = required
        if ~isfield(config, f)
            error("    (f) remove_guard_interval: missing config.%s", f);
        end
    end

    if isempty(symbols_gi_rx) || size(symbols_gi_rx, 1) ~= config.ofdm_symbol_samples
        error("    (f) remove_guard_interval: input must have %d rows, has %d", ...
            config.ofdm_symbol_samples, size(symbols_gi_rx, 1));
    end

    gi = config.gi_samples;
    if gi + config.ifft_size ~= config.ofdm_symbol_samples
        error("    (f) remove_guard_interval: gi_samples + ifft_size ~= ofdm_symbol_samples");
    end

    % ---- GI removal ------------------------------------------------------
    n_sym = size(symbols_gi_rx, 2);
    fprintf("    (f) remove_guard_interval: removing %d-sample GI from %d symbol(s)\n", gi, n_sym);

    symbols_t_rx = symbols_gi_rx(gi+1:end, :);

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(symbols_t_rx), [config.ifft_size, n_sym])
        error("    (f) remove_guard_interval: unexpected output size");
    end

    fprintf("    (f) remove_guard_interval: output size %d x %d\n", size(symbols_t_rx, 1), n_sym);
    fprintf("    (f) remove_guard_interval: finished successfully\n");

end
