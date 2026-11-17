% =========================================================================
% Function name: generate_pilots
% Author: Kamil
% Creation date: 2026-11-15
% Last modified: 2026-11-15
%
% Description:
% Generates the known pilot values (boosted BPSK) placed on the pilot
% subcarriers config.pilot_idx. Shared by TX (insertion) and RX
% (channel estimation), so both sides use identical values.
%
% Inputs:
%   config - configuration structure, uses:
%            pilots_per_symbol - number of pilots in one OFDM symbol
%            pilot_boost       - pilot amplitude
%            pilot_prbs_state  - 1x7 initial LFSR state
%
% Outputs:
%   pilots - 1 x pilots_per_symbol real row vector, values +-pilot_boost.
%            Element k is the pilot on used subcarrier config.pilot_idx(k).
%
% Notes:
%   Pilot values depend only on the subcarrier, not on the OFDM symbol
%   number - the same vector is used in every OFDM symbol, so the RX does
%   not need to know the symbol index. PRBS bit 0 -> +boost, 1 -> -boost.
% =========================================================================

function pilots = generate_pilots(config)

    fprintf("    (f) generate_pilots: started\n");

    % ---- Input validation ------------------------------------------------
    required = ["pilots_per_symbol", "pilot_boost", "pilot_prbs_state"];
    for f = required
        if ~isfield(config, f)
            error("    (f) generate_pilots: missing config.%s", f);
        end
    end

    n = config.pilots_per_symbol;
    if ~isscalar(n) || n < 1 || n ~= round(n)
        error("    (f) generate_pilots: pilots_per_symbol must be a positive integer");
    end

    if ~isscalar(config.pilot_boost) || config.pilot_boost <= 0
        error("    (f) generate_pilots: pilot_boost must be a positive number");
    end

    % ---- PRBS -> BPSK ----------------------------------------------------
    prbs = generate_prbs(config.pilot_prbs_state, n);
    pilots = config.pilot_boost * (1 - 2 * prbs);

    % ---- Output validation -----------------------------------------------
    if ~isequal(size(pilots), [1, n])
        error("    (f) generate_pilots: unexpected output size");
    end

    fprintf("    (f) generate_pilots: %d pilots, amplitude %.4f\n", n, config.pilot_boost);
    fprintf("    (f) generate_pilots: finished successfully\n");

end
