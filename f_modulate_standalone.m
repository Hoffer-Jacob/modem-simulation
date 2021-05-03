function [mod_sig, t] = f_modulate_standalone(f_c, f_m, v_c, v_m)
%F_MODULATE Modulate an AM signal with lower, carrier, and upper components
%   Inputs
%       f_c: carrier frequency
%       f_m: message (harmonic) frequency
%       v_c: carrier signal amplitude
%       v_m: message amplitude
%   Outputs:
%       mod_sig: modulated signal
%       t:       time

%% Variables
t = (0:0.1:1500) * 1e-6;

%% Components
carrier = v_c * cos(2 * pi * f_c .* t);
lower_sideband = (v_m / 2) * cos(2 * pi * (f_c - f_m) .* t);
upper_sideband = (v_m / 2) * cos(2 * pi * (f_c + f_m) .* t);

%% Modulated Signal
mod_sig = carrier + lower_sideband + upper_sideband;
end

