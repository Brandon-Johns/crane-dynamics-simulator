# Tutorial: Create and Run Your First Model
This tutorial is recommended as an introduction to all users.

You will learn how to use this package to simulate a triple pendulum.

Steps:
1. Define the model on paper
2. Create a new run-file
3. Define the model in code
4. Run the solver
5. Post-process the solution

The full code of this example is `run_matlab/Examples/E8_TriplePendulum.m`


## Define the Model on paper
To define your model:
- Draw the kinematic chain
- Assign constant parameters (e.g. gravity, link lengths)
- Assign generalised coordinates (e.g. joint angles, lengths of prismatic joints)
- Assign a coordinate frame to every joint and centre of mass location
- Attach mass and/or moment of inertia to the coordinate frames

There is no need to write equations. A labelled diagram is sufficient.

For the triple pendulum, I have used
- Constants
    - `g = 9.8`
    - `L_1 = 1`
    - `L_2 = 1`
    - `L_3 = 1`
- Generalised coordinates
    - `theta_1`, with initial conditions $\theta_1 = \pi/4$ and $\dot{\theta}_1 = 0$
    - `theta_2`, with initial conditions $\theta_2 = 0$ and $\dot{\theta}_2 = 0$
    - `theta_3`, with initial conditions $\theta_3 = 0$ and $\dot{\theta}_3 = 0$
- Frames: `O`, `O2`, `A`, `B`, `C`
- Mass and moment of inertia
    - At `A`: $m_A = 1$ and $I_A = 0_{3,3}$
    - At `B`: $m_B = 1$ and $I_B = 0_{3,3}$
    - At `C`: $m_C = 1$ and $I_C = 0_{3,3}$

![triple pendulum](/Documentation/img/TriplePendulumModel.png)


## Create a new run-file
Initial Setup
- Download this repository
- Create a new directory within `run_matlab`
    - e.g. `run_matlab/MyProject`
- Copy in a `CDS_FindIncludes.m` file from one of the other folders within `run_matlab`
- Edit this file so that it adds `core/includes_matlab/` to the MATLAB path

Create a run-file
- In the new directory, create a new matlab script (I call this a run-file, because it runs the simulator)
    - e.g. `run_matlab/MyProject/TriplePendulum.m`
- At the top of the run-file, add the code
```MATLAB
CDS_FindIncludes;
CDS_IncludeSimulator;
```

You should now have created
- `run_matlab/MyProject/CDS_FindIncludes.m`
- `run_matlab/MyProject/TriplePendulum.m`


## Define the Model in code
Continuing editing the run-file:

### Parameters
All parameters must be created with a single `CDS_Params` instance by calling `.Create()`.
An appropriate `Set` method can optionally be chained to the output.
```MATLAB
% Builder/manager object
params = CDS_Params();

% System parameters
%   Define and set the numeric value
params.Create('const', 'L_1').SetNum(1);
params.Create('const', 'L_2').SetNum(1);
params.Create('const', 'L_3').SetNum(1);
params.Create('const', 'g').SetNum(9.8);

% Generalised coordinates
%   Define and set the initial conditions
params.Create('free', 'theta_1').SetIC(pi/4);
params.Create('free', 'theta_2').SetIC(0);
params.Create('free', 'theta_3').SetIC(0);
```

**Aside:** This syntax can be understood as the combination of
```MATLAB
tmp = params.Create('const', 'myVar');
tmp.SetNum(1);
```

Note that `CDS_Params.Create('myType', 'myVar')` has the side effect of calling `syms myVar` in the current workspace.

### Points / Kinematic Chains
The geometry of the system can now be described, in terms of the parameters, as a set of homogeneous transformation matrices
```MATLAB
% Forward kinematics between the frames
% NOTE: Using shorthand notation. See the aside for explanation
T_OO2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [0;0;0]);
T_O2A = CDS_T('atP', 'z', theta_2, [L_1;0;0]);
T_AB  = CDS_T('atP', 'z', theta_3, [L_2;0;0]);
T_BC  = CDS_T('atP', 'z', 0, [L_3;0;0]);

% Combine to obtain the transformation to each frame as relative to the base frame
T_OA = T_OO2 * T_O2A;
T_OB = T_OA * T_AB;
T_OC = T_OB * T_BC;
```

The notation `T_AB` means the transformation matrix that satisfies the relation `P_A = T_AB * P_B` where `P_A` is a point as measured in frame A, and `P_B` is the same point as measured in frame B.

**Aside:** `CDS_T()` accepts shorthand inputs as well as full 4x4 transformation matrices
```MATLAB
% These are equivalent ('P' means point)
CDS_T('P', [x;y;z]);
CDS_T([1,0,0,x; 0,1,0,y; 0,0,1,z; 0,0,0,1]);

% These are equivalent ('at' means rotation about the x, y, or z axis by theta)
CDS_T('at', 'z' theta); % Rotation about the z axis
CDS_T([1,0,0,0; 0,cos(theta),-sin(theta),0; 0,sin(theta),cos(theta),0; 0,0,0,1]);

% These are equivalent (Combination of the above)
CDS_T('atP', 'z', theta, [x;y;z]);
CDS_T([1,0,0,x; 0,cos(theta),-sin(theta),y; 0,sin(theta),cos(theta),z; 0,0,0,1]);
```

Next, all particles and rigid bodies must be registered with a single `CDS_Points` instance by calling `.Create().SetT_0n()`
- Notation
    - `0` means the base frame (world frame)
    - `n` means the frame of the current point
- Points are locations defined by a transformation matrix (they have both position and orientation)
    - Particles are points that have mass
    - Rigid bodies are points that have mass and moment of inertia
- Uses
    - Only particles and rigid bodies influence the solution dynamics
    - Other points may be optionally defined by omitting the mass and moment of inertia inputs
    - The locations of all points are calculated after solving, that their values may be queried or plotted
```MATLAB
% Builder/manager object
points = CDS_Points(params);

% SYNTAX: .Create('Name', mass, inertia)
O = points.Create('O');
A = points.Create('A', 1).SetT_0n(T_OA);
B = points.Create('B', 1).SetT_0n(T_OB);
C = points.Create('C', 1).SetT_0n(T_OC);
```

The structure of the kinematic chain is then declared as a set of arrays.
- This is does not effect the solution. It is only used for plotting the animation
- The plotter will draw animated lines joining the points in each array

```MATLAB
% Kinematic chains (used only for plotting the animation)
chains = {[O,A,B,C]};
```

### Complete the System Description
The magnitude and direction of gravity should be defined as an acceleration vector, as measured in the base frame.

In this case, I have chosen y as up in the base frame, with gravity pointing in the negative y direction.
```MATLAB
% Direction of gravity in base frame
g0 = [0; -g; 0];
```

Then, all of the above are combined into a complete `CDS_SystemDescription`
```MATLAB
% System description
% This contains all of the information required to simulate the system
sys = CDS_SystemDescription(params, points, chains, g0);
```


## Run the Solver
Now that the system has been completely defined, the package can automatically generate and solve the equations of motion

The final options to choose are:
- The time to solve over
    - Specified either as a range, or a set of values to evaluate
    - This does not influence the values that the solver uses internally, only the values that are output
- The integration tolerances
- The solver
    - `.Solve(sys)` (Automatic)
    - `.Solve(sys, "ode89")` Specify a MATLAB ODE solver
    - `.Solve(sys, "drawIC")` Skip solving and just plot the initial conditions
    - `.Solve(sys, "sundials")` Export the equations to C++ for solving with SUNDIALS
- The equation formulation method
    - For almost all cases, the best option is to use the automatic mode

```MATLAB
SO = CDS_Solver_Options();
SO.time = 0 : 0.02 : 20;
SO.RelTol = 1e-10;
SO.AbsTol = 1e-10;

% Generate and solve equation of motion
S = CDS_Solver(SO);
[t,x,xd] = S.Solve(sys);
```


## Post-Process the Solution
The system description can be used to automatically post-process the solution to obtain
- The value of each generalised coordinate
- The position of each point
- The energies of each particle / rigid body

```MATLAB
SS = CDS_SolutionSim(sys, t,x,xd);
```

This solution object can then be used to
- Generate plots
- Generate a real-time animation

```MATLAB
SSp = CDS_Solution_Plot(SS);
SSa = CDS_Solution_Animate(SS);

SSp.PlotConfigSpace
SSp.PlotLambda
SSp.PlotInput
SSp.PlotEnergyTotal
SSp.PlotEnergyAll
SSp.PlotTaskSpace


SSa.Set_View_Predefined("front")
SSa.PlotFrame
SSa.Animate("play") % Click the "Repeat" button on the figure to play the animation!
%SSa.Animate("gif")
%SSa.Animate("video")
```

The post-processed data can be exported to excel in a human readable format
```MATLAB
% Export
SSe = CDS_Solution_Export(SS);
SSe.DataToExcel("mySolution.xlsx");
```

The post-processed data can also be queried by using the names of the parameters / points
- Recall that each parameter / point was named during its creation; when `CDS_Params.Create()` or `CDS_Points.Create()` was called
```MATLAB
SSg = CDS_Solution_GetData(SS);

% Get the value of theta_2, and its derivatives at the time 3.8 seconds
idx = SSg.t_idx(3.8);
fprintf("theta_2 at 3.8s = %g\n",           SSg.q("theta_2", idx));
fprintf("d[theta_2]/dt at 3.8s = %g\n",     SSg.qd("theta_2", idx));
fprintf("d^2[theta_2]/dt^2 at 3.8s = %g\n", SSg.qdd("theta_2", idx));

% Get the x,y,z locations of each point at this same time
fprintf("x coordinate of point C at 3.8s = %g\n", SSg.Px("C", idx));
fprintf("y coordinate of point C at 3.8s = %g\n", SSg.Py("C", idx));
fprintf("z coordinate of point C at 3.8s = %g\n", SSg.Pz("C", idx));
```


## Experiment with the Code
Explore the properties of the variable `SS`

Also try changing the
- model parameters (lengths, mass, moment of inertia)
- initial conditions (initial angle, initial angular velocity)
- solve options

### Add a Constraint
Using `sys.SetConstraint(C)` requires the solver to satisfy the equation $\frac{dC}{dt}=0$

Try different constraints by adding the following just after the line `sys = CDS_SystemDescription(params, points, chains, g0);`
```MATLAB
% These constraints can fix the linkage to slide along a rail
% Use only 1 at a time
sys.SetConstraint(T_OB.x);
sys.SetConstraint(T_OB.y);
sys.SetConstraint(T_OC.x);
sys.SetConstraint(T_OC.y);
```

### Add an Input
Inputs are parameters that vary with time according to a predefined function. Note that using inputs makes the Lagrangian time dependent. This means that the total system energy will not necessarily be conserved.

Implement the following changes to make the top of the pendulum move according to the trajectory $L_O(t) = sin(t)$
```MATLAB
% Add this
params.Create('input', 'L_O').SetAnalytic(sin(sym('t')));

% Change this
T_OO2 = CDS_T('atP', 'z', theta_1-sym(pi)/2, [L_O;0;0]);

% Change this
O = points.Create('O').SetT_0n(T_OO2);
```

It may be necessary to remove any previously added constraints. Check that the input dopes not cause impossible geometry!


