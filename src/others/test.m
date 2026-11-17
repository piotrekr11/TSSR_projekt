%% Test przesylania ASCII art i odtwarzania.

close all; clc; clear;

%% ASCII art jako wektor znakow
kot = [' /\_/\', char(10), ...
       '( o.o )', char(10), ...
       ' > ^ <', char(10)];

disp('=== Oryginalna wiadomosc ===');
fprintf('%s\n', kot);

%% Tekst -> bajty -> bity
bajty = uint8(kot);

bity_macierz = dec2bin(bajty, 8);
bity = reshape((bity_macierz - '0').', 1, []);

fprintf('Liczba bajtow: %d\n', numel(bajty));
fprintf('Liczba bitow: %d\n', numel(bity));

%% Bity -> bajty
bity_8 = reshape(bity, 8, []).';
bajty_odtworzone = uint8(bin2dec(char(bity_8 + '0')));

%% Bajty -> tekst
kot_odtworzony = char(bajty_odtworzone);

disp('=== Odtworzona wiadomosc ===');
fprintf('%s', kot_odtworzony);

%% Porownanie bajt po bajcie
if isequal(bajty(:), bajty_odtworzone(:))
    disp('SUKCES: wszystkie bajty sa identyczne!');
else
    disp('BLAD: bajty sie roznia.');
    disp('Bajty oryginalne:');
    disp(double(bajty));
    disp('Bajty odtworzone:');
    disp(double(bajty_odtworzone));
end
