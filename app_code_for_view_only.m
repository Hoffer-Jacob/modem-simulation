classdef app1 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                      matlab.ui.Figure
        UIAxes                        matlab.ui.control.UIAxes
        ModeButtonGroup               matlab.ui.container.ButtonGroup
        AMButton                      matlab.ui.control.RadioButton
        FMButton                      matlab.ui.control.RadioButton
        FilePathEditFieldLabel        matlab.ui.control.Label
        FilePathEditField             matlab.ui.control.EditField
        MessageButtonGroup            matlab.ui.container.ButtonGroup
        HarmonicButton_2              matlab.ui.control.RadioButton
        FileButton                    matlab.ui.control.RadioButton
        HarmonickHzEditFieldLabel     matlab.ui.control.Label
        HarmonickHzEditField          matlab.ui.control.NumericEditField
        ModulationandDemodulationSimulationLabel  matlab.ui.control.Label
        CarrierkHzEditFieldLabel      matlab.ui.control.Label
        CarrierkHzEditField           matlab.ui.control.NumericEditField
        UIAxes_2                      matlab.ui.control.UIAxes
        MessagePeriodsEditFieldLabel  matlab.ui.control.Label
        MessagePeriodsEditField       matlab.ui.control.NumericEditField
        bAMEditFieldLabel             matlab.ui.control.Label
        bAMEditField                  matlab.ui.control.NumericEditField
        SNREditFieldLabel             matlab.ui.control.Label
        SNREditField                  matlab.ui.control.NumericEditField
        UIAxes2                       matlab.ui.control.UIAxes
    end

    
    properties (Access = public)
        time;
        message;
        modulated_signal;
        received_signal;
        demodulated_signal;
    end
    
    methods (Access = private)
        
        function f_modulate(app)
            
            %% Variables
            f_c = app.CarrierkHzEditField.Value*1e3;
            f_m = app.HarmonickHzEditField.Value*1e3;
            
            T_m = 1 / f_m;
            t_end = app.MessagePeriodsEditField.Value * T_m;
            t_step = T_m / 1000;
            app.time = 0:t_step:t_end;
            
            v_c = 1;
            
            if app.AMButton.Value
                
                v_m = v_c * app.bAMEditField.Value;
                
                app.message = app.bAMEditField.Value * cos(2 * pi * f_m .* app.time);
                
                %% Components
                carrier = v_c * cos(2 * pi * f_c .* app.time);
                lower_sideband = (v_m / 2) * cos(2 * pi * (f_c - f_m) .* app.time);
                upper_sideband = (v_m / 2) * cos(2 * pi * (f_c + f_m) .* app.time);
                
                %% Modulated Signal
                app.modulated_signal = carrier + lower_sideband + upper_sideband;
                
            elseif app.FMButton.Value
                v_m = 1;
                app.message = v_m * cos(2 * pi * f_m .* app.time);
                app.modulated_signal = v_c .* cos(2*pi*f_c.*app.time + ...
                    app.bAMEditField.Value .* sin(2*pi*f_m.*app.time));
            end
        end
        
        function f_demodulate(app)
            
            if app.AMButton.Value
                app.demodulated_signal = envelope(app.received_signal);
            elseif app.FMButton.Value
%% Source:                
%https://www.gaussianwaves.com/2017/06/phase-demodulation-using-hilbert-tra
%nsform-application-of-analytic-signal/
    
                %% Demodulation of the noisy Phase Modulated signal
                % form the analytical signal from the received vector
                z = hilbert(app.received_signal);
                % instaneous phase
                inst_phase = unwrap(angle(z));
                
                p = polyfit(app.time, inst_phase, 1); %linearly fit the instaneous phase
                estimated = polyval(p, app.time); %re-evaluate the offset term using the fitted values
                offsetTerm = estimated;
                
                app.demodulated_signal = inst_phase - offsetTerm;
                
                app.demodulated_signal = app.demodulated_signal ...
                    / max(abs(app.demodulated_signal));
                
            end
        end
        
        function f_noise(app)
            app.received_signal = awgn(app.modulated_signal, ...
                app.SNREditField.Value);
        end
        
        function main(app)
            f_modulate(app);
            f_noise(app);
            f_demodulate(app);
            f_plot(app);
        end
        
        function f_plot(app)
            %% Message
            app.UIAxes.cla;
            hold(app.UIAxes, 'on');
            grid(app.UIAxes, 'on');

            plot(app.UIAxes, app.time .* 1e6, app.message);
            
            %% Received Signal
            app.UIAxes2.cla;
            hold(app.UIAxes2, 'on');
            grid(app.UIAxes2, 'on');
            plot(app.UIAxes2, app.time .* 1e6, app.received_signal);            
            
            %% Demodulated Signal
            app.UIAxes_2.cla;
            hold(app.UIAxes_2, 'on');
            grid(app.UIAxes_2, 'on');
            plot(app.UIAxes_2, app.time .* 1e6, app.demodulated_signal);
            
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            main(app);
        end

        % Selection changed function: MessageButtonGroup, 
        % ModeButtonGroup
        function radio_message_callback(app, event)
            if app.AMButton.Value
                app.bAMEditFieldLabel.Text = 'bAM';
            elseif app.FMButton.Value
                app.bAMEditFieldLabel.Text = 'bFM';
            end
            
            app.HarmonickHzEditField.Enable = app.HarmonicButton_2.Value;
            app.MessagePeriodsEditField.Enable = app.HarmonicButton_2.Value;
            app.FilePathEditField.Enable = app.FileButton.Value;
            
            main(app);
        end

        % Value changed function: CarrierkHzEditField, 
        % HarmonickHzEditField, MessagePeriodsEditField, 
        % bAMEditField
        function CarrierkHzEditFieldValueChanged(app, event)
            main(app);
        end

        % Value changed function: SNREditField
        function SNREditFieldValueChanged(app, event)
            f_noise(app);
            f_demodulate(app);
            f_plot(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1020 920];
            app.UIFigure.Name = 'UI Figure';

            % Create UIAxes
            app.UIAxes = uiaxes(app.UIFigure);
            title(app.UIAxes, 'Message')
            xlabel(app.UIAxes, 'Time (us)')
            ylabel(app.UIAxes, 'm(t)')
            app.UIAxes.Tag = 'axes_modulated';
            app.UIAxes.Position = [300 620 700 250];

            % Create ModeButtonGroup
            app.ModeButtonGroup = uibuttongroup(app.UIFigure);
            app.ModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @radio_message_callback, true);
            app.ModeButtonGroup.Title = 'Mode';
            app.ModeButtonGroup.Tag = 'radio_mode';
            app.ModeButtonGroup.Position = [20 720 100 80];

            % Create AMButton
            app.AMButton = uiradiobutton(app.ModeButtonGroup);
            app.AMButton.Text = 'AM';
            app.AMButton.Position = [11 30 58 22];
            app.AMButton.Value = true;

            % Create FMButton
            app.FMButton = uiradiobutton(app.ModeButtonGroup);
            app.FMButton.Text = 'FM';
            app.FMButton.Position = [11 8 65 22];

            % Create FilePathEditFieldLabel
            app.FilePathEditFieldLabel = uilabel(app.UIFigure);
            app.FilePathEditFieldLabel.HorizontalAlignment = 'right';
            app.FilePathEditFieldLabel.Position = [20 680 85 20];
            app.FilePathEditFieldLabel.Text = 'File Path';

            % Create FilePathEditField
            app.FilePathEditField = uieditfield(app.UIFigure, 'text');
            app.FilePathEditField.Tag = 'edit_file_path';
            app.FilePathEditField.Enable = 'off';
            app.FilePathEditField.Position = [120 680 120 20];

            % Create MessageButtonGroup
            app.MessageButtonGroup = uibuttongroup(app.UIFigure);
            app.MessageButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @radio_message_callback, true);
            app.MessageButtonGroup.Title = 'Message';
            app.MessageButtonGroup.Tag = 'radio_message';
            app.MessageButtonGroup.Position = [140 720 100 80];

            % Create HarmonicButton_2
            app.HarmonicButton_2 = uiradiobutton(app.MessageButtonGroup);
            app.HarmonicButton_2.Text = 'Harmonic';
            app.HarmonicButton_2.Position = [11 29 73 22];
            app.HarmonicButton_2.Value = true;

            % Create FileButton
            app.FileButton = uiradiobutton(app.MessageButtonGroup);
            app.FileButton.Text = 'File';
            app.FileButton.Position = [11 7 41 22];

            % Create HarmonickHzEditFieldLabel
            app.HarmonickHzEditFieldLabel = uilabel(app.UIFigure);
            app.HarmonickHzEditFieldLabel.HorizontalAlignment = 'right';
            app.HarmonickHzEditFieldLabel.Position = [20 640 85 20];
            app.HarmonickHzEditFieldLabel.Text = 'Harmonic (kHz)';

            % Create HarmonickHzEditField
            app.HarmonickHzEditField = uieditfield(app.UIFigure, 'numeric');
            app.HarmonickHzEditField.ValueChangedFcn = createCallbackFcn(app, @CarrierkHzEditFieldValueChanged, true);
            app.HarmonickHzEditField.Tag = 'edit_harmonic';
            app.HarmonickHzEditField.Position = [120 640 120 20];
            app.HarmonickHzEditField.Value = 20;

            % Create ModulationandDemodulationSimulationLabel
            app.ModulationandDemodulationSimulationLabel = uilabel(app.UIFigure);
            app.ModulationandDemodulationSimulationLabel.HorizontalAlignment = 'center';
            app.ModulationandDemodulationSimulationLabel.FontSize = 18;
            app.ModulationandDemodulationSimulationLabel.FontWeight = 'bold';
            app.ModulationandDemodulationSimulationLabel.Position = [0 870 300 40];
            app.ModulationandDemodulationSimulationLabel.Text = {'Modulation and Demodulation '; 'Simulation'};

            % Create CarrierkHzEditFieldLabel
            app.CarrierkHzEditFieldLabel = uilabel(app.UIFigure);
            app.CarrierkHzEditFieldLabel.HorizontalAlignment = 'right';
            app.CarrierkHzEditFieldLabel.Position = [20 600 85 20];
            app.CarrierkHzEditFieldLabel.Text = 'Carrier (kHz)';

            % Create CarrierkHzEditField
            app.CarrierkHzEditField = uieditfield(app.UIFigure, 'numeric');
            app.CarrierkHzEditField.ValueChangedFcn = createCallbackFcn(app, @CarrierkHzEditFieldValueChanged, true);
            app.CarrierkHzEditField.Tag = 'edit_carrier';
            app.CarrierkHzEditField.Position = [120 600 120 20];
            app.CarrierkHzEditField.Value = 300;

            % Create UIAxes_2
            app.UIAxes_2 = uiaxes(app.UIFigure);
            title(app.UIAxes_2, 'Demodulated Signal')
            xlabel(app.UIAxes_2, 'Time (us)')
            ylabel(app.UIAxes_2, 'd(t)')
            app.UIAxes_2.Tag = 'axes_demodulated';
            app.UIAxes_2.Position = [300 20 700 250];

            % Create MessagePeriodsEditFieldLabel
            app.MessagePeriodsEditFieldLabel = uilabel(app.UIFigure);
            app.MessagePeriodsEditFieldLabel.HorizontalAlignment = 'right';
            app.MessagePeriodsEditFieldLabel.Position = [7 558 98 22];
            app.MessagePeriodsEditFieldLabel.Text = 'Message Periods';

            % Create MessagePeriodsEditField
            app.MessagePeriodsEditField = uieditfield(app.UIFigure, 'numeric');
            app.MessagePeriodsEditField.ValueChangedFcn = createCallbackFcn(app, @CarrierkHzEditFieldValueChanged, true);
            app.MessagePeriodsEditField.Tag = 'edit_carrier';
            app.MessagePeriodsEditField.Position = [120 560 120 20];
            app.MessagePeriodsEditField.Value = 2;

            % Create bAMEditFieldLabel
            app.bAMEditFieldLabel = uilabel(app.UIFigure);
            app.bAMEditFieldLabel.HorizontalAlignment = 'right';
            app.bAMEditFieldLabel.Position = [20 520 85 20];
            app.bAMEditFieldLabel.Text = 'bAM';

            % Create bAMEditField
            app.bAMEditField = uieditfield(app.UIFigure, 'numeric');
            app.bAMEditField.ValueChangedFcn = createCallbackFcn(app, @CarrierkHzEditFieldValueChanged, true);
            app.bAMEditField.Tag = 'edit_carrier';
            app.bAMEditField.Position = [120 520 120 20];
            app.bAMEditField.Value = 1;

            % Create SNREditFieldLabel
            app.SNREditFieldLabel = uilabel(app.UIFigure);
            app.SNREditFieldLabel.HorizontalAlignment = 'right';
            app.SNREditFieldLabel.Position = [20 480 85 20];
            app.SNREditFieldLabel.Text = 'SNR';

            % Create SNREditField
            app.SNREditField = uieditfield(app.UIFigure, 'numeric');
            app.SNREditField.ValueChangedFcn = createCallbackFcn(app, @SNREditFieldValueChanged, true);
            app.SNREditField.Tag = 'edit_carrier';
            app.SNREditField.Position = [120 480 120 20];
            app.SNREditField.Value = 20;

            % Create UIAxes2
            app.UIAxes2 = uiaxes(app.UIFigure);
            title(app.UIAxes2, 'Received Signal')
            xlabel(app.UIAxes2, 'Time (us)')
            ylabel(app.UIAxes2, 's(t)')
            app.UIAxes2.Position = [300 320 700 250];

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end