# ScaledRelativeGraphs.jl
[WORK IN PROGRESS]

**Geometric stability analysis for industrial control systems — from classical Nyquist to nonlinear robustness certificates.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Julia](https://img.shields.io/badge/Julia-1.10%2B-purple.svg)](https://julialang.org)

ScaledRelativeGraphs.jl is a Julia toolkit for computing, visualizing, and applying Scaled Relative Graphs (SRGs) to real-world stability problems. It bridges the gap between SRG theory and engineering practice by providing computable stability certificates, standards-linked compliance checking, and measured-data workflows — alongside a rigorous mathematical foundation.

## Why SRGs?

Classical stability tools give you a binary answer (stable/unstable) or scalar margins (gain margin, phase margin). SRGs give you a **geometric stability certificate**: a computable, visualizable region in the complex plane whose distance from the critical point quantifies *how robustly* your system is stable — even when it contains nonlinearities like saturation, backlash, hysteresis, or droop control.

| Classical Method | What You Get | Limitation |
|-----------------|-------------|------------|
| Nyquist plot | Encirclement count | LTI only, single curve, no uncertainty |
| Gain/Phase margin | Two scalar numbers | Miss multi-frequency interactions |
| Circle criterion | Stable / not stable | Conservative for real nonlinearities |
| **SRG analysis** | **Geometric region + distance margin** | **Handles nonlinear, modular, quantitative** |

## Who Is This For?

**Control engineers and practitioners** who need to verify stability of real plants — including systems with actuator saturation, sensor deadzone, communication delays, or nonlinear process dynamics — and want quantitative robustness margins beyond classical GM/PM.

**Power systems engineers** working with inverter-based resources, droop-controlled microgrids, or standards compliance (IEEE 2800, IEC 61400) who need decentralized stability certificates for grid-connected converters.

**Process control engineers** dealing with integrating processes, transport delays, and nonlinear valve characteristics where classical margins are insufficient or misleading.

**Researchers** in nonlinear control, robust control, and optimization who want a computational platform for SRG-based analysis with reproducible benchmarks and publication-quality visualization.

## Features

### Core SRG Engine
- **LTI systems**: Soft and hard SRG computation via hyperbolic convex hull and disk intersection algorithms
- **Static nonlinearities**: Saturation, deadzone, backlash, quantizer, and user-defined monotone/non-monotone maps
- **Dynamic nonlinear operators**: Rayleigh sampling and Monte Carlo SRG estimation
- **Feedback composition**: SRG interconnection rules for series, parallel, and feedback configurations
- **Stability certificates**: SRG separation distance as a quantitative robustness metric
- **Incremental L₂-gain bounds**: Performance certificates derived from SRG geometry

### Classical Methods (Built-in Comparison)
- Nyquist plots with encirclement counting and annotation
- Bode magnitude and phase plots
- Gain margin, phase margin, and delay margin computation
- Circle criterion and Popov criterion visualization
- Side-by-side Nyquist vs. SRG comparison panels

### Visualization
- Publication-quality vector figures via CairoMakie (PDF/SVG/PNG export)
- Scatter → convex hull → density contour progression
- Frequency-colored SRG plots showing gain-phase interaction across bandwidth
- Annotated stability margins as geometric distances
- Interactive parameter sweeps (damping, gain, delay) showing SRG evolution

### Practitioner Tools
- **Measured data import**: Compute empirical SRGs from frequency response measurements (Bode analyzer, network analyzer, swept-sine test data)
- **Standards compliance**: Map control performance requirements onto SRG constraints (IEEE 2800 ride-through envelopes, droop specifications)
- **Stability reports**: Generate exportable margin summaries with pass/fail against user-defined or standard-defined criteria
- **What-if analysis**: Recompute stability certificates under parameter variations (gain changes, component degradation, operating point shifts)

## References

**Foundational SRG theory:**
- E. K. Ryu, R. Hannah, W. Yin, "Scaled relative graphs: nonexpansive operators via 2D Euclidean geometry," *Mathematical Programming*, vol. 194, pp. 569–619, 2022.

**SRGs for control systems:**
- T. Chaffey, F. Forni, R. Sepulchre, "Graphical nonlinear system analysis," *IEEE Trans. Automatic Control*, 2023.
- T. Chaffey, F. Forni, R. Sepulchre, "Scaled relative graphs for system analysis," *CDC*, 2021.

**Recent advances:**
- J. P. J. Krebbekx, R. Tóth, A. Das, "Graphical analysis of nonlinear multivariable feedback systems," *arXiv:2507.16513*, 2025.
- J. P. J. Krebbekx, E. Baron-Prada, R. Tóth, A. Das, "Computing the hard scaled relative graph of LTI systems," *arXiv:2511.17297*, 2025.
- J. P. J. Krebbekx, R. Tóth, A. Das, "Scaled relative graph analysis of general interconnections of SISO nonlinear systems," *arXiv:2507.15564*, 2025.
- C. Chen, S. Z. Khong, R. Sepulchre, "Soft and hard scaled relative graphs for nonlinear feedback stability," *arXiv:2504.14407*, 2025.

**Power systems applications:**
- E. Baron-Prada, A. Anta, "Stability analysis of power-electronics-dominated grids using scaled relative graphs," *arXiv:2601.16014*, 2026.
- L. Huang et al., "Gain and phase: decentralized stability conditions for power electronics-dominated power systems," *IEEE Trans. Power Systems*, 2024.

**Standards:**
- IEEE Std 2800-2022, "Standard for Interconnection and Interoperability of Inverter-Based Resources Interconnecting with Associated Transmission Electric Power Systems."

## Contributing

Contributions welcome — especially:
- New benchmark systems from your domain (chemical process, aerospace, robotics, power)
- Nonlinearity models (friction, backlash, rate limiters, lookup tables)
- Import filters for commercial instrument data formats
- Standards compliance envelopes for your industry
- Performance improvements and test coverage

## License

MIT License. See [LICENSE](LICENSE) for details.
