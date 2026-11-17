
function data_bits = uint_to_bits(data)

    data_bits = zeros(1, numel(data) * 8);
    
    for i = 1:numel(data)
        for b = 1:8
            data_bits((i-1)*8 + b) = bitget(data(i), 9-b);
        end
    end

end