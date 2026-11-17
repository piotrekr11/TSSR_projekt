
function value = bits_to_uint(bits)

    value = 0;

    for i = 1:length(bits)
        value = value + bits(i) * 2^(length(bits)-i);
    end

end