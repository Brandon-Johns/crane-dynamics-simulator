%{
Superclass of Integration tests

%}
classdef IntegrationTest
methods(Abstract)
    Description()
    Run()
end
methods
    function RunVerbose(this, varargin)
        fprintf("(TEST) " + class(this) +"\n")
        fprintf("(TEST) " + this.Description +"\n")
        if length(varargin) >= 1
            fprintf("(TEST) solverArgs = " + strjoin([varargin{1}{:}], ",")+"\n")
        end
        this.Run(varargin{:});
        fprintf("(TEST) Run Complete\n\n")
    end
end
methods(Static)
    function AssertTol(val, val_true, tol)
        IntegrationTest.AssertClass(val,val_true);
        IntegrationTest.AssertSize(val,val_true);
        maxError = max(abs(val - val_true), [], "all");
        if maxError > tol
            IntegrationTest.DisplayIfSmall(val,val_true);
            IntegrationTest.AssignInBase(val, val_true);
            error("Tolerance exceeded:\n tol       = %g\n max error = %g",tol,maxError);
        end
    end

    function AssertTol_zeros(val, validateTol)
        IntegrationTest.AssertTol(val, zeros(size(val), class(val)), validateTol);
    end

    function AssertZeros(val)
        if ~all(val == 0, 'all')
            numNotSame = nnz(val);
            IntegrationTest.DisplayIfSmall(val);
            IntegrationTest.AssignInBase(val);
            error("Assert Equal:\n Num elements not same: "+numNotSame+"\n Num elements (total) : "+numel(val), [])
        end
    end

    function AssertEqual(val, val_true)
        IntegrationTest.AssertClass(val,val_true);
        IntegrationTest.AssertSize(val,val_true);
        if ~all(val == val_true, 'all')
            numNotSame = sum(val ~= val_true, 'all');
            IntegrationTest.DisplayIfSmall(val,val_true);
            IntegrationTest.AssignInBase(val, val_true);
            error("Assert Equal:\n Num elements not same: "+numNotSame+"\n Num elements (total) : "+numel(val), [])
        end
    end

    % Errors can pass though when there are duplicate elements: [1,3,3] compared with [1,1,3]
    % But it's good enough, so whatever
    function AssertEqual_unordered(val, val_true)
        IntegrationTest.AssertClass(val,val_true);
        IntegrationTest.AssertSize(val,val_true);
        if ~ ( all(contains(val, val_true), 'all') && all(contains(val_true, val), 'all') )
            IntegrationTest.DisplayIfSmall(val,val_true);
            IntegrationTest.AssignInBase(val, val_true);
            error("Assert Equal (unordered): Not equal")
        end
    end

    function out = OutputMayContainLambdaD(solverArgs)
        args = [solverArgs{:}];
        case1 = any(contains(args, ["ode15i","fullyImplicit"]));
        case2 = any(contains(args, ["ode15s","ode23t","ode23s"])) && any(contains(args, "massMatrix"));
        out = case1 || case2;
    end

    % Mostly used to compose more holistic tests
    function AssertSize(val,val_true)
        if ~all(size(val)==size(val_true))
            sizeVal  = strjoin(string(size(val)),",");
            sizeTrue = strjoin(string(size(val_true)),",");
            IntegrationTest.DisplayIfSmall(val,val_true);
            IntegrationTest.AssignInBase(val, val_true);
            error("Assert Size:\n Should be: ["+sizeTrue+"]\n Is       : ["+sizeVal+"]", [])
        end
    end

    % Mostly used to compose more holistic tests
    function AssertClass(val,val_true)
        if string(class(val))~=string(class(val_true))
            IntegrationTest.DisplayIfSmall(val,val_true);
            IntegrationTest.AssignInBase(val, val_true);
            error("Assert Class:\n Should be: "+string(class(val_true))+"\n Is       : "+string(class(val)), [])
        end
    end
end
methods (Static, Access=private)
    % Internal utility functions

    function AssignInBase(val, val_true)
        arguments
            val
            val_true = "NOT SPECIFIED" % I want to explicitly overwrite or clear the previous value. This seems good enough
        end
        assignin('base','ASSERTION_val',  val);
        assignin('base','ASSERTION_true', val_true);
    end

    function DisplayIfSmall(varargin)
        if ~any(nargin==[1,2]); error("Test not working"); end

        val = varargin{1};
        if nargin==1 && numel(val)<50
            disp(val)
            return
        end

        val_true = varargin{2};
        isSameSize = all(size(val)==size(val_true));
        if numel(val)<50 && numel(val_true)<50
            fprintf("\n\nVALUES FAILING ASSERTION:\n\n")
            if isSameSize && isrow(val)
                disp([val_true; val])
            elseif isSameSize && iscolumn(val)
                disp([val_true, val])
            else
                disp(val)
                disp(val_true)
            end
        end
    end
end
end
