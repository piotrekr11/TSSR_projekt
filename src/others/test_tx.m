%% Test nadajnika - warstwa bitowa (KAMIL)
% Sprawdza sciezke: get_payload_tx (obrazek -> bity -> padding -> scrambler)
% -> split_payload -> qam_modulate -> generate_pilots + map_resource_grid
% -> insert_null_subcarriers -> oversample_spectrum -> ofdm_modulate
% -> add_guard_interval -> loopback (usuniecie GI, FFT, odczyt siatki)
% -> prosty demapper QPSK (w tescie)
% -> get_payload_rx (descrambler -> bity -> obrazek), bez kanalu i bez OFDM.
%
% Oczekiwany wynik: po obcieciu koncowych char(0) (padding) odtworzony
% obrazek jest identyczny z oryginalem. Dopoki get_payload_rx nie obcina
% paddingu, display_payload wypisuje zera jako dluga linie "spacji".
%
% Uruchomienie: z dowolnego folderu, np. >> run('src/others/test_tx.m')
close all; clc; clear;

%% Paths and configuration (relative to this file, works from any folder)
src_dir = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(src_dir, 'lib', 'tx'));
addpath(fullfile(src_dir, 'lib', 'rx'));
addpath(fullfile(src_dir, 'lib', 'channel'));
addpath(fullfile(src_dir, 'utils'));
run(fullfile(src_dir, 'configuration.m'));

%% QPSK mapping check: all 4 bit pairs -> expected Gray constellation points
fprintf("\n================ test_tx: QPSK mapping ================\n");
test_groups = [0 0; 0 1; 1 0; 1 1];
expected = [1+1i, 1-1i, -1+1i, -1-1i] / sqrt(2);
mapped = qam_modulate(config, test_groups);
mapping_ok = max(abs(mapped - expected)) < 1e-12;
fprintf("test_tx: QPSK mapping -> %s\n", string(mapping_ok));

%% Pilot check: +-boost values, deterministic, PRBS period 127
fprintf("\n================ test_tx: pilots ================\n");
p1 = generate_pilots(config);
p2 = generate_pilots(config);
pilots_ok = isequal(p1, p2) && all(abs(p1) == config.pilot_boost) && ...
    isequal(p1(1:127), p1(128:254));
fprintf("test_tx: pilots (%d, first 10 signs: %s) -> %s\n", length(p1), ...
    sprintf("%+d", sign(p1(1:10))), string(pilots_ok));

%% Images to test
images = ["cat", "rabbit", "owl", "dog", "fish", "castle"];
n_ok = 0;

for img = images

    fprintf("\n================ test_tx: %s ================\n", img);
    config.payload_img = img;

    % ---- TX ----
    [payload, ~] = get_payload_tx(config);

    % ---- TX: bits -> QAM symbols ----
    bit_groups = split_payload(config, payload.bits);
    data_symbols = qam_modulate(config, bit_groups);

    n_expected = payload.n_ofdm_symbols * config.data_per_symbol;
    qam_ok = length(data_symbols) == n_expected;
    if ~qam_ok
        fprintf("test_tx: QAM produced %d symbols, expected %d\n", ...
            length(data_symbols), n_expected);
    end

    % ---- TX: pilots + resource grid ----
    pilots = generate_pilots(config);
    grid = map_resource_grid(config, data_symbols, pilots);

    % Grid check: size, pilots in every column, data read back in order
    n_sym = payload.n_ofdm_symbols;
    grid_ok = isequal(size(grid), [config.used_subcarriers, n_sym]) && ...
        isequal(grid(config.pilot_idx, :), pilots(:) * ones(1, n_sym));
    rx_data_symbols = reshape(grid(config.data_idx, :), 1, []);
    grid_ok = grid_ok && isequal(rx_data_symbols, data_symbols);
    if ~grid_ok
        fprintf("test_tx: resource grid check FAILED\n");
    end

    % ---- TX: OFDM layer ----
    spectrum = insert_null_subcarriers(config, grid);
    spectrum_os = oversample_spectrum(config, spectrum);
    symbols_t = ofdm_modulate(config, spectrum_os);
    symbols_gi = add_guard_interval(config, symbols_t);

    % ---- TX: preamble + frame ----
    preamble = generate_preamble(config);
    signal = build_frame(config, preamble, symbols_gi);

    % Frame check: column vector, preamble [GI; A; A], data after preamble
    gi = config.gi_samples;
    L = config.ifft_size;
    blk_a = preamble(gi+1 : gi+L);
    blk_b = preamble(gi+L+1 : gi+2*L);
    frame_ok = iscolumn(signal) && ...
        length(signal) == length(preamble) + n_sym * config.ofdm_symbol_samples && ...
        isequal(blk_a, blk_b) && isequal(preamble(1:gi), blk_a(end-gi+1:end));
    if ~frame_ok
        fprintf("test_tx: frame structure check FAILED\n");
    end

    % ---- Loopback OFDM (no channel): cut symbols out of the frame ----
    rx_symbols_gi = reshape(signal(length(preamble)+1:end), ...
        config.ofdm_symbol_samples, n_sym);
    % GI must be a copy of the end of the useful part
    ofdm_ok = frame_ok && isequal(rx_symbols_gi(1:gi, :), rx_symbols_gi(end-gi+1:end, :));
    % remove GI -> FFT -> shift -> used subcarriers
    rx_spectrum = spectrum_shift(fft(rx_symbols_gi(gi+1:end, :)));
    % Out-of-band rows (oversampling zeros + guard bands) must stay ~0
    used_rows = (config.ifft_size - config.fft_size) / 2 + ...
        config.left_zero_subcarriers + (1:config.used_subcarriers);
    rx_grid = rx_spectrum(used_rows, :);
    out_of_band = rx_spectrum;
    out_of_band(used_rows, :) = 0;
    ofdm_err = max(abs(rx_grid(:) - grid(:)));
    ofdm_ok = ofdm_ok && ofdm_err < 1e-9 && max(abs(out_of_band(:))) < 1e-9;
    fprintf("test_tx: OFDM loopback max error %.2e\n", ofdm_err);
    if ~ofdm_ok
        fprintf("test_tx: OFDM loopback FAILED\n");
    end

    % Data symbols read back from the received grid
    rx_data_symbols = reshape(rx_grid(config.data_idx, :), 1, []);

    % ---- Simple QPSK demapper for the test (signs of I and Q) ----
    % (works on symbols recovered by the OFDM loopback)
    rx_groups = [real(rx_data_symbols(:)) < 0, imag(rx_data_symbols(:)) < 0];
    rx_bits = reshape(double(rx_groups).', 1, []);
    qam_ok = qam_ok && isequal(rx_bits, payload.bits);

    % ---- RX (no channel): bits after QAM demapping ----
    payload_rx = payload;
    payload_rx.bits = rx_bits;
    [data, ~] = get_payload_rx(config, payload_rx);

    % ---- Strip trailing char(0) padding (loop instead of find) ----
    rx_image = data.image;
    k = length(rx_image);
    while k > 0 && rx_image(k) == char(config.pad_byte)
        k = k - 1;
    end
    n_pad = length(rx_image) - k;
    rx_image = rx_image(1:k);

    % ---- Compare with the original image ----
    original = get_data(config);
    ok = isequal(rx_image, original.image) && qam_ok && grid_ok && ofdm_ok;
    n_ok = n_ok + ok;

    if ok
        result = "OK";
    else
        result = "FAILED";
    end
    fprintf("test_tx: %-7s OFDM symbols: %d, pad bytes TX: %d, stripped RX: %d -> %s\n", ...
        img, payload.n_ofdm_symbols, payload.pad_bytes, n_pad, result);

end

%% Synchronization check with the RX functions (ADAM) on the last frame
% noise before the frame + frequency shift + AWGN -> detect_frame_start
% and estimate_frequency_offset must find the preamble and the offset.
fprintf("\n================ test_tx: synchronization ================\n");
noise_prefix = 5000;                                   % samples of noise only
subcarrier_spacing = 1 / (config.ifft_size * config.sample_period);
f_shift = 0.3 * subcarrier_spacing;                    % |f| < spacing / 2
snr_db = 20;

rx_signal = [zeros(noise_prefix, 1); signal];
rx_signal = ofdm_addfreqshift(rx_signal, f_shift, config.sample_period);
rx_signal = ofdm_addnoise(rx_signal, snr_db);

[frame_start, corr_vals] = detect_frame_start(config, rx_signal);
ferror = estimate_frequency_offset(config, corr_vals, frame_start);

% The correlation has a plateau of gi_samples+1 positions (GI is cyclic),
% so any start within [prefix+1, prefix+1+gi] is correct
start_ok = frame_start >= noise_prefix + 1 && ...
           frame_start <= noise_prefix + 1 + config.gi_samples;
freq_ok = abs(ferror - f_shift) < 0.02 * subcarrier_spacing;
fprintf("test_tx: frame start %d (expected %d..%d) -> %s\n", frame_start, ...
    noise_prefix + 1, noise_prefix + 1 + config.gi_samples, string(start_ok));
fprintf("test_tx: freq offset %.2f Hz, estimated %.2f Hz (spacing %.2f Hz) -> %s\n", ...
    f_shift, ferror, subcarrier_spacing, string(freq_ok));

%% Summary
fprintf("\n================ test_tx: %d / %d images passed, sync: %s ================\n", ...
    n_ok, length(images), string(start_ok && freq_ok));
