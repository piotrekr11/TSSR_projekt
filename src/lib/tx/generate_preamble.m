% =========================================================================
% Function name: generate_preamble
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Generates the synchronization preamble: one OFDM symbol with BPSK
% (PRBS) values on all used subcarriers, whose useful part is repeated
% preamble_repetitions times and preceded by a guard interval:
%   [GI; A; A]   (for preamble_repetitions = 2)
% Two identical blocks distant by ifft_size samples let the RX detect
% the frame start and estimate the frequency offset (moving-segment
% correlation, sync_win = sync_jump = ifft_size).
%
% Inputs:
%   config - configuration structure, uses:
%            used_subcarriers, preamble_prbs_state, preamble_repetitions,
%            gi_samples, ifft_size (+ fields used by
%            insert_null_subcarriers, oversample_spectrum, ofdm_modulate)
%
% Outputs:
%   preamble - (gi_samples + preamble_repetitions*ifft_size) x 1 complex
%              column vector (time samples)
%
% Notes:
%   Same OFDM chain as the data (null subcarriers, oversampling, IFFT),
%   so the preamble occupies the same band. BPSK amplitude 1 - the same
%   mean power as the normalized QPSK data.
% =========================================================================

function preamble = generate_preamble(config)

    fprintf("    (f) generate_preamble: started\n");

    % ---- Input validation ------------------------------------------------
    required = ["used_subcarriers", "preamble_prbs_state", ...
                "preamble_repetitions", "gi_samples", "ifft_size"];
    for f = required
        if ~isfield(config, f)
            error("    (f) generate_preamble: missing config.%s", f);
        end
    end

    reps = config.preamble_repetitions;
    if ~isscalar(reps) || reps < 2 || reps ~= round(reps)
        error("    (f) generate_preamble: preamble_repetitions must be an integer >= 2");
    end

    % ---- Frequency domain: BPSK from PRBS on all used subcarriers --------
    prbs = generate_prbs(config.preamble_prbs_state, config.used_subcarriers);
    preamble_grid = (1 - 2 * prbs).';         % column = one OFDM symbol

    % ---- Same OFDM chain as for the data ---------------------------------
    spectrum = insert_null_subcarriers(config, preamble_grid);
    spectrum_os = oversample_spectrum(config, spectrum);
    block = ofdm_modulate(config, spectrum_os);  % ifft_size x 1

    % ---- [GI; A; A; ...] -------------------------------------------------
    gi = config.gi_samples;
    fprintf("    (f) generate_preamble: GI %d + %d x %d samples\n", ...
        gi, reps, config.ifft_size);

    % block * ones(1, reps) = reps identical columns, (:) serializes them
    repeated = block * ones(1, reps);
    preamble = [block(end-gi+1:end); repeated(:)];

    % ---- Output validation -----------------------------------------------
    expected_len = gi + reps * config.ifft_size;
    if ~iscolumn(preamble) || length(preamble) ~= expected_len
        error("    (f) generate_preamble: expected a %d x 1 column vector", expected_len);
    end

    fprintf("    (f) generate_preamble: preamble length %d samples\n", length(preamble));
    fprintf("    (f) generate_preamble: finished successfully\n");

end
