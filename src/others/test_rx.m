%% Test odbiornika (PIOTR)
% Pelny lancuch: nadajnik (KAMIL/ADAM) -> szum przed ramka -> kanal
% dwudrogowy (ofdm_wbchannel) -> przesuniecie czestotliwosci
% (ofdm_addfreqshift) -> AWGN (ofdm_addnoise) -> synchronizacja (ADAM)
% -> extract_ofdm_symbols -> remove_guard_interval -> ofdm_demodulate
% -> extract_subcarriers -> estimate_channel -> interpolate_channel
% -> equalize_symbols -> qam_demodulate -> get_payload_rx (ADAM).
%
% Dla kazdego scenariusza liczona jest bitowa stopa bledow (BER, przed
% descramblerem) i sprawdzane jest, czy obrazek odtworzono bez bledow.
% Kryterium poprawnego dzialania: BER = 0 (obrazek identyczny).
% Scenariusze 1-5 maja dzialac (dobre warunki), 6-7 sa poza granica
% (silny szum / echo dluzsze niz pozwala rozstaw pilotow) - tam
% oczekiwane sa bledy. Test sprawdza zgodnosc z oczekiwaniem.
%
% Uruchomienie: z dowolnego folderu, np. >> run('src/others/test_rx.m')
close all; clc; clear;

%% Paths and configuration (relative to this file, works from any folder)
src_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(src_dir, 'lib', 'tx'));
addpath(fullfile(src_dir, 'lib', 'rx'));
addpath(fullfile(src_dir, 'lib', 'channel'));
addpath(fullfile(src_dir, 'utils'));
run(fullfile(src_dir, 'configuration.m'));

show_plots = true;

%% TX (once)
config.payload_img = "castle";
[payload, config] = get_payload_tx(config);
bit_groups = split_payload(config, payload.bits);
data_symbols = qam_modulate(config, bit_groups);
pilots = generate_pilots(config);
grid = map_resource_grid(config, data_symbols, pilots);
spectrum = insert_null_subcarriers(config, grid);
spectrum_os = oversample_spectrum(config, spectrum);
symbols_t = ofdm_modulate(config, spectrum_os);
symbols_gi = add_guard_interval(config, symbols_t);
preamble = generate_preamble(config);
signal_tx = build_frame(config, preamble, symbols_gi);

% Frame length known to the RX
config.n_ofdm_symbols = payload.n_ofdm_symbols;
original = get_data(config);

ts = config.sample_period;
subcarrier_spacing = 1 / (config.ifft_size * ts);

%% Scenarios:
% [SNR dB, 2nd path delay (samples after 1st), |a2|, f_shift / spacing, expected OK]
%  1st path delay = 300 samples (nonzero, as required), amplitude 1
scenarios = [ ...
    30,    0, 0.0,  0.00, 1; ...   % (almost) ideal
    20,  200, 0.5,  0.30, 1; ...   % typical
    12,  300, 0.5, -0.45, 1; ...   % noisy, frequency shift near the limit
     8,    0, 0.0,  0.40, 1; ...   % strong noise, no echo
    20,  750, 0.7,  0.20, 1; ...   % long, strong echo
     3,  300, 0.5,  0.20, 0; ...   % too much noise
    30, 1250, 0.8,  0.40, 0];      % echo too long for pilot spacing 8

noise_prefix = 5000;      % noise-only samples before the frame
delay1 = 300;             % 1st path delay in samples
n_ok = 0;

for s = 1:size(scenarios, 1)

    snr_db = scenarios(s, 1);
    d2 = scenarios(s, 2);
    a2 = scenarios(s, 3);
    f_shift = scenarios(s, 4) * subcarrier_spacing;
    expected_ok = scenarios(s, 5) == 1;

    fprintf("\n======== test_rx: scenario %d: SNR %d dB, echo %d samples x %.2f, df %.2f spacing ========\n", ...
        s, snr_db, d2, a2, scenarios(s, 4));

    % ---- Channel ----
    rx = [zeros(noise_prefix, 1); signal_tx; zeros(2000, 1)];
    rx = ofdm_wbchannel(rx, [delay1; delay1 + d2] * ts, ...
        [1; a2 * exp(1i * pi / 5)], ts);
    rx = ofdm_addfreqshift(rx, f_shift, ts);
    rx = ofdm_addnoise(rx, snr_db);

    % ---- RX: synchronization (ADAM) ----
    [frame_start, corr_vals] = detect_frame_start(config, rx);
    ferror = estimate_frequency_offset(config, corr_vals, frame_start);
    rx = compensate_frequency_offset(config, rx, ferror);

    % ---- RX: PIOTR ----
    symbols_gi_rx = extract_ofdm_symbols(config, rx, frame_start, preamble);
    symbols_t_rx = remove_guard_interval(config, symbols_gi_rx);
    spectrum_os_rx = ofdm_demodulate(config, symbols_t_rx);
    grid_rx = extract_subcarriers(config, spectrum_os_rx);
    h_pilots = estimate_channel(config, grid_rx, pilots);
    h_est = interpolate_channel(config, h_pilots);
    data_symbols_rx = equalize_symbols(config, grid_rx, h_est);
    rx_bits = qam_demodulate(config, data_symbols_rx);

    % ---- RX: payload (ADAM) ----
    payload_rx.bits = rx_bits;
    [data, ~] = get_payload_rx(config, payload_rx);

    % ---- Results ----
    n_err = sum(rx_bits ~= payload.bits);
    ber = n_err / length(payload.bits);
    evm = sqrt(sum(abs(data_symbols_rx - data_symbols).^2) / length(data_symbols));

    rx_image = data.image(1:length(original.image));
    ok = n_err == 0 && isequal(rx_image, original.image);
    n_ok = n_ok + (ok == expected_ok);

    fprintf("test_rx: frame_start %d (preamble at %d), df %.0f Hz est. %.0f Hz\n", ...
        frame_start, noise_prefix + delay1 + 1, f_shift, ferror);
    fprintf("test_rx: bit errors %d / %d, BER %.2e, EVM %.3f -> image OK: %d (expected %d)\n", ...
        n_err, length(payload.bits), ber, evm, ok, expected_ok);

    if show_plots
        figure("Name", sprintf("Scenario %d", s));
        set(gcf, "color", "white");
        subplot(1, 2, 1);
        plot(real(data_symbols_rx), imag(data_symbols_rx), '.');
        axis('equal'); grid('on');
        title(sprintf("Equalized symbols, SNR %d dB", snr_db));
        subplot(1, 2, 2);
        plot(abs(h_est(:, 1))); hold on;
        plot(config.pilot_idx, abs(h_pilots(:, 1)), 'o');
        grid('on'); xlabel("used subcarrier"); ylabel("|H|");
        title("Channel estimate (symbol 1)");
        legend("interpolated", "pilots (LS)");
    end
end

fprintf("\n================ test_rx: %d / %d scenarios as expected ================\n", ...
    n_ok, size(scenarios, 1));
