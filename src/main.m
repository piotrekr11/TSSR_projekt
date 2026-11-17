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

% % Detect frame start - ADAM
% [frame_start, corr_vals] = detect_frame_start(config, signal);
% 
% % Estimate frequency offset - ADAM
% ferror = estimate_frequency_offset(config, corr_vals, frame_start);
% 
% % Compensate frequency offset - ADAM
% signal = compensate_frequency_offset(config, signal, ferror);

% extract OFDM symbols - PIOTR

% remove GI - PIOTR

% OFDM demodulator  - PIOTR

% extract subcarriers - PIOTR

% estimate channel - PIOTR

% interpolate channel - PIOTR

% equalize symbols - PIOTR

% qam demodulator - PIOTR

% get payload back - ADAM
% get_payload_rx(config, payload);


