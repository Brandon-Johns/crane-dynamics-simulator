%{
Intended for internal use only

PURPOSE
    Used by CDS_Solver.Solve() with solveMode="export"
    Generates the exported files

NOTES
    Matlab export is a single stand alone file
    Sundials export should be run by the framework in "./run_sundials"
%}

classdef CDS_Solver_ODEs_Export < handle
properties
    sys CDS_SystemDescription
    ODEs CDS_Solver_ODEs
    options CDS_Solver_Options
    
    subExpr_expr
    subExpr_var
end
methods
    function this = CDS_Solver_ODEs_Export(sys, ODEs, options)
        this.sys = sys;
        this.ODEs = ODEs;
        this.options = options;
        
        % Swap variables for short names
        this.GenShortNames;
        paramsSwap = [this.sys.params.x; this.sys.params.u; this.sys.params.const];
        this.Swap(paramsSwap.Sym, paramsSwap.SymShort);
        
        % Sub sin & cos for pre-evaluated variables
        [this.subExpr_expr, this.subExpr_var] = this.GenSubExpr_Trig([this.sys.params.q; this.sys.params.const]);
        this.Swap(this.subExpr_expr, this.subExpr_var);
        
        % Display substitutions
        %[paramsSwap.Sym,paramsSwap.SymShort]
        %[this.subExpr_expr, this.subExpr_var]
    end
    
    function Export_Matlab(this, solverName)
        arguments
            this(1,1)
            solverName(1,1) string = "ode45"
        end
        fileName = this.options.exportPath;
        % Validate and create file path
        if ~endsWith(fileName, ".m")
            if fileName=="" || isfolder(fileName) || endsWith(fileName, "/") || endsWith(fileName, "/")
                fileName = fullfile(fileName,"tmp.m");
            else
                fileName = fileName+".m";
            end
        end
        FileHelper = CDS_Helper_StrOut();
        fileName = FileHelper.MakePathToFile(fileName);
        FileHelper.ClearFile(fileName);
        
        % Macros
        strE = @(str) FileHelper.StrToTxt(str, fileName, "exact");
        strEn = @(str) FileHelper.StrToTxt(str, fileName, "exactN");
        symTr = @(str) FileHelper.SymToTxt(str, fileName, "terminate", "removeWS");
        
        % Clear file
        strEn("% Generated Code");
        strEn("");
        
        % Solver inputs
        strEn("t_span = " + mat2str(this.options.time, 16) + ";");
        strEn("x0 = " + mat2str(this.sys.params.x.x0, 16) + ";");
        strEn("");
        
        strEn("opt = odeset('RelTol', " + compose("%.15G", this.options.RelTol) + ");");
        strEn("opt = odeset(opt, 'AbsTol', " + compose("%.15G", this.options.AbsTol) + ");");
        strEn("opt = odeset(opt, 'Stats','on');");
        strEn("[t_sol,x_sol] = " + solverName + "(@ODEs, t_span, x0, opt);");
        strEn("");
        
        % Excel out
        strEn("fileName = 'solvetimeTxt_excel.xlsx';");
        strEn("values = [t_sol,x_sol];");
        strEn("names = {'t', " + strjoin(compose("'%s'", this.sys.params.x.NameReadable), ",") + "};");
        strEn("data = array2table(values, 'VariableNames',names);");
        strEn("writetable(data, fileName, 'WriteMode','replacefile', 'Range','A1', 'UseExcel',0);");
        strEn("");
        
        % Function start
        strEn("%####################################################################################");
        strEn("function [sys_xd] = ODEs(t,sys_x)");
        
        % Constants
        c = this.sys.params.const;
        strEn(compose("%s = %.15G;", c.StrShort, c.Num));
        strEn("");
        
        % x
        x = this.sys.params.x;
        idx_x = (1:length(x)).';
        strEn(compose("%s = sys_x(%d);", x.StrShort, idx_x));
        strEn("");
        
        % u
        qIn = this.sys.params.q_input;
        for idx = 1:length(qIn)
            if any(qIn(idx).mode == ["analytic", "analyticFeedback"])
                % Note: regexprep() removes the function handle head "@(t,x)"
                regexPattern="@\(.*?\)";
                strEn(qIn(idx).StrShort(0) + " = " + regexprep(func2str(qIn(idx).q),regexPattern,"") + ";");
                strEn(qIn(idx).StrShort(1) + " = " + regexprep(func2str(qIn(idx).q_d),regexPattern,"") + ";");
                strEn(qIn(idx).StrShort(2) + " = " + regexprep(func2str(qIn(idx).q_dd),regexPattern,"") + ";");
            else
                warning( "Input can't be exported (Not implemented for input type): " + qIn(idx).NameReadable )
                for d_offset = 0:2
                    strEn(qIn(idx).StrShort(d_offset) + " = ERROR; % " + qIn(idx).NameReadable(d_offset));
                end
            end
        end
        strEn("");
        
        % Common subexpressions
        strEn(compose("%s = %s;", string(this.subExpr_var), string(this.subExpr_expr)));
        strEn("");
        
        % ODE segments
        strE("sys_M_order2 = "); symTr(this.ODEs.M_order2);
        strE("sys_f_b = "); symTr(this.ODEs.f_b);
        strE("sys_f_c = "); symTr(this.ODEs.f_c);
        strE("sys_f_dT = "); symTr(this.ODEs.f_dT);
        strE("sys_f_e = "); symTr(this.ODEs.f_e);
        
        % ODE solving
        if ~isempty(this.sys.params.lambda)
            strEn("sys_f_mb = sys_M_order2\sys_f_b;");
            strEn("sys_f_mc = sys_M_order2\sys_f_c;");
            strEn("sys_f_lambda = (sys_f_e - sys_f_dT*sys_f_mc)/(sys_f_dT*sys_f_mb);");
            strEn("sys_q_free_dd = -sys_f_mc - sys_f_lambda*sys_f_mb;");
            strEn("sys_xd = [sys_q_free_dd; sys_x(1:length(sys_x)/2)];");
        else
            strEn("sys_q_free_dd = -sys_M_order2\sys_f_c;");
            strEn("sys_xd = [sys_q_free_dd; sys_x(1:length(sys_x)/2)];");
        end

        % Function end
        strEn("");
        strEn("end");
        
        % Compile
        %mcc -mv fileName
    end
    
    function Export_Sundials(this)
        arguments
            this(1,1)
        end
        % Validate file output path
        baseFilePath = this.options.exportPath;
        [~,~,pathEx] = fileparts(baseFilePath);
        if pathEx~=""; error("Bad input: path should be to a directory, not a file"); end
        
        fileNames_noPath = ["crane_head_shared"; "crane_head"; "crane_x"; "crane_inputs"; "crane_ode"];
        fileNames = fullfile(baseFilePath, fileNames_noPath);
        FileHelper = CDS_Helper_StrOut();
        
        % Validate and create file path
        for idx = 1:length(fileNames)
            if ~endsWith(fileNames(idx), ".cpp")
                fileNames(idx) = strcat(fileNames(idx), ".cpp");
            end
            fileNames(idx) = FileHelper.MakePathToFile(fileNames(idx));
            FileHelper.ClearFile(fileNames(idx));
        end
        
        % Swap pi (sym number -> sym string)
        this.Swap(sym(pi), sym('pi'));

        % FIRST FILE
        idxFile = 1;
        strEn = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exactN");
        
        strEn("//####################################################################################");
        strEn("// Macros & Global Vars (Shared)");
        strEn("//##########################################");
        strEn("// Solution duration");
        strEn(compose("constexpr sunrealtype t_final = %.15G;", this.options.time(end) ));
        strEn("");
        strEn("// Constants in system equations");
        c = this.sys.params.const;
        strEn(compose("constexpr sunrealtype %s = %.15G;\t\t// %s", c.StrShort, c.Num, c.NameReadable));
        strEn("");
        
        % NEXT FILE
        idxFile = 2;
        strEn = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exactN");
        
        strEn("//####################################################################################");
        strEn("// Macros & Global Vars");
        strEn("//##########################################");
        strEn("// X:  Length of x = number of equations (with constraint removed)");
        strEn("// QF: Length of q_free = numX/2 (always)");
        strEn("// numConstraints:  No. constraints");
        strEn(compose("constexpr sunindextype numX           = %d;", length( this.sys.params.x )));
        strEn(compose("constexpr sunindextype numQF          = %d;", length( this.sys.params.q_free )));
        strEn(compose("constexpr sunindextype numConstraints = %d;", length( this.sys.params.lambda )));
        strEn("");
        strEn("// (String) Head of csv containing [t,x]");
        x = this.sys.params.x;
        strEn("#define x_sym ""t," + strjoin(x.NameReadable,",") + """");
        strEn("");
        strEn("// Initial conditions");
        strEn("const sunrealtype x_ICs[] = {" + strjoin(compose("%.15G",x.x0),",") + "};");
        strEn("");
        
        % NEXT FILE
        idxFile = 3;
        strEn = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exactN");
        
        strEn("//####################################################################################");
        strEn("// Part of function to evaluate the ODEs (1/3)");
        strEn("//##########################################");
        strEn("// x (state vector)");
        x = this.sys.params.x;
        idx_x = (1:length(x)).';
        strEn(compose("sunrealtype %s = Ith(sys_x, %d); // %s", x.StrShort, idx_x, x.NameReadable));
        strEn("");
        
        % NEXT FILE
        idxFile = 4;
        strEn = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exactN");
        
        strEn("//####################################################################################");
        strEn("// Part of function to evaluate the ODEs (2/3)");
        strEn("//##########################################");
        % u may depend on
        %   t: equation must address as 't'
        %   x & constants: equation must address them by name, not component of the vector
        strEn("// u (system inputs)");
        qIn_array = this.sys.params.q_input;
        for idx = 1:length(qIn_array)
            qIn = qIn_array(idx);
            if any(qIn.mode == ["analytic", "analyticFeedback"])
                for d_offset = 0:2
                    % Retrieve qIn at current offset
                    % Swap pi (sym number -> sym string)
                    tmp_qIn = qIn.q_Sym(d_offset);
                    tmp_qIn = subs(tmp_qIn, sym(pi), sym('pi'));
        
                    strEn(compose("sunrealtype %s = %s // %s",...
                        qIn.StrShort(d_offset),...
                        regexprep(ccode( tmp_qIn ), '^.*= ', ''),...
                        qIn.NameReadable(d_offset)...
                        ));
                end
            elseif qIn.mode == "analyticPiecewise"
                nPieces = length(qIn.q_Sym);
                Name_tSwitch = "t_switch_" + qIn.StrShort;
                strEn("// " + qIn.NameReadable);
                strEn("sunrealtype " + Name_tSwitch + " = {" + strjoin(compose("%.15G",qIn.switchTimes),",") + "};");
                strEn("sunrealtype "+qIn.StrShort(0)+", "+qIn.StrShort(1)+", "+qIn.StrShort(2)+";");
                for idxPiece = nPieces:-1:1
                    % Note: idxPiece-2 for C++ indexing and switchTimes is 1 shorter
                    if     idxPiece==nPieces; strEn("if     (t >= " + Name_tSwitch + "[" + (idxPiece-2) + "]) {");
                    elseif idxPiece~=1;       strEn("else if(t >= " + Name_tSwitch + "[" + (idxPiece-2) + "]) {");
                    else;                     strEn("else {");
                    end
                    for d_offset = 0:2
                        % Retrieve qIn at current offset
                        % Retrieve current piece
                        % Swap pi (sym number -> sym string)
                        tmp_qIn = qIn.q_Sym(d_offset);
                        tmp_qIn = tmp_qIn(idxPiece);
                        tmp_qIn = subs(tmp_qIn, sym(pi), sym('pi'));
                        
                        strEn(compose("    %s = %s",...
                            qIn.StrShort(d_offset),...
                            regexprep(ccode( tmp_qIn ), '^.*= ', '')...
                            ));
                    end
                    strEn("}");
                end
            else
                warning( "Input can't be exported (Not implemented for input type): " + qIn.NameReadable )
                for d_offset = 0:2
                    strEn(compose("sunrealtype %s = %s; // %s",...
                        qIn.StrShort(d_offset),...
                        "ERROR",...
                        qIn.NameReadable(d_offset)...
                        ));
                end
            end
        end
        strEn("");
        
        % NEXT FILE
        idxFile = 5;
        strF = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "format");
        strE = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exact");
        strEn = @(str) FileHelper.StrToTxt(str, fileNames(idxFile), "exactN");
        symB = @(str) FileHelper.SymToTxt(str, fileNames(idxFile), "bare");
        
        % Common subexpressions
        strEn("//####################################################################################");
        strEn("// Part of function to evaluate the ODEs (3/3)");
        strEn("//##########################################");
        strEn("// Common subexpressions");
        strEn(compose("sunrealtype %s = %s;", string(this.subExpr_var), string(this.subExpr_expr)));
        strEn("");
        
        strEn("// ODE segments");
        % Using ccode():
        %   Matrix input: Output is formatted using name of input variable
        %   Scalar input: completely different behaviour
        %   => rename variables before use
        %   &  f_e needs special treatment
        sys_M_order2=this.ODEs.M_order2;
        sys_f_b=this.ODEs.f_b;
        sys_f_c=this.ODEs.f_c;
        sys_f_dT=this.ODEs.f_dT;
        sys_f_e=this.ODEs.f_e;
        if ~isempty(sys_f_e)
            symB(ccode(sys_M_order2)); strF("\n\n");
            symB(ccode(sys_f_b)); strF("\n\n");
            symB(ccode(sys_f_c)); strF("\n\n");
            symB(ccode(sys_f_dT)); strF("\n\n");
            strE("sys_f_e[0][0] ="); symB(regexprep(ccode(sys_f_e), '^.+=', '')); strF("\n\n");
            
        else % No constraints to solve
            if ~isscalar(sys_M_order2)
                symB(ccode(sys_M_order2)); strF("\n\n");
                symB(ccode(sys_f_c)); strF("\n\n");
            else
                strE("sys_M_order2[0][0] ="); symB(regexprep(ccode(sys_M_order2), '^.+=', '')); strF("\n\n");
                strE("sys_f_c[0][0] ="); symB(regexprep(ccode(sys_f_c), '^.+=', '')); strF("\n\n");
            end
        end
    end
    
end
methods (Access=private)
    % Rename variables with alphabet
    function GenShortNames(this)
        params = this.sys.params;
        
        % Check not too many variables - limitation of this function
        if length(params.q) > 'z'-'a'-1 ... % skip 't' for time
            || length(params.const) > 'Z'-'A'
            error('too many vars')
        end
        
        % Choose new names
        %   'u' is first for consistency between similar systems
        %   which all take same u, but different number of x
        idxChar = double('a');
        q = [params.q_input; params.q_free];
        for idx = 1:length(q)
            q(idx).SetSymShort(char(idxChar));
            
            % Get next letter (skip 't' for time)
            idxChar=idxChar+1;
            if idxChar==double('t'); idxChar=idxChar+1; end
        end
        
        idxChar = double('A');
        for idx = 1:length(params.const)
            params.const(idx).SetSymShort(char(idxChar));
            idxChar=idxChar+1;
        end
    end
    
    %{
    Substitute common expressions with temp vars
        Sx = sin(x)
        Cx = cos(x)
    %}
    function [expr, var] = GenSubExpr_Trig(this, param)
        arguments
            this(1,1)
            param(:,1) CDS_Param
        end
        % List sub expressions
        expr = [sin(param.SymShort); cos(param.SymShort)];
        
        % Generate variables to replace the sub expressions: sin(x), cos(x)
        var = sym([strcat("S",param.StrShort); strcat("C",param.StrShort)]);
    end
    
    % Helper: rename variables
    function Swap(this, swap_old, swap_new, mode)
        arguments
            this(1,1)
            swap_old(1,:) sym
            swap_new(1,:) sym
            mode(1,1) string = "notInput"
        end
        this.ODEs.M_order2 = subs(this.ODEs.M_order2, swap_old, swap_new);
        this.ODEs.f_b = subs(this.ODEs.f_b, swap_old, swap_new);
        this.ODEs.f_c = subs(this.ODEs.f_c, swap_old, swap_new);
        this.ODEs.f_dT = subs(this.ODEs.f_dT, swap_old, swap_new);
        this.ODEs.f_e = subs(this.ODEs.f_e, swap_old, swap_new);
        
        if ~strcmp(mode, "notInput")
            error("TODO")
        end
    end
end
end
