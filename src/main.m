%% This is the main script of the OFDM simulation
close all; clc; clear;

%% ========================================================================
% OFDM Simulation Configuration 
% =========================================================================

% Load Configuration parameters
run("configuration.m");

% Load libraries and utilities
addpath("lib/tx");
addpath("lib/rx");
addpath("lib/channel");
addpath("utils/");
    
%% ========================================================================
% OFDM Simulation - Transmitter 
% =========================================================================

% Load the payload (incl. zero-byte padding and scrambling) - ADAM / KAMIL
[payload, config] = get_payload_tx(config);

% Divide the bitstream into groups of bits for QAM modulation - KAMIL
bit_groups = split_payload(config, payload.bits);

% QAM modulator - KAMIL
data_symbols = qam_modulate(config, bit_groups);

% Pilot values (shared with RX) - KAMIL
pilots = generate_pilots(config);

% Time-frequency grid: data + pilots on used subcarriers - KAMIL
grid = map_resource_grid(config, data_symbols, pilots);

% =======================================

% Insert zero subcarriers (frequency guard bands) - KAMIL
spectrum = insert_null_subcarriers(config, grid);

% Upsampling (zero padding of the spectrum) - KAMIL
spectrum_os = oversample_spectrum(config, spectrum);

% IFFT with shift: ifft(spectrum_shift(X)) - KAMIL
symbols_t = ofdm_modulate(config, spectrum_os);

% Add Guard Interval - KAMIL
symbols_gi = add_guard_interval(config, symbols_t);

% (pilots are inserted above, in map_resource_grid - before the IFFT)

% Synchronization preamble [GI; A; A] - KAMIL
preamble = generate_preamble(config);

% Build OFDM frame - preamble + data symbols, column vector - KAMIL
signal = build_frame(config, preamble, symbols_gi);

%% ========================================================================
% OFDM Simulation - Channel 
% =========================================================================

% Apply Channel - from tssr_lib
% signal = ofdm_wbchannel();

% Apply Noise - from tssr_lib
% signal = ofdm_addnoise();

% Apply Frequency Shift - from tssr_lib
% signal = ofdm_addfreqshift();

%% ========================================================================
% OFDM Simulation - Receiver 
% =========================================================================

% Detect frame start - ADAM
[frame_start, corr_vals] = detect_frame_start(config, signal);

% Estimate frequency offset - ADAM
ferror = estimate_frequency_offset(config, corr_vals, frame_start);

% Compensate frequency offset - ADAM
signal = compensate_frequency_offset(config, signal, ferror);

% Frame length (number of data OFDM symbols) known to the RX - PIOTR
config.n_ofdm_symbols = payload.n_ofdm_symbols;

% extract OFDM symbols - PIOTR
symbols_gi_rx = extract_ofdm_symbols(config, signal, frame_start, preamble);

% remove GI - PIOTR
symbols_t_rx = remove_guard_interval(config, symbols_gi_rx);

% OFDM demodulator  - PIOTR
spectrum_os_rx = ofdm_demodulate(config, symbols_t_rx);

% extract subcarriers - PIOTR
grid_rx = extract_subcarriers(config, spectrum_os_rx);

% estimate channel - PIOTR
h_pilots = estimate_channel(config, grid_rx, pilots);

% interpolate channel - PIOTR
h_est = interpolate_channel(config, h_pilots);

% equalize symbols - PIOTR
data_symbols_rx = equalize_symbols(config, grid_rx, h_est);

% qam demodulator - PIOTR
payload_rx.bits = qam_demodulate(config, data_symbols_rx);

% get payload back - ADAM
[data_rx, config] = get_payload_rx(config, payload_rx);
