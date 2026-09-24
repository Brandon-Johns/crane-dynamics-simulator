%{
PURPOSE
    Generate a smooth pseudorandom signals to use as inputs for testing

EXAMPLE
    % Create an input driven by a random signal with a maximum rate of 3Hz
    t = 0 : 0.01 : 20;
    RandSignal = CDSu_RandSignal;
    sys = CDS_SystemDescription();
    params = sys.params;
    params.Create('input', 'F').SetSpline( RandSignal.GenerateSignal_PP(t, 3) );
%}

classdef CDSu_RandSignal
properties
    % Random number generator
    randStream = RandStream("mt19937ar","Seed","shuffle");

    % Setting this causes the random sequence to start from the beginning for every newly generated signal
    alwaysResetRandStream(1,1) logical = false;
end
methods
    % Make output deterministic
    function this = SetRandSeed(this, in)
        arguments
            this(1,1)
            in = 0
        end
        this.randStream = RandStream("mt19937ar","Seed",in);
    end

    % Force the random sequence to start from the beginning for every newly generated signal
    function this = AlwaysResetStream(this)
        this.alwaysResetRandStream = true;
    end

    % Generate a smooth pseudorandom signal with a maximum frequency no higher than specified
    % INPUT
    %   time:
    %       vector of time coordinates that bounds the solution time domain
    %       The specific time coordinates do not have to match the solution time coordinates
    %       The sample rate should be ~8 times greater than the input 'maxFrequency'
    %       The sample rate must be constant
    %   maxFrequency:
    %       The frequencies contained in the generated signal will be roughly between 0 and this value
    % OUTPUT
    %   The signal at the time coordinates of the input 'time'
    function signal = GenerateSignal(this, time, maxFrequency, amplitude)
        arguments
            this(1,1)
            time double {mustBeVector}
            maxFrequency(1,1) double {mustBePositive} = 1
            amplitude(1,1) double {mustBePositive} = 1
        end
        if this.alwaysResetRandStream
            reset(this.randStream);
        end

        % Filter some Gaussian noise with the Gaussian window
        % Why Gaussian?- Because I tested it, and it gives nice results. No special reason
        % The magic number 3 is from testing and inspecting the signal
        noise = amplitude*3*randn(this.randStream, size(time));
        signal = CDSu_SmoothSignal.LowPass(time, noise, maxFrequency);

        % Plot for testing
        %CDSu_SmoothSignal.PlotSignalAndFFT(time, noise, signal, maxFrequency)
    end

    % Same as this.GenerateSignal()
    % OUTPUT
    %   A spline that was fit by the inbuilt function spline()
    function out = GenerateSignal_PP(this, time, varargin)
        signal = this.GenerateSignal(time, varargin{:});
        out = spline(time, signal);
    end
end
end
