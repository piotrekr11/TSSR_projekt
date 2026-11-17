% =========================================================================
% Function name: extract_ofdm_symbols
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Cuts the data OFDM symbols (each with its guard interval) out of the
% received, frequency-corrected signal. Fine timing: one useful block A
% of the received preamble (taken at frame_start) is circularly
% cross-correlated with the known block A (via fft / ifft). The result is
% the channel impulse response; its first significant path marks the
% exact start of block A, so the FFT window of every data symbol can be
% placed timing_backoff samples before the ideal position (inside the
% GI - no ISI, small effective channel delay).
%
% Inputs:
%   config      - configuration structure, uses:
%                 gi_samples, ifft_size, ofdm_symbol_samples,
%                 preamble_repetitions, timing_path_threshold,
%                 timing_backoff, n_ofdm_symbols (optional - see Notes)
%   signal      - received signal, complex column vector (after
%                 compensate_frequency_offset)
%   frame_start - scalar, sample index from detect_frame_start (a point
%                 of the correlation plateau of the preamble, i.e. within
%                 about gi_samples of the start of the first block A)
%   preamble    - known preamble (generate_preamble), column vector
%                 [GI; A; A], shared by TX and RX like the pilots
%
% Outputs:
%   symbols_gi_rx - ofdm_symbol_samples x n_sym complex matrix,
%                   column k = [GI; useful part] of OFDM symbol k
%                   (same layout as add_guard_interval on the TX side)
%
% Notes:
%   The block A is periodic in the preamble, so any ifft_size window
%   inside [GI; A; A] is a cyclic shift of A -> the circular correlation
%   ifft(fft(r) .* conj(fft(A))) gives the paths at their cyclic delays.
%   The first path is the earliest lag with |corr| >= timing_path_threshold
%   * max |corr| (lags ordered from -ifft_size/2 to ifft_size/2-1).
%   A first path weaker than this threshold is treated as missing.
%   n_ofdm_symbols is the frame length known to the RX (fixed frame);
%   if it is missing, all whole symbols that fit in the signal are taken.
% =========================================================================

function symbols_gi_rx = extract_ofdm_symbols(config, signal, frame_start, preamble)

    fprintf("    (f) extract_ofdm_symbols: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 4
        error("    (f) extract_ofdm_symbols: expected 4 inputs (config, signal, frame_start, preamble)");
    end

    required = ["gi_samples", "ifft_size", "ofdm_symbol_samples", ...
                "preamble_repetitions", "timing_path_threshold", "timing_backoff"];
    for f = required
        if ~isfield(config, f)
            error("    (f) extract_ofdm_symbols: missing config.%s", f);
        end
    end

    if ~isvector(signal) || isempty(signal)
        error("    (f) extract_ofdm_symbols: signal must be a nonempty vector");
    end

    % Force column vectors (channel functions also return columns)
    signal = signal(:);
    preamble = preamble(:);
    n_samples = length(signal);

    gi = config.gi_samples;
    L = config.ifft_size;
    S = config.ofdm_symbol_samples;
    reps = config.preamble_repetitions;
    preamble_len = gi + reps * L;

    if length(preamble) ~= preamble_len
        error("    (f) extract_ofdm_symbols: preamble must have %d samples, has %d", ...
            preamble_len, length(preamble));
    end

    if ~isscalar(frame_start) || frame_start < 1 || frame_start ~= round(frame_start) ...
            || frame_start + L - 1 > n_samples
        error("    (f) extract_ofdm_symbols: frame_start must be an integer in 1..%d", ...
            n_samples - L + 1);
    end

    beta = config.timing_path_threshold;
    if ~isscalar(beta) || beta <= 0 || beta > 1
        error("    (f) extract_ofdm_symbols: timing_path_threshold must be in (0, 1]");
    end

    backoff = config.timing_backoff;
    if ~isscalar(backoff) || backoff < 0 || backoff > gi || backoff ~= round(backoff)
        error("    (f) extract_ofdm_symbols: timing_backoff must be an integer in 0..gi_samples");
    end

    % ---- Fine timing: channel impulse response from the preamble ---------
    block_ref = preamble(gi+1 : gi+L);               % known block A
    block_rx = signal(frame_start : frame_start+L-1); % received, cyclic shift of A

    % Circular cross-correlation via FFT, normalized to the energy of A
    cir = ifft(fft(block_rx) .* conj(fft(block_ref))) / sum(abs(block_ref).^2);

    % Lags reordered to -L/2 .. L/2-1 (spectrum_shift swaps the halves)
    cir_mag = abs(spectrum_shift(cir));
    lags = (0:L-1) - L/2;

    % First (earliest) lag above the threshold = first path
    [peak, j_peak] = max(cir_mag);
    threshold = beta * peak;
    j = 1;
    while cir_mag(j) < threshold
        j = j + 1;
    end
    first_lag = lags(j);

    % Start of the first block A of the preamble (1st path)
    block_a_start = frame_start + first_lag;

    fprintf("    (f) extract_ofdm_symbols: frame_start %d, first path lag %+d -> block A at %d\n", ...
        frame_start, first_lag, block_a_start);
    fprintf("    (f) extract_ofdm_symbols: strongest path |h| = %.4f at lag %+d\n", ...
        peak, lags(j_peak));

    % Useful part of data symbol 1: after all blocks A and its own GI,
    % moved back by the backoff margin
    useful_start = block_a_start + reps * L + gi - backoff;
    block_start = useful_start - gi;            % start of [GI; useful] block 1

    if block_start < 1
        error("    (f) extract_ofdm_symbols: frame starts before the signal");
    end

    % ---- Number of OFDM symbols ------------------------------------------
    n_fit = floor((n_samples - block_start + 1) / S);
    if isfield(config, 'n_ofdm_symbols')
        n_sym = config.n_ofdm_symbols;
        if ~isscalar(n_sym) || n_sym < 1 || n_sym ~= round(n_sym)
            error("    (f) extract_ofdm_symbols: n_ofdm_symbols must be a positive integer");
        end
        if n_sym > n_fit
            error("    (f) extract_ofdm_symbols: signal too short - %d symbol(s) expected, %d fit", ...
                n_sym, n_fit);
        end
    else
        n_sym = n_fit;
        fprintf("    (f) extract_ofdm_symbols: n_ofdm_symbols not set, taking %d whole symbol(s)\n", n_sym);
    end

    if n_sym < 1
        error("    (f) extract_ofdm_symbols: no whole OFDM symbol in the signal");
    end

    % ---- Cutting out the symbols -----------------------------------------
    fprintf("    (f) extract_ofdm_symbols: %d symbol(s) x %d samples from sample %d (backoff %d)\n", ...
        n_sym, S, block_start, backoff);

    % Inverse of build_frame: consecutive S-sample blocks -> columns
    frame_part = signal(block_start : block_start + n_sym * S - 1);
    symbols_gi_rx = reshape(frame_part, S, n_sym);

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(symbols_gi_rx), [S, n_sym])
        error("    (f) extract_ofdm_symbols: unexpected output size");
    end

    fprintf("    (f) extract_ofdm_symbols: output size %d x %d\n", S, n_sym);
    fprintf("    (f) extract_ofdm_symbols: finished successfully\n");

end
