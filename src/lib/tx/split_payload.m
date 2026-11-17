% =========================================================================
% Function name: split_payload
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Splits the (padded, scrambled) payload bitstream into groups of
% bits_per_qam_symbol bits - one group per QAM symbol.
%
% Inputs:
%   config - configuration structure, uses:
%            bits_per_qam_symbol - number of bits per QAM symbol (b)
%   bits   - binary vector of length L, L divisible by b
%            (payload.bits from get_payload_tx)
%
% Outputs:
%   bit_groups - (L/b) x b matrix of 0/1, row k = bits of k-th QAM symbol,
%                first column = most significant bit
%
% Notes:
%   Bits are taken in transmission order: row 1 = bits(1:b),
%   row 2 = bits(b+1:2b), ...
% =========================================================================

function bit_groups = split_payload(config, bits)

    fprintf("    (f) split_payload: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) split_payload: expected 2 inputs (config, bits)");
    end

    if ~isfield(config, 'bits_per_qam_symbol')
        error("    (f) split_payload: missing config.bits_per_qam_symbol");
    end

    b = config.bits_per_qam_symbol;
    if ~isscalar(b) || b < 1 || b ~= round(b)
        error("    (f) split_payload: bits_per_qam_symbol must be a positive integer");
    end

    if ~isvector(bits) || isempty(bits) || any(bits ~= 0 & bits ~= 1)
        error("    (f) split_payload: bits must be a nonempty binary vector");
    end

    if mod(length(bits), b) ~= 0
        error("    (f) split_payload: number of bits (%d) is not divisible by %d", ...
            length(bits), b);
    end

    % Force a row vector so reshape takes bits in transmission order
    bits = bits(:).';

    % ---- Splitting -------------------------------------------------------
    n_groups = length(bits) / b;
    fprintf("    (f) split_payload: %d bits -> %d groups of %d bits\n", ...
        length(bits), n_groups, b);

    % reshape fills columns: column k = bits of group k, then transpose
    bit_groups = reshape(bits, b, n_groups).';

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(bit_groups), [n_groups, b])
        error("    (f) split_payload: unexpected output size");
    end

    fprintf("    (f) split_payload: finished successfully\n");

end
