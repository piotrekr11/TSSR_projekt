% =========================================================================
% Function name: pad_payload
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Pads the payload bitstream with whole zero bytes (config.pad_byte) so
% that it fills an integer number of OFDM symbols. Called before the
% scrambler, so the padding is scrambled together with the payload.
%
% Inputs:
%   config  - configuration structure, uses:
%             bits_per_ofdm_symbol - data bits carried by one OFDM symbol
%                                    (must be divisible by 8)
%             pad_byte             - value of the padding byte (0..255)
%   payload - structure from form_payload, uses:
%             bits - 1xL binary row vector, L divisible by 8
%
% Outputs:
%   payload - the same structure with:
%             bits           - 1x(n_ofdm_symbols*bits_per_ofdm_symbol)
%                              binary row vector (payload + padding)
%             pad_bytes      - number of appended padding bytes
%             n_ofdm_symbols - number of OFDM data symbols needed
%
% Notes:
%   RX strips trailing char(0) after descrambling. This is safe for
%   ASCII art, which never contains a NUL byte. payload_length set by
%   form_payload is kept unchanged (length without padding).
% =========================================================================

function payload = pad_payload(config, payload)

    fprintf("    (f) pad_payload: started\n");

    % ---- Input validation ------------------------------------------------
    if nargin < 2
        error("    (f) pad_payload: expected 2 inputs (config, payload)");
    end

    if ~isfield(config, 'bits_per_ofdm_symbol') || ~isfield(config, 'pad_byte')
        error("    (f) pad_payload: config must contain bits_per_ofdm_symbol and pad_byte");
    end

    bits_per_sym = config.bits_per_ofdm_symbol;
    if ~isscalar(bits_per_sym) || bits_per_sym <= 0 || mod(bits_per_sym, 8) ~= 0
        error("    (f) pad_payload: bits_per_ofdm_symbol must be a positive multiple of 8");
    end

    pad_byte = config.pad_byte;
    if ~isscalar(pad_byte) || pad_byte < 0 || pad_byte > 255 || pad_byte ~= round(pad_byte)
        error("    (f) pad_payload: pad_byte must be an integer in 0..255");
    end

    if ~isfield(payload, 'bits')
        error("    (f) pad_payload: payload must contain field 'bits'");
    end

    bits = payload.bits;
    if ~isvector(bits) || isempty(bits) || any(bits ~= 0 & bits ~= 1)
        error("    (f) pad_payload: payload.bits must be a nonempty binary vector");
    end

    % Force a row vector (other TX functions work on rows)
    bits = bits(:).';

    if mod(length(bits), 8) ~= 0
        error("    (f) pad_payload: payload length (%d) is not a whole number of bytes", ...
            length(bits));
    end

    % ---- Padding ---------------------------------------------------------
    n_ofdm_symbols = ceil(length(bits) / bits_per_sym);
    n_pad_bits = n_ofdm_symbols * bits_per_sym - length(bits);
    n_pad_bytes = n_pad_bits / 8;

    fprintf("    (f) pad_payload: %d payload bits -> %d OFDM symbol(s), adding %d pad bytes\n", ...
        length(bits), n_ofdm_symbols, n_pad_bytes);

    % Repeat the 8 bits of pad_byte n_pad_bytes times (8 x n matrix read
    % column by column) - matrix product instead of repmat
    byte_bits = uint_to_bits(pad_byte);
    pad_bits = reshape(byte_bits(:) * ones(1, n_pad_bytes), 1, []);
    bits = [bits, pad_bits];

    % ---- Output validation -----------------------------------------------
    if length(bits) ~= n_ofdm_symbols * bits_per_sym
        error("    (f) pad_payload: padded length %d is not %d", ...
            length(bits), n_ofdm_symbols * bits_per_sym);
    end

    payload.bits = bits;
    payload.pad_bytes = n_pad_bytes;
    payload.n_ofdm_symbols = n_ofdm_symbols;

    fprintf("    (f) pad_payload: padded payload contains %d bits\n", length(bits));
    fprintf("    (f) pad_payload: finished successfully\n");

end
