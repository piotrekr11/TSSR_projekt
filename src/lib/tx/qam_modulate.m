% =========================================================================
% Function name: qam_modulate
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Maps groups of bits onto complex QAM constellation points
% (config.constellation, QPSK with Gray mapping in the current config).
%
% Inputs:
%   config     - configuration structure, uses:
%                bits_per_qam_symbol - number of bits per symbol (b)
%                constellation       - 1 x 2^b complex vector, element
%                                      k+1 is the point for bit value k
%   bit_groups - N x b matrix of 0/1 from split_payload, first column = MSB
%
% Outputs:
%   symbols - 1 x N complex row vector of QAM symbols
%
% Notes:
%   Index of a group = binary value of its bits + 1, computed as a matrix
%   product with powers of two (no bi2de / qammod).
%   QPSK: [0 0] -> (1+1i)/sqrt(2), [0 1] -> (1-1i)/sqrt(2),
%         [1 0] -> (-1+1i)/sqrt(2), [1 1] -> (-1-1i)/sqrt(2)
% =========================================================================

function symbols = qam_modulate(config, bit_groups)

    fprintf("    (f) qam_modulate: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) qam_modulate: expected 2 inputs (config, bit_groups)");
    end

    if ~isfield(config, 'bits_per_qam_symbol') || ~isfield(config, 'constellation')
        error("    (f) qam_modulate: config must contain bits_per_qam_symbol and constellation");
    end

    b = config.bits_per_qam_symbol;
    constellation = config.constellation(:).';   % force row vector

    if length(constellation) ~= 2^b
        error("    (f) qam_modulate: constellation must have 2^%d = %d points, has %d", ...
            b, 2^b, length(constellation));
    end

    if isempty(bit_groups) || size(bit_groups, 2) ~= b
        error("    (f) qam_modulate: bit_groups must be an N x %d matrix", b);
    end

    if any(bit_groups(:) ~= 0 & bit_groups(:) ~= 1)
        error("    (f) qam_modulate: bit_groups must contain only 0 and 1");
    end

    % ---- Mapping ---------------------------------------------------------
    n_symbols = size(bit_groups, 1);
    fprintf("    (f) qam_modulate: mapping %d groups onto %d-point constellation\n", ...
        n_symbols, 2^b);

    % Binary value of each row (MSB first) -> constellation index
    weights = 2.^(b-1:-1:0).';
    idx = double(bit_groups) * weights + 1;

    symbols = constellation(idx);
    symbols = symbols(:).';                    % force row vector

    % ---- Output validation -----------------------------------------------
    if length(symbols) ~= n_symbols
        error("    (f) qam_modulate: produced %d symbols, expected %d", ...
            length(symbols), n_symbols);
    end

    fprintf("    (f) qam_modulate: mean symbol power = %.4f\n", ...
        sum(abs(symbols).^2) / n_symbols);
    fprintf("    (f) qam_modulate: finished successfully\n");

end
