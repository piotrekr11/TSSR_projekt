% =========================================================================
% Function name: qam_demodulate
% Author: Piotr
% Creation date: 2026-11-17
% Last modified: 2026-11-17
%
% Description:
% Hard-decision QAM demodulator: every equalized symbol is mapped to the
% nearest point of config.constellation (minimum Euclidean distance) and
% replaced by the bits of that point. Bits of consecutive symbols are
% concatenated into one bitstream.
%
% Inputs:
%   config  - configuration structure, uses:
%             bits_per_qam_symbol - number of bits per symbol (b)
%             constellation       - 1 x 2^b complex vector, element k+1
%                                   is the point for bit value k
%   symbols - 1 x N complex vector of equalized symbols (equalize_symbols)
%
% Outputs:
%   bits - 1 x (N*b) binary row vector (double 0/1), bits of symbol 1
%          first, MSB first - input of get_payload_rx (payload.bits)
%
% Notes:
%   Inverse of split_payload + qam_modulate. Works for any constellation
%   given in config (QPSK Gray in the current configuration). Index ->
%   bits is computed with floor/mod (no de2bi / qamdemod).
% =========================================================================

function bits = qam_demodulate(config, symbols)

    fprintf("    (f) qam_demodulate: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) qam_demodulate: expected 2 inputs (config, symbols)");
    end

    if ~isfield(config, 'bits_per_qam_symbol') || ~isfield(config, 'constellation')
        error("    (f) qam_demodulate: config must contain bits_per_qam_symbol and constellation");
    end

    b = config.bits_per_qam_symbol;
    constellation = config.constellation(:).';   % force row vector

    if ~isscalar(b) || b < 1 || b ~= round(b)
        error("    (f) qam_demodulate: bits_per_qam_symbol must be a positive integer");
    end

    if length(constellation) ~= 2^b
        error("    (f) qam_demodulate: constellation must have 2^%d = %d points, has %d", ...
            b, 2^b, length(constellation));
    end

    if ~isvector(symbols) || isempty(symbols) || ~isnumeric(symbols)
        error("    (f) qam_demodulate: symbols must be a nonempty numeric vector");
    end

    if any(~isfinite(symbols))
        error("    (f) qam_demodulate: symbols contain NaN or Inf");
    end

    % Force a column vector: one row of the distance matrix per symbol
    symbols = symbols(:);
    n_symbols = length(symbols);

    % ---- Minimum distance decision ---------------------------------------
    fprintf("    (f) qam_demodulate: deciding %d symbols on %d-point constellation\n", ...
        n_symbols, 2^b);

    % N x 2^b matrix of squared distances to every constellation point
    dist = abs(symbols * ones(1, 2^b) - ones(n_symbols, 1) * constellation).^2;
    [min_dist, idx] = min(dist, [], 2);

    % ---- Index -> bits (MSB first) ---------------------------------------
    value = idx - 1;                                   % N x 1, 0..2^b-1
    bit_groups = mod(floor(value * 2.^(-(b-1:-1:0))), 2); % N x b

    % Row after row -> bitstream (inverse of split_payload)
    bits = reshape(bit_groups.', 1, []);

    % ---- Output validation -----------------------------------------------
    if length(bits) ~= n_symbols * b || any(bits ~= 0 & bits ~= 1)
        error("    (f) qam_demodulate: invalid output bitstream");
    end

    fprintf("    (f) qam_demodulate: mean squared decision distance %.4f\n", ...
        sum(min_dist) / n_symbols);
    fprintf("    (f) qam_demodulate: produced %d bits\n", length(bits));
    fprintf("    (f) qam_demodulate: finished successfully\n");

end
