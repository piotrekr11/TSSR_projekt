
close all;
clc;
clear;

%% Configuration

config.fft_size = 256;
config.oversampling = 4;
config.useful_symbol_time = 2000/4096 * 1e-6;

config.sync_win = config.fft_size * config.oversampling;
config.sync_jump = config.fft_size * config.oversampling;

% Sampling frequency after 4x oversampling
config.sample_period = 1 / (80e6);

config.detection_threshold_alfa = 0.8;
config.guard_interval_length = 1/8 * config.useful_symbol_time;

%% Generate synchronization preamble

number_of_symbols = 5;

% Generate five synchronization symbols.
% Each symbol consists of two identical halves.

preamble = [];

for k = 1:number_of_symbols

    preamble_half = sign(randn(config.sync_win, 1)) + ...
                    1i * sign(randn(config.sync_win, 1));

    preamble_half = preamble_half / sqrt(2);

    % Two identical halves
    symbol = [preamble_half; preamble_half];

    % Slightly increase amplitude for each successive symbol
    symbol = (1 + 0.1 * (k - 1)) * symbol;

    preamble = [preamble; symbol];

end

%% Generate received signal

% Noise-only segment before the frame
noise_length = 200;

prefix = 0.05 * (randn(noise_length, 1) + ...
                 1i * randn(noise_length, 1));

% Noise after the five-symbol preamble
suffix = 0.05 * (randn(500, 1) + ...
                 1i * randn(500, 1));

% Complete transmitted test signal
tx_signal = [prefix; preamble; suffix];

% Remember the actual preamble start
expected_frame_start = noise_length + 1;

%% Add frequency offset

% Artificial frequency offset in Hz
expected_frequency_offset = 20000;

N = length(tx_signal);
n = (0:N-1).';

frequency_shift = exp(1i * 2 * pi * ...
    expected_frequency_offset * config.sample_period * n);

signal = tx_signal .* frequency_shift;

%% Add AWGN

noise_amplitude = 0.05;

noise = noise_amplitude / sqrt(2) * ...
    (randn(N, 1) + 1i * randn(N, 1));

signal = signal + noise;

%% Receiver

% Detect frame start
[frame_start, corr_vals] = detect_frame_start(config, signal);

% Estimate frequency offset
ferror = estimate_frequency_offset(config, corr_vals, frame_start);

% Compensate frequency offset
signal_corrected = compensate_frequency_offset(config, signal, ferror);

%% Display results

fprintf("\n========== TEST RESULTS ==========\n");

fprintf("Number of synchronization symbols: %d\n", number_of_symbols);
fprintf("Expected frame start:              %d\n", expected_frame_start);
fprintf("Detected frame start:              %d\n", frame_start);

fprintf("Expected frequency offset:         %.2f Hz\n", ...
    expected_frequency_offset);

fprintf("Estimated frequency offset:        %.2f Hz\n", ferror);

fprintf("Frequency estimation error:        %.2f Hz\n", ...
    abs(expected_frequency_offset - ferror));

fprintf("==================================\n");

%% Plot correlation

figure;

plot(abs(corr_vals));
hold on;

plot(frame_start, abs(corr_vals(frame_start)), 'ro');

% Mark expected frame start
xline(expected_frame_start, '--g', 'Expected frame start');

xlabel("Sample index");
ylabel("Correlation magnitude");
title("Moving-segment correlation - 5 synchronization symbols");
legend("Correlation", "Detected position", "Expected position");
grid on;
