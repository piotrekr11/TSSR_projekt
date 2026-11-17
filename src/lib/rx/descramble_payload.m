% =========================================================================
% Function name: descramble_payload
% Author: Adam
% Creation date: 2026-11-11
% Last modified: 2026-11-11
%
% Description:
% Descrambles input bits using a 7-bit LFSR.
% Maintains its state between consecutive calls.
%
% Inputs:
%   config        - Configuration structure containing rx_scrambler_state
%   scrambled_bits - Input scrambled bit vector
%
% Outputs:
%   bits      - Recovered original bit vector
%   new_state - Updated 7-bit LFSR state
%
% Notes:
%   Uses the same polynomial and initial state as the TX scrambler.
%   Polynomial: x^7 + x^4 + 1
% =========================================================================

function [bits, new_state] = descramble_payload(config, scrambled_bits)

    fprintf("    (f) descramble_payload: started\n");

    % Validate input bits
    if ~isvector(scrambled_bits) || isempty(scrambled_bits) || ...
            any(scrambled_bits ~= 0 & scrambled_bits ~= 1)
        error("    (f) descramble_payload: input must be a nonempty binary vector");
    end

    % Validate LFSR state
    if ~isfield(config, 'rx_scrambler_state')
        error("    (f) descramble_payload: missing rx_scrambler_state");
    end

    state = config.rx_scrambler_state;

    if ~isvector(state) || length(state) ~= 7 || ...
            any(state ~= 0 & state ~= 1)
        error("    (f) descramble_payload: state must contain 7 binary values");
    end

    if all(state == 0)
        error("    (f) descramble_payload: state cannot be all zeros");
    end

    % Preserve input dimensions
    original_size = size(scrambled_bits);
    scrambled_bits = scrambled_bits(:).';
    state = state(:).';

    bits = zeros(size(scrambled_bits));

    % Generate scrambling sequence and XOR with received bits
    for i = 1:length(scrambled_bits)

        % Feedback polynomial: x^7 + x^4 + 1
        feedback = xor(state(7), state(4));

        % Recover original bit
        bits(i) = xor(scrambled_bits(i), state(7));

        % Shift register
        state = [feedback, state(1:6)];

    end

    % Restore input dimensions
    bits = reshape(bits, original_size);

    % Return updated state
    new_state = state;

    fprintf("    (f) descramble_payload: processed %d bits\n", ...
        length(scrambled_bits));

    fprintf("    (f) descramble_payload: finished successfully\n");

end
