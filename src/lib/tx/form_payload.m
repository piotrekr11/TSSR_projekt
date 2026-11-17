% =========================================================================
% Function name: get_payload_tx
% Author: Adam
% Creation date: 2026-11-10
% Last modified: 2026-11-11
%
% Description:
% This function forms the full payload frame with size meta-data appended
% at the beginning
%
% Inputs:
%   data - data structure, with the image and sizes in bits
%
% Outputs:
%   payload - XXX
%
% Notes:
%   
% =========================================================================

function payload = form_payload(data)

    fprintf("    (f) form_payload: started\n");

    % Assemble complete payload
    payload.bits = [data.size_m_bits, ...
                    data.size_n_bits, ...
                    data.image_bits];

    payload.payload_length = length(payload.bits);

    fprintf("    (f) form_payload: generated %d bits\n", ...
        payload.payload_length);

    fprintf("    (f) form_payload: finished successfully\n");

end