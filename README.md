# Crane Dynamics Simulator
Coming soon...

A MATLAB and C++ package to generate and solve equations of motion.

Mainly intended for the dynamical modelling of construction cranes, this package can solve systems with closed kinematic chains, holonomic algebraic constraints, and arbitrary external inputs (including use of state feedback).

The software architecture is designed around homogeneous transformation matrices. The user should specify the kinematic chain of their system as the sequence of transformations between each joint. The package then symbolically generates the equation of motion through the Euler-Lagrange formulation with Lagrange multipliers. The package can then solve these equations in MATLAB, or export them to C++. Tools provided to visualise the results can calculate the joint space trajectories, task space trajectories, and system energies.

