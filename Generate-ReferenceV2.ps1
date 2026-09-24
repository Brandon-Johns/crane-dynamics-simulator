## Written By: Brandon Johns
## Date Version Created: 2026-08-25
## Date Last Edited: 2026-09-23
## Purpose: Generate documentation from matlab code with structured comments, and from the manually authored html
## Status: Functional

## Instructions
##    Set config
##    Then call from project root directory
##    Then edit the matlab code, html templates, etc. and run again to rerender


################################################################################################
## Schema
################################################
<#
Classes
	Must be proceeded by a block comment, using the 'HeadComment' schema

Properties
	Grouped by organising without any blank newlines between
	Must be proceeded by a block of single-line comments, no schema used
	May have an inline comment

Methods
	Grouped by organising without any blank newlines between
	Must be proceeded by a block of single-line comments, using the 'HeadComment' schema
	Inline comments are not permitted (on the name or the arguments block)

Ignore rule
	Begin the HeadComment ShortDescription with the line "Intended for internal use only"

Call Style
	Methods are assumed array call unless static, or unless the arguments block restricts otherwise


################################################
Schema: Common subparts of other schema

(type)
	A matlab type or class, with optionally additional information
	Where there are multiple possibilities, delimit with |
	Syms should be specified by the more specific pseudo-types per $tokens_inbuiltTypesSym
	e.g. (double)
	e.g. (cell{double(4,4)})
	e.g. (CDS_T | symbolic expression | double)

DIM[expr]
	A matlab expression (or pseudocode) which evaluates the size of the variable
	Where there are multiple possibilities, delimit with |
	The [] should be treated as concatenation of the sizes
	e.g. DIM[1,4]
	e.g. DIM[3,size(this)]
	e.g. DIM[[3,size(a)] | [3,size(b)]]


################################################
Schema: property inline comments

% (type) DIM[expr] OneLineDescription

Special rules
	Ungrouped properties shall not have description text in both the HeadComment and inline comment


################################################
Schema: HeadComment

% ShortDescription
% BLOCK NAME
%   BlockContent
%   ...
% ...

Specially recognised block names: class
	EXAMPLE
	INTERNAL

Specially recognised block names: method
	INPUT
	INPUT (Repeating)
	INPUT (Name=Value)
	OUTPUT
	SIDE EFFECTS
	EXAMPLE


################################################
Schema: BlockContent

% NON-RECOGNISED BLOCK NAME
%   MultilineFreeText

% INTERNAL
%   MultilineFreeText

% EXAMPLE
%   MultilineMatlabCode

% INPUT (BlockType)
%   ArgName (type) DIM[expr] OneLineArgDescription
%   ArgName (type) DIM[expr]
%       MultilineArgDescription
%   ArgName
#           MultilineArgDescription
%       (type) DIM[expr] OneLineTypeDescription
%       (type) DIM[expr]
%           MultilineTypeDescription
%   ArgName DIM[expr]
#           MultilineArgDescription
%       (type) OneLineTypeDescription
%       (type)
%           MultilineTypeDescription
%   ArgName DIM[expr]
#           MultilineArgDescription
%       value: OneLineValueDescription
%       value:
%           MultilineValueDescription
%       ...
%   ...
where
	BlockType shall be appropriately omitted or set to "Repeating" or "Name=Value"
	if(nargin>1 | mustBeMember | mustBeA): ArgName is required. Otherwise, not permitted
	if(mustBeMember): value are the members, verbatim, and all must be specified. Otherwise, not permitted
	if(mustBeA):      type are the types,    verbatim, and all must be specified. Otherwise, optional
	(optional) type
	(optional) expr
	(optional) OneLineArgDescription|MultilineArgDescription describes the argument as a whole
	(optional) OneLineValueDescription|MultilineValueDescription describes the effect of the chosen value output

% OUTPUT
%   RetName (type) DIM[expr] OneLineDescription
%   RetName (type) DIM[expr]
%       MultilineDescription
%   ...
where
	This block is required for methods that produce output, except it shall be omitted when the output is 'this'
	if(nargout>1): RetName is required. Otherwise, not permitted
	(required) type
	(required) expr
	(optional) OneLineDescription|MultilineDescription describes the singular output

#>


$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest


################################################################################################
## Server Config
################################################
# Github pages why?
$productionDomain = 'https://Brandon-Johns.github.io'
$productionRoot = '/crane-dynamics-simulator'


################################################################################################
## Project Config
################################################
$projectRoot = $PSScriptRoot;
$dirpathWebRoot = Join-Path $projectRoot 'doc/public_html/'

$filepathLayoutMain            = Join-Path $projectRoot 'doc/web-src/html-templates/layoutMain.html'
$filepathLayoutReference       = Join-Path $projectRoot 'doc/web-src/html-templates/layoutReference.html'
$filepathLayoutReferenceHome   = Join-Path $projectRoot 'doc/web-src/html-templates/layoutReferenceHome.html'
$filepathLayoutReferenceMethod = Join-Path $projectRoot 'doc/web-src/html-templates/layoutReferenceMethod.html'
$filepathIncludeExLink         = Join-Path $projectRoot 'doc/web-src/html-templates/includeExLink.html'
$dirpathManuallyAuthoredHtml   = Join-Path $projectRoot 'doc/web-src/html-manually-authored'

$htmlLayoutMain            = Get-Content -LiteralPath $filepathLayoutMain -Raw
$htmlLayoutReference       = Get-Content -LiteralPath $filepathLayoutReference -Raw
$htmlLayoutReferenceHome   = Get-Content -LiteralPath $filepathLayoutReferenceHome -Raw
$htmlLayoutReferenceMethod = Get-Content -LiteralPath $filepathLayoutReferenceMethod -Raw
$htmlExLinkSvg             = Get-Content -LiteralPath $filepathIncludeExLink -Raw

$filesMisc = @(
	'core/CDS/CDS_T.m'
	'core/CDS/CDS_Calc_Energy.m'
	'core/CDS/CDS_Helper_StrOut.m'
	'core/includes_matlab/CDS_GetDataLocations.m'
)
$filesDescription = @(
	'core/CDS/CDS_SystemDescription.m'
	'core/CDS/CDS_Params.m'
	'core/CDS/CDS_NamedItem.m'
	'core/CDS/CDS_Param.m'
	'core/CDS/CDS_Param_Const.m'
	'core/CDS/CDS_Param_Free.m'
	'core/CDS/CDS_Param_Input.m'
	'core/CDS/CDS_Param_Lambda.m'
	'core/CDS/CDS_Point.m'
	'core/CDS/CDS_Component_LinearSpring.m'
	'core/CDS/CDS_Component_TorsionSpring.m'
	'core/CDS/CDS_Component_LinearDamper.m'
	'core/CDS/CDS_Component_GeneralisedForce.m'
	'core/CDS/CDS_Component_PointForce.m'
	'core/CDS/CDS_Component_Constraint.m'
)
$filesSolving = @(
	'core/CDS/CDS_Solver.m'
	'core/CDS/CDS_Solver_Options.m'
)
$filesPost = @(
	'core/CDS/CDS_Solution.m'
	'core/CDS/CDS_SolutionSim.m'
	'core/CDS/CDS_SolutionExp.m'
	'core/CDS/CDS_SolutionInterpolated.m'
	'core/CDS/CDS_SolutionSaved.m'
	'core/CDS/CDS_Solution_Plot.m'
	'core/CDS/CDS_Solution_Animate.m'
	'core/CDS/CDS_Solution_GetData.m'
	'core/CDS/CDS_Solution_Export.m'
)


################################################################################################
## Recognised Tokens
################################################
$tokens_mustBeBooleans = @(
	'mustBeFinite',
	'mustBeScalarOrEmpty',
	'mustBeVector',
	'mustBePositive',
	'mustBeNonnegative'
)
$tokens_inbuiltKeywords = @(
	'if',
	'elseif',
	'else',
	'end',
	'for',
	'while',
	'switch',
	'case',
	'otherwise',
	'break',
	'continue',
	'return'
)
$tokens_inbuiltFunctions = @(
	'sin',
	'cos',
	'pi',
	'syms',
	'numel',
	'size',
	'length',
	'strings',
	'zeros',
	'any',
	'readmatrix',
	'fullfile',
	'fileparts',
	'addpath',
	'clearvars'
)
$tokens_inbuiltTypes = @(
	'this',
	'true',
	'false',
	'logical',
	'uint64',
	'double',
	'string',
	'char',
	'sym',
	'cell',
	'struct',
	'table',
	'function_handle',
	'matlab.graphics.axis.Axes'
)
$tokens_inbuiltTypesSym = @('symbolic expression', 'symbolic variable')
$tokens_inbuiltTypesExtended = $tokens_inbuiltTypes + $tokens_inbuiltTypesSym
$tokens_punctuation = @(
	'(',
	')',
	'[',
	']',
	'{',
	'}',
	'|',
	';',
	',',
	':',
	'=',
	'.',
	'+',
	'-',
	'*',
	'/',
	'^',
	'~',
	'>>',
	'×'
)

$html_op     = '<span class="tk-paren-o">(</span>'
$html_cp     = '<span class="tk-paren-c">)</span>'
$html_os     = '<span class="tk-paren-o">[</span>'
$html_cs     = '<span class="tk-paren-c">]</span>'
$html_ob     = '<span class="tk-paren-o">{</span>'
$html_cb     = '<span class="tk-paren-c">}</span>'
$html_pipe   = '<span class="tk-pipe">|</span>'
$html_semi   = '<span class="tk-semi">;</span>'
$html_comma  = '<span class="tk-comma">,</span>'
$html_colon  = '<span class="tk-colon">:</span>'
$html_equals = '<span class="tk-equals">=</span>'
$html_dot    = '<span class="tk-dot">.</span>'
$html_plus   = '<span class="tk-plus">+</span>'
$html_minus  = '<span class="tk-minus">-</span>'
$html_times  = '<span class="tk-times">*</span>'
$html_divide = '<span class="tk-divide">/</span>'
$html_hat    = '<span class="tk-hat">^</span>'
$html_tilde  = '<span class="tk-tilde">~</span>'
$html_prompt = '<span class="tk-prompt">'+[System.Web.HttpUtility]::HtmlEncode('>>')+'</span>'
$html_ans    = '<span class="tk-prompt">ans</span>'
$html_uncodeTimes = '<span class="tk-uncode-times">×</span>'


################################################################################################
## Parse Tree 1
################################################
class ClassRecord {
	[String]$RelativePath
	[String]$Name
	[Boolean]$IsAbstract
	[String[]]$Super
	[String[]]$HeadComment = @()
	[PropGroupRecord[]]$PropGroups = @()
	[MethodGroupRecord[]]$MethodGroups = @()
}
class PropGroupRecord {
	[String[]]$HeadComment
	[PropRecord[]]$Props
}
class MethodGroupRecord {
	[String[]]$HeadComment
	[MethodRecord[]]$Methods
}
class MethodRecord {
	[String]$Name
	[Boolean]$IsGetter
	[Boolean]$IsStatic
	[String[]]$ReturnStrings
	[String[]]$ArgStrings
	[ArgumentsRecord[]]$ArgBlocks = @()
}
class ArgumentsRecord {
	[Boolean]$IsRepeating
	[PropRecord[]]$Args
}
class PropRecord {
	# From properties block head
	[Boolean]$UserCanRead
	[Boolean]$UserCanSet
	# From property
	[String]$Name
	[System.Nullable[Int32][]]$Sizes
	[String]$Type
	[String[]]$MustBeA
	[String[]]$MustBeMember
	[String[]]$MustBe_Booleans
	[String]$DefaultValue
	[String]$InlineComment
}

enum ParseContextMain {
	FileHead
	FileHeadComment
	PropertiesBlock
	PropertiesComment
	PropertiesGroup
	MethodsBlock
	MethodsComment
	MethodsGroup
	MethodArgs
	MethodBody
	StarDelimComment
}


################################################################################################
## Parse Tree 2/3
################################################
enum ArgBlockType2 {
	Normal
	Repeating
	NameValue
}

class ClassRecord2 {
	[String]$RelativePath
	[String]$Name
	[Boolean]$IsAbstract
	[String[]]$Super
	[String[]]$HeadComment = @()
	[CommentClass]$CommentClass    # Set in Parse3
	[PropGroupRecord2[]]$PropGroups = @()
	[MethodGroupRecord2[]]$MethodGroups = @()
}
class MethodGroupRecord2 {
	[String[]]$HeadComment
	[CommentMethod]$CommentMethod    # Set in Parse3
	[String[]]$Names
	[Boolean]$IsStatic
	[Boolean]$SupportsObjectArrays
	[RetRecord2[]]$Returns = @()
	[ArgRecord2[]]$Args = @()
}
class RetRecord2 {
	[String]$Name
	[String]$CommentType          # Set in Parse3
	[String]$CommentDim           # Set in Parse3
	[String[]]$CommentFreeText    # Set in Parse3
}
class ArgRecord2 {
	[ArgBlockType2]$ArgBlockType
	[String]$Name
	[System.Nullable[Int32][]]$Sizes
	[String[]]$TypesOrMembers     # Empty array if not specified by code (in arguments block)
	[Boolean]$AreTypesMembers
	[String[]]$MustBe_Booleans
	[String]$DefaultValue
	[String[]]$InlineComment
	[String[]]$CommentTypes       # Set in Parse3. Set null for enums (i.e. mustBeMember)
	[String[]]$CommentDims        # Set in Parse3
	[String[]]$CommentFreeText    # Set in Parse3
	[System.Collections.Generic.List[string[]]]$CommentVariationsFreeText # Set in Parse3
}
class PropGroupRecord2 {
	[String[]]$HeadComment
	[String[]]$CommentFreeText    # Set in Parse3
	[PropRecord2[]]$Props = @()
}
class PropRecord2 {
	[Boolean]$UserCanRead
	[Boolean]$UserCanSet
	[String]$Name
	[System.Nullable[Int32][]]$Sizes
	[String[]]$TypesOrMembers     # Empty array if not specified by code (in declaration)
	[Boolean]$AreTypesMembers
	[String[]]$MustBe_Booleans
	[String]$DefaultValue
	[String]$InlineComment
	[String]$CommentType          # Set in Parse3. Set null for enums (i.e. mustBeMember)
	[String]$CommentDim           # Set in Parse3
	[String[]]$CommentFreeText    # Set in Parse3
}


# Used in Parse3
class CommentClass {
	[String[]]$ShortDescription
	[CommentBlock[]]$FreeBlocks
	[CommentBlock[]]$Examples
}
class CommentMethod {
	[String[]]$ShortDescription
	[CommentBlock[]]$FreeBlocks
	[CommentBlock]$SideEffects = $null
	[CommentBlock[]]$Examples
}
class CommentBlock {
	[String]$Name
	[String[]]$Content = @()
}


################################################################################################
## Main
################################################
function RunMain {
	$filesAll = $filesDescription + $filesSolving + $filesPost + $filesMisc

	# Lexical tokenisation + parse 1
	$classes = [System.Collections.Generic.List[ClassRecord]]::new()
	$Parser1 = [Parse1]::new()
	foreach($relativePath in $filesAll) {
		$fullPath = (Join-Path $projectRoot $relativePath)
		$fileObject = Get-Item -Path $fullPath
		$classRecord = $Parser1.ParseFile($relativePath, $fileObject)
		$classes += $classRecord
	}
	#$classes | ConvertTo-Json -Depth 20 | Out-File -Width '2000' -Encoding 'utf8' -FilePath 'README-TMP1.json'

	# Parse 2
	# Eliminate "get.NAME" -> merge into params
	# Eliminate args from signature -> merge into arguments block
	# Eliminate argument "this" -> replace with flag [Boolean]$SupportsObjectArrays
	#	false: "this(1,1)"
	#	true:  "this", no args block
	#	error: anything else e.g. "this(1,:)" or "this(:,1)"
	# Eliminate "options." from name=value args
	#	Drop the "options." from the arg name
	#	Group into args block type "NameValue"
	# Merge input types "MustBeA" and "Type" -> "Types"
	$Parser2 = [Parse2]::new()
	$classes2 = [System.Collections.Generic.List[ClassRecord2]]::new()
	foreach($class in $classes) {
		$classRecord = $Parser2.ParseRound2($class)
		$classes2 += $classRecord
	}
	#$classes2 | ConvertTo-Json -Depth 20 | Out-File -Width '2000' -Encoding 'utf8' -FilePath 'README-TMP2.json'

	# Special case modifications
	$odeSolversList = @('"ode45"','"ode23"','"ode113"','"ode78"','"ode89"','"ode15s"','"ode23t"','"ode23s"','"ode23tb"','"ode15i"','"cvodesnonstiff"','"cvodesstiff"','"idas"')
	$solverNameArg = (($classes2 |
		Where-Object Name -eq "CDS_Solver").MethodGroups |
		Where-Object Names -contains "Solve").Args |
		Where-Object Name -eq "solverName"
	$solverNameArg.TypesOrMembers = @($solverNameArg.TypesOrMembers | Where-Object { $_ -notin $odeSolversList })
	$solverNameArg.TypesOrMembers += "(any standard Matlab solver)"

	# Parse 3
	# Classify method return type to detect support for method chaining
	#	"Self" returns self
	#	"SelfSubset" returns subset of array of self
	#	"HeldObject" returns held objects
	#	"BuiltObject" returns built object
	#	"Other" cannot tell form the name alone (see structured comments in next parse)
	# Extract information from structured the comments
	$Parser3 = [Parse3]::new()
	foreach($class in $classes2) {
		$Parser3.ParseRound3($class)
	}

	#**********************************************************************
	# Pre-Render
	#***********************************
	$classesDict = [System.Collections.Generic.Dictionary[String,ClassRecord2]]::new()
	foreach($class in $classes2) {
		$classesDict[$class.Name] = $class
	}
	#$classesDict | ConvertTo-Json -Depth 20 | Out-File -Width '2000' -Encoding 'utf8' -FilePath 'README-TMP3.json'

	[String[]]$allClassNames = $classesDict.Keys

	# Map ClassName to list of all classes that it recursively inherits from
	$inheritanceDict = [System.Collections.Generic.Dictionary[String,String[]]]::new()
	foreach($class in $classesDict.Values) {
		[String[]]$inheritsFrom = @()
		$super = [System.Collections.Generic.List[String]]::new()
		$super.AddRange($class.Super)
		while($super.Count -ne 0) {
			if($allClassNames -contains $super[0]) {
				$inheritsFrom += $super[0]
				$super.AddRange($classesDict[$super[0]].Super)
			}
			$super.RemoveAt(0)
		}
		$inheritanceDict[$class.Name] = $inheritsFrom
	}

	#**********************************************************************
	# Render (same for all files)
	#***********************************
	# Render sidebar
	$map_fileToClassName = [System.Collections.Generic.Dictionary[string,string]]::new()
	foreach($class in $classesDict.Values) {
		$map_fileToClassName[$class.RelativePath] = $class.Name
	}
	[string[]]$htmlNavDescription = @()
	[string[]]$htmlNavSolving     = @()
	[string[]]$htmlNavPost        = @()
	[string[]]$htmlNavMisc        = @()
	foreach($relativePath in $filesDescription) {
		$htmlNavDescription += "<li>$(RenderLinkToClass ($map_fileToClassName[$relativePath]))</li>"
	}
	foreach($relativePath in $filesSolving) {
		$htmlNavSolving += "<li>$(RenderLinkToClass ($map_fileToClassName[$relativePath]))</li>"
	}
	foreach($relativePath in $filesPost) {
		$htmlNavPost += "<li>$(RenderLinkToClass ($map_fileToClassName[$relativePath]))</li>"
	}
	foreach($relativePath in $filesMisc) {
		$htmlNavMisc += "<li>$(RenderLinkToClass ($map_fileToClassName[$relativePath]))</li>"
	}

	$htmlMain = $script:htmlLayoutMain
	$htmlMain = HtmlInsert $htmlMain 'navDescription' ($htmlNavDescription -join "`n")
	$htmlMain = HtmlInsert $htmlMain 'navSolving' ($htmlNavSolving -join "`n")
	$htmlMain = HtmlInsert $htmlMain 'navPost' ($htmlNavPost -join "`n")
	$htmlMain = HtmlInsert $htmlMain 'navMisc' ($htmlNavMisc -join "`n")

	#**********************************************************************
	# Render (per file)
	#***********************************
	$ReferenceRenderer = [RenderLayoutReference]@{
		AllClassNames = $allClassNames
		ClassesDict = $classesDict
		InheritanceDict = $inheritanceDict
	}
	foreach($class in $classesDict.Values) {
		$pageName = ($class.IsAbstract ? "(Abstract) " : "") + "$($class.Name)"
		$pageDescription = "Crane Dynamics Simulator Documentation: $($class.Name) API Reference"
		$pageUrl = URLFormatReference $class.Name
		$pageUrlCanonical = "$($script:productionDomain)$pageUrl"
		$htmlRef = $ReferenceRenderer.Render($class, $pageName)
		$htmlMain_thisFile = $htmlMain
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaTitle' "$pageName | Crane Dynamics Simulator" -Trim
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaUrlCanonical' $pageUrlCanonical -Trim
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaDescription' $pageDescription
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'inner' $htmlRef
		$htmlMain_thisFile = HtmlRemoveComments $htmlMain_thisFile
		$htmlMain_thisFile = HtmlFormatExLink $htmlMain_thisFile
		HtmlErrorIfRemainingTags $htmlMain_thisFile "($pageUrl)"
		$outPath = Join-Path $script:dirpathWebRoot $pageUrl
		$htmlMain_thisFile | Out-File -LiteralPath $outPath -Encoding utf8
	}


	$htmlInner = $script:htmlLayoutReferenceHome
	$htmlInner = HtmlInsert $htmlInner 'refHomeSystemDescription' ($ReferenceRenderer.RenderClassList($allClassNames) -join "`n")

	$pageName = "API Reference Home"
	$pageDescription = "Crane Dynamics Simulator Documentation"
	$pageUrl = URLFormatMain "reference-home"
	$pageUrlCanonical = "$($script:productionDomain)$pageUrl"
	$htmlMain_thisFile = $htmlMain
	$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaTitle' "$pageName | Crane Dynamics Simulator" -Trim
	$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaUrlCanonical' $pageUrlCanonical -Trim
	$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaDescription' $pageDescription
	$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'inner' $htmlInner
	$htmlMain_thisFile = HtmlFormatExLink $htmlMain_thisFile
	$htmlMain_thisFile = HtmlRemoveComments $htmlMain_thisFile
	HtmlErrorIfRemainingTags $htmlMain_thisFile "($pageUrl)"
	$outPath = Join-Path $script:dirpathWebRoot $pageUrl
	$htmlMain_thisFile | Out-File -LiteralPath $outPath -Encoding utf8

	#**********************************************************************
	# Render (Manually authored files)
	#***********************************
	$manualFiles = Get-ChildItem -LiteralPath $script:dirpathManuallyAuthoredHtml -File -Depth 0
	foreach($fileObject in $manualFiles) {
		$htmlInner = Get-Content $fileObject -Raw
		$htmlInner = HtmlRenderMatlabCode $htmlInner $ReferenceRenderer

		$pageName = $fileObject.BaseName -replace '-', ' '
		if($fileObject.BaseName -eq "index") { $pageName = 'home' }
		$pageName = (Get-Culture).TextInfo.ToTitleCase($pageName.ToLower())

		$pageDescription = "Crane Dynamics Simulator Documentation"
		$pageUrl = URLFormatMain $fileObject.BaseName
		$pageUrlCanonical = "$($script:productionDomain)$pageUrl"
		$htmlMain_thisFile = $htmlMain
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaTitle' "$pageName | Crane Dynamics Simulator" -Trim
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaUrlCanonical' $pageUrlCanonical -Trim
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'metaDescription' $pageDescription
		$htmlMain_thisFile = HtmlInsert $htmlMain_thisFile 'inner' $htmlInner
		$htmlMain_thisFile = HtmlRemoveComments $htmlMain_thisFile
		$htmlMain_thisFile = HtmlFormatExLink $htmlMain_thisFile
		HtmlErrorIfRemainingTags $htmlMain_thisFile "($pageUrl)"
		$outPath = Join-Path $script:dirpathWebRoot $pageUrl
		$htmlMain_thisFile | Out-File -LiteralPath $outPath -Encoding utf8
	}
}


################################################################################################
## Common Parsing Helpers
################################################
function AreArraysEqual($a, $b) {
	if($a.Count -ne $b.Count) {
		return $false
	}
	for($idx=0; $idx -lt $a.Count; $idx++) {
		if($a[$idx] -ne $b[$idx]) {
			return $false
		}
	}
	return $true
}


function SplitNotBracketed([String]$Text, [Char]$Delim, [Switch]$Trim) {
	# Split at delimiters that are not contained in brackets
	$charsOpen = @('(','[','{')
	$charsClose = @(')',']','}')

	[String[]]$out = @()
	[Int32]$idxDelimPrev = -1
	[Int32]$idx = 0
	[Int32]$depth = 0
	[Char[]]$chars = $Text.ToCharArray()
	for($idx=0; $idx -lt $chars.Count; $idx++) {
		if    ($charsOpen -contains $chars[$idx]) { $depth++ }
		elseif($charsClose -contains $chars[$idx]) { $depth-- }
		elseif(($depth -eq 0) -and ($chars[$idx] -eq $Delim)) {
			$out += $Text.Substring( ($idxDelimPrev + 1), ($idx - $idxDelimPrev - 1) )
			$idxDelimPrev = $idx
		}
		if($depth -lt 0) {
			throw "Brackets are not balanced. In expression: $Text"
		}
	}
	if($depth -ne 0) {
		throw "Brackets are not balanced. In expression: $Text"
	}
	$out += $Text.Substring( ($idxDelimPrev + 1), ($idx - $idxDelimPrev - 1) )
	if($Trim) {
		$out = $out | ForEach-Object { $_.Trim() }
	}
	return $out
}


function SplitBalancedBrackets([String]$Text) {
	$charOpen = $Text.Substring(0,1)
	if    ($charOpen -eq '(') { $charClose = ')' }
	elseif($charOpen -eq '[') { $charClose = ']' }
	elseif($charOpen -eq '{') { $charClose = '}' }
	else {
		throw "First char is not an open bracket. In expression: $Text"
	}

	[Int32]$idx = 0
	[Int32]$depth = 0
	[Char[]]$chars = $Text.ToCharArray()
	for($idx=0; $idx -lt $chars.Count; $idx++) {
		if    ($chars[$idx] -eq $charOpen) { $depth++ }
		elseif($chars[$idx] -eq $charClose) { $depth-- }
		if($depth -eq 0) {
			break
		}
	}
	if($depth -ne 0) {
		throw "Close bracket not found. In expression: $Text"
	}

	return [PSCustomObject]@{
		Bracketed = $Text.Substring(0, $idx+1)
		Contained = $Text.Substring(1, $idx-1)
		Remainder = $Text.Substring($idx+1)
	}
}


################################################################################################
## Parse 1
################################################
class Parse1 {
[PSObject] ParseLinePropertiesOrMethods([String]$Line) {
	# NOTES
	#	Dependent properties shall be assumed to be read only (assume there is a getter but no setter)
	#	Hidden does not effect get/set => ignore

	$delim = '[,\(\)]'
	$notDelim = '[^,\(\)]'
	$regexAttributes   = "^(?<blockType>methods|properties)\s*(?:\((?:(?<attributes>$notDelim*)$delim)*)?\s*$"
	$regexPrivate      = '^Access\s*=\s*private$'
	$regexProtected    = '^Access\s*=\s*protected$'
	# Properties only
	$regexSetImmutable = '^SetAccess\s*=\s*immutable$'
	$regexSetPrivate   = '^SetAccess\s*=\s*private$'
	$regexSetProtected = '^SetAccess\s*=\s*protected$'
	$regexGetPrivate   = '^GetAccess\s*=\s*private$'
	$regexGetProtected = '^GetAccess\s*=\s*protected$'
	$regexDependent    = '^Dependent(?:\s*=\s*true)?$'
	$regexHidden       = '^Hidden(?:\s*=\s*true)?$'
	# Methods only
	$regexStatic       = '^Static(?:\s*=\s*true)?$'
	$regexSealed       = '^Sealed(?:\s*=\s*true)?$'

	$matchAttributes = [System.Text.RegularExpressions.Regex]::Match($Line, $regexAttributes)
	if(-not $matchAttributes.Success) {
		throw "Properties/Methods block not fully matched: " + $Line
	}

	[Boolean]$userCanCall = $true
	[Boolean]$userCanRead = $true
	[Boolean]$userCanSet = $true
	[Boolean]$isStatic = $false
	$isMethod = $matchAttributes.Groups['blockType'].Value -eq "methods"
	$attributes = ($matchAttributes.Groups['attributes'].Captures | Select-Object -ExpandProperty Value)
	foreach ($attribute in $attributes) {
		$attribute = $attribute.Trim()
		if     ($isMethod -and ($attribute -match $regexPrivate))   { $userCanCall=$false }
		elseif ($isMethod -and ($attribute -match $regexProtected)) { $userCanCall=$false }
		elseif ($isMethod -and ($attribute -match $regexStatic))    { $isStatic = $true }
		elseif ($isMethod -and ($attribute -match $regexSealed)) { }
		elseif ((-not $isMethod) -and ($attribute -match $regexPrivate))   { $userCanSet=$false; $userCanRead=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexProtected)) { $userCanSet=$false; $userCanRead=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexSetImmutable)) { $userCanSet=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexSetPrivate))   { $userCanSet=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexSetProtected)) { $userCanSet=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexGetPrivate))   { $userCanRead=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexGetProtected)) { $userCanRead=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexDependent))    { $userCanSet=$false }
		elseif ((-not $isMethod) -and ($attribute -match $regexHidden))    { }
		else {
			throw "An attribute of the Properties/Methods block failed to match: " + $Line + " : " + $attribute
		}
	}
	if($isMethod) { return [PSCustomObject]@{
		UserCanCall=$userCanCall;
		IsStatic=$isStatic
	}}
	return [PSCustomObject]@{
		UserCanRead = $userCanRead
		UserCanSet = $userCanSet
	}
}


[PropRecord] ParseLineProp([String]$Line) {
	# NOTES
	#   Lets assume that the validators can't have "=" or "%" inside them
	#   They can have braces and commas inside them though => can't be passed with regex
	$op = '\('
	$cp = '\)'
	$os = '\['
	$cs = '\]'
	$ob = '\{'
	$cb = '\}'
	$s = '\s*'
	$regexDims = "$op$s(?<dim1>[\w:]+)$s,$s(?<dim2>[\w:]+)$s$cp"
	$regexValidators = "$ob$s(?<validators>[^=%]+)$s$cb"
	$default = "=$s(?<default>[^=%]+)"
	$comment = "%$s(?<comment>.+)"
	$regexProp   = "^$s(?<name>[\w~\.]+)$s(?:$regexDims)?(?:\s+(?<type>[\w\.]+))?$s(?:$regexValidators)?$s(?:$default)?(?:$comment)?$"

	$matchProp = [System.Text.RegularExpressions.Regex]::Match($Line, $regexProp)
	if(-not $matchProp.Success) {
		throw "Property failed to match: " + $Line
	}
	$propName = $matchProp.Groups['name'].Value

	# Distinguish not specified from (:,:) by leaving blank instead of null
	$dim1 = $matchProp.Groups['dim1'].Success ? $matchProp.Groups['dim1'].Value : $null
	$dim2 = $matchProp.Groups['dim2'].Success ? $matchProp.Groups['dim2'].Value : $null
	if(($null -eq $dim1) -and ($null -eq $dim2)) {
		$sizes = [System.Nullable[Int32][]]@()
	}
	else {
		$dim1 = ($dim1 -eq ':') ? $null : $dim1
		$dim2 = ($dim2 -eq ':') ? $null : $dim2
		$sizes = [System.Nullable[Int32][]]@($dim1, $dim2)
	}

	$mustBeA = [String[]]@()
	$mustBeMember = [String[]]@()
	$mustBe_Booleans = [String[]]@()
	if($matchProp.Groups['validators'].Success) {
		$validatorsStr = $matchProp.Groups['validators'].Value.Trim()

		# Based on actual usage, we can assume more structure on the validators
		# Throw errors if it doesn't match
		$regexValidator = "^(?<name>\w+)\b$s(?:$op$s$propName$s,$s$os(?<args>[^$cs$cp]+)$cs$s$cp)?$s(?:,(?<next>.+))?"
		$regexValidatorQuoted = "^$s(""(?<arg>\w+)""|'(?<arg>\w+)')$s$"

		while($true) {
			$matchValidator = [System.Text.RegularExpressions.Regex]::Match($validatorsStr, $regexValidator)
			if(-not $matchValidator.Success) {
				throw "Property validator to match: " + $validatorsStr
			}
			$validatorName = $matchValidator.Groups['name'].Value
			if($validatorName -eq 'mustBeA') {
				if(-not $matchValidator.Groups['args'].Success) {
					throw "Property validator to match (mustBeA): " + $validatorsStr
				}
				$mustBeA = $matchValidator.Groups['args'].Value.Split(",").Trim()
				# Remove quotes
				$mustBeA = $mustBeA | ForEach-Object {
					($_ -match $regexValidatorQuoted) ? $Matches['arg'] : (throw "Property validator to match (mustBeA)")
				}
			}
			elseif($validatorName -eq 'mustBeMember') {
				if(-not $matchValidator.Groups['args'].Success) {
					throw "Property validator to match (mustBeMember): " + $validatorsStr
				}
				$mustBeMember = $matchValidator.Groups['args'].Value.Split(",").Trim()
			}
			elseif($script:tokens_mustBeBooleans -contains $validatorName) {
				$mustBe_Booleans += $validatorName
			}
			else {
				throw "Parsing for property validator ($validatorName) not yet implemented: " + $validatorsStr
			}
			if($matchValidator.Groups['next'].Success) {
				$validatorsStr = $matchValidator.Groups['next'].Value.Trim()
			}
			else {
				break
			}
		}
	}

	# Attributes directly from line only
	# Other attributes to be set by caller
	$out = [PropRecord]@{
		Name  = $propName
		Sizes = $sizes
		Type  = $matchProp.Groups['type'].Success ? $matchProp.Groups['type'].Value : $null
		MustBeA         = $mustBeA
		MustBeMember    = $mustBeMember
		MustBe_Booleans = $mustBe_Booleans
		DefaultValue = $matchProp.Groups['default'].Success ? $matchProp.Groups['default'].Value.Trim() : $null
		InlineComment = $matchProp.Groups['comment'].Success ? $matchProp.Groups['comment'].Value.Trim() : ''
	}
	return $out
}

[PSObject] ParseLineMethodSignature([String]$Line) {
	$op = '\('
	$cp = '\)'
	$os = '\['
	$cs = '\]'
	$s = '\s*'
	$regexMultipleReturns = "^$s(?:$s$os(?<retVars>[\w\s,]+)$cs$s)$"
	$regexMethodLine = "^    function\s+(?:(?<out>[^=]+)=$s)?(?<get>get\.)?(?<name>\w+)$s$op(?:(?<args>[~$s,\w]*))$cp$s(?<oneLine>;.+)?"

	$matchMethod = [System.Text.RegularExpressions.Regex]::Match($line, $regexMethodLine)
	if(-not $matchMethod.Success) {
		throw "Method line not fully matched: " + $line
	}

	$isOneLine = $matchMethod.Groups['oneLine'].Success
	$argStr   = $matchMethod.Groups['args'].Success ? $matchMethod.Groups['args'].Value : ''

	[String]$retStr = ''
	if($matchMethod.Groups['out'].Success) {
		$retStr = $matchMethod.Groups['out'].Value.Trim()
		if($retStr -match $regexMultipleReturns) {
			$retStr = $Matches['retVars']
		}
	}

	# Attributes directly from line only
	# Other attributes to be set by caller
	$out = [MethodRecord]@{
		Name          = $matchMethod.Groups['name'].Value
		IsGetter      = $matchMethod.Groups['get'].Success
		ReturnStrings = ($retStr -eq '') ? @() : $retStr.Split(",") | ForEach-Object { $_.Trim() }
		ArgStrings    = ($argStr -eq '') ? @() : $argStr.Split(",") | ForEach-Object { $_.Trim() }
	}
	return [PSCustomObject]@{
		Record = $out
		IsOneLine = $isOneLine
	}
}


[ClassRecord] ParseFile([String]$RelativePath, [System.IO.FileInfo]$FileObject)	{
	$className = $FileObject.BaseName
	$out = [ClassRecord]@{
		RelativePath = $RelativePath
		Name = $className
		Super = $null
	}

	# If the 2nd line in the file matches this string exactly, then skip the file
	If ((Get-Content -LiteralPath $FileObject.FullName -TotalCount 2)[-1] -eq "Intended for internal use only") {
		return $out;
	}

	$op = '\('
	$cp = '\)'
	$s = '\s*'
	$regexTreatPrivateFlag = "^${s}Intended for internal use only$s$"
	$regexStarDelimCommentS = "^$s%\*{70}$s$"
	$regexStarDelimCommentE = "^$s%\*{35}$s$"
	$regexBlockCommentS = "^$s%\{"
	$regexBlockCommentE = "^$s%\}"
	$regexComment = "^$s%(?<comment>.+)?"
	$regexClassdefParen = "$op$s(?:(?<abs>Abstract)|(?<inferior>InferiorClasses.+?))$s$cp"
	$regexClassdef      = "^classdef\b"
	$regexClassdefLine  = "^classdef\b$s(?:$regexClassdefParen)?$s\w+(?:$s[<&]$s(?<super>[\w\.]+))*$s$"
	$regexProperties = "^properties\b"
	$regexMethods    = "^methods\b"
	$regexBlockEnd   = "^end\b"
	$regexMethod     = "^    function\b"
	$regexMethodEnd  = "^    end\b"
	$regexArgs       = "^        arguments\b"
	$regexArgsLine   = "^        arguments\s*(?<repeating>$op${s}Repeating$s$cp)?$"
	$regexArgsEnd    = "^        end\b"

	[ParseContextMain]$contextMain = [ParseContextMain]::FileHead
	[ParseContextMain]$contextMain_ReturnTo = [ParseContextMain]::FileHead
	[Boolean]$contextUserCanCall = $false
	[Boolean]$contextUserCanRead = $false
	[Boolean]$contextUserCanSet = $false
	[Boolean]$contextStatic = $false
	[Boolean]$wasClassdefFound = $false
	[PropGroupRecord]$holdPropGroup = [PropGroupRecord]::new()
	[MethodGroupRecord]$holdMethodGroup = [MethodGroupRecord]::new()
	[MethodRecord]$holdMethod = [MethodRecord]::new()
	[ArgumentsRecord]$holdArgBlock = [ArgumentsRecord]::new()
	foreach ($line in Get-Content -LiteralPath $FileObject.FullName) {
		# Context independent
		# Find start of the signature, then do full match
		if($line -match $regexClassdef) {
			$matchClassdef = [System.Text.RegularExpressions.Regex]::Match($line, $regexClassdefLine)
			if(-not $matchClassdef.Success) {
				throw "($className) Classdef line not fully matched: " + $line
			}
			if($wasClassdefFound) {
				throw "($className) Classdef line found multiple times: " + $line
			}
			$wasClassdefFound = $true
			$out.IsAbstract = $matchClassdef.Groups['abs'].Success
			$out.Super     = ($matchClassdef.Groups['super'].Captures | Select-Object -ExpandProperty Value)
			continue
		}
		if($line -match $regexProperties) {
			$attributes = $this.ParseLinePropertiesOrMethods($line)
			$contextUserCanRead = $attributes.UserCanRead
			$contextUserCanSet  = $attributes.UserCanSet
			$contextMain = [ParseContextMain]::PropertiesBlock
			continue
		}
		if($line -match $regexMethods) {
			$attributes = $this.ParseLinePropertiesOrMethods($line)
			$contextUserCanCall = $attributes.UserCanCall
			$contextStatic      = $attributes.IsStatic
			$contextMain = [ParseContextMain]::MethodsBlock
			continue
		}

		# Context dependent
		if($contextMain -eq [ParseContextMain]::FileHead) {
			if($line -match $regexBlockCommentS) { $contextMain = [ParseContextMain]::FileHeadComment; continue }
		}
		elseif($contextMain -eq [ParseContextMain]::FileHeadComment) {
			if ($line -match $regexBlockCommentE) { $contextMain = [ParseContextMain]::FileHead; continue }
			$out.HeadComment += $line
		}
		elseif($contextMain -eq [ParseContextMain]::PropertiesBlock) {
			# Skip private
			# Skip blank
			# Skip properties block end
			if((-not $contextUserCanRead) -and (-not $contextUserCanSet)) { continue }
			if($line.Trim() -eq '')    { continue }
			if($line -match $regexBlockEnd) { continue }

			# Skip star delimited comments
			if ($line -match $regexStarDelimCommentS) {
				$contextMain_ReturnTo = $contextMain
				$contextMain = [ParseContextMain]::StarDelimComment
				continue
			}

			# Accumulate comments above property
			if($line -match $regexComment) {
				$holdPropGroup = [PropGroupRecord]::new()
				$holdPropGroup.HeadComment += $Matches['comment'];
				$contextMain = [ParseContextMain]::PropertiesComment
				continue
			}

			# Error on property
			throw "($className) Property missing preceding comment: " + $line
		}
		elseif($contextMain -eq [ParseContextMain]::PropertiesComment) {
			# Error on detached comments
			if($line.Trim() -eq '') {
				throw "($className) Dangling comment: " + $holdPropGroup.HeadComment
			}

			# Accumulate comments above the property
			if($line -match $regexComment) {
				$holdPropGroup.HeadComment += $Matches['comment'];
				continue
			}

			# Match property or error
			$prop = $this.ParseLineProp($line)
			$prop.UserCanRead = $contextUserCanRead
			$prop.UserCanSet = $contextUserCanSet
			$holdPropGroup.Props += $prop
			$contextMain = [ParseContextMain]::PropertiesGroup
			continue
		}
		elseif($contextMain -eq [ParseContextMain]::PropertiesGroup) {
			# Detect end of group (newline or block end)
			# Commit, unless "Intended for internal use only"
			if(($line.Trim() -eq '') -or ($line -match $regexBlockEnd)) {
				if(-not ($holdPropGroup.HeadComment[0] -match $regexTreatPrivateFlag)) {
					$out.PropGroups += $holdPropGroup
				}
				$contextMain = [ParseContextMain]::PropertiesBlock
				continue
			}

			# Match property or error
			$prop = $this.ParseLineProp($line)
			$prop.UserCanRead = $contextUserCanRead
			$prop.UserCanSet = $contextUserCanSet
			$holdPropGroup.Props += $prop
			$contextMain = [ParseContextMain]::PropertiesGroup
			continue
		}
		elseif($contextMain -eq [ParseContextMain]::MethodsBlock) {
			# Skip private
			# Skip blank
			if(-not $contextUserCanCall) { continue }
			if($line.Trim() -eq '') { continue }

			# Skip star delimited comments
			if ($line -match $regexStarDelimCommentS) {
				$contextMain_ReturnTo = $contextMain
				$contextMain = [ParseContextMain]::StarDelimComment
				continue
			}

			# Accumulate comments above method function signature
			if($line -match $regexComment) {
				$holdMethodGroup = [MethodGroupRecord]::new()
				$holdMethodGroup.HeadComment += $Matches['comment'];
				$contextMain = [ParseContextMain]::MethodsComment
				continue
			}

			# Error on method start
			if($line -match $regexMethod) {
				throw "($className) Function signature missing preceding comment: " + $line
			}
		}
		elseif($contextMain -eq [ParseContextMain]::MethodsComment) {
			# Error on detached comments
			if($line.Trim() -eq '') {
				throw "($className) Dangling comment: " + $holdMethodGroup.HeadComment
			}

			# Accumulate comments above method function signature
			if($line -match $regexComment) {
				$holdMethodGroup.HeadComment += $Matches['comment'];
				continue
			}

			# Match start of method
			if($line -match $regexMethod) {
				$ret = $this.ParseLineMethodSignature($line)
				$holdMethod = $ret.Record
				$isOneLine =  $ret.IsOneLine
				$holdMethod.IsStatic = $contextStatic

				# Special case for one line method: finalise record
				if($isOneLine) {
					$holdMethodGroup.Methods += $holdMethod
					$contextMain = [ParseContextMain]::MethodsGroup
					continue
				}
				$contextMain = [ParseContextMain]::MethodBody
				continue
			}
		}
		elseif($contextMain -eq [ParseContextMain]::MethodsGroup) {
			# Match start of method
			if($line -match $regexMethod) {
				$ret = $this.ParseLineMethodSignature($line)
				$holdMethod = $ret.Record
				$isOneLine =  $ret.IsOneLine
				$holdMethod.IsStatic = $contextStatic

				# Special case for one line method: finalise record
				if($isOneLine) {
					$holdMethodGroup.Methods += $holdMethod
					continue
				}
				$contextMain = [ParseContextMain]::MethodBody
				continue
			}

			# Detect end of group (newline or block end)
			# Commit, unless "Intended for internal use only"
			if(($line.Trim() -eq '') -or ($line -match $regexBlockEnd)) {
				if(-not ($holdMethodGroup.HeadComment[0] -match $regexTreatPrivateFlag)) {
					$out.MethodGroups += $holdMethodGroup
				}
				$contextMain = [ParseContextMain]::MethodsBlock
				continue
			}
		}
		elseif($contextMain -eq [ParseContextMain]::MethodBody) {
			# Start of arguments block
			if($line -match $regexArgs) {
				$matchArgs = [System.Text.RegularExpressions.Regex]::Match($line, $regexArgsLine)
				if(-not $matchArgs.Success) {
					throw "($className) Method arguments line not fully matched: " + $line
				}
				$holdArgBlock = [ArgumentsRecord]::new()
				$holdArgBlock.IsRepeating = $matchArgs.Groups['repeating'].Success
				$contextMain = [ParseContextMain]::MethodArgs
				continue
			}

			# End of method block: Finalise record
			if($line -match $regexMethodEnd) {
				$holdMethodGroup.Methods += $holdMethod
				$contextMain = [ParseContextMain]::MethodsGroup
				continue
			}
		}
		elseif($contextMain -eq [ParseContextMain]::MethodArgs) {
			# At end of arguments block: Finalise record
			if($line -match $regexArgsEnd) {
				$holdMethod.ArgBlocks += $holdArgBlock
				$contextMain = [ParseContextMain]::MethodBody
				continue
			}

			# New argument
			$prop = $this.ParseLineProp($line)
			$holdArgBlock.Args += $prop
		}
		elseif($contextMain -eq [ParseContextMain]::StarDelimComment) {
			if ($line -match $regexStarDelimCommentE) {
				$contextMain = $contextMain_ReturnTo;
				continue
			}
			if(-not ($line -match $regexComment)) {
					throw "($className) Inside/End of star delimited comment not matched: " + $line
			}
		}
	}

	if(-not $wasClassdefFound) { throw "($className) classdef statement not found" }

	return $out;
}
}


################################################################################################
## Parse 2
################################################
class Parse2 {
[ArgRecord2[]] Args2FromSignature([MethodRecord]$Method) {
	[ArgRecord2[]]$out = @()
	foreach($argString in $Method.ArgStrings) {
		if($argString -eq 'varargin') { $argBlockType = [ArgBlockType2]::Repeating }
		else                          { $argBlockType = [ArgBlockType2]::Normal }
		$out += [ArgRecord2]@{
			ArgBlockType = $argBlockType
			Name = $argString
			Sizes = @()
			TypesOrMembers = @()
			AreTypesMembers = $false
			MustBe_Booleans = @()
			DefaultValue = ''
			InlineComment = @()
		}
	}
	return $out
}


[ArgRecord2[]] Args2FromBlock([String]$ClassName, [MethodRecord]$Method) {
	[ArgRecord2[]]$out = @()
	$regexPropNameValue = "^(?<optionsName>[\w]+)\.(?<name>[\w]+)$"

	# By matlab language rules, we can unambiguously attribute ArgBlockType2 to the arg
	#	Repeating can at most appear once (thus, all repeating appear together anyway)
	#	NameValue always appears last
	# Therefore, we can drop the ArgBlocks grouping

	$nameValueEncountered = $false
	foreach($argBlock in $Method.ArgBlocks) {
		foreach($arg in $argBlock.Args) {
			$argBlockType = $argBlock.IsRepeating ? [ArgBlockType2]::Repeating : [ArgBlockType2]::Normal
			$argName = $arg.Name
			if($arg.Name -match $regexPropNameValue) {
				$nameValueEncountered = $true
				if($argBlock.IsRepeating) {
					throw "($ClassName.$($Method.Name) : $argName) NameValue found in repeating arguments block"
				}
				$argBlockType = [ArgBlockType2]::NameValue
				$argName = $Matches['name']
			}
			elseif($nameValueEncountered) {
				throw "($ClassName.$($Method.Name) : $argName) Normal argument encountered after NameValue argument"
			}

			$ret_TypesOrMembers = $this.TypesOrMembersFromProp($className, $arg)
			$out += [ArgRecord2]@{
				ArgBlockType    = $argBlockType
				Name            = $argName
				Sizes           = $arg.Sizes
				TypesOrMembers  = $ret_TypesOrMembers.TypesOrMembers
				AreTypesMembers = $ret_TypesOrMembers.AreTypesMembers
				MustBe_Booleans = $arg.MustBe_Booleans
				DefaultValue    = $arg.DefaultValue
				InlineComment   = $arg.InlineComment -ne '' ? $arg.InlineComment : @()
			}
		}
	}
	return $out
}


[PSObject] TypesOrMembersFromProp([String]$ClassName,[PropRecord]$Prop) {
	[Boolean]$areTypesMembers = ($Prop.MustBeMember.Count -ne 0)
	[String[]]$typesOrMembers = @()
	if($areTypesMembers) {
		$typesOrMembers = $Prop.MustBeMember
	}
	elseif($Prop.MustBeA.Count -ne 0) {
		if($Prop.Type -ne '') { throw "($ClassName.$($Prop.Name)) Property with MustBeA should not have a set type" }
		$typesOrMembers = $Prop.MustBeA
	}
	else {
		$typesOrMembers = $Prop.Type -eq '' ? @() : @($Prop.Type)
	}
	return [PSCustomObject]@{
		AreTypesMembers = $areTypesMembers
		TypesOrMembers = $typesOrMembers
	}
}


[String[]] NormalisePercentLeadingCommentBlock([String]$ErrorMsgPre, [String[]]$CommentBlock) {
	# Normalise spaces in comment blocks like
	#% TITLE
	#%   Content
	# to
	#TITLE
	#    Content
	# Where the % has already been stripped in parse 1

	$regexLevel0      = "^ (?<text>\S.*)$"
	$regexLevelsOther = "^   (?<text>( {4})*\S.*)$"

	[String[]]$out = @()
	foreach($line in $CommentBlock) {
		if    ($line -match $regexLevel0)      { $out += $Matches['text'] }
		elseif($line -match $regexLevelsOther) { $out += " $line" }
		else {
			throw "$ErrorMsgPre failed to normalise whitespace on line: $line"
		}
	}
	return $out
}

[ClassRecord2] ParseRound2([ClassRecord]$Class) {
	$className = $Class.Name
	$out = [ClassRecord2]@{
		RelativePath = $Class.RelativePath
		Name         = $Class.Name
		IsAbstract   = $Class.IsAbstract
		Super        = $Class.Super ?? @()
		HeadComment  = $Class.HeadComment
	}

	foreach($propGroup in $Class.PropGroups) {
		$ErrorMsgPre = "($className.$($propGroup.Props[0].Name))"
		$propGroup2 = [PropGroupRecord2]@{
			HeadComment = $this.NormalisePercentLeadingCommentBlock($ErrorMsgPre, $propGroup.HeadComment)
		}
		foreach($prop in $propGroup.Props) {
			$ret_TypesOrMembers = $this.TypesOrMembersFromProp($className, $prop)
			$prop2 = [PropRecord2]@{
				UserCanRead     = $prop.UserCanRead
				UserCanSet      = $prop.UserCanSet
				Name            = $prop.Name
				Sizes           = $prop.Sizes
				TypesOrMembers  = $ret_TypesOrMembers.TypesOrMembers
				AreTypesMembers = $ret_TypesOrMembers.AreTypesMembers
				MustBe_Booleans = $prop.MustBe_Booleans
				DefaultValue    = $prop.DefaultValue
				InlineComment   = $prop.InlineComment
			}
			$propGroup2.Props += $prop2
		}
		$out.PropGroups += $propGroup2
	}

	foreach($methodGroup in $Class.MethodGroups) {
		$methodGroup2 = $null
		foreach($method in $methodGroup.Methods) {
			[ArgRecord2[]]$args2 = @()
			if($method.ArgBlocks.Count -eq 0) { $args2 = $this.Args2FromSignature($method) }
			else                              { $args2 = $this.Args2FromBlock($Class.Name, $method) }

			# Remove "this" (not present in constructor, overloads, or if static)
			# Determine support for method call from object arrays
			#   Static methods do not support
			#   Constructors not applicable
			#   Overloads generally do support
			[Boolean]$isConstructor = ($method.Name -eq $className)
			[Boolean]$supportsObjectArrays = ((-not $method.IsStatic) -and (-not $isConstructor))
			$operatorOverloads = @('eq','ne','mtimes','findobj')
			if((-not $method.IsStatic) -and (-not $isConstructor) -and ($operatorOverloads -notcontains $Method.Name)) {
				if(-not (@('this', '~') -contains $method.ArgStrings[0])) {
					throw "($className.$($method.Name)) Cannot detect 'this' in function signature"
				}
				# Drop arg 'this'
				$argThis = $args2[0]
				$args2 = ($args2.Count -gt 1) ? @($args2[1..($args2.Count - 1)]) : [ArgRecord2[]]@()

				if(($argThis.Sizes.Count -eq 0)) {
					# Use setting from outside of loop
				}
				elseif(($argThis.Sizes.Count -eq 2) -and ($argThis.Sizes[0] -eq 1) -and ($argThis.Sizes[1] -eq 1)) {
					$supportsObjectArrays = $false
				}
				else {
					throw "($className.$($method.Name)) 'this' in function signature supports limited object array sizes"
				}
			}

			[RetRecord2[]]$returns = @()
			foreach($ret in $method.ReturnStrings) {
				$returns += [RetRecord2]@{ Name = $ret }
			}

			if($method.IsGetter) {
				# Corresponding prop already has UserCanRead=$true
				# Just skip to remove getter
				continue
			}

			if($null -eq $methodGroup2) {
				$ErrorMsgPre = "($className.$($method.Name))"
				# Create group
				$methodGroup2 = [MethodGroupRecord2]@{
					HeadComment = $this.NormalisePercentLeadingCommentBlock($ErrorMsgPre, $methodGroup.HeadComment)
					Names     = @($method.Name)
					IsStatic = $method.IsStatic
					Returns  = $returns
					SupportsObjectArrays = $supportsObjectArrays
					Args = $args2
				}
				continue
			}

			# Enforce all methods in group are identical in everything but name
			# Then add to group
			$errorMsgPre = "($className.$($method.Name)) Unmatched grouped methods:"
			if($methodGroup2.IsStatic -ne $method.IsStatic) {
				throw "$errorMsgPre Static attribute"
			}
			if($methodGroup2.SupportsObjectArrays -ne $supportsObjectArrays) {
				throw "$errorMsgPre object array support"
			}
			if($methodGroup2.Returns.Count -ne $returns.Count) {
				throw "$errorMsgPre number of returns"
			}
			if($methodGroup2.Args.Count -ne $args2.Count) {
				throw "$errorMsgPre number of arguments"
			}
			for($idx=0; $idx -lt $methodGroup2.Returns.Count; $idx++) {
				$r0 = $methodGroup2.Returns[$idx]
				$r = $returns[$idx]
				if($r0.Name -ne $r.Name) { throw "$errorMsgPre returns: Name" }
			}
			for($idx=0; $idx -lt $methodGroup2.Args.Count; $idx++) {
				$a0 = $methodGroup2.Args[$idx]
				$a = $args2[$idx]
				if($a0.ArgBlockType -ne $a.ArgBlockType)       { throw "$errorMsgPre arguments: ArgBlockType" }
				if($a0.Name -ne $a.Name)                       { throw "$errorMsgPre arguments: Name" }
				if($a0.AreTypesMembers -ne $a.AreTypesMembers) { throw "$errorMsgPre arguments: AreTypesMembers" }
				if($a0.DefaultValue -ne $a.DefaultValue)       { throw "$errorMsgPre arguments: DefaultValue" }
				if(-not (AreArraysEqual $a0.Sizes $a.Sizes))        { throw "$errorMsgPre arguments: Sizes" }
				if(-not (AreArraysEqual $a0.TypesOrMembers $a.TypesOrMembers))   { throw "$errorMsgPre arguments: TypesOrMembers" }
				if(-not (AreArraysEqual $a0.MustBe_Booleans $a.MustBe_Booleans)) { throw "$errorMsgPre arguments: MustBe_Booleans" }
				if(-not (AreArraysEqual $a0.InlineComment $a.InlineComment))     { throw "$errorMsgPre arguments: InlineComment" }
			}
			$methodGroup2.Names += $method.Name
		}
		# Guard empty for removed getters
		if($null -eq $methodGroup2) { continue }

		$out.MethodGroups += $methodGroup2
	}

	return $out
}
}


################################################################################################
## Parse 3
################################################
class Parse3 {
	[String[]]$AllClassNames

[Void] ParseRound3([ClassRecord2]$Class) {
	$className = $Class.Name

	$blocks = $this.ClassHeadCommentToBlocks($className, $class.HeadComment)
	$Class.CommentClass = [CommentClass]@{
		ShortDescription = $blocks.Description
		FreeBlocks = $blocks.BlocksOther
		Examples = $blocks.BlocksExamples
	}

	foreach($propGroup in $class.PropGroups) {
		$this.WriteCommentVariables_Props($className, $propGroup)
	}

	foreach($methodGroup in $class.MethodGroups) {
		$blocks = $this.MethodGroupHeadCommentToBlocks($className, $methodGroup.Names[0], $methodGroup.HeadComment)

		# Type is validated against the main tree
		#    To match the arguments block: during the call WriteCommentVariables_Inputs()
		# VALIDATIONS NOT IMPLEMENTED
		# Dims is NOT validated against the main tree
		#    To match the arguments block. This could be done during the call RenderSizes()
		#    To be real matlab or CDS classes
		# Matching of the arguments block type and between the comment input block and the args block is NOT validated
		#    The args block version is always used => fail case doesn't even effect the rendered docs
		$this.WriteCommentVariables_Inputs($className, $methodGroup, $blocks.BlockInput)
		$this.WriteCommentVariables_Outputs($className, $methodGroup, $blocks.BlockOutput)

		$methodGroup.CommentMethod = [CommentMethod]@{
			ShortDescription = $blocks.Description
			FreeBlocks = $blocks.BlocksOther
			SideEffects = $blocks.BlockSideEffects
			Examples = $blocks.BlocksExamples
		}

		foreach($arg in $methodGroup.Args) {
			if($arg.InlineComment.Count -ne 0) { throw "Comments inline to arguments are not permitted" }
		}
	}
}


[PSObject] HeadCommentToBlocks([String]$ErrorMsgPre, [String[]]$HeadComment) {
	# (?-i) disables case insensitive matching
	$regexDescription = "^(?<text>\S.*)$"
	$regexBlockContent = "^    (?<text>( {4})*\S.*)$"
	$regexBlockName = "(?-i)^(?<text>[A-Z][A-Z ]*( \d)?|INPUT \(Repeating\)|INPUT \(Name=Value\))$"

	[String[]]$description = @()
	[CommentBlock[]]$blocks = @()
	[CommentBlock]$block = $null
	[Boolean]$isDescriptionEnded = $false
	foreach($line in $HeadComment) {
		if($line -eq '') {
			# Skip blank lines (found in class head comments)
			continue
		}
		elseif($line -match $regexBlockName) {
			$isDescriptionEnded = $true

			# Save previous block and create new block
			if($null -ne $block) {
				$blocks += $block
			}
			$block = [CommentBlock]@{ Name = $Matches['text'] }
		}
		elseif((-not $isDescriptionEnded) -and ($line -match $regexDescription)) {
			$description += $Matches['text']
		}
		elseif($isDescriptionEnded -and ($line -match $regexBlockContent)) {
			$block.Content += $Matches['text']
		}
		else {
			throw "$ErrorMsgPre failed to parse on line: $line"
		}
	}
	# Save final block
	if($null -ne $block) {
		$blocks += $block
	}
	return [PSCustomObject]@{
		Description = $description
		Blocks = $blocks
	}
}


[PSObject] ClassHeadCommentToBlocks([String]$ClassName, [String[]]$ClassHeadComment) {
	$errorMsgPre = "($className) Class Head Comment:"

	$ret = $this.HeadCommentToBlocks($errorMsgPre, $ClassHeadComment)
	$blocks = $ret.Blocks
	$description = $ret.Description

	# Sort, and asset unique where applicable
	[CommentBlock[]]$blocksExamples = @()
	[CommentBlock[]]$blocksInternal = @()
	[CommentBlock[]]$blocksOther = @()
	foreach($block in $blocks) {
		if    ($block.Name -eq "EXAMPLE")  { $blocksExamples += $block }
		elseif($block.Name -eq "INTERNAL") { $blocksInternal += $block }
		else                               { $blocksOther += $block }
	}
	return [PSCustomObject]@{
		Description = $description
		Blocks = $blocks
		BlocksInternal = $blocksInternal
		BlocksExamples = $blocksExamples
		BlocksOther = $blocksOther
	}
}


[PSObject] MethodGroupHeadCommentToBlocks([String]$ClassName, [String]$MethodName, [String[]]$MethodGroupHeadComment) {
	$errorMsgPre = "($className.$MethodName) Method Group Head Comment:"

	$ret = $this.HeadCommentToBlocks($errorMsgPre, $MethodGroupHeadComment)
	$blocks = $ret.Blocks
	$description = $ret.Description

	# Sort, and asset unique where applicable
	[CommentBlock]$blockInput = $null
	[CommentBlock]$blockInputR = $null
	[CommentBlock]$blockInputNV = $null
	[CommentBlock]$blockOutput = $null
	[CommentBlock]$blockSideEffects = $null
	[CommentBlock[]]$blocksExamples = @()
	[CommentBlock[]]$blocksOther = @()
	foreach($block in $blocks) {
		if($block.Name -eq "INPUT") {
			if($null -eq $blockInput) { $blockInput = $block }
			else { throw "$errorMsgPre found multiple INPUT blocks" }
		}
		elseif($block.Name -eq "INPUT (Repeating)") {
			if($null -eq $blockInputR) { $blockInputR = $block }
			else { throw "$errorMsgPre found multiple INPUT (Repeating) blocks" }
		}
		elseif($block.Name -eq "INPUT (Name=Value)") {
			if($null -eq $blockInputNV) { $blockInputNV = $block }
			else { throw "$errorMsgPre found multiple INPUT (Name=Value) blocks" }
		}
		elseif($block.Name -eq "OUTPUT") {
			if($null -eq $blockOutput) { $blockOutput = $block }
			else { throw "$errorMsgPre found multiple OUTPUT blocks" }
		}
		elseif($block.Name -eq "SIDE EFFECTS") {
			if($null -eq $blockSideEffects) { $blockSideEffects = $block }
			else { throw "$errorMsgPre found multiple SIDE EFFECTS blocks" }
		}
		elseif($block.Name -eq "EXAMPLE") {
			$blocksExamples += $block
		}
		else {
			$blocksOther += $block
		}
	}

	# Merge input blocks
	$blockAllInputs = [CommentBlock]@{ Name = "INPUT" }
	if($null -ne $blockInput) { $blockAllInputs.Content += $blockInput.Content }
	if($null -ne $blockInputR) { $blockAllInputs.Content += $blockInputR.Content }
	if($null -ne $blockInputNV) { $blockAllInputs.Content += $blockInputNV.Content }
	if($blockAllInputs.Content.Count -eq 0) {
		$blockAllInputs = $null
	}

	return [PSCustomObject]@{
		Description = $description
		Blocks = $blocks
		BlockInput = $blockAllInputs
		BlockOutput = $blockOutput
		BlockSideEffects = $blockSideEffects
		BlocksExamples = $blocksExamples
		BlocksOther = $blocksOther
	}
}


[void] WriteCommentVariables_Inputs([String]$ClassName, [MethodGroupRecord2]$MethodGroup, [CommentBlock]$CommentBlock) {
	$errorMsgPre = "($className.$($MethodGroup.Names[0])) Method Group Head Comment (INPUT):"

	# Using moderately strict whitespace
	$regexArg   = "^(?<name>\w+)(:?\s+(?<remainder>\S.+))?$"
	$regexType  = "^\("
	$regexDim   = "^DIM(?<remainder>\[.+)$"
	$regexValue1 = "^    (?<value>\w+|""[\-\w]+""|'\w+'|\([\w ]+\))(:?\s+(?<remainder>\S.+))?$"
	$regexType1  = "^    (?<remainder>\(.+)"
	$regexMultiLine1 = "^ {4}(?<remainder>\S.+)$"
	$regexMultiLine2 = "^ {8}(?<remainder>\S.+)$"
	$regexTypeMainType  = "^(?<mainType>[\w\.]+)[^\w\.]?"

	# Types that should be written in comments to match the argument block type 'sym'

	# Special cases
	#	nargin==0: INPUT block not permitted
	#	nargin==1: argName is not permitted (this case runs through the main loop)
	# 	UnknownSpec: if type was not given in args block (empty array), then allow the comment to specify anything
	if($MethodGroup.Args.Count -eq 0) {
		if($null -ne $CommentBlock) { throw "$errorMsgPre INPUT block found, but the method has no inputs" }
		return
	}
	if($null -eq $CommentBlock) {
		throw "$errorMsgPre INPUT block not found"
	}
	[Boolean]$isSingleArg = ($MethodGroup.Args.Count -eq 1)
	[Boolean]$isSingleArgWithSingleSpec = $isSingleArg -and ($MethodGroup.Args[0].TypesOrMembers.Count -eq 1)
	[Boolean]$isSingleArgWithUnknownSpec = $isSingleArg -and ($MethodGroup.Args[0].TypesOrMembers.Count -eq 0)

	[Int32]$argIdx = -1
	[ArgRecord2]$currentArg = $null
	[String]$errorMsgPreArg = $errorMsgPre
	[System.Collections.Generic.List[String]]$typesOrValues = @()
	[Boolean]$allowMultilineArg1Next = $false
	[Boolean]$allowMultilineArg2Next = $false
	[Boolean]$allowMultilineVariation2Next = $false
	[Boolean]$isUnknownSpec = $false
	[String]$inlineType = $null
	[String]$inlineDim = $null
	foreach($line in $CommentBlock.Content) {
		if($isSingleArgWithSingleSpec -and ($argIdx -ne -1)) {
			# Always path for subsequent lines where method has 1 arg, which is single spec
			$currentArg.CommentFreeText += $line
		}
		elseif($line -match $regexArg -or (($isSingleArgWithSingleSpec -or $isSingleArgWithUnknownSpec) -and ($argIdx -eq -1))) {
			# Always path for first line of any arg

			# Check finished previous arg
			if($typesOrValues.Count -ne 0) {
				throw "$errorMsgPreArg Not all types or members have been specified"
			}
			if($MethodGroup.Args.Count -eq $argIdx+1) {
				throw "$errorMsgPreArg Too many arguments in comment"
			}

			# Progress to next arg
			$argIdx++
			$currentArg = $MethodGroup.Args[$argIdx]
			$currentArg.CommentVariationsFreeText = [System.Collections.Generic.List[string[]]]::new()

			$isSingleSpec = ($currentArg.TypesOrMembers.Count -eq 1)
			$isUnknownSpec = ($currentArg.TypesOrMembers.Count -eq 0)
			$isSpecNotSpecified_inCode = ($currentArg.TypesOrMembers.Count -eq 0)

			# Reset parser state
			$errorMsgPreArg = "$errorMsgPre ($($currentArg.Name))"
			$typesOrValues = [System.Collections.Generic.List[String]]::new()
			$typesOrValues.AddRange($currentArg.TypesOrMembers)
			$allowMultilineArg1Next = $false
			$allowMultilineArg2Next = $false
			$allowMultilineVariation2Next = $false
			$inlineType = ''
			$inlineDim = ''

			# Decide if isSingleSpec or not based on presence of name
			if($isSingleArgWithUnknownSpec) {
				if(($line -match $regexArg) -and ($Matches['name'] -ceq $currentArg.Name)) {
					$isSingleArgWithSingleSpec = $false
					$isSingleSpec = $false
					$isUnknownSpec = $true
				}
				else {
					$isSingleArgWithSingleSpec = $true
					$isSingleSpec = $true
					$isUnknownSpec = $false
				}
			}

			# Parse arg name
			if($isSingleArgWithSingleSpec) {
				if(($line -match $regexArg) -and ($Matches['name'] -ceq $currentArg.Name)) {
					throw "$errorMsgPreArg Arg name should not be specified for single arguments"
				}
				$rem = $line
			}
			else{
				if($Matches['name'] -ne $currentArg.Name) {
					throw "$errorMsgPreArg Arg name/order does not match arguments block"
				}
				$rem = $Matches['remainder'] ?? ''
			}

			# Parse remainder of first line
			if($rem -match $regexType) {
				if($isUnknownSpec) {
					# Assume, as an alternative to erroring
					$isSingleSpec = $true
					$isUnknownSpec = $false
				}
				if(-not $isSingleSpec) { throw "$errorMsgPreArg Args with multiple types/members must be specified on separate lines" }
				$ret = SplitBalancedBrackets($rem)
				$inlineType = $ret.Contained
				$rem = $ret.Remainder.Trim()
				# Validate match of outer part of type
				if(-not $isSpecNotSpecified_inCode) {
					if($typesOrValues.Count -eq 0) {
						throw "$errorMsgPreArg Argument type/order does not match arguments block. Too many arguments"
					}
					elseif(($inlineType -match $regexTypeMainType) -and ($Matches['mainType'] -eq $typesOrValues[0])) {
						$typesOrValues.RemoveAt(0)
					}
					elseif(($script:tokens_inbuiltTypesSym -contains $inlineType) -and ($typesOrValues[0] -eq 'sym')) {
						$typesOrValues.RemoveAt(0)
					}
					else {
						throw "$errorMsgPreArg Argument type/order does not match arguments block"
					}
				}
			}
			if($rem -match $regexDim) {
				$rem = $Matches['remainder']    # Discard the text 'DIM'
				$ret = SplitBalancedBrackets($rem)
				$inlineDim = $ret.Contained
				$rem = $ret.Remainder.Trim()
			}
			$freeText = ''
			if($rem -ne '') {
				if($isUnknownSpec) {
					# Assume, as an alternative to erroring
					$isSingleSpec = $true
					$isUnknownSpec = $false
				}
				if($isSingleArg -or $isSingleSpec) {
					$freeText = @($rem)
				}
				else {
					throw "$errorMsgPreArg Multi type/value args shall not have inline comments"
				}
			}

			# Branch point
			# Always set freeText
			$currentArg.CommentFreeText = ($freeText -ne '') ? $freeText : @()
			if(-not $isSingleSpec) {
				$allowMultilineArg2Next = $true
				continue
			}

			# Single spec arg: create variation, add comments
			$typesOrValues = @()
			$currentArg.CommentTypes += $inlineType
			$currentArg.CommentDims += $inlineDim
			$currentArg.CommentVariationsFreeText.Add( @() )
			if($rem -eq '') { $allowMultilineArg1Next = $true }
		}
		elseif($argIdx -eq -1) {
			throw "$errorMsgPre First arg not found"
		}
		elseif($allowMultilineArg1Next -and ($line -match $regexMultiLine1)) {
			$rem = $Matches['remainder']
			$currentArg.CommentFreeText += $rem
		}
		elseif($allowMultilineArg2Next -and ($line -match $regexMultiLine2)) {
			$rem = $Matches['remainder']
			$currentArg.CommentFreeText += $rem
		}
		elseif($allowMultilineVariation2Next -and ($line -match $regexMultiline2)) {
			$rem = $Matches['remainder']
			$currentArg.CommentVariationsFreeText[-1] += $rem
		}
		elseif((-not $currentArg.AreTypesMembers) -and ($line -match $regexType1)) {
			$allowMultilineArg1Next = $false
			$allowMultilineArg2Next = $false
			$allowMultilineVariation2Next = $true
			if($inlineType -ne '') { throw "$errorMsgPreArg Type specified twice" }

			$rem = $Matches['remainder']
			$ret = SplitBalancedBrackets($rem)
			$type = $ret.Contained
			$rem = $ret.Remainder.Trim()

			# Validate and pop type
			if(-not $isUnknownSpec) {
				if($typesOrValues.Count -eq 0) {
					throw "$errorMsgPreArg Argument type/order does not match arguments block. Too many arguments"
				}
				elseif(($type -match $regexTypeMainType) -and ($Matches['mainType'] -eq $typesOrValues[0])) {
					$typesOrValues.RemoveAt(0)
				}
				elseif(($script:tokens_inbuiltTypesSym -contains $type) -and ($typesOrValues[0] -eq 'sym')) {
					$typesOrValues.RemoveAt(0)
				}
				else {
					throw "$errorMsgPreArg Argument type/order does not match arguments block"
				}
			}

			# Parse remainder of line
			$dim = $inlineDim
			if($rem -match $regexDim) {
				if($inlineDim -ne '') { throw "$errorMsgPreArg DIM specified twice" }
				$rem = $Matches['remainder']    # Discard the text 'DIM'
				$ret = SplitBalancedBrackets($rem)
				$dim = $ret.Contained
				$rem = $ret.Remainder.Trim()
			}
			$freeText = @()
			if($rem -ne '') {
				$freeText = @($rem)
				$allowMultilineVariation2Next = $false
			}
			$currentArg.CommentTypes += $type
			$currentArg.CommentDims += $dim
			$currentArg.CommentVariationsFreeText.Add( @($freeText) )
		}
		elseif($currentArg.AreTypesMembers -and ($line -match $regexValue1)) {
			$allowMultilineArg1Next = $false
			$allowMultilineArg2Next = $false
			$allowMultilineVariation2Next = $true

			# Validate and pop value name
			$val = $Matches['value']
			if($typesOrValues[0] -ne $val) { throw "$errorMsgPreArg Value name/order does not match arguments block" }
			$typesOrValues.RemoveAt(0)

			# Parse remainder of line
			$freeText = @()
			if($null -ne $Matches['remainder']) {
				$allowMultilineVariation2Next = $false
				$freeText = @($Matches['remainder'])
			}
			$currentArg.CommentTypes += ''
			$currentArg.CommentDims += $inlineDim
			$currentArg.CommentVariationsFreeText.Add( @($freeText) )
		}
		else {
			throw "$errorMsgPre failed to parse on line: $line"
		}
	}
	# Check finished previous arg
	if($typesOrValues.Count -ne 0) {
		throw "$errorMsgPreArg Not all types or members have been specified"
	}

	if($argIdx+1 -ne $MethodGroup.Args.Count) {
		throw "$errorMsgPre Not enough arguments in comment"
	}

	foreach($arg in $MethodGroup.Args) {
		$isSpecNotSpecified_inCode = ($arg.TypesOrMembers.Count -eq 0)
		$isSpecNotSpecified_inComment = ($arg.CommentTypes.Count -eq 0) -or ($arg.CommentTypes -contains '')
		if($isSpecNotSpecified_inCode -and $isSpecNotSpecified_inComment -and ($arg.Name -ne 'varargin')) {
			Write-Warning "$errorMsgPre ($($arg.Name)) Argument type not known"
		}
	}
}


[void] WriteCommentVariables_Outputs([String]$ClassName, [MethodGroupRecord2]$MethodGroup, [CommentBlock]$CommentBlock) {
	$errorMsgPre = "($className.$($MethodGroup.Names[0])) Method Group Head Comment (OUTPUT):"

	# Using moderately strict whitespace
	$regexArg   = "^(?<name>\w+)(:?\s+(?<remainder>\S.+))?$"
	$regexType  = "^\("
	$regexDim   = "^DIM(?<remainder>\[.+)$"
	$regexMultiLine1 = "^ {4}(?<remainder>\S.+)$"

	# Special case: Constructor
	#   Even though not commented, it can only return its own type, so set this
	#   However, the size can vary, so leaving that unset
	if($className -eq $MethodGroup.Names[0]) {
		if($MethodGroup.Names.Count -ne 1) {
			throw "$errorMsgPre Constructors shall not be grouped with other methods (required: separate the methods with a space)"
		}
		if($null -ne $CommentBlock) { throw "$errorMsgPre OUTPUT block not permitted for constructors" }
		$MethodGroup.Returns[0].CommentType = $className
		$MethodGroup.Returns[0].CommentDim = ''
		$MethodGroup.Returns[0].CommentFreeText = @()
		return
	}

	# Special case: returns 'this'
	if(($MethodGroup.Returns.Count -eq 1) -and ($MethodGroup.Returns[0].Name -eq 'this')) {
		if($null -ne $CommentBlock) { throw "$errorMsgPre OUTPUT block not permitted for return of 'this'" }
		$MethodGroup.Returns[0].CommentType = ''
		$MethodGroup.Returns[0].CommentDim = ''
		$MethodGroup.Returns[0].CommentFreeText = @()
		return
	}

	# Special cases
	#	nargout==0: OUTPUT block not permitted
	#	nargout==1: argName is not permitted (this case runs through the main loop)
	if($MethodGroup.Returns.Count -eq 0) {
		if($null -ne $CommentBlock) { throw "$errorMsgPre OUTPUT block found, but the method has no outputs" }
		return
	}
	if($null -eq $CommentBlock) {
		throw "$errorMsgPre OUTPUT block not found"
	}
	[Boolean]$isSingleArg = ($MethodGroup.Returns.Count -eq 1)

	[Int32]$retIdx = -1
	[RetRecord2]$currentRet = $null
	[String]$errorMsgPreArg = $errorMsgPre
	[Boolean]$allowMultilineArg1Next = $false
	foreach($line in $CommentBlock.Content) {
		if(($line -match $regexArg) -or ($isSingleArg -and ($retIdx -eq -1))) {
			# Always path for first line of any arg

			# Check finished previous arg
			if($MethodGroup.Returns.Count -eq $retIdx+1) {
				throw "$errorMsgPreArg Too many return arguments in comment"
			}

			# Progress to next arg
			$retIdx++
			$currentRet = $MethodGroup.Returns[$retIdx]

			# Reset parser state
			$errorMsgPreArg = "$errorMsgPre ($($currentRet.Name))"
			$allowMultilineArg1Next = $false

			# Parse arg name
			if($isSingleArg) {
				if(($line -match $regexArg) -and ($Matches['name'] -ceq $currentRet.Name)) {
					throw "$errorMsgPreArg Ret name should not be specified for single arguments"
				}
				$rem = $line
			}
			else{
				if($Matches['name'] -ne $currentRet.Name) {
					throw "$errorMsgPreArg Ret name/order does not match signature"
				}
				$rem = $Matches['remainder'] ?? ''
			}

			# Parse type
			if(-not ($rem -match $regexType)) {
				throw "$errorMsgPreArg Ret type not found"
			}
			$ret = SplitBalancedBrackets($rem)
			$type = $ret.Contained
			$rem = $ret.Remainder.Trim()

			# Parse dimensions
			if(-not ($rem -match $regexDim)) {
				throw "$errorMsgPreArg Ret dimensions not found"
			}
			$rem = $Matches['remainder']    # Discard the text 'DIM'
			$ret = SplitBalancedBrackets($rem)
			$dim = $ret.Contained
			$rem = $ret.Remainder.Trim()

			# Parse description
			$freeText = @()
			if($rem -ne '') {
				$freeText = @($rem)
			}
			else {
				$allowMultilineArg1Next = $true
			}
			$currentRet.CommentType = $type
			$currentRet.CommentDim = $dim
			$currentRet.CommentFreeText = $freeText
		}
		elseif($retIdx -eq -1) {
			throw "$errorMsgPre First return argument not found"
		}
		elseif($allowMultilineArg1Next -and ($line -match $regexMultiLine1)) {
			$rem = $Matches['remainder']
			$currentRet.CommentFreeText += $rem
		}
		else {
			throw "$errorMsgPre failed to parse on line: $line"
		}
	}

	if($retIdx+1 -ne $MethodGroup.Returns.Count) {
		throw "$errorMsgPre Not enough return arguments in comment"
	}
}


[void] WriteCommentVariables_Props([String]$ClassName, [PropGroupRecord2]$PropGroup) {
	$errorMsgPre = "($className.$($PropGroup.Props[0].Name)) Prop Group Comments:"

	# Using moderately strict whitespace
	$regexType  = "^\("
	$regexDim   = "^DIM(?<remainder>\[.+)$"

	[Boolean]$isSingleProp   = ($PropGroup.Props.Count -eq 1)
	[Boolean]$hasHeadComment = ($PropGroup.HeadComment.Count -ne 0)

	foreach($prop in $PropGroup.Props) {
		$rem = $prop.InlineComment.Trim()
		$type = ''
		$dim = ''
		# Parse type
		if($rem -match $regexType) {
			$ret = SplitBalancedBrackets($rem)
			$type = $ret.Contained
			$rem = $ret.Remainder.Trim()
		}
		# Parse dimensions
		if($rem -match $regexDim) {
			$rem = $Matches['remainder']    # Discard the text 'DIM'
			$ret = SplitBalancedBrackets($rem)
			$dim = $ret.Contained
			$rem = $ret.Remainder.Trim()
		}
		# Parse description
		$freeText = @()
		if($rem -ne '') {
			if($isSingleProp -and $hasHeadComment) {
				throw "$errorMsgPre Ungrouped properties should not have both inline and above free text comments"
			}
			$freeText = @($rem)
		}
		$prop.CommentType = $type
		$prop.CommentDim = $dim
		$prop.CommentFreeText = $freeText
	}

	[String[]]$headComment = $PropGroup.HeadComment

	# For ungrouped properties, normalise comment to appear on head, and not on inline
	$PropGroup.CommentFreeText = $headComment
	if($isSingleProp -and (-not $hasHeadComment)) {
		$PropGroup.CommentFreeText = $PropGroup.Props[0].CommentFreeText
		$PropGroup.Props[0].CommentFreeText = ''
	}
}
}


################################################################################################
## Render
################################################
class RenderLayoutReference {
	[String]$errorPre = ''
	[String[]]$AllClassNames
	[System.Collections.Generic.Dictionary[String,ClassRecord2]]$ClassesDict
	[System.Collections.Generic.Dictionary[String,String[]]]$InheritanceDict

[String] Render([ClassRecord2]$Class, [String]$PageName) {
	$this.errorPre = "($($class.Name)) Renderer: "
	$htmlTemplateMethod = $script:htmlLayoutReferenceMethod

	[String[]]$summaryPropsRows = @()
	[String[]]$summaryMethodsRows = @()
	$summaryPropsRows += $this.RenderPropSummaryRows($class.PropGroups, '')
	$summaryMethodsRows += $this.RenderMethodSummaryRows($class.MethodGroups, '')
	foreach($inheritedFrom in $this.InheritanceDict[$class.Name]) {
		$inheritedClass = $this.ClassesDict[$inheritedFrom]
		$summaryPropsRows += $this.RenderPropSummaryRows($inheritedClass.PropGroups, $inheritedFrom)
		$summaryMethodsRows += $this.RenderMethodSummaryRows($inheritedClass.MethodGroups, $inheritedFrom)
	}

	[String[]]$htmlPropsBlocks = $this.RenderPropRows($class.PropGroups)

	[String[]]$htmlMethodsBlocks = @()
	foreach($methodGroup in $class.MethodGroups) {
		$signature = $this.RenderMethodSignature($methodGroup.Args)
		$methodDescription = $this.RenderMethodDescription($methodGroup.CommentMethod)

		[String[]]$nameAndSignature = @()
		foreach($methodName in $methodGroup.Names) {
			$nameAndSignature += "<span class=""tk-method"">$($methodName)</span>$signature"
		}
		[Boolean]$hasConstraints = $null -ne ($methodGroup.Args | Where-Object { $_.MustBe_Booleans.Count -ne 0 })
		[Boolean]$hasDefaults    = $null -ne ($methodGroup.Args | Where-Object { $_.DefaultValue -ne '' })
		$summaryArgRows = $this.RenderArgSummaryRows($methodGroup.Args, $hasConstraints, $hasDefaults)
		$summaryRetRows = $this.RenderRetSummaryRows($methodGroup.Returns)
		$htmlMethod = $htmlTemplateMethod
		$htmlMethod = HtmlInsert   $htmlMethod 'methodNameAndSignature' ($nameAndSignature -join "<br>")
		#$htmlMethod = HtmlInsert $htmlMethod 'methodDescription' (<pre class=""text-comment"">+(HtmlEscape $methodGroup.HeadComment -Join "`n")+</pre>)
		$htmlMethod = HtmlInsert $htmlMethod 'methodDescription' ($methodDescription -join "`n")
		$htmlMethod = HtmlRenderInnerIf $htmlMethod 'summaryArgsConstraints' $hasConstraints
		$htmlMethod = HtmlRenderInnerIf $htmlMethod 'summaryArgsDefault' $hasDefaults
		$htmlMethod = HtmlInsertIf $htmlMethod 'summaryArgs' ($summaryArgRows -join "`n")
		$htmlMethod = HtmlInsertIf $htmlMethod 'summaryReturn' ($summaryRetRows -join "`n")
		$htmlMethodsBlocks += $htmlMethod
	}

	[String[]]$superHierarchyHtml = @()
	[String[]]$superHierarchy = @()
	$superHierarchy += $class.Name
	$superHierarchy += $this.InheritanceDict[$class.Name]
	foreach($inheritedFrom in $superHierarchy) {
		$inheritedClass = $this.ClassesDict[$inheritedFrom]
		[String[]]$superLinked = @()
		foreach($super in $inheritedClass.Super) {
			$superLinked += ($this.AllClassNames -contains $super) ? (RenderLinkToClass $super) : "<span class=""tk-type"">$super</span>"
		}
		if($superLinked.Count -eq 0) {
			# No superclass
			continue
		}
		$superJoined = $superLinked -join ", "
		$superHierarchyHtml += ($superLinked.Count -gt 1) ? "<span class=""type-paren"">(</span>$superJoined<span class=""type-paren"">)</span>" : $superJoined
	}
	$unicodeLessThan = "&#xFE64;"
	$superHtml = ($superHierarchyHtml.Count -eq 0) ? '' : "$unicodeLessThan" + ($superHierarchyHtml -join " $unicodeLessThan ")

	$htmlRef = $script:htmlLayoutReference
	$htmlRef = HtmlInsert   $htmlRef 'h1' $PageName
	$htmlRef = HtmlInsertIf $htmlRef 'super' $superHtml
	#$htmlRef = HtmlInsertIf $htmlRef 'description' (HtmlEscape $class.HeadComment -Join "`n")
	$htmlRef = HtmlInsertIf $htmlRef 'description' ($this.RenderClassDescription($class.CommentClass))
	$htmlRef = HtmlInsertIf $htmlRef 'summaryProperties' ($summaryPropsRows -join "`n")
	$htmlRef = HtmlInsertIf $htmlRef 'summaryMethods' ($summaryMethodsRows -join "`n")
	$htmlRef = HtmlInsertIf $htmlRef 'properties' ($htmlPropsBlocks -join "`n")
	$htmlRef = HtmlInsertIf $htmlRef 'methods' ($htmlMethodsBlocks -join "`n")
	return $htmlRef
}

[String[]] RenderSizes([System.Nullable[Int32][]]$Sizes, [String[]]$CommentDims, [String[]]$MustBe_Booleans) {
	# Input Sizes is for the whole arg/prop. CommentDims is 1 per variation
	# Output 1 string per variation
	$op = $script:html_op
	$cp = $script:html_cp
	$os = $script:html_os
	$cs = $script:html_cs
	$pipe = $script:html_pipe
	$comma = $script:html_comma
	$colon = $script:html_colon
	$commaSpace = "$comma&nbsp;" # Paired with $maybeSpace in RenderMatlabCode(), otherwise browser hates me
	$emptyHtml = "<span class=""tk-dim-keyword"">empty</span>"
	$scalarHtml = "<span class=""tk-dim-keyword"">scalar</span>"
	$colHtml = "<span class=""tk-dim-keyword"">col</span>"
	$rowHtml = "<span class=""tk-dim-keyword"">row</span>"
	$vecHtml = "<span class=""tk-dim-keyword"">vector</span>"
	$anyHtml = "<span class=""tk-dim-keyword"">any</span>"

	# Split Dims [variation][option][dim]
	[System.Collections.Generic.List[System.Collections.Generic.List[String[]]]]$dimsTokens = @()
	foreach($CommentDim in $CommentDims) {
		[System.Collections.Generic.List[String[]]]$dimTokens = @()
		$options = SplitNotBracketed -Text $CommentDim -Delim "|" -Trim
		foreach($option in $options) {
			if($option -match "^\[(?<remainder>.*)\]$") { $option = $Matches['remainder'] }
			[String[]]$optionDims = SplitNotBracketed -Text $option -Delim "," -Trim
			if(($optionDims.Count -eq 1) -and ($optionDims[0] -eq '')) { $optionDims = @() }
			$dimTokens.Add($optionDims)
		}
		$dimsTokens.Add($dimTokens)
	}

	# Tokenise and join dims [variation]
	[System.Collections.Generic.List[String]]$out = @()
	foreach($options in $dimsTokens) {
		[String[]]$dimStrings = @()
		foreach($option in $options) {
			$dimsHtml = $option | ForEach-Object { $this.RenderMatlabCode($_, $true) }
			$stringHtml = $dimsHtml -join $commaSpace
			if(($option.Count -eq 2) -and ($option[0] -eq '1') -and ($option[1] -eq '1')) {
				$stringHtml = "<span class=""tk-dim-keyword"">scalar</span>"
			}
			elseif(($option.Count -eq 2) -and ($option[1] -eq '1')) {
				$s0 = $dimsHtml[0]
				$stringHtml = $colHtml + (($s0 -eq '') ? '' : "$op$s0$cp")
			}
			elseif(($option.Count -eq 2) -and ($option[0] -eq '1')) {
				$s1 = $dimsHtml[1]
				$stringHtml = $rowHtml + (($s1 -eq '') ? '' : "$op$s1$cp")
			}
			elseif($option.Count -gt 1) {
				$stringHtml = "$os$stringHtml$cs"
			}
			$dimStrings += $stringHtml
		}
		$dimsString = ($dimStrings -join $pipe)
		$out.Add($dimsString)
	}

	if    ($MustBe_Booleans -contains 'mustBeScalarOrEmpty') { $sizesHtml = "$scalarHtml$pipe$emptyHtml" }
	elseif($MustBe_Booleans -contains 'mustBeVector')        { $sizesHtml = $vecHtml }
	elseif($Sizes.Count -eq 0) { $sizesHtml = $anyHtml }
	elseif($Sizes.Count -eq 2) {
		$s0 = $Sizes[0]
		$s1 = $Sizes[1]
		if(($s0 -eq 1) -and ($s1 -eq 1)) {
			$sizesHtml = $scalarHtml
		}
		elseif(($s0 -ne 1) -and ($s1 -eq 1)) {
			$sizesHtml = $colHtml + (($null -eq $s0) ? '' : "$op<span class=""tk-numeric"">$s0</span>$cp")
		}
		elseif(($s0 -eq 1) -and ($s1 -ne 1)) {
			$sizesHtml = $rowHtml + (($null -eq $s1) ? '' : "$op<span class=""tk-numeric"">$s1</span>$cp")
		}
		else {
			$s0_str = ($null -eq $s0) ? $colon : "<span class=""tk-numeric"">$s0</span>"
			$s1_str = ($null -eq $s1) ? $colon : "<span class=""tk-numeric"">$s1</span>"
			$sizesHtml = "$os$s0_str$commaSpace$s1_str$cs"
		}
	}
	else {
		throw "Sizes not recognised"
	}

	# Merge Dims and Sizes (prefer Dims)
	for($idx=0; $idx -lt $out.Count; $idx++) {
		if($out[$idx] -eq '') { $out[$idx] = $sizesHtml }
	}
	return $out
}

[String[]] RenderTypesOrMembers([String[]]$TypesOrMembers, [Boolean]$AreTypesMembers) {
	[String[]]$out = $TypesOrMembers
	if($AreTypesMembers) {
		$out = $out | ForEach-Object {
			$escaped = HtmlEscape $_
			if($_ -match '^[\d\.]+$') {
				return "<span class=""tk-numeric"">$escaped</span>"
			}
			elseif($_ -match "^("".+""|'.+')$") {
				return "<span class=""tk-string"">$escaped</span>"
			}
			return $escaped
		}
	}
	else {
		$out = $out | ForEach-Object {
			$escaped = HtmlEscape $_
			if($this.AllClassNames -contains $_) {
				return (RenderLinkToClass $escaped)
			}
			elseif($script:tokens_inbuiltTypesExtended -contains $_) {
				"<span class=""tk-type"">$escaped</span>"
			}
			else {
				throw "$($this.errorPre) Unrecognised inbuilt type: $_"
			}
		}
	}
	return $out
}


[String] RenderMatlabCode([String]$Text) {
	return $this.RenderMatlabCode($Text, $false)
}

[String] RenderMatlabCode([String]$Text, [Boolean]$Trim) {
	$tokenNumber = '\d+\.?\d*e?'
	$tokenString = "("".*?""|'.*?')"
	$tokenComment = '^%'
	$tokenWhitespace = '\s+'
	$regex_tokens_text = $this.AllClassNames + $script:tokens_inbuiltFunctions + $script:tokens_inbuiltTypesExtended + $script:tokens_inbuiltKeywords | Sort-Object Length -Descending
	$regex_tokensEscaped_punctuation = $script:tokens_punctuation

	[String[]]$split = @()
	$regexJoined_punctuation = ($regex_tokensEscaped_punctuation | ForEach-Object { [Regex]::Escape($_) }) -join '|'
	$regexJoined_text = ($regex_tokens_text | ForEach-Object { [Regex]::Escape($_) }) -join '|'
	$regexJoined_all = "\b(?:$regexJoined_text)\b|$regexJoined_punctuation"
	# Split into tokens
	$rem = $Text
	while($rem -ne '') {
		if($rem -match "^(?<token>$tokenWhitespace)(?<remainder>.*)$") {
			if(-not $Trim) {
				$split +=  $Matches['token']
			}
			$rem = $Matches['remainder'] ?? ''
		}
		elseif($rem -match $tokenComment) {
			$split += $rem
			$rem = ''
		}
		elseif($rem -match "^(?<token>$regexJoined_all)(?<remainder>.*)$") {
			$split += $Matches['token']
			$rem = $Matches['remainder'] ?? ''
		}
		elseif($rem -match "^(?<token>$tokenNumber|$tokenString)(?<remainder>.*)$") {
			$split +=  $Matches['token']
			$rem = $Matches['remainder'] ?? ''
		}
		elseif($rem -match "^(?<token>.+?)(?<remainder>($tokenWhitespace|$regexJoined_punctuation).*)?$") {
			$split += $Matches['token']
			$rem = $Matches['remainder'] ?? ''
		}
		else {
			throw "$($this.errorPre) Unrecognised token in matlab code: $rem"
		}
	}

	# Detect full-line comment
	if($Text -match "^\s*%") {
		$escaped = HtmlEscape ($split -join '')
		return "<span class=""text-comment text-comment-line"">$escaped</span>"
	}

	# If trim, add spaces back in after commas
	$maybeSpace = $Trim ? '&nbsp;' : ''

	$isDot = $false
	[string[]]$out = @()
	foreach($token in $split) {
		$afterDot = $isDot
		$isDot = $false

		$escaped = HtmlEscape $token
		if    ($token -match $tokenComment)           { $out += "<span class=""text-comment"">$escaped</span>" }
		elseif($token -match "^$tokenWhitespace$")    { $out += $escaped }
		elseif($token -match "^$tokenNumber$")        { $out += "<span class=""tk-numeric"">$escaped</span>" }
		elseif($token -match "^$tokenString$")        { $out += "<span class=""tk-string"">$escaped</span>" }
		elseif($script:tokens_inbuiltTypesExtended -ccontains $token) { $out += "<span class=""tk-type"">$escaped</span>" }
		elseif($script:tokens_inbuiltKeywords -ccontains $token)      { $out += "<span class=""tk-keyword"">$escaped</span>" }
		elseif($script:tokens_inbuiltFunctions -ccontains $token)     { $out += "<span class=""tk-function"">$escaped</span>" }
		elseif($this.AllClassNames -ccontains $token)          { $out += (RenderLinkToClass $escaped) }
		elseif($token -eq '(') { $out += $script:html_op }
		elseif($token -eq ')') { $out += $script:html_cp }
		elseif($token -eq '[') { $out += $script:html_os }
		elseif($token -eq ']') { $out += $script:html_cs }
		elseif($token -eq '{') { $out += $script:html_ob }
		elseif($token -eq '}') { $out += $script:html_cb }
		elseif($token -eq '|') { $out += $script:html_pipe }
		elseif($token -eq ';') { $out += $script:html_semi }
		elseif($token -eq ',') { $out += ($script:html_comma + $maybeSpace) }
		elseif($token -eq ':') { $out += $script:html_colon }
		elseif($token -eq '=') { $out += $script:html_equals }
		elseif($token -eq '.') { $out += $script:html_dot; $isDot=$true}
		elseif($token -eq '+') { $out += $script:html_plus }
		elseif($token -eq '-') { $out += $script:html_minus }
		elseif($token -eq '*') { $out += $script:html_times }
		elseif($token -eq '/') { $out += $script:html_divide }
		elseif($token -eq '^') { $out += $script:html_hat }
		elseif($token -eq '~') { $out += $script:html_tilde }
		elseif($token -eq '>>') { $out += $script:html_prompt }
		elseif($token -eq 'ans') { $out += $script:html_ans }
		elseif($token -eq '×') { $out += $script:html_uncodeTimes }
		elseif($token -match "^\w+$") {
			if($afterDot) { $out += "<span class=""tk-function"">$escaped</span>" }
			else          { $out += "<span class=""tk-normal"">$escaped</span>" }
		}
		else {
			$out += $escaped
		}
		$afterDot = $false
	}
	return ($out -join '')
}


[String[]] RenderMustBe([String[]]$MustBe_Booleans) {
	[String[]]$out = $MustBe_Booleans | Where-Object { @('mustBeScalarOrEmpty', 'mustBeVector') -notcontains $_ }
	if($null -eq $out) {
		$out = @()
	}
	$out = HtmlEscape $out
	$out = $out | ForEach-Object { "<span class=""tk-function"">$_</span>" }
	return $out
}


[String[]] RenderPropSummaryRows([PropGroupRecord2[]]$PropGroups, [String]$InheritedFrom) {
	[String[]]$out = @()
	$InheritedFrom = $InheritedFrom -eq '' ? '' : (RenderLinkToClass $InheritedFrom)
	$comma = $script:html_comma

	foreach($propGroup in $PropGroups) {
		foreach($prop in $propGroup.Props) {
			$propAccess = ''
			if($prop.UserCanRead -and $prop.UserCanSet) { $propAccess = 'r/w' }
			elseif($prop.UserCanRead)                   { $propAccess = 'read only' }
			elseif($prop.UserCanSet)                    { $propAccess = 'write only' }

			$sizes = $this.RenderSizes($prop.Sizes, $prop.CommentDim, $prop.MustBe_Booleans)
			$constraints = $this.RenderMustBe($prop.MustBe_Booleans) -join ", "
			$default = $this.RenderMatlabCode($prop.DefaultValue, $true)

			# Get best: TypesOrMembers or CommentType
			$typesOrMembers = $this.RenderTypesOrMembers($prop.TypesOrMembers, $prop.AreTypesMembers) -join "$comma "
			if($prop.CommentType -ne '') { $typesOrMembers = $this.RenderMatlabCode($prop.CommentType, $true) }

			$out +=
"<tr>
	<td>$InheritedFrom</td>
	<td>$propAccess</td>
	<td class=""tk-property"">$($prop.Name)</td>
	<td>$sizes</td>
	<td>$typesOrMembers</td>
	<td>$constraints</td>
	<td>$default</td>
</tr>"
		}
	}
	return $out
}


[String[]] RenderPropRows([PropGroupRecord2[]]$PropGroups) {
	[String[]]$out = @()

	foreach($propGroup in $PropGroups) {
		$description = RenderArray $propGroup.CommentFreeText "p" "text-comment" -Join
		$out +=
"<table class=""ref-properties"">
	<tbody>
		<tr>
			<td colspan=""2""  class=""text-comment"">$description</td>
		</tr>"

		foreach($prop in $propGroup.Props) {
			$out +=
"		<tr>
			<td class=""tk-property"">$($prop.Name)</td>
			<td class=""text-comment"">$(HtmlEscape $prop.CommentFreeText)</td>
		</tr>"
		}
		$out +=
"	</tbody>
</table>"
	}
	return $out
}


[String[]] RenderArgSummaryRows([ArgRecord2[]]$Args2, [Boolean]$renderConstraints, [Boolean]$renderDefaults) {
	[String[]]$out = @()

	foreach($arg in $Args2) {
		$argNameHtml = $this.RenderArgNameShort($arg)
		$sizes = $this.RenderSizes($arg.Sizes, $arg.CommentDims, $arg.MustBe_Booleans)
		$description = RenderArray $arg.CommentFreeText "p" "text-comment" -Join
		$constraints = $this.RenderMustBe($arg.MustBe_Booleans) -join ", "
		$default = $this.RenderMatlabCode($arg.DefaultValue, $true)

		# Get best from TypesOrMembers vs CommentTypes
		$typesOrMembers = $this.RenderTypesOrMembers($arg.TypesOrMembers, $arg.AreTypesMembers) ?? @()
		for($idxMem=0; $idxMem -lt $typesOrMembers.Count; $idxMem++ ) {
			$typeMem = $arg.CommentTypes[$idxMem]
			if($typeMem -ne '') { $typesOrMembers[$idxMem] = $this.RenderMatlabCode($typeMem, $true) }
		}
		for($idxMem=$typesOrMembers.Count; $idxMem -lt $arg.CommentTypes.Count; $idxMem++ ) {
			$typeMem = $arg.CommentTypes[$idxMem]
			if($typeMem -ne '') { $typesOrMembers += $this.RenderMatlabCode($typeMem, $true) }
		}
		$sizes_line1          = ($sizes.Count -eq 1) ? $sizes : ''
		$typesOrMembers_line1 = ($typesOrMembers.Count -eq 1) ? $typesOrMembers : ''
		$out +=
"<tr>
	<td>$argNameHtml</td>
	<td>$sizes_line1</td>
	<td>$typesOrMembers_line1</td>
	$($renderConstraints ? '<td>'+$constraints+'</td>' : '')
	$($renderDefaults    ? '<td>'+$default+'</td>'     : '')
	<td>$description</td>
</tr>"

		if($typesOrMembers.Count -eq 1) {
			continue
		}
		for($idxMem=0; $idxMem -lt $typesOrMembers.Count; $idxMem++ ) {
			$descriptionMem = RenderArray $arg.CommentVariationsFreeText[$idxMem] "p" "text-comment" -Join
			$sizeMem = $sizes[$idxMem]
			$typeOrMem = $typesOrMembers[$idxMem]
			$out +=
"<tr>
	<td></td>
	<td>$sizeMem</td>
	<td>$typeOrMem</td>
	$($renderConstraints ? '<td></td>' : '')
	$($renderDefaults    ? '<td></td>' : '')
	<td>$descriptionMem</td>
</tr>"
		}
	}
	return $out
}


[String[]] RenderRetSummaryRows([RetRecord2[]]$Rets2) {
	[String[]]$out = @()

	foreach($ret in $Rets2) {
		$nameHtml = "<span class=""tk-normal"">$($ret.Name)</span>"
		$sizes = $this.RenderSizes(@(), $ret.CommentDim, @())
		$description = RenderArray $ret.CommentFreeText "p" "text-comment" -Join
		$typeHtml = $this.RenderMatlabCode($ret.CommentType, $true)
		$out +=
"<tr>
	<td>$nameHtml</td>
	<td>$sizes</td>
	<td>$typeHtml</td>
	<td>$description</td>
</tr>"
	}
	return $out
}


[String] RenderArgNameShort([ArgRecord2]$Arg) { return $this.RenderArgName($Arg, $true); }
[String] RenderArgNameLong([ArgRecord2]$Arg) { return $this.RenderArgName($Arg, $false); }
[String] RenderArgName([ArgRecord2]$Arg, [Boolean]$DisplayShort) {
	$argName = $Arg.Name
	if($arg.ArgBlockType -eq [ArgBlockType2]::NameValue) {
		if($DisplayShort) {
			return "<span class=""tk-nv-name"">$argName</span>"
		}
		return "<span class=""tk-nv-name"">$argName</span><span class=""tk-nv-equals"">=</span><span class=""tk-nv-val"">...</span>"
	}
	elseif($arg.ArgBlockType -eq [ArgBlockType2]::Repeating) {
		return "<span class=""tk-repeating"">$argName</span>"
	}
	else {
		return "<span class=""tk-normal"">$argName</span>"
	}
}


[String[]] RenderMethodSignature([ArgRecord2[]]$Args2) {
	[String[]]$out = @()
	$comma = $script:html_comma
	foreach($arg in $Args2) {
		$out += $this.RenderArgNameLong($arg)
	}
	$out = "<span class=""tk-paren-o"">(</span>$($out -join "$comma ")<span class=""tk-paren-c"">)</span>"
	return $out
}


[String[]] RenderMethodReturns([RetRecord2[]]$Returns2) {
	$comma = $script:html_comma
	[String[]]$outArray = $Returns2 | ForEach-Object {
		$name = $_.Name
		if($name -eq 'this') { return "<span class=""tk-type"">this</span>" }
		return $name
	}
	if($Returns2.Count -eq 0) { return '' }
	if($Returns2.Count -eq 1) { return $outArray }
	$out = "<span class=""tk-paren-o"">[</span>"+($outArray -join $comma)+"<span class=""tk-paren-c"">]</span>"
	return $out
}


[String[]] RenderMethodSummaryRows([MethodGroupRecord2[]]$MethodGroups, [String]$InheritedFrom) {
	[String[]]$out = @()
	$InheritedFrom = $InheritedFrom -eq '' ? '' : (RenderLinkToClass $InheritedFrom)

	foreach($methodGroup in $MethodGroups) {
		if($methodGroup.IsStatic)                 { $callStyle="Static" }
		elseif($methodGroup.SupportsObjectArrays) { $callStyle="Array Call" }
		else                                      { $callStyle="Single Instance" }
		$signature = $this.RenderMethodSignature($methodGroup.Args)
		$returns = $this.RenderMethodReturns($methodGroup.Returns)
		foreach($methodName in $methodGroup.Names) {
			$out +=
"<tr>
	<td>$InheritedFrom</td>
	<td>$callStyle</td>
	<td>$returns</td>
	<td><span class=""tk-method"">$methodName</span>$signature</td>
</tr>"
		}
	}
	return $out
}


[String[]] RenderMethodDescription([CommentMethod]$CommentMethod) {
	[String[]]$out = @()
	$out += RenderArray $CommentMethod.ShortDescription "p" "text-comment"

	foreach($block in $CommentMethod.FreeBlocks) {
		$out += RenderArray $block.Name    "h4"  "text-comment"
		$out += RenderArray $block.Content "pre" "text-comment text-comment-indent"
	}
	$se = $CommentMethod.SideEffects
	if($null -ne $se) {
		$out += RenderArray $se.Name    "h4"  "text-comment"
		$out += RenderArray $se.Content "pre" "text-comment text-comment-indent"
	}
	foreach($block in $CommentMethod.Examples) {
		$out += RenderArray $block.Name    "h4"  "text-comment"
		$code = $block.Content | ForEach-Object { $this.RenderMatlabCode($_) }
		$out += "<pre class=""code-example""><code>$($code -join "`n")</code></pre>"
	}
	return $out
}


[String[]] RenderClassDescription([CommentClass]$CommentClass) {
	[String[]]$out = @()
	$out += RenderArray $CommentClass.ShortDescription "p" "text-comment"

	foreach($block in $CommentClass.FreeBlocks) {
		$out += RenderArray $block.Name    "h4"  "text-comment"
		$out += RenderArray $block.Content "pre" "text-comment text-comment-indent"
	}
	foreach($block in $CommentClass.Examples) {
		$out += RenderArray $block.Name    "h4"  "text-comment"
		$code = $block.Content | ForEach-Object { $this.RenderMatlabCode($_) }
		$out += "<pre class=""code-example""><code>$($code -join "`n")</code></pre>"
	}
	return $out
}


[String[]] RenderClassList([String[]]$ClassNames) {
	[String[]]$out = @()

	foreach($className in $ClassNames) {
		$class = $this.ClassesDict[$className]

		if($class.IsAbstract) {
			continue
		}

		$classNameHtml = RenderLinkToClass $className

		# Not using ShortDescription for classes because it looks bad lol
		# Using the PURPOSE block instead
		[String[]]$purpose = @()
		foreach($block in $class.CommentClass.FreeBlocks) {
			if($block.Name -eq "PURPOSE") {
				$purpose += RenderArray $block.Content "p" "text-comment"
			}
		}

		[String[]]$propNamesInherited = @()
		[String[]]$methodNamesInherited = @()
		foreach($inheritedFrom in $this.InheritanceDict[$class.Name]) {
			$inheritedClass = $this.ClassesDict[$inheritedFrom]
			[String[]]$propNamesInherited += ($inheritedClass.PropGroups | ForEach-Object { $_.Props }  | ForEach-Object { $_.Name }) ?? @()
			[String[]]$methodNamesInherited += ($inheritedClass.MethodGroups | ForEach-Object { $_.Names }) ?? @()
		}
		[String[]]$propNames = ($class.PropGroups | ForEach-Object { $_.Props }  | ForEach-Object { $_.Name }) ?? @()
		[String[]]$methodNames = ($class.MethodGroups | ForEach-Object { $_.Names }) ?? @()
		$propNamesHtml = RenderArray $propNames "div" "tk-property" -Join
		$methodNamesHtml = RenderArray $methodNames "div" "tk-method" -Join
		$propNamesInheritedHtml = RenderArray $propNamesInherited "div" "tk-property-inherited" -Join
		$methodNamesInheritedHtml = RenderArray $methodNamesInherited "div" "tk-method-inherited" -Join

		$out +=
"<tr>
	<td>$classNameHtml$purpose</td>
	<td><div class=""methods-list"">$propNamesInheritedHtml$methodNamesInheritedHtml$propNamesHtml$methodNamesHtml</div></td>
</tr>"
	}
	return $out
}
}


################################################################################################
## Render (helpers)
################################################
function HtmlEscape {
	Param(
		[Parameter(Mandatory=$true)][AllowEmptyString()][AllowEmptyCollection()] [String[]]$Strings,
		[Parameter()] [String]$Join = "DO_NOT_JOIN",
		[Parameter()] [Switch]$Trim
	)
	[String[]]$escaped = @()
	foreach($str in $Strings) {
		if($Trim) { $str = $str.Trim() }
		$escaped += [System.Web.HttpUtility]::HtmlEncode($str)
	}
	if($Join -eq "DO_NOT_JOIN") {
		return $escaped
	}
	else {
		return ($escaped -join $Join)
	}
}


function URLFormatReference {
	Param(
		[Parameter(Mandatory=$true)] [String]$Text
	)
	$filename = $Text.Replace("_","-")
	return "$($script:productionRoot)/reference/$filename.html"
}


function URLFormatMain {
	Param(
		[Parameter(Mandatory=$true)] [String]$Text
	)
	return "$($script:productionRoot)/$Text.html"
}


function RenderLinkToClass {
	Param(
		[Parameter(Mandatory=$true)] [String]$className
	)
	# Class names do not need escaping
	return "<a href=""$(URLFormatReference $className)"">$className</a>"
}


function RenderArray {
	Param(
		[Parameter(Mandatory=$true)][AllowEmptyString()][AllowEmptyCollection()] [String[]]$Strings,
		[Parameter(Mandatory=$true)] [String]$Tag,
		[Parameter(Mandatory=$true)] [String]$CssClass,
		[Parameter()] [Switch]$Trim,
		[Parameter()] [Switch]$Join
	)
	$tagO = "<$Tag class=""$CssClass"">"
	$tagC = "</$Tag>"
	$escaped = $Trim ? (HtmlEscape $Strings -Trim) : (HtmlEscape $Strings)
	[String[]]$out = $escaped | ForEach-Object { return ($tagO + $_ + $tagC) }
	if($Join) {
		return ($out -join "`n")
	}
	return $out
}


################################################################################################
## Template insert
################################################
function HtmlErrorIfRemainingTags {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template,
		[Parameter(Mandatory=$true)] [String]$ErrorMsgPre
	)
	if(($Template -match "\{\{(?<tag>.*?)\}\}")) {
		throw "$ErrorMsgPre Unused template tag found: " + $Matches['tag']
	}
	if(($Template -match "\{\{") -or ($Template -match "\}\}")) {
		throw "$ErrorMsgPre Unused partial template tag found"
	}
}

function HtmlRemoveComments {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template
	)
	return $Template -replace '(?s)\{\{--.+?--\}\}', ''
}

function HtmlFormatExLink {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template
	)
	$exLinkSvg = $script:htmlExLinkSvg
	$regexPair = "<exLink (?<attributes>[^>]*?)>(?<content>.*?)</exLink>"
	$regexCssClass = "^class=""(?<classes>.+)""$"

	$Template = $Template -replace $regexPair, {
		$content = $_.Groups['content'].Value
		$attributes = $_.Groups['attributes'].Value

		$attributeList = ($attributes -split " "  | Where-Object { $_.Trim() -ne '' }) ?? @()
		$cssClasses = 'ex-link'
		foreach($attribute in $attributeList) {
			if($attribute -match $regexCssClass) {
				$cssClasses += " " + $Matches['classes'].Trim()
			}
		}
		$attributesHtml = (($attributeList | Where-Object { $_ -notmatch $regexCssClass }) ?? @() ) -join " "

		return "<a target=""_blank"" rel=""noopener noreferrer"" class=""$cssClasses"" $attributesHtml>$content$exLinkSvg</a>"
	}
	return $Template
}


function HtmlInsert {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template,
		[Parameter(Mandatory=$true)] [String]$Key,
		[Parameter(Mandatory=$true)][AllowEmptyString()][AllowEmptyCollection()] [String[]]$Strings,
		[Parameter()] [String]$Join = '',
		[Parameter()] [Switch]$Trim
	)
	$tagContent = "{{$Key}}"

	if(-not $Template.Contains($tagContent)) {
		throw "Can't find tag for key: $Key"
	}

	if($Trim) {
		$Strings = @($Strings | ForEach-Object { $_.Trim() })
	}
	$joined = $Strings -join $Join
	$Template = $Template.Replace($tagContent, $joined)
	return $Template
}


function HtmlInsertIf {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template,
		[Parameter(Mandatory=$true)] [String]$Key,
		[Parameter(Mandatory=$true)][AllowEmptyString()][AllowEmptyCollection()] [String[]]$Strings,
		[Parameter()] [String]$Join = '',
		[Parameter()] [Switch]$Trim
	)
	$tagStart   = "{{@$Key}}"
	$tagContent = "{{$Key}}"
	$tagEnd     = "{{/$Key}}"
	$regex_tagStart = [Regex]::Escape($tagStart)
	$regex_tagEnd   = [Regex]::Escape($tagEnd)

	if(-not ($Template.Contains($tagContent) -and $Template.Contains($tagStart) -and $Template.Contains($tagEnd))) {
		throw "Can't find tags for key: $Key"
	}

	if($Trim) {
		$Strings = @($Strings | ForEach-Object { $_.Trim() })
	}
	$joined = $Strings -join $Join

	if($joined.Trim() -eq '') {
		# Remove template bounding IF
		# (?s) means multiline mode
		$Template = $Template -replace "(?s)$regex_tagStart.+?$regex_tagEnd", ''
	}
	else {
		# Remove IF statement, fill template
		$Template = $Template.Replace($tagStart, '')
		$Template = $Template.Replace($tagEnd, '')
		$Template = $Template.Replace($tagContent, $joined)
	}
	return $Template
}


function HtmlRenderInnerIf {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template,
		[Parameter(Mandatory=$true)] [String]$Key,
		[Parameter(Mandatory=$true)] [Boolean]$Include
	)
	$tagStart   = "{{@$Key}}"
	$tagEnd     = "{{/$Key}}"
	$regex_tagStart = [Regex]::Escape($tagStart)
	$regex_tagEnd   = [Regex]::Escape($tagEnd)

	if(-not ($Template.Contains($tagStart) -and $Template.Contains($tagEnd))) {
		throw "Can't find tags for key: $Key"
	}

	if($Include) {
		# Remove IF statement
		$Template = $Template.Replace($tagStart, '')
		$Template = $Template.Replace($tagEnd, '')
	}
	else {
		# Remove template bounding IF
		# (?s) means multiline mode
		$Template = $Template -replace "(?s)$regex_tagStart.+?$regex_tagEnd", ''
	}
	return $Template
}


function HtmlRenderMatlabCode {
	Param(
		[Parameter(Mandatory=$true)] [String]$Template,
		[Parameter(Mandatory=$true)] [RenderLayoutReference]$Renderer
	)
	$preStart       = [Regex]::Escape("{{@matlab-pre}}")
	$preEnd         = [Regex]::Escape("{{/matlab-pre}}")
	$consoleStart    = [Regex]::Escape("{{@matlab-console-pre}}")
	$consoleEnd      = [Regex]::Escape("{{/matlab-console-pre}}")
	$inlineStart = [Regex]::Escape("{{@matlab}}")
	$inlineEnd   = [Regex]::Escape("{{/matlab}}")

	# (?s) means multiline mode
	$regexCode        = "(?s)$preStart(?<code>.*?)$preEnd"
	$regexCodeConsole = "(?s)$consoleStart(?<code>.*?)$consoleEnd"
	$regexCodeInline  = "$inlineStart(?<code>.*?)$inlineEnd"

	$Template = $Template -replace $regexCodeInline, {
		$code = $_.Groups['code'].Value
		if($code.Contains("}}")) { throw "Partial tag found in matlab code snippet: $code" }
		$Renderer.RenderMatlabCode( $code )
	}
	$Template = $Template -replace $regexCode, {
		$code = $_.Groups['code'].Value.Trim("`r", "`n")
		$lines = $code -split '\r?\n'
		$linesRendered = $lines | ForEach-Object {
			if($_.Contains("}}")) { throw "Partial tag found in matlab code snippet: $_" }
			$Renderer.RenderMatlabCode( $_ )
		}
		return "<pre class=""code-example""><code>$($linesRendered -join "`n")</code></pre>"
	}
	$Template = $Template -replace $regexCodeConsole, {
		$code = $_.Groups['code'].Value.Trim("`r", "`n")
		$lines = $code -split '\r?\n'
		$linesRendered = $lines | ForEach-Object {
			if($_.Contains("}}")) { throw "Partial tag found in matlab code snippet: $_" }
			$Renderer.RenderMatlabCode( $_ )
		}
		return "<pre class=""code-example code-console""><code>$($linesRendered -join "`n")</code></pre>"
	}
	return $Template
}


################################################################################################
## RUN
################################################
try {
	RunMain;
}
catch {
	$trace = $_.ScriptStackTrace -split "`n"
	[Array]::Reverse($trace)
	Write-Host ($trace -join "`n")
	throw
}

