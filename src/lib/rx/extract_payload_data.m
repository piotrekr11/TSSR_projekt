% =========================================================================
% Function: extract_payload_data
% Responsible person: ADAM
%
% Inputs:
%   config  - Configuration structure containing the metadata bit length
%   payload - Structure containing the received payload bitstream
%
% Outputs:
%   data - Structure containing the decoded dimensions and image bitstream:
%          size_m_bits, size_n_bits, size_m, size_n, image_bits
%
% Description:
%   Separates the payload metadata from the image bitstream, converts
%   the dimension fields from binary to integers, and stores the
%   extracted information in a data structure.
% =========================================================================

function data = extract_payload_data(config, payload)

    fprintf("    (f) extract_payload_data: started\n");

    dimension_bits = config.dimension_bits;
    metadata_length = 2 * dimension_bits;

    % Validate payload length
    if length(payload.bits) < metadata_length
        error("    extract_payload_data: payload too short");
    end

    % Extract dimension bit vectors
    data.size_m_bits = payload.bits(1:dimension_bits);
    data.size_n_bits = payload.bits(dimension_bits+1:metadata_length);

    % Convert dimensions from bits to integers
    data.size_m = bits_to_uint(data.size_m_bits);
    data.size_n = bits_to_uint(data.size_n_bits);

    % Extract image bitstream
    data.image_bits = payload.bits(metadata_length+1:end);

    fprintf("    (f) extract_payload_data: dimensions %d x %d\n", ...
        data.size_m, data.size_n);

    fprintf("    (f) extract_payload_data: finished successfully\n");

end