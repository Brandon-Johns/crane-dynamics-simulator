# Crane Dynamics Simulator
A MATLAB and C++ package to generate and solve equations of motion.

Mainly intended for the dynamical modelling of construction cranes, this package can solve systems with closed kinematic chains, holonomic algebraic constraints, and arbitrary external inputs (including use of state feedback).

The software architecture is designed around homogeneous transformation matrices. To simulate a system, the user specifies the kinematic chain of the system as the sequence of transformations between each joint. The package then symbolically generates the equation of motion through the Euler-Lagrange formulation with Lagrange multipliers. The package can then solve these equations in MATLAB, or export them to C++. Tools provided to visualise the results automatically calculate the joint space trajectories, task space trajectories, and system energies.

DOC LINKS:
- [Tutorial](./README-Tutorial.md)
- [How To](./README-HowTo.md)
- [Reference](./README-Reference.md)

EXAMPLES:
- `run_matlab/Examples/`


## Requirements
**Theoretical background of user:**
- Robotics / Mechanics
    - Describe mechanical systems with [kinematic chains](https://en.wikipedia.org/wiki/Kinematic_chain)
    - Describe 3D pose with [4x4 homogeneous transformation matrices](https://robotacademy.net.au/masterclass/3d-geometry/?lesson=102)
    - Describe system state with [generalised coordinates](https://en.wikipedia.org/wiki/Generalized_coordinates)
- ODEs
    - Basic understanding of [ODEs](https://en.wikipedia.org/wiki/Ordinary_differential_equation)
    - Set initial conditions

**Matlab**
- Symbolic Math Toolbox
- Robotics System Toolbox
- Signal Processing Toolbox (used in some input files)

**C++**
- C++ is only required if using the [SUNDIALS solver](https://computing.llnl.gov/projects/sundials) instead of the MATLAB ODE solvers
- For dependencies, see setup instructions


## Getting Started
1. Download this repository
2. Run the tests to validate that the package is working by executing
    - `run_matlab/Tests/Run_IntegrationTests.m`
3. Follow the [Tutorial](./README-Tutorial.md) to create and run your first model
4. Run the examples (`run_matlab/Examples/`) to learn more complex functionality
5. Review the [How To](./README-HowTo.md)
6. Review the [Reference](./README-Reference.md)


## Citation
This work is companion to [our publication](https://doi.org/10.1007/s43452-023-00702-x)
```bibtex
@Article{citeKey,
  author  = {Johns, Brandon and Abdi, Elahe and Arashpour, Mehrdad},
  journal = {Archives of Civil and Mechanical Engineering},
  title   = {Dynamical modelling of boom tower crane rigging systems: model selection for construction},
  year    = {2023},
  issn    = {1644-9665},
  number  = {3},
  pages   = {162},
  volume  = {23},
  doi     = {10.1007/s43452-023-00702-x},
}
```

(Optional) If you find this work to be useful, please message me and share how you used it. I'd love to hear about it. 
You can find me here: [twitter](https://twitter.com/BrandonJohns96), [linkedin](https://www.linkedin.com/in/brandon-johns-6bab7815a).


## Acknowledgments
This research was supported by an Australian Government Research Training Program (RTP) Scholarship.


## License
This work is distributed under the [BSD-3-Clause License](./LICENSE.txt)

The data, user guide, and documentation are distributed under the [Creative Commons CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/)


## Source Code
This project is hosted at https://github.com/Brandon-Johns/crane-dynamics-simulator

