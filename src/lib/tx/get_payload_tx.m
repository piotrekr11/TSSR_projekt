% =========================================================================
% Function name: get_payload_tx
% Author: Adam
% Creation date: 2026-11-10
% Last modified: 2026-11-15 (Kamil: pad_payload before scrambling)
%
% Description:
% Creates the complete TX payload. Selects ASCII art, converts it into
% bits, adds image dimensions as metadata, pads it with zero bytes to a
% whole number of OFDM symbols and scrambles the bitstream.
%
% Inputs:
%   config  - Configuration structure
%
% Outputs:
%   payload - Structure containing:
%             bits            - Scrambled payload bitstream
%             payload_length  - Number of payload bits
%             image_size      - Original image dimensions
%
% Notes:
%   Scrambling is performed on the complete payload before OFDM framing.
% =========================================================================

function [payload, config] = get_payload_tx(config)

    fprintf("(f) get_payload_tx: started\n");

    % Choose an ASCII art to be transmitted
    data = get_data(config);

    % Convert ASCII art into bits
    data = data_to_bits(data);

    % Form complete payload, including metadata
    payload = form_payload(data);

    % Pad with zero bytes to a whole number of OFDM symbols - KAMIL
    payload = pad_payload(config, payload);

    % Scramble complete payload
    [payload.bits, config.scrambler_state] = ...
        scramble_payload(config, payload.bits);

    fprintf("(f) get_payload_tx: payload contains %d bits\n", ...
        length(payload.bits));

    fprintf("(f) get_payload_tx: finished successfully\n");

end
