% =========================================================================
% Function name: ofdm_demodulate
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% OFDM demodulator: computes the FFT of the useful part of every OFDM
% symbol (column) and shifts the result so that row 1 is the lowest
% frequency again - the same ordering as on the TX before the IFFT.
%
% Inputs:
%   config       - configuration structure, uses: ifft_size
%   symbols_t_rx - ifft_size x n_sym complex matrix (remove_guard_interval)
%
% Outputs:
%   spectrum_os_rx - ifft_size x n_sym complex matrix, oversampled
%                    spectrum, row 1 = lowest frequency
%                    (input of extract_subcarriers)
%
% Notes:
%   Inverse of ofdm_modulate: spectrum_shift(fft(x)) (fftshift replaced
%   by spectrum_shift). fft works column-wise on a matrix. TX ifft keeps
%   the 1/N factor, so fft gives back the original subcarrier values.
% =========================================================================

function spectrum_os_rx = ofdm_demodulate(config, symbols_t_rx)

    fprintf("    (f) ofdm_demodulate: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) ofdm_demodulate: expected 2 inputs (config, symbols_t_rx)");
    end

    if ~isfield(config, 'ifft_size')
        error("    (f) ofdm_demodulate: missing config.ifft_size");
    end

    if isempty(symbols_t_rx) || size(symbols_t_rx, 1) ~= config.ifft_size
        error("    (f) ofdm_demodulate: input must have %d rows, has %d", ...
            config.ifft_size, size(symbols_t_rx, 1));
    end

    % ---- FFT + shift -----------------------------------------------------
    n_sym = size(symbols_t_rx, 2);
    fprintf("    (f) ofdm_demodulate: FFT of %d point(s) for %d OFDM symbol(s)\n", ...
        config.ifft_size, n_sym);

    spectrum_os_rx = spectrum_shift(fft(symbols_t_rx));

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(spectrum_os_rx), [config.ifft_size, n_sym])
        error("    (f) ofdm_demodulate: unexpected output size");
    end

    fprintf("    (f) ofdm_demodulate: finished successfully\n");

end
