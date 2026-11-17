%% This is a configuration file/function for the OFDM simulation

%% OFDM parameters
% Useful symbol time [s]
config.useful_symbol_time = 2000/4096 * 1e-6;
% Guard interval length []
config.guard_interval_length = 1/8 * config.useful_symbol_time;
% FFT size
config.fft_size = 4096;
% Oversampling
config.oversampling_factor = 4;
% Elementary period
config.elementary_period = config.useful_symbol_time / config.fft_size;

%% Transmitter parameters - KAMIL
% All lengths below are in samples / subcarriers (not seconds).
% config.fft_size is the nominal transform size N (number of subcarriers),
% the IFFT is computed on N * oversampling_factor points.

% IFFT size after oversampling (zero padding of the spectrum)
config.ifft_size = config.fft_size * config.oversampling_factor;
% Guard interval (cyclic prefix) length in samples after oversampling: 1/8
config.gi_samples = config.ifft_size / 8;
% Full OFDM symbol length in samples (GI + useful part)
config.ofdm_symbol_samples = config.gi_samples + config.ifft_size;

% --- Zero subcarriers (frequency guard bands at the band edges) ----------
config.left_zero_subcarriers = 400;
config.right_zero_subcarriers = 399;
config.used_subcarriers = config.fft_size ...
    - config.left_zero_subcarriers - config.right_zero_subcarriers;

% --- Subcarrier modulation: QPSK with Gray mapping -----------------------
% Group of bits [b1 b0] -> index 2*b1 + b0 + 1 into the constellation:
%   b1 selects the sign of I, b0 selects the sign of Q (0 -> +, 1 -> -)
config.bits_per_qam_symbol = 2;
config.constellation = [1+1i, 1-1i, -1+1i, -1-1i] / sqrt(2);

% --- Pilots (comb type, same positions in every OFDM symbol) -------------
% Pilot on every 8th used subcarrier, including the first and the last
% used subcarrier, so the RX only interpolates (never extrapolates)
% the channel estimate between pilots.
config.pilot_spacing = 8;
% Pilot / data positions as indices within the used subcarriers
config.pilot_idx = 1 : config.pilot_spacing : config.used_subcarriers;
is_data = true(1, config.used_subcarriers);
is_data(config.pilot_idx) = false;
all_idx = 1 : config.used_subcarriers;
config.data_idx = all_idx(is_data);
clear is_data all_idx;
config.pilots_per_symbol = length(config.pilot_idx);
config.data_per_symbol = length(config.data_idx);
% BPSK pilots boosted in amplitude, signs taken from a PRBS (LFSR x^7+x^4+1)
config.pilot_boost = 4/3;
config.pilot_prbs_state = [1 0 1 0 1 1 1];

% --- Synchronization preamble --------------------------------------------
% Preamble = GI + preamble_repetitions identical useful parts
% (each ifft_size samples). Two identical blocks distant by ifft_size
% samples are needed by detect_frame_start / estimate_frequency_offset
% (sync_win = sync_jump = ifft_size).
config.preamble_repetitions = 2;
config.preamble_prbs_state = [1 1 0 0 1 0 1];

% --- Payload packing -----------------------------------------------------
config.bits_per_ofdm_symbol = config.data_per_symbol * config.bits_per_qam_symbol;
% Padding with whole zero bytes (char(0)), RX strips trailing char(0)
config.pad_byte = 0;

% Padding with whole bytes requires bits_per_ofdm_symbol divisible by 8
if mod(config.bits_per_ofdm_symbol, 8) ~= 0
    error("configuration: bits_per_ofdm_symbol (%d) must be divisible by 8", ...
        config.bits_per_ofdm_symbol);
end

%% Payload selection
% Available: "cat", "dog", "fish", "rabbit", "owl", "castle" (much bigger), or "random"
config.payload_img = "cat";

% encoding size
config.dimension_bits = 8;

% scrambler initial state
config.tx_scrambler_state = [1 1 1 1 1 1 1];
config.rx_scrambler_state = [1 1 1 1 1 1 1];

%% Detection

% threshold to be exceeded by the correlation peaks to be identified
% (normalized to max)
config.detection_threshold_alfa = 0.8;
config.sync_win = config.fft_size * 4;
% Define restricted search window for first peak
config.peak_search_window = 2 * (config.fft_size + config.guard_interval_length) * config.oversampling_factor;

%% Frequency error estimation and compensation:
config.sync_jump = config.fft_size * 4;
config.sample_period = config.elementary_period / 4;
