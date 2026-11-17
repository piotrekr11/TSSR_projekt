% =========================================================================
% Function name: spectrum_shift
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Swaps the two halves of a vector, or of every column of a matrix.
% Replacement for fftshift / ifftshift (not on the allowed function list).
% Used by TX before the IFFT and by RX after the FFT.
%
% Inputs:
%   x - vector of even length, or matrix with an even number of rows
%       (each column is shifted separately)
%
% Outputs:
%   y - x with halves swapped, same size and orientation as x
%
% Notes:
%   For even length fftshift == ifftshift, so the same function is used
%   in both directions. No debug messages - called very often.
% =========================================================================

function y = spectrum_shift(x)

    if nargin < 1 || isempty(x)
        error("    (f) spectrum_shift: input must be a nonempty vector or matrix");
    end

    % A row vector is treated as one column and restored at the end
    was_row = isrow(x);
    if was_row
        x = x.';
    end

    n = size(x, 1);
    if mod(n, 2) ~= 0
        error("    (f) spectrum_shift: length (%d) must be even", n);
    end

    y = [x(n/2+1:end, :); x(1:n/2, :)];

    if was_row
        y = y.';
    end

end
