%% Wlasna kopia czesci nadawczej z wykladu 03/11/2026 (KAMIL)
% Zrodlo: src/others/wyklad.m  (ORYGINALU NIE EDYTOWAC)
%
% Zmiany wzgledem wyklad.m:
%   - stale nazwane zamiast "magicznych liczb" (1024, 1.5*fft_size, 101...)
%   - jednakowa dlugosc GI dla symbolu pilotowego i danych
%     (w wykladzie linia 55: end-fft_size-1 -> 1026 probek zamiast 1024)
%   - dopelnienie zerami przy nadprobkowaniu liczone z ups,
%     a nie na sztywno 1.5*fft_size
%   - nieuzywana stala GI = 4 zastapiona gi_len (w probkach)
%   - recznie zrobione przesuniecie widma (fftshift nie jest na liscie
%     dozwolonych funkcji)
%   - sygnal wyjsciowy jako wektor kolumnowy (tego oczekuja funkcje kanalu
%     i odbiornik)
%   - sekcja kontrolna "loopback": FFT po stronie odbiorczej bez kanalu,
%     h liczone tylko na podnosnych niezerowych (w wykladzie linia 126
%     dzielila 823 probki przez 4096-elementowe p)
%
% UWAGA: symbol zlozony z samych pilotow to tylko demo z wykladu.
% Zadanie projektowe wymaga pilotow rozproszonych (z interpolacja).
clc; close all; clear all;

show_plots = true;

%% Constants
fprintf("[wyklad_tx] started\n");
% Transmitted constellation (QPSK)
K = [1+1i, 1-1i, -1+1i, -1-1i];
% FFT size (number of subcarriers before oversampling)
fft_size = 1024;
% Elementary period (as in the lecture)
tel = 1000/1024 * 1e-6;
% Oversampling
ups = 4;
% IFFT size after oversampling
ifft_size = ups * fft_size;
% Guard interval length in samples (after oversampling) - lecture: 1024
gi_len = fft_size;
% Zero subcarriers (frequency guard bands)
l_zeros = 101;
r_zeros = 100;
non_zero = fft_size - l_zeros - r_zeros;
% Zeros added on each side when oversampling
os_pad = (ifft_size - fft_size) / 2;

fprintf("[wyklad_tx] fft_size=%d, ups=%d, ifft_size=%d, gi_len=%d, used=%d\n", ...
    fft_size, ups, ifft_size, gi_len, non_zero);

%% Data symbols (random test data - later replaced by the payload)
fprintf("[wyklad_tx] generating %d QPSK data symbols\n", non_zero);
d = K(randi(length(K), 1, non_zero));
if show_plots, figure(); plot(d, 'o'); title('Data constellation'); grid on; end

%% Pilot symbols (whole symbol of BPSK pilots - lecture demo only)
fprintf("[wyklad_tx] generating %d pilot symbols\n", non_zero);
p_used = 2 * sign(randn(1, non_zero));

%% OFDM modulation of both symbols
sym_d = ofdm_symbol_local(d,      l_zeros, r_zeros, os_pad, gi_len);
sym_p = ofdm_symbol_local(p_used, l_zeros, r_zeros, os_pad, gi_len);

%% Frame: pilot symbol + data symbol (column vector)
tx = [sym_p, sym_d].';
fprintf("[wyklad_tx] frame length: %d samples (%d per symbol)\n", ...
    length(tx), ifft_size + gi_len);

if show_plots
    figure();
    plot(20*log10(abs(shift_local(fft(tx.')))));
    title('TX spectrum'); grid on;
end

%% ========================================================================
% Loopback check (no channel) - simplified receiver from the lecture
% =========================================================================
fprintf("[wyklad_tx] loopback check started\n");
rx = tx.';
sym_len = ifft_size + gi_len;

% drop GI of each symbol
rx_p = rx(gi_len+1 : sym_len);
rx_d = rx(sym_len+gi_len+1 : 2*sym_len);

% FFT + shift back
rx_p = shift_local(fft(rx_p));
rx_d = shift_local(fft(rx_d));

% keep only used subcarriers
used_idx = os_pad + l_zeros + (1:non_zero);
rx_p = rx_p(used_idx);
rx_d = rx_d(used_idx);

% channel estimate from pilots and equalization
h = rx_p ./ p_used;
u = rx_d ./ h;

err = max(abs(u - d));
fprintf("[wyklad_tx] loopback max |u - d| = %.3e\n", err);
if err < 1e-9
    fprintf("[wyklad_tx] loopback OK\n");
else
    fprintf("[wyklad_tx] loopback FAILED\n");
end
if show_plots, figure(); plot(u, 'o'); title('Equalized symbols (loopback)'); grid on; end

fprintf("[wyklad_tx] finished\n");

%% ========================================================================
% Local helper functions
% =========================================================================
function sym = ofdm_symbol_local(q, l_zeros, r_zeros, os_pad, gi_len)
    % zero subcarriers -> oversampling -> shift -> IFFT -> GI
    q = [zeros(1, l_zeros), q, zeros(1, r_zeros)];
    q = [zeros(1, os_pad), q, zeros(1, os_pad)];
    q = shift_local(q);
    sym = ifft(q);
    sym = [sym(end-gi_len+1:end), sym];
end

function y = shift_local(x)
    % swap halves of an even-length vector (fftshift == ifftshift here)
    n = length(x);
    y = [x(n/2+1:end), x(1:n/2)];
end
