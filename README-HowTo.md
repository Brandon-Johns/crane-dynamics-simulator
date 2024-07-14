# How To

Contents
* Use the transformation matrix class CDS_T
* Define a time dependent parameter (an input)
	* See also: `run_matlab/Examples/E10_TriplePendulumCartDriven.m`
* Define a closed-kinematic-chain model
	* See also: `run_matlab/Examples/E11_4BarLinkage.m`
* Define a model that has a kinematic constraint
	* See also: `run_matlab/Examples/E3_ParticleOnPath_A.m`
	* See also: `run_matlab/Examples/E4_ParticleOnPath_B.m`
	* See also: `run_matlab/Examples/E5_ParticleOnCone.m`
	* See also: `run_matlab/Examples/E6_ParticleOnSphere.m`
	* See also: `run_matlab/Examples/E11_4BarLinkage.m`
	* See also: `run_matlab/Examples/E12_Pulley.m`
	* See also: `run_matlab/Examples/E13_ParticleOnPath_Fancy.m`
* Use the SUNDIALS Solver
* Make automatic plots
* Export/Import the post-processed solution


## Use the transformation matrix class CDS_T
The class `CDS_T` represents a 4x4 homogeneous transformation matrix.

An instance can be created by inputting a 4x4 matrix directly
```MATLAB
T_matrix = [
    1,0,0,3;
    0,1,0,4;
    0,0,1,5;
    0,0,0,1
];

T = CDS_T(T_matrix);
```

Or by shorthand. The following pairs show the equivalent direct input to each shorthand
```MATLAB
syms x y z theta

% 'P' means point
CDS_T('P', [x;y;z]);
CDS_T([1,0,0,x; 0,1,0,y; 0,0,1,z; 0,0,0,1]);

% 'R' means rotation matrix
CDS_T('R', [0,0,1; -1,0,0; 0,1,0])
CDS_T([0,0,1,0; -1,0,0,0; 0,1,0,0; 0,0,0,1]);

% 'at' means rotation by theta about the x, y, or z axis
CDS_T('at', 'z' theta); % Rotation about the z axis
CDS_T([1,0,0,0; 0,cos(theta),-sin(theta),0; 0,sin(theta),cos(theta),0; 0,0,0,1]);

% Combination of 'R' and 'P'
CDS_T('RP', [0,0,1; -1,0,0; 0,1,0], [x;y;z]);
CDS_T([0,0,1,x; -1,0,0,y; 0,1,0,z; 0,0,0,1]);

% Combination of 'at' and 'P'
CDS_T('atP', 'z', theta, [x;y;z]);
CDS_T([1,0,0,x; 0,cos(theta),-sin(theta),y; 0,sin(theta),cos(theta),z; 0,0,0,1]);
```

The class provides these methods to extract data
```MATLAB
%% Position
>> T.x
3

>> T.y
4

>> T.z
5

>> T.P
[3; 4; 5]

% Homogeneous position
>> T.Ph
[3; 4; 5; 1]

% Rotation matrix
>> T.R
[1,0,0; 0,1,0; 0,0,1]

% Itself as a matrix
>> T.T
[1,0,0,3; 0,1,0,4; 0,0,1,5; 0,0,0,1]

% Its inverse
>> T_inv = T.Inv;
>> T_inv.T
[1,0,0,-3; 0,1,0,-4; 0,0,1,-5; 0,0,0,1]
```

Instances can be directly multiplied by each other and other matrices of compatible size
```MATLAB
syms x y z theta a b c
T1 = CDS_T('P', [x;y;z]);
T2 = CDS_T('at', 'z', theta);
P = [a;b;c;1];
T1 * T2 * P
```

Instances of this class are immutable (the value cannot be modified).
Instead of changing the value, a new object should be created

(Regarding DH Notation: I have no intension of ever implementing it.
Look, I get that it's useful, but I feel that I have to re-learn it every time I use it.)


## Define a time dependent parameter (an input)
Inputs are parameters that vary with time according to a predefined function

A potential application of an input is to represent a joint that is servo-actuated (i.e. position controlled, as opposed to force controlled)

When using inputs, the total system energy will not necessarily be conserved (i.e. the motor applies force which changes the system energy)

The variable to represent time must be the symbolic variable `t`

The following makes the parameter $L$ time dependent: $L(t) = sin(t)$
```MATLAB
syms t
params = CDS_Params();
params.Create('input', 'L').SetAnalytic(sin(t));

% Plot the input
time = 0:0.01:15;
plot(time, params.Param("L").q(time));
```

The following makes the parameter $L$ time dependent according to the piecewise function:
- $L(t) = t, t \in [0,5]$
- $L(t) = 2t - 5, t \in (5,9]$
- $L(t) = t + 4, t \in (9,15]$
```MATLAB
syms t
params = CDS_Params();
params.Create('input', 'L').SetPiecewise([t, 2*t-5, t+4], [5,9]);

% Plot the input
time = 0:0.01:15;
plot(time, params.Param("L").q(time));
```

Warning:
- Inputs can make the ODE become stiff
- Piecewise inputs can make the ODE stiff at the discontinuity

In general, it is best to first test with no input, and then with slow smooth inputs, before trying fast/rough inputs


## Define a closed-kinematic-chain model
This section uses the notation $T_{AB}$ to denote the transformation matrix that satisfies the relation $P_A = T_{AB} * P_B$ where $P_A$ is a point as measured in frame A, and $P_B$ is the same point as measured in frame B.

Defining a closed-kinematic chain model can be difficult.

Th following procedure can work in some circumstances:
1. Define the model as an open kinematic chain which just happens to close back on itself
	- This will result in assigning more generalised coordinates than degrees of freedom.
2. Identify a continuous segment of the chain for which its configuration which fully defines the closed chain model.
	- I call this the driving segment, and the rest of the chain is driven. Any generalised coordinates in the driven segment are dependent on the configuration of the driving segment. Hence, they should be solved in terms of the driving variables
3. Manually solve for the driven variables, in terms of the driving variables, through use of inverse kinematics methods
	1. Define every transformation matrix to move around the full chain
	2. Compose the transformation around the driving segment $T_{AB,driving}$ and then invert it for $T_{BA,driving}$
	3. Compose the transformation around the driven segment $T_{BA,driven}$
	4. Form the equation $T_{BA,driving} = T_{BA,driven}$ and solve for the driven variables
4. Substitute the solution expressions into the driven transformation matrices
5. Compose the transformations to each centre of mass, and finish building the model as usual

In case that it is difficult to manually solve $T_{BA,driving} = T_{BA,driven}$ then constraint equations can be used
1. Redo the procedure, but allow 1 more generalised coordinate then degree of freedom to be driving
2. Form a scalar constraint equation $C=0$ to force the chain to be closed
3. Apply this constraint with `sys.SetConstraint(C)`
4. Finish building the model as usual

Variations on this method can eliminate more driven variables, depending on the model. E.g. The constraint equation can require the length of a link to be constant by means of pythagoras theorem between the start and end of the link. Therefore, it's orientation does not need to be found. In 3D problems, this can eliminate multiple driven variables.

### Example
Consider a 4-bar mechanism
```
A---D
|   |
B---C
```
1. Define it as a 4 link open chain D-A-B-C
2. Fix link AD in space. Therefore, 3 joint angles are free. However, the model has 1 degree of freedom
	- Let joint A and joint B be driving
	- Therefore joint C is driven
3. Inverse kinematics
	- Find $T_{DC}$ in terms of the driven variables, and invert it for $T_{CD}$
	- The angle for joint C can be found as $\theta_3 = atan(y_{CD} / x_{CD})$, where
		- $x_{CD}=T_{CD}(1,4)$
		- $y_{CD}=T_{CD}(2,4)$
4. Constraint
	- Using the previously found $T_{CD}$
	- A possible constraint is $0 = \sqrt{x_{CD}^2 + y_{CD}^2} - L_{CD}$, which describes that the length of the link CD must be constant
	- Because the constrain equation is automatically differentiated by the package, it is valid to apply the constraint as `sys.SetConstraint( sqrt(x_CD^2 + y_CD^2) )`

This is demonstrated in `run_matlab/Examples/E11_4BarLinkage.m`

## Define a model that has a kinematic constraint
This package is optimised for use with either 1 or no constraint equations.
Use of multiple constraint equations is permitted, but requires using the low-accuracy ode15i solver.

Form a scalar constraint equation $C=0$. Apply this constraint with
```MATLAB
%   Given: sys = an instance of CDS_SystemDescription
sys.SetConstraint(C);
```

The set constraint will automatically be applied during solving.
Technically, the constraint will be differentiated by the package before being applied, but the effect is the same.

WARNING: Ensure that the initial conditions are consistent with the constraint equation

### Example
Constrain a point to move on the surface of a sphere
```MATLAB
% Equation for sphere
%    1 = Lx^2 + Ly^2 + Lz^2
% Rearrange into the form C=0
%    C = 0 = 1 - Lx^2 - Ly^2 - Lz^2

params = CDS_Params();
params.Create('free', 'Lx').SetIC(0.9);
params.Create('free', 'Ly').SetIC(0);
params.Create('free', 'Lz').SetIC(1 - 0.9^2);

% ...

C = 1 - Lx^2 - Ly^2 - Lz^2;
sys.SetConstraint(C);
```

The initial conditions are consistent with the constraint equation because when substituted into the constraint equation, the equation is equal to 0.


## Use the SUNDIALS Solver
Follow the installation instructions for your operating system
- `lib_ubuntu/instructions/Install_Instructions_Ubuntu.txt`
- `lib_windows/instructions/Install_Instructions_Windows.txt`

Generate the C++ code that represents the model by calling Solve with the following options
```MATLAB
% Given:
%   The generated code will be created in "data/sundials_generated/myDir1/myDir2"
%   SO = CDS_Solver_Options
%   sys = CDS_SystemDescription

exportPath = CDS_GetDataLocations().sun_generated("myDir1", "myDir2");
SO.exportPath = exportPath;

S = CDS_Solver(SO);
S.Solve(sys, "sundials");
```

In `run_sundials/src/SimC3/CMakeLists.txt`, set the variable `SunGenerated_Includes` to `myDir1/myDir2`
```CMake
set(SunGenerated_Includes
    "myDir1/myDir2"
)
```

Compile and run the code with the Visual Studio GUI or with the appropriate script. See `README-Reference.md` for more details
```BASH
# BASH
chmod +x "./run_sundials/ubuntu_buildrun.sh"
./run_sundials/ubuntu_buildrun.sh -cbe -r myResults -t myDir1-myDir2
```

```PowerShell
# PowerShell
#   It may be necessary to edit the paths in these scripts to match your version of Visual Studio
./run_sundials/rebuild.ps1
./run_sundials/runExe.ps1 -exeName "myDir1-myDir2" > "../data/sundials_results/myResults/myDir1-myDir2.txt"
```

The solution will be created at `data/sundials_results/myResults/myDir1-myDir2.txt`

Read the solution back into the simulator
```MATLAB
% Given:
%   The solution is in "data/sundials_results/myResults/myDir1-myDir2.txt"
%   sys = CDS_SystemDescription

% Read in the CSV/txt results
importPath = CDS_GetDataLocations().sun_results("myResults", "myDir1-myDir2.txt");
dataRaw = readmatrix(importPath);
t_import = dataRaw(:, 1).';
x_import = dataRaw(:, 2:end).';

% Remove the solver stats
t = t_import(isfinite(t_import));
x = x_import(:, isfinite(t_import));

% Build the solution object
sys.params.SetStateVectorMode("withoutLambda");
SS = CDS_SolutionSim(sys, t, x);
```


## Make automatic plots
The full list of automatic plots is
```MATLAB
%   Given: SS = an instance of CDS_Solution (or a subclass)
SSp = CDS_Solution_Plot(SS);
SSa = CDS_Solution_Animate(SS);

SSp.PlotConfigSpace
SSp.PlotLambda
SSp.PlotInput
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace
SSa.PlotFrame
SSa.Animate % Click the "Repeat" button on the figure to play the animation!

% Export the animation to a gif or video file
SSa.Animate("gif")
SSa.Animate("video")
```


## Export/Import the post-processed solution
The post-processed solution can be exported to excel in human readable format
```MATLAB
% Export
%   Given: SS = an instance of CDS_Solution (or a subclass)
SSe = CDS_Solution_Export(SS);
SSe.DataToExcel("mySolution.xlsx");
```

Reimporting the solution requires rebuilding the `CDS_SystemDescription` object.
It is your responsibility to ensure that this object is identical to the one that created the exported solution
```MATLAB
% Reimport
%   Given: sys = CDS_SystemDescription
SS_imported = CDS_SolutionSaved(sys, "mySolution.xlsx");
```


