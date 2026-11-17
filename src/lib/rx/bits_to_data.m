% =========================================================================
% Function: bits_to_data
% Responsible person: ADAM
%
% Inputs:
%   data - Structure containing the reconstructed image bitstream
%          in data.image_bits
%
% Outputs:
%   data - Updated structure containing the reconstructed ASCII image
%          in data.image
%
% Description:
%   Converts the image bitstream into 8-bit character values and then
%   reconstructs the ASCII image as a character array.
% =========================================================================

function data = bits_to_data(data)

    fprintf("    (f) bits_to_data: started\n");

    % Validate image bit count
    if mod(length(data.image_bits), 8) ~= 0
        error("    (f) bits_to_data: image bit count must be divisible by 8");
    end

    % Calculate number of characters
    num_chars = length(data.image_bits) / 8;
    image_chars = zeros(1, num_chars, 'uint8');

    % Convert every 8 bits into one character
    for i = 1:num_chars

        bit_start = (i-1)*8 + 1;
        bit_end = i*8;

        image_chars(i) = bits_to_uint(data.image_bits(bit_start:bit_end));

    end

    % Convert uint8 values into ASCII characters
    data.image = char(image_chars);

    fprintf("    (f) bits_to_data: reconstructed %d characters\n", num_chars);
    fprintf("    (f) bits_to_data: finished successfully\n");

end