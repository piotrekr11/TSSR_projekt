% =========================================================================
% Function name: scramble_payload
% Author: Adam
% Creation date: 2026-11-11
% Last modified: 2026-11-11
%
% Description:
% Scrambles input bits using a 7-bit LFSR.
% Maintains its state between consecutive calls.
%
% Inputs:
%   config - Configuration structure containing tx_scrambler_state
%   bits   - Input bit vector
%
% Outputs:
%   scrambled_bits - Scrambled bit vector
%   new_state      - Updated 7-bit LFSR state
%
% Notes:
%   Polynomial: x^7 + x^4 + 1
%   Initial state must not be all zeros.
% =========================================================================

function [scrambled_bits, new_state] = scramble_payload(config, bits)

    fprintf("    (f) scramble_payload: started\n");

    % Validate input bits
    if ~isvector(bits) || isempty(bits) || any(bits ~= 0 & bits ~= 1)
        error("    (f) scramble_payload: input must be a nonempty binary vector");
    end

    % Validate LFSR state
    if ~isfield(config, 'tx_scrambler_state')
        error("    (f) scramble_payload: missing tx_scrambler_state");
    end

    state = config.tx_scrambler_state;

    if ~isvector(state) || length(state) ~= 7 || ...
            any(state ~= 0 & state ~= 1)
        error("    (f) scramble_payload: state must contain 7 binary values");
    end

    if all(state == 0)
        error("    (f) scramble_payload: state cannot be all zeros");
    end

    % Preserve input dimensions
    original_size = size(bits);
    bits = bits(:).';
    state = state(:).';

    scrambled_bits = zeros(size(bits));

    % Generate scrambling sequence and XOR with input
    for i = 1:length(bits)

        % Feedback polynomial: x^7 + x^4 + 1
        feedback = xor(state(7), state(4));

        % Scramble current bit
        scrambled_bits(i) = xor(bits(i), state(7));

        % Shift register
        state = [feedback, state(1:6)];

    end

    % Restore input dimensions
    scrambled_bits = reshape(scrambled_bits, original_size);

    % Return updated state
    new_state = state;

    fprintf("    (f) scramble_payload: processed %d bits\n", length(bits));
    fprintf("    (f) scramble_payload: finished successfully\n");

end
