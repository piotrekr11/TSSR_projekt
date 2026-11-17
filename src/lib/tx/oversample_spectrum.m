% =========================================================================
% Function name: oversample_spectrum
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Oversampling in the frequency domain: pads the spectrum with zeros on
% both sides from fft_size to ifft_size = fft_size * oversampling_factor
% points. After the IFFT this gives a signal oversampled
% oversampling_factor times.
%
% Inputs:
%   config   - configuration structure, uses: fft_size, ifft_size
%   spectrum - fft_size x n_sym complex matrix (insert_null_subcarriers)
%
% Outputs:
%   spectrum_os - ifft_size x n_sym complex matrix, signal band in the
%                 middle, row 1 = lowest frequency (not yet shifted)
% =========================================================================

function spectrum_os = oversample_spectrum(config, spectrum)

    fprintf("    (f) oversample_spectrum: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) oversample_spectrum: expected 2 inputs (config, spectrum)");
    end

    if ~isfield(config, 'fft_size') || ~isfield(config, 'ifft_size')
        error("    (f) oversample_spectrum: config must contain fft_size and ifft_size");
    end

    if isempty(spectrum) || size(spectrum, 1) ~= config.fft_size
        error("    (f) oversample_spectrum: spectrum must have %d rows, has %d", ...
            config.fft_size, size(spectrum, 1));
    end

    n_pad = (config.ifft_size - config.fft_size) / 2;
    if n_pad < 0 || n_pad ~= round(n_pad)
        error("    (f) oversample_spectrum: (ifft_size - fft_size) must be even and >= 0");
    end

    % ---- Zero padding on both sides --------------------------------------
    n_sym = size(spectrum, 2);
    fprintf("    (f) oversample_spectrum: %d -> %d points (%d zeros on each side)\n", ...
        config.fft_size, config.ifft_size, n_pad);

    spectrum_os = [zeros(n_pad, n_sym); spectrum; zeros(n_pad, n_sym)];

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(spectrum_os), [config.ifft_size, n_sym])
        error("    (f) oversample_spectrum: unexpected output size");
    end

    fprintf("    (f) oversample_spectrum: finished successfully\n");

end
