%{
Intended for internal use only

PURPOSE
    Used by CDS_Solver.Solve() with solveMode=["solveTime2","export"]
    Holds the partially formed ODEs
%}

classdef CDS_Solver_ODEs < handle
properties (Access=public)
    modeConstraint(1,1) string {mustBeMember(modeConstraint,["noConstraint","withConstraint",""])} = ""
    
    M_order2(:,:) sym
    f_b(:,1) sym
    f_c(:,1) sym
    f_dT(1,:) sym
    f_e(:,1) sym
end
methods
    function this = CDS_Solver_ODEs()
        %
    end
end
end
