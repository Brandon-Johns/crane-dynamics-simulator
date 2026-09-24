%{
PURPOSE
    Treat matlab arrays as dictionaries

DETAILS
    Elements of an array of CDS_NamedItem can be addressed by name
    This data type is not a container
        In associative arrays (dictionaries), the name is used as a key to fetch a value
        With this data type, the value itself is named
    Intent
        Use a 1D array to store multiple objects of this type
        Then query the array with .Subset() to obtain a sub-array
        Then use call methods on the sub-array as needed

RULES
    name is required
    name is immutable
%}

classdef(Abstract) CDS_NamedItem < handle
properties (GetAccess=private, SetAccess=immutable)
    name_nominal(1,1) string
end
methods (Sealed=true)
    %**********************************************************************
    % Interface: Create
    %***********************************
    % Intended for internal use only
    function this = CDS_NamedItem(name)
        this.name_nominal = name;
    end

    %**********************************************************************
    % Interface: Methods inherited from 'handle'
    %***********************************
    % Operator overloads
    % Required because matlab.mixin.Heterogeneous wants sealed methods
    % REFERENCE
    %   matlab.mixin.Heterogeneous "Sealing Inherited Methods"
    %       https://au.mathworks.com/help/matlab/ref/matlab.mixin.heterogeneous-class.html
    %   Add more as required - will get errors about method not sealed
    %       https://au.mathworks.com/help/matlab/handle-classes.html
    % NOTE
    %   Operator overloading semantics
    %       Depending on "InferiorClasses" (where some classes are inferior by default),
    %       the first argument is not always 'this'.
    %       e.g. A==2 vs 2==A will switch the order of the arguments
    % INPUT
    %   The left and right operands, or the function inputs otherwise
    % OUTPUT
    %   (logical | CDS_NamedItem) DIM[various]
    function varargout = eq(varargin)
        % Copies of a handle variable always compare as equal
        [varargout{1:nargout}] = eq@handle(varargin{:});
    end
    function varargout = ne(varargin)
        % Different handles are always not equal
        [varargout{1:nargout}] = ne@handle(varargin{:});
    end
    function varargout = findobj(varargin)
        % e.g. objectArray.findobj('-class',"CDS_Param_Free")
        [varargout{1:nargout}] = findobj@handle(varargin{:});
    end

    %**********************************************************************
    % Interface: Get
    %***********************************
    % The nominal name
    % OUTPUT
    %   (string) DIM[size(this)]
    function out = Name(this); out = string(this.PropArray(this.name_nominal)); end

    % Test if specific object is in array of objects
    % INPUT
    %   Names of the objects to test for
    %       (string)            Values from CDS_NamedItem.Name
    %       (symbolic variable) Values from sym(CDS_NamedItem.Name)
    %       (CDS_NamedItem)     The objects themselves
    % OUTPUT
    %   (logical) DIM[size(this)] Corresponding to each name
    function result = Contains(this, names)
        arguments
            this
            names {mustBeA(names, ["string", "sym", "CDS_NamedItem"])}
        end
        idx = this.SubsetIdx(names(:), warnMissing=false, warnDuplicates=false, matchQuery=true);
        result = ~isnan(idx);
        result = reshape(result, size(names));
    end

    % Get specific objects from an array of objects, as referenced by name or sym
    % NOTE
    %   Shortcut for calling out=this(this.SubsetIdx)
    % INPUT
    %   namesIn
    %       (string)            Values from CDS_NamedItem.Name
    %       (symbolic variable) Values from sym(CDS_NamedItem.Name)
    %       (CDS_NamedItem)     The objects themselves
    % INPUT (Name=Value)
    %   warnMissing
    %       true:  Warn if any names in namesIn do not match the names of any items in the object array
    %       false: Do not emit warning
    %   warnDuplicates
    %       true:  Warn if any duplicate names exist in namesIn
    %       false: Do not emit warning
    %   keepDuplicates
    %       true:  Keep any duplicates
    %       false: Given duplicate names in namesIn, keep only the first of each. Discard the rest
    % OUTPUT
    %   (CDS_Param) DIM[numFound, 1]
    %       Heterogeneous array of (CDS_Param_Const|CDS_Param_Free|CDS_Param_Input|CDS_Param_Lambda)
    %       The order of the output corresponds to that of the input
    %       If a object is not found, then that element is dropped
    function selfSubset = Subset(this, namesIn, options)
        arguments
            this
            namesIn(:,1) {mustBeA(namesIn, ["string", "sym", "CDS_NamedItem"])}
            options.warnMissing(1,1) logical = true
            options.warnDuplicates(1,1) logical = true
            options.keepDuplicates(1,1) logical = true
        end
        this_asCol = this(:);
        optionsCell = namedargs2cell(options);
        selfSubset = this_asCol( this.SubsetIdx(namesIn, optionsCell{:}, 'matchQuery',false) );
    end

    % Get indexes of specific objects in array of objects
    % INPUT
    %   namesIn
    %       (string)            Values from CDS_NamedItem.Name
    %       (symbolic variable) Values from sym(CDS_NamedItem.Name)
    %       (CDS_NamedItem)     The objects themselves
    % INPUT (Name=Value)
    %   warnMissing
    %       true:  Warn if any names in namesIn do not match the names of any items in the object array
    %       false: Do not emit warning
    %   warnDuplicates
    %       true:  Warn if any duplicate names exist in namesIn
    %       false: Do not emit warning
    %   keepDuplicates
    %       true:  Keep any duplicates
    %       false: Given duplicate names in namesIn, keep only the first of each. Discard the rest
    %   matchQuery
    %       true:  The output array will strictly match namesIn by both length and order. Missing/discarded will be set NaN
    %       false: The output array will strictly match namesIn by order only. Missing/discarded will be removed
    % OUTPUT
    %   (double) DIM[n, 1]
    %       If matchQuery==true: DIM[length(namesIn), 1] else DIM[n, 1], where 0<=n<=length(namesIn)
    %       Array of linear indices to the array calling this method
    %       The order of the output corresponds to that of the input
    %       If a object is not found, then that element is dropped
    function idxMatches = SubsetIdx(this, namesIn, options)
        arguments
            this
            namesIn(:,1) {mustBeA(namesIn, ["string", "sym", "CDS_NamedItem"])}
            options.warnMissing(1,1) logical = true
            options.warnDuplicates(1,1) logical = true
            options.keepDuplicates(1,1) logical = true
            options.matchQuery(1,1) logical = false
        end
        % Interpret input type (effectively implements input overloading)
        if isa(namesIn, "CDS_NamedItem");
            queriedNames=namesIn.Name;
        elseif isa(namesIn, "string");
            queriedNames=namesIn;
        elseif isa(namesIn, "sym");
            if ~all(isSymType(namesIn,'variable'),'all')
                error("Bad input: Some inputs are not symbolic variables (e.g. might be symbolic expressions)");
            end
            queriedNames = string(namesIn);
        else
            error("Bad input")
        end

        % Output uses linear indices to 'this', so may as well flatten here to make it more clear
        names = this(:).Name;

        % Match the order in the input, handle duplicate points, and setting not found as nan
        idxMatches = nan(numel(namesIn), 1);
        for idx = 1:numel(queriedNames)
            queriedName = queriedNames(idx);

            % Check if duplicate of any previous items
            if any(queriedName==queriedNames(1:idx-1))
                if options.warnDuplicates; warning("Duplicate name in query: %s", queriedName); end
                if ~options.keepDuplicates
                    % Discard duplicate (leave nan)
                    continue
                end
            end

            idxMatch = find(queriedName==names, 1,'first');
            if isempty(idxMatch)
                if options.warnMissing; warning("Object not found: %s", queriedName); end
                % Missing (leave nan)
                continue
            end
            idxMatches(idx) = idxMatch;
        end

        if ~options.matchQuery
            % Drop nan
            idxMatches = idxMatches(~isnan(idxMatches));
        end

        % Force column, even after dropping nan might leave empty
        idxMatches = idxMatches(:);
    end
end
methods (Sealed=true, Access=protected)
    % Helper to allow using functions with an array of objects
    % NOTE
    %   Only intended for 1D arrays
    % INPUT
    %   List of properties
    % OUTPUT
    %   Array of properties corresponding to the object
    % EXAMPLE
    %   PropArray(this.prop)
    function propArray = PropArray(this, varargin)
        propArray = reshape([varargin{:}],size(this));
    end
end
end
