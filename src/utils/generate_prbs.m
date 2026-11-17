% =========================================================================
% Function name: generate_prbs
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Generates a pseudo-random binary sequence with a 7-bit LFSR,
% polynomial x^7 + x^4 + 1 (the same register as in scramble_payload).
% Shared by TX and RX (pilots, synchronization preamble).
%
% Inputs:
%   state - 1x7 binary vector, initial LFSR state (not all zeros)
%   n     - number of bits to generate (positive integer)
%
% Outputs:
%   prbs      - 1xn binary row vector
%   new_state - 1x7 LFSR state after generating n bits
%
% Notes:
%   Output bit = state(7), feedback = state(7) XOR state(4), shift right.
%   Sequence period: 127 bits.
% =========================================================================

function [prbs, new_state] = generate_prbs(state, n)

    fprintf("    (f) generate_prbs: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) generate_prbs: expected 2 inputs (state, n)");
    end

    if ~isvector(state) || length(state) ~= 7 || any(state ~= 0 & state ~= 1)
        error("    (f) generate_prbs: state must contain 7 binary values");
    end

    if all(state == 0)
        error("    (f) generate_prbs: state cannot be all zeros");
    end

    if ~isscalar(n) || n < 1 || n ~= round(n)
        error("    (f) generate_prbs: n must be a positive integer");
    end

    state = state(:).';                       % force row vector

    % ---- LFSR ------------------------------------------------------------
    prbs = zeros(1, n);
    for i = 1:n
        prbs(i) = state(7);
        feedback = xor(state(7), state(4));
        state = [feedback, state(1:6)];
    end

    new_state = state;

    fprintf("    (f) generate_prbs: generated %d bits\n", n);
    fprintf("    (f) generate_prbs: finished successfully\n");

end
