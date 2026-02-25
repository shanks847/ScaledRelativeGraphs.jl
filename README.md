# ScaledRelativeGraphs.jl

**A pedagogical and application-oriented Julia toolkit for graphical nonlinear stability analysis.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Julia](https://img.shields.io/badge/Julia-1.10%2B-purple.svg)](https://julialang.org)

ScaledRelativeGraphs.jl provides a complete computational pipeline from classical Nyquist stability analysis to Scaled Relative Graph (SRG) methods for nonlinear systems, with a focus on clear pedagogy, publication-quality figures, and power systems benchmarks.

## Motivation

Scaled Relative Graphs generalize the Nyquist diagram to nonlinear operators, enabling geometric stability assessment where classical methods either fail or produce conservative results. While the theory has matured rapidly (Ryu et al., 2022; Chaffey et al., 2023; Krebbekx et al., 2025), accessible computational tools with worked examples remain scarce.

This package bridges that gap by providing:

- A **first-principles progression** from Nyquist plots → SRGs → nonlinear stability → feedback interconnections
- **Classical benchmark systems** (mass-spring-damper, DC motor, tank level, op-amp with saturation) that build intuition before tackling complex applications
- **Publication-quality visualization** with convex hulls, density contours, and annotated stability margins via CairoMakie
- **Power systems benchmarks** including droop-controlled grid-forming inverters

## Relationship to SrgTools.jl

[SrgTools.jl](https://github.com/Krebbekx/SrgTools.jl) by Krebbekx, Tóth, and Das provides MIMO SRG computation focused on Linear Fractional Representations (LFR) for the research frontier. ScaledRelativeGraphs.jl complements it with a different scope: pedagogical progression, classical benchmark systems, advanced visualization, and power-electronic applications. Users working on MIMO LFR problems should use SrgTools.jl; users seeking tutorial-level understanding or power systems analysis will find this package more suitable.

## Features

### Nyquist Analysis
- Nyquist plot computation and rendering for arbitrary LTI systems
- Gain margin, phase margin, and stability margin visualization
- Encirclement counting and annotation
- Side-by-side comparison with SRG representations

### SRG Computation
- **LTI systems**: Soft SRG via hyperbolic convex hull of the Nyquist diagram
- **Static nonlinearities**: Sector-bounded, saturation, deadzone, and custom monotone maps
- **Rayleigh sampling**: Monte Carlo SRG estimation for general operators
- **Convex hull boundaries**: Tight SRG enclosures with `QHull` integration

### Feedback & Stability
- SRG separation theorem: geometric distance as stability certificate
- Feedback interconnection SRG composition
- Circle criterion recovery and comparison
- Incremental L₂-gain bounds from SRG distances
- Connection to incremental Lyapunov / dissipativity theory

### Visualization
- Publication-quality figures via CairoMakie (PDF/SVG vector export)
- Scatter plots → convex hull boundaries → density contours
- Annotated stability margins as geometric distances
- Frequency-colored SRG plots showing gain-phase interaction
- Side-by-side Nyquist vs. SRG comparison panels

### Benchmark Systems
| System | Type | What It Teaches |
|--------|------|-----------------|
| Mass-spring-damper | 2nd order LTI | SRG as enriched Nyquist; damping ratio effects |
| DC motor with load | 3rd order LTI | Multi-timescale dynamics; gain-phase interaction |
| Tank level control | Integrator + delay | SRG margins vs. classical GM/PM; delay limitations |
| Op-amp with saturation | Lur'e (LTI + nonlinearity) | SRG vs. circle criterion; tightness of bounds |
| Inverter droop control | Nonlinear power systems | Decentralized stability; grid-forming applications |

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/<your-username>/ScaledRelativeGraphs.jl")
```

Or for development:

```bash
git clone https://github.com/<your-username>/ScaledRelativeGraphs.jl.git
cd ScaledRelativeGraphs.jl
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

## Quick Start

```julia
using ScaledRelativeGraphs
using ControlSystemsBase
using CairoMakie

# Define a plant: mass-spring-damper
G = tf([1], [1.0, 0.8, 4.0])   # m=1, c=0.8, k=4 (underdamped)

# Compute and plot the Nyquist diagram
fig_nyquist = plot_nyquist(G, label="G(jω)")

# Compute the SRG (hyperbolic convex hull of Nyquist)
srg = compute_srg(G)
fig_srg = plot_srg(srg, label="SRG(G)")

# Compare side by side
fig = compare_nyquist_srg(G)
save("comparison.pdf", fig)

# Feedback stability check
C = tf([2], [1])                # proportional controller
margin_info = srg_stability_margin(G, C)
println("SRG separation distance: ", margin_info.distance)
```

## Repository Structure

```
ScaledRelativeGraphs.jl/
├── src/
│   ├── ScaledRelativeGraphs.jl   # Main module
│   ├── nyquist.jl                # Nyquist computation and plotting
│   ├── srg_lti.jl                # SRG for LTI systems
│   ├── srg_nonlinear.jl          # SRG for static and dynamic nonlinearities
│   ├── srg_feedback.jl           # Feedback interconnection and separation
│   ├── visualization.jl          # CairoMakie plotting utilities
│   ├── convex_hull.jl            # Convex hull and boundary computation
│   └── benchmarks/
│       ├── mass_spring_damper.jl
│       ├── dc_motor.jl
│       ├── tank_level.jl
│       ├── opamp_saturation.jl
│       └── inverter_droop.jl
├── examples/
│   ├── 01_nyquist_basics.jl
│   ├── 02_srg_lti.jl
│   ├── 03_srg_nonlinear.jl
│   ├── 04_feedback_stability.jl
│   ├── 05_nyquist_vs_srg.jl
│   └── 06_inverter_droop.jl
├── paper/
│   ├── figures/                  # Generated publication figures
│   └── generate_all_figures.jl   # Reproduce all manuscript figures
├── test/
│   ├── runtests.jl
│   ├── test_nyquist.jl
│   ├── test_srg_lti.jl
│   └── test_srg_nonlinear.jl
├── Project.toml
├── LICENSE
└── README.md
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `ControlSystemsBase.jl` | Transfer functions, frequency response |
| `CairoMakie.jl` | Publication-quality vector graphics |
| `QHull.jl` | Convex hull computation for SRG boundaries |
| `LinearAlgebra` | SVD, eigenvalues for MIMO SRGs |
| `StaticArrays.jl` | Performance for small fixed-size arrays |

## Companion Manuscript

This package accompanies the manuscript:

> S. Ramharack and J. Nancoo, "From Nyquist to Scaled Relative Graphs: A Computational Tutorial for Nonlinear Stability Analysis with Power Systems Applications," *submitted to [journal]*, 2026.

The `paper/` directory contains scripts to reproduce all figures in the manuscript.

## References

**Foundational SRG theory:**
- E. K. Ryu, R. Hannah, W. Yin, "Scaled relative graphs: nonexpansive operators via 2D Euclidean geometry," *Mathematical Programming*, vol. 194, pp. 569–619, 2022.

**SRGs for control systems:**
- T. Chaffey, F. Forni, R. Sepulchre, "Graphical nonlinear system analysis," *IEEE Trans. Automatic Control*, 2023.
- T. Chaffey, F. Forni, R. Sepulchre, "Scaled relative graphs for system analysis," *CDC*, 2021.

**Recent advances:**
- J. P. J. Krebbekx, R. Tóth, A. Das, "Scaled relative graph analysis of general interconnections of SISO nonlinear systems," *arXiv:2507.15564*, 2025.
- J. P. J. Krebbekx, E. Baron-Prada, R. Tóth, A. Das, "Computing the hard scaled relative graph of LTI systems," *arXiv:2511.17297*, 2025.
- C. Chen, S. Z. Khong, R. Sepulchre, "Soft and hard scaled relative graphs for nonlinear feedback stability," *arXiv:2504.14407*, 2025.

**SRGs for power systems:**
- E. Baron-Prada, A. Anta, F. Dörfler, "On decentralized stability conditions using scaled relative graphs," *IEEE Control Systems Letters*, 2025.
- E. Baron-Prada, A. Anta, "Stability analysis of power-electronics-dominated grids using scaled relative graphs," *arXiv:2601.16014*, 2026.
- L. Huang, D. Wang, X. Wang, et al., "Gain and phase: decentralized stability conditions for power electronics-dominated power systems," *IEEE Trans. Power Systems*, vol. 39, no. 6, 2024.

**Companion toolbox:**
- J. P. J. Krebbekx, R. Tóth, A. Das, [SrgTools.jl](https://github.com/Krebbekx/SrgTools.jl), 2025.

## Contributing

Contributions are welcome. Please open an issue or pull request for:
- Additional benchmark systems
- Visualization improvements
- Performance optimizations
- Documentation and tutorials

## License

MIT License. See [LICENSE](LICENSE) for details.
