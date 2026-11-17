% =========================================================================
% Function: display_payload
% Responsible person: ADAM
%
% Inputs:
%   data - Structure containing the reconstructed ASCII image
%
% Outputs:
%   None - Displays the reconstructed ASCII art in the MATLAB console
%
% Description:
%   Displays the reconstructed ASCII image stored in data.image.
% =========================================================================


function display_payload(data)

    fprintf("    (f) display_payload: started\n");

    fprintf("\nReconstructed ASCII art:\n\n");
    fprintf('%s\n', data.image);

    fprintf("\n    (f) display_payload: finished successfully\n");

end
