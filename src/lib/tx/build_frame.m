% =========================================================================
% Function name: build_frame
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Builds the transmitted OFDM frame: synchronization preamble followed by
% all data OFDM symbols (with GI), serialized into one signal vector:
%   [preamble; symbol_1; symbol_2; ...]
%
% Inputs:
%   config     - configuration structure, uses: ofdm_symbol_samples
%   preamble   - column vector from generate_preamble
%   symbols_gi - ofdm_symbol_samples x n_sym matrix (add_guard_interval)
%
% Outputs:
%   signal - (length(preamble) + n_sym*ofdm_symbol_samples) x 1 complex
%            column vector - TX output, input of the channel functions
%
% Notes:
%   Column vector, as expected by ofdm_wbchannel / ofdm_addnoise /
%   ofdm_addfreqshift and the RX. The noise segment before the frame is
%   added in the channel part, not here.
% =========================================================================

function signal = build_frame(config, preamble, symbols_gi)

    fprintf("    (f) build_frame: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 3
        error("    (f) build_frame: expected 3 inputs (config, preamble, symbols_gi)");
    end

    if ~isfield(config, 'ofdm_symbol_samples')
        error("    (f) build_frame: missing config.ofdm_symbol_samples");
    end

    if ~isvector(preamble) || isempty(preamble)
        error("    (f) build_frame: preamble must be a nonempty vector");
    end

    if isempty(symbols_gi) || size(symbols_gi, 1) ~= config.ofdm_symbol_samples
        error("    (f) build_frame: symbols_gi must have %d rows, has %d", ...
            config.ofdm_symbol_samples, size(symbols_gi, 1));
    end

    % Force a column vector
    preamble = preamble(:);

    % ---- Serialization ---------------------------------------------------
    n_sym = size(symbols_gi, 2);
    fprintf("    (f) build_frame: preamble %d samples + %d data symbol(s) x %d samples\n", ...
        length(preamble), n_sym, config.ofdm_symbol_samples);

    % (:) reads the matrix column by column = symbol after symbol
    signal = [preamble; symbols_gi(:)];

    % ---- Output validation -----------------------------------------------
    expected_len = length(preamble) + n_sym * config.ofdm_symbol_samples;
    if ~iscolumn(signal) || length(signal) ~= expected_len
        error("    (f) build_frame: expected a %d x 1 column vector", expected_len);
    end

    fprintf("    (f) build_frame: frame length %d samples\n", length(signal));
    fprintf("    (f) build_frame: finished successfully\n");

end
