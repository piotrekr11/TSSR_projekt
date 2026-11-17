% =========================================================================
% Function name: get_payload_rx
% Author: Adam
% Creation date: 2026-11-11
% Last modified: 2026-11-11
%
% Description:
% Reconstructs the received payload by descrambling, extracting metadata,
% converting bits into ASCII art and displaying the result.
%
% Inputs:
%   config  - Configuration structure
%   payload - Structure containing received scrambled bits
%
% Outputs:
%   data    - Reconstructed payload data
%   config  - Updated configuration structure
% =========================================================================

function [data, config] = get_payload_rx(config, payload)

    fprintf("(f) get_payload_rx: started\n");

    % Descramble received payload
    [payload.bits, config.scrambler_state] = ...
        descramble_payload(config, payload.bits);

    % Extract metadata and image bits
    data = extract_payload_data(config, payload);

    % Convert image bits into ASCII art
    data = bits_to_data(data);

    % Display reconstructed ASCII art
    display_payload(data);

    fprintf("(f) get_payload_rx: finished successfully\n");

end
