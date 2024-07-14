%{
Superclass of Integration tests

%}
classdef IntegrationTest
methods(Abstract)
    Description()
    Run()
end
methods(Static)
    function AssertTol(val, val_true, tol)
        assert(all(abs(val - val_true) < tol), 'all');
    end

    function AssertTol_zeros(val, validateTol)
        IntegrationTest.AssertTol(val, zeros(size(val)), validateTol);
    end

    function AssertZeros(val)
        assert(all(val == 0, 'all'));
    end

    function AssertEqual(val, val_true)
        assert(all(val == val_true, 'all'));
    end

    function AssertEqual_unordered(val, val_true)
        assert(all(contains(val, val_true), 'all') && all(contains(val_true, val), 'all'));
    end

    function out = OutputMayContainLambda(solverArgs)
        args = [solverArgs{:}];
        case1 = any(contains(args, ["ode15i","fullyImplicit"]));
        case2 = any(contains(args, ["ode15s","ode23t","ode23s"])) && any(contains(args, "massMatrix"));
        out = case1 || case2;
    end
end
end
