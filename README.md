![Static Badge](https://img.shields.io/badge/license-BSD--3--Clause--Clear-darkgreen)
![Static Badge](https://img.shields.io/badge/tested-MATLAB_2025a-blue)
![Static Badge](https://img.shields.io/badge/version-2.0.0-blue)
![Static Badge](https://img.shields.io/badge/NO_AI-rebeccapurple)

# Crane Dynamics Simulator
A MATLAB package for simulating mechanical systems.

Systems are described through a declarative interface, and the software then symbolically generates the equations of motion using the Euler-Lagrange formulation with Lagrange multipliers. The software can solve these equations in MATLAB, or export them to C++. Tooling is provided to automatically generate, evaluate, and plot symbolic expressions for physical quantities at a per-system-element level, including trajectories, force decompositions, energy decompositions, and power decompositions.

- This package does not contain any AI generated content.
- The design philosophy is to provide automation, not abstraction.
- The underlying maths and physics are accessible to the user, and are presented in a way that mirrors a pen-and-paper derivation.


DOCUMENTATION
- [Documentation Website](https://Brandon-Johns.github.io/crane-dynamics-simulator/)
- [Maths and Physics Background (pdf)](./doc/public_html/crane-dynamics-simulator/crane-dynamics-simulator-maths-and-physics.pdf)

KEY DIRECTORIES
- The simulator: `core/CDS/`
- Introductory examples: `run_matlab/Examples/`


## Citation
Please cite this work as
```bibtex
@Software{BrandonJohnsCDS,
  author  = {Brandon Johns},
  title   = {Crane Dynamics Simulator},
  url     = {https://github.com/Brandon-Johns/crane-dynamics-simulator},
  version = {2.0.0},
  year    = {2026},
}

@TechReport{BrandonJohnsCDS2,
  author      = {Brandon Johns},
  title       = {Crane Dynamics Simulator: Physics and Mathematical Background},
  url         = {https://github.com/Brandon-Johns/crane-dynamics-simulator},
  institution = {No Affiliation},
  note        = {Version 2.0.0},
  year        = {2026},
}
```

Version 1.0.0 of this work is companion to [our publication](https://doi.org/10.1007/s43452-023-00702-x)
```bibtex
@Article{BrandonJohnsCDS1,
  author  = {Brandon Johns and Elahe Abdi and Mehrdad Arashpour},
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
Version 1.0.0 of this research was supported by an Australian Government Research Training Program (RTP) Scholarship.


## License
This software is distributed under the [BSD-3-Clause-Clear License](./LICENSE.txt)

The data, user guide, and documentation are distributed under the [Creative Commons CC BY 4.0 license](https://creativecommons.org/licenses/by/4.0/)

The following files are excluded from these licenses. Copyright (c) 2023 Brandon Johns. All rights reserved. Do not redistribute, repurpose, modify, etc.
- `docs/apple-touch-icon.png`
- `docs/favicon-96x96.png`
- `docs/favicon.ico`
- `docs/favicon.svg`
- `docs/web-app-manifest-192x192.png`
- `docs/web-app-manifest-512x512.png`
- `docs/embed.png`


## Source Code
This project is hosted at https://github.com/Brandon-Johns/crane-dynamics-simulator

