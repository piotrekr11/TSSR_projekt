Readme!

## Function Development Guidelines

Każda funkcja w projekcie powinna spełniać następujące wytyczne:

1. **Function Header** – każda funkcja musi posiadać nagłówek zawierający:
   - Creation date – data utworzenia.
   - Last modified – data ostatniej modyfikacji.
   - Author – autor.
   - Function name – nazwa funkcji.
   - Description – krótki opis działania funkcji.

2. **Input Validation** – należy sprawdzać:
   - Czy wszystkie wymagane argumenty wejściowe zostały przekazane.
   - Czy dane wejściowe mają oczekiwany format, typ i wymiary.
   - Czy wartości mieszczą się w oczekiwanym zakresie.
   - W razie potrzeby należy jawnie dostosować format danych (np. `vec = vec(:);`) i dodać komentarz informujący o wykonanym przekształceniu.

3. **Output Validation** – należy upewnić się, że funkcja zwraca dane w oczekiwanym formacie, o odpowiednich wymiarach i typie.

4. **Debug Messages** – każda funkcja powinna wyświetlać komunikaty informujące o:
   - Rozpoczęciu wykonywania funkcji.
   - Istotnych operacjach lub przekształceniach danych.
   - Zakończeniu wykonywania funkcji.
   - Wykrytych błędach lub nieprawidłowych danych wejściowych.

5. **Code Readability** – kod powinien być czytelny, podzielony na logiczne sekcje i opatrzony komentarzami tam, gdzie działanie nie jest oczywiste.

### Function Header Template

```matlab
% =========================================================================
% Function name: function_name
% Author: Name
% Creation date: YYYY-MM-DD
% Last modified: YYYY-MM-DD
%
% Description:
% Short description of the function's purpose.
%
% Inputs:
%   input1 - description, expected format and dimensions
%
% Outputs:
%   output1 - description, expected format and dimensions
%
% Notes:
%   Additional information about assumptions or data transformations.
% =========================================================================