function [x, y] = f_dynamic_plot(app, method)
%F_DYNAMIC_PLOT Continuously update axes
%   Uses mothod to determine modulate / demodulate
switch lower(method)
    case 'modulate'
        [x, y] = f_modulate(app);
    case 'demodulate'
        % [x, y] = f_demodulate(app);
    otherwise
        x = 0;
        y = 0;
end

