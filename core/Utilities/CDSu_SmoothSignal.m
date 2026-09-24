%{
PURPOSE
    Apply a low pass filter on a signal

EXAMPLE
    % Filter a unit step
    t = 0 : 0.01 : 20;
    x = zeros(size(t));
    x(floor(length(x)/2):end) = 1;
    y = CDSu_SmoothSignal.LowPass(t, x, 1);
%}

classdef CDSu_SmoothSignal
methods (Static)
    % Matlab's inbuilt low pass filter has extremely noisy derivatives
    % If my signal is position, then the velocity and acceleration would be bad
    % My filter adds a lot of lag into the signal, but the derivatives are smooth and reasonably small in value
    function signal_filtered = LowPass(time, signal, maxFrequency)
        arguments
            time double {mustBeVector}
            signal double {mustBeVector}
            maxFrequency(1,1) double {mustBePositive} = 1
        end
        % Sample rate [Hz]
        Fs = 1/(time(2)-time(1));

        % Validate constant sample rate
        tmp = diff(time);
        if max(tmp(1)-tmp) > 10*eps*time(end); error("Bad input: Time must be sampled at a constant rate"); end

        % Validate minimum required sample rate
        % Warn at less than 2 * Nyquist frequency
        if Fs < 4*maxFrequency; warning("Bad input: Can not achieve requested frequency. Increase sample rate of time"); end

        % Create a Gaussian window
        %   This method produces a smoother output (especially for the 2nd derivative) than the inbuilt gausswin()
        %   The window is created by convolving a box window with itself repeatedly
        %   After infinite repeats, this would converge on the normal distribution
        %   About 10 repeats seems good though
        % The magic number 4 is from testing and inspecting the FFT
        windowSizeFinal_request = 4*Fs/maxFrequency;
        nConvolutions = 10;
        windowSizeInitial = ceil((windowSizeFinal_request + nConvolutions - 1)/nConvolutions);
        w_initial = (1/windowSizeInitial)*ones(1,windowSizeInitial);
        w = w_initial;
        for idx = 1 : nConvolutions-1
            w = conv(w,w_initial);
        end

        signal_filtered = filter(w,1, signal);

        % Plot for testing
        %CDSu_SmoothSignal.PlotSignalAndFFT(time, signal, signal_filtered, maxFrequency)
    end

    % Plots for testing the correct functioning of LowPass()
    function PlotSignalAndFFT(time, signal, signal_filtered, maxFrequency)
        arguments
            time double {mustBeVector}
            signal double {mustBeVector}
            signal_filtered {mustBeA(signal_filtered,["double","struct"])}
            maxFrequency(1,1) double {mustBePositive} = NaN
        end
        % Sample rate [Hz]
        Fs = 1/(time(2)-time(1));

        % Validate constant sample rate
        tmp = diff(time);
        if max(tmp(1)-tmp) > 10*eps*time(end); error("Bad input: Time must be sampled at a constant rate"); end

        if isa(signal_filtered,"struct") % The input is a spline
            pp = signal_filtered;
        else
            pp = spline(time,signal_filtered);
        end
        x_spline = ppval(pp,time);
        x_spline_d = ppval(fnder(pp), time);
        x_spline_dd = ppval(fnder(pp,2), time);

        % Plot signal and derivatives
        figure;
        tiledlayout("vertical");
        nexttile; plot(time,signal, time,x_spline)
        grid on
        ylabel("Signal")
        legend(["original","filtered"], "location","best")

        nexttile; plot(time,x_spline, time,x_spline_d, time,x_spline_dd)
        ylabel("Filtered signal")
        legend(["signal","1st derivative","2nd derivative"], "location","best")
        grid on;

        % Plot FFT
        L = length(time);
        n = 2^nextpow2(L);
        Y = fft(x_spline,n);
        Y = abs(Y/L);
        Y = 2*Y(1:n/2+1);
        f = Fs*(0:(n/2))/n;
        nexttile; plot(f,Y)
        xlabel("f (Hz)")
        ylabel("fft of zero-padded signal")
        grid on;
        if ~isnan(maxFrequency)
            xlim([0,maxFrequency*2])
            hold on
            xline(maxFrequency)
            hold off
        end
    end

    % Same as this.LowPass()
    % OUTPUT
    %   A spline that was fit by the inbuilt function spline()
    function out = LowPass_PP(time, varargin)
        signal = CDSu_SmoothSignal.LowPass(time, varargin{:});
        out = spline(time, signal);
    end
end
end
