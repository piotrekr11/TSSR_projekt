function plot_spectrum(signal)

figure("Name","Signal Spectrum");
set(gcf, "color", "white");

plot(20*log10(fftshift(abs(fft(signal)))));
grid on;

end