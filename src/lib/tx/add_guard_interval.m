% =========================================================================
% Function name: add_guard_interval
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Adds the guard interval (cyclic prefix) to every OFDM symbol: the last
% gi_samples samples of the useful part are copied in front of it.
%
% Inputs:
%   config    - configuration structure, uses: ifft_size, gi_samples,
%               ofdm_symbol_samples
%   symbols_t - ifft_size x n_sym complex matrix (ofdm_modulate)
%
% Outputs:
%   symbols_gi - ofdm_symbol_samples x n_sym complex matrix,
%                column k = [GI; useful part] of OFDM symbol k
%
% Notes:
%   Symbols stay in columns; serialization into one signal vector is done
%   by build_frame.
% =========================================================================

function symbols_gi = add_guard_interval(config, symbols_t)

    fprintf("    (f) add_guard_interval: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) add_guard_interval: expected 2 inputs (config, symbols_t)");
    end

    required = ["ifft_size", "gi_samples", "ofdm_symbol_samples"];
    for f = required
        if ~isfield(config, f)
            error("    (f) add_guard_interval: missing config.%s", f);
        end
    end

    if isempty(symbols_t) || size(symbols_t, 1) ~= config.ifft_size
        error("    (f) add_guard_interval: input must have %d rows, has %d", ...
            config.ifft_size, size(symbols_t, 1));
    end

    gi = config.gi_samples;
    if gi < 0 || gi > config.ifft_size || gi ~= round(gi)
        error("    (f) add_guard_interval: gi_samples must be an integer in 0..ifft_size");
    end

    % ---- Cyclic prefix ---------------------------------------------------
    n_sym = size(symbols_t, 2);
    fprintf("    (f) add_guard_interval: adding %d-sample GI to %d symbol(s)\n", gi, n_sym);

    symbols_gi = [symbols_t(end-gi+1:end, :); symbols_t];

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(symbols_gi), [config.ofdm_symbol_samples, n_sym])
        error("    (f) add_guard_interval: unexpected output size");
    end

    fprintf("    (f) add_guard_interval: output size %d x %d\n", size(symbols_gi, 1), n_sym);
    fprintf("    (f) add_guard_interval: finished successfully\n");

end
