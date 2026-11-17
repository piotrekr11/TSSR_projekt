% =========================================================================
% Function name: ofdm_modulate
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% OFDM modulator: shifts every column of the oversampled spectrum so that
% the band centre lands at index 1 (DC) and computes the IFFT of each
% column - one column = useful part of one OFDM symbol.
%
% Inputs:
%   config      - configuration structure, uses: ifft_size
%   spectrum_os - ifft_size x n_sym complex matrix (oversample_spectrum),
%                 row 1 = lowest frequency
%
% Outputs:
%   symbols_t - ifft_size x n_sym complex matrix, time samples of the
%               useful parts (without guard interval)
%
% Notes:
%   Equivalent to ifft(ifftshift(X)) - spectrum_shift replaces ifftshift.
%   ifft works column-wise on a matrix. No power normalization (as in the
%   lecture); the 1/N factor of ifft is kept.
% =========================================================================

function symbols_t = ofdm_modulate(config, spectrum_os)

    fprintf("    (f) ofdm_modulate: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) ofdm_modulate: expected 2 inputs (config, spectrum_os)");
    end

    if ~isfield(config, 'ifft_size')
        error("    (f) ofdm_modulate: missing config.ifft_size");
    end

    if isempty(spectrum_os) || size(spectrum_os, 1) ~= config.ifft_size
        error("    (f) ofdm_modulate: spectrum must have %d rows, has %d", ...
            config.ifft_size, size(spectrum_os, 1));
    end

    % ---- Shift + IFFT ----------------------------------------------------
    n_sym = size(spectrum_os, 2);
    fprintf("    (f) ofdm_modulate: IFFT of %d point(s) for %d OFDM symbol(s)\n", ...
        config.ifft_size, n_sym);

    symbols_t = ifft(spectrum_shift(spectrum_os));

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(symbols_t), [config.ifft_size, n_sym])
        error("    (f) ofdm_modulate: unexpected output size");
    end

    fprintf("    (f) ofdm_modulate: mean sample power = %.3e\n", ...
        sum(abs(symbols_t(:)).^2) / numel(symbols_t));
    fprintf("    (f) ofdm_modulate: finished successfully\n");

end
