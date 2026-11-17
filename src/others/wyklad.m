%% Wyklad 03/11/2026
clc; close all; clear all;

%% Constants
% Transmited sequence
K = [1+1i, 1-1i, -1+1i, -1-1i];
% FFT size
fft_size = 1024;
%
tel = 1000/1024 * 1e-6;
% Guard Interval
GI = 4;
% Oversampling
ups = 4;
% Subcarriers
l_zeros = 101;
r_zeros = 100;
non_zero = fft_size - l_zeros - r_zeros;

%%
q = K(randi(length(K), 1, non_zero));
figure();
plot(q,'o');

%% Before going into FFT - add zeros
q = [zeros(1,l_zeros), q, zeros(1,r_zeros)];
figure();
plot(q,'o');
figure();
plot(abs(q));

%% Upsampling
q = [zeros(1,1.5*fft_size), q, zeros(1,1.5*fft_size)];
figure();
plot(abs(q));

%% Shifting
q = [q(length(q)/2 + 1:end), q(1:length(q)/2)];
plot(abs(q))

%% IFFT
sym = ifft(q);

%% Guard Interval
sym = [sym(end-1023:end), sym];

%% Pilots
p = 2 * sign(randn(1, non_zero));
p = [zeros(1, l_zeros), p, zeros(1, r_zeros)];
p = [zeros(1, 1.5 * fft_size), p, zeros(1, 1.5 * fft_size)];

p = [p(length(p)/2+1:end),p(1:length(p)/2)];

sym_p = ifft(p);
sym_p = [sym_p(end-fft_size-1:end), sym_p];
tx = [sym_p, sym];

%%
figure();
plot(20*log10(fftshift(abs(fft(tx)))));
grid on;

%% Channel
% tx_c = ofdm_wbchannel(tx, [100e-6, 110e-6], [1*exp(1i*pi/7), 0.3*exp(1i*pi/42)], tel/4);
% tx_c = ofdm_addfreqshift(tx_c, 200, tel/4);
% figure();
% plot(20*log10(fftshift(abs(fft(tx_c)))));
% grid on;

%%
% dt = tel/4;
% Tobs = length(tx_c)*dt;
% df = 1/Tobs;
% B = 1/dt;
% ff = -B/2 : df : B/2-df;
%
% figure();
% plot(ff/1e6, 20*log10(fftshift(abs(fft(tx_c)))));
% grid on;

%% receiver

% cc = ofdm_moving_segment_correlation(tx_c, fft_size, fft_size * 4);
%
% figure()
% plot(abs(cc));

% [~, II] = max(cc);
% %% argument z piku
% ksi = angle(cc(ii));
% %% synchronizacja czestotliwosci slajd
% ferror = ksi/2/pi/(1024*tel);
%
% fvec = exp(-1i * 2 * pi * ferror * tel/4 * (0:length(tx_c)-1)).';
% tx_c  = tx_c.*fvec;

%% czesci uzyteczne symboli - odrzucenie GI i opoznien
%odrzucenie opoznienia
% tx_c = tx_c(II:end);
% odrzucenie GI
tx_c = tx(1025:end);
%
tx_sym_p = tx_c(1:4*1024);
tx_c = tx_c(4*1024+1:end);
% odrzucenie drugiego GI
tx_c = tx_c(1025:end);
tx_sym_d = tx_c(1:4*1024);

tx_sym_p = fftshift(fft(tx_sym_p));
tx_sym_d = fftshift(fft(tx_sym_d));

figure();
plot(tx_sym_d,'o');
figure();
plot(abs(tx_sym_d),'o');

%
tx_sym_p = tx_sym_p(1.5*fft_size+101+1:end);
tx_sym_p = tx_sym_p(1:823).';

%
tx_sym_d = tx_sym_d(1.5*fft_size+101+1:end);
tx_sym_d = tx_sym_d(1:823).';

% known pilot -> unknown symbol. Works for a stationary channel
h = tx_sym_p./p;
u = tx_sym_d./h;