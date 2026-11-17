% =========================================================================
% Function name: data_to_bits
% Author: Adam
% Creation date: 2026-11-10
% Last modified: 2026-11-11
%
% Description:
% This function converts ASCII art from a char table into uint8 table
%
% Inputs:
%   config - configuration structure (here only payload_img selector is 
%   accessed)
%
% Outputs:
%   data - data structure containing: image in chars, size M, size N
%
% Notes:
%   Current version assumes static available payloads, but can be called
%   numerous times to construct a bigger payload data
% =========================================================================

function data = data_to_bits(data)

    fprintf("    (f) data_to_bits: started\n");

    % Validate input
    if ~isfield(data, 'image')
        error("    (f) data_to_bits: missing field 'image'");
    end

    fprintf("    (f) data_to_bits: converting image to uint8\n");

    % Convert image data to uint8
    image_uint8 = uint8(data.image);

    fprintf("    (f) data_to_bits: image size: %d x %d\n", ...
        size(image_uint8, 1), size(image_uint8, 2));

    % Convert each byte into 8 individual bits
    fprintf("    (f) data_to_bits: converting pixels into binary representation\n");

    % Store binary representation
    data.image_bits = uint_to_bits(image_uint8);
    data.size_m_bits = uint_to_bits(data.size_m);
    data.size_n_bits = uint_to_bits(data.size_n);

    % Verify length of bits
    expectedBitCount = numel(image_uint8) * 8;
    if numel(data.image_bits) ~= expectedBitCount
        error("    (f) data_to_bits: generated bit count does not match image size");
    end

    fprintf("    (f) data_to_bits: generated %d bit n of image\n", length(data.image_bits));
    fprintf("    (f) data_to_bits: finished successfully\n");

end
