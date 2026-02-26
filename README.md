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

### Benchmark Library
| System | Type | Domain | What It Teaches |
|--------|------|--------|-----------------|
| Mass-spring-damper | 2nd order LTI | Mechanical | SRG as enriched Nyquist; damping effects |
| DC motor with load | 3rd order LTI | Electromechanical | Multi-timescale dynamics; gain-phase coupling |
| Tank level control | Integrator + delay | Process control | SRG margins vs. classical GM/PM; delay limits |
| Op-amp with saturation | Lur'e system | Electronics | SRG vs. circle criterion; tightness of bounds |
| Servo with backlash | LTI + hysteresis | Motion control | Nonlinear SRG sampling; limit cycle prediction |
| Inverter droop control | Nonlinear monotone | Power systems | Decentralized stability; grid-forming certification |

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

### For Practitioners: "Is my system robustly stable?"

```julia
using ScaledRelativeGraphs
using ControlSystemsBase

# Define your plant and controller
G = tf([10], [1, 3, 5, 0])     # 3rd-order plant with integrator
C = tf([2, 1], [1, 10])         # lead compensator

# Get a stability certificate in one call
report = stability_report(G, C)
println(report)
# Output:
#   Closed-loop stable: ✓
#   Classical gain margin: 8.4 dB
#   Classical phase margin: 52.3°
#   SRG separation distance: 0.37  (≥ 0 required for stability)
#   Incremental L₂-gain bound: 2.71
#   Robustness: system tolerates up to 37% simultaneous gain AND phase perturbation

# Visualize
plot_stability_report(report)
```

### For Practitioners: "What if my actuator saturates?"

```julia
# Add a saturation nonlinearity in the loop
phi = Saturation(lower=-1.0, upper=1.0)

# SRG-based analysis handles this directly
report_nl = stability_report(G, C, nonlinearity=phi)
println(report_nl)
# Output:
#   Closed-loop incrementally stable: ✓
#   SRG separation distance: 0.21  (reduced from 0.37 — saturation costs margin)
#   Circle criterion margin: 0.08  (more conservative)
#   SRG improvement over circle criterion: 2.6×

plot_comparison(report, report_nl, labels=["Linear", "With saturation"])
```

### For Researchers: Full Access to Mathematical Objects

```julia
using ScaledRelativeGraphs
using ControlSystemsBase
using CairoMakie

# Compute the SRG object directly
G = tf([2], [1, 0.8, 4])
ω = exp10.(range(-2, 2, length=2000))

srg = compute_srg(G, ω, type=:soft)      # soft SRG (L₂ signals)
srg_h = compute_srg(G, ω, type=:hard)    # hard SRG (L₂e signals)

# Access the geometry
srg.boundary          # Vector{ComplexF64} — boundary points
srg.nyquist           # Nyquist diagram (subset of boundary)
srg.contains(-1+0im)  # true/false — does the SRG contain -1?
srg.distance_to(-1)   # minimum distance from SRG to -1

# Compute SRG of a nonlinear operator via sampling
phi = x -> clamp(x, -1, 1)   # saturation
srg_nl = sample_srg(phi, n_samples=10_000)

# Feedback stability: check separation
is_stable, margin = check_separation(srg, inv(srg_nl))

# Build publication figures
fig = Figure(size=(1200, 500))
plot_srg!(fig[1,1], srg, title="Plant SRG")
plot_srg!(fig[1,2], srg_nl, title="Nonlinearity SRG")
plot_feedback_srg!(fig[1,3], srg, srg_nl, title="Feedback Analysis")
save("figure_for_paper.pdf", fig)
```

### From Measured Data

```julia
# Import frequency response data from a Bode analyzer
# Format: CSV with columns [frequency_Hz, magnitude_dB, phase_deg]
data = import_frd("plant_measurement.csv")

# Compute empirical SRG from measured data
srg_measured = compute_srg(data)

# Compare against model
G_model = tf([10], [1, 3, 5, 0])
srg_model = compute_srg(G_model, data.frequencies)

plot_comparison(srg_model, srg_measured,
    labels=["Model", "Measured"],
    title="Model Validation via SRG")
```

## Repository Structure

```
ScaledRelativeGraphs.jl/
├── src/
│   ├── ScaledRelativeGraphs.jl    # Main module and exports
│   ├── types.jl                   # Core types: SRGResult, FRDData, StabilityReport
│   ├── nyquist.jl                 # Classical Nyquist computation and margins
│   ├── srg_lti.jl                 # SRG for LTI systems (soft and hard)
│   ├── srg_nonlinear.jl           # SRG for static and dynamic nonlinearities
│   ├── srg_feedback.jl            # Feedback interconnection and separation
│   ├── certificates.jl            # Stability reports and compliance checking
│   ├── convex_hull.jl             # Hyperbolic convex hull and boundary algorithms
│   ├── visualization.jl           # CairoMakie plotting utilities
│   ├── io.jl                      # Import/export: FRD files, CSV, reports
│   ├── nonlinearities/
│   │   ├── saturation.jl
│   │   ├── deadzone.jl
│   │   ├── backlash.jl
│   │   ├── quantizer.jl
│   │   └── custom.jl
│   ├── benchmarks/
│   │   ├── mass_spring_damper.jl
│   │   ├── dc_motor.jl
│   │   ├── tank_level.jl
│   │   ├── opamp_saturation.jl
│   │   ├── servo_backlash.jl
│   │   └── inverter_droop.jl
│   └── standards/
│       ├── ieee2800.jl            # IEEE 2800 ride-through and droop envelopes
│       └── common.jl              # Generic compliance envelope framework
├── examples/
│   ├── 01_nyquist_basics.jl
│   ├── 02_srg_lti.jl
│   ├── 03_srg_nonlinear.jl
│   ├── 04_feedback_stability.jl
│   ├── 05_nyquist_vs_srg.jl
│   ├── 06_from_measurements.jl
│   ├── 07_saturation_analysis.jl
│   ├── 08_inverter_droop.jl
│   └── 09_parameter_sweep.jl
├── paper/
│   ├── figures/
│   └── generate_all_figures.jl
├── test/
│   ├── runtests.jl
│   ├── test_nyquist.jl
│   ├── test_srg_lti.jl
│   ├── test_srg_nonlinear.jl
│   └── test_certificates.jl
├── Project.toml
├── LICENSE
└── README.md
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `ControlSystemsBase.jl` | Transfer functions, frequency response, margins |
| `CairoMakie.jl` | Publication-quality vector graphics |
| `QHull.jl` | Convex hull computation for SRG boundaries |
| `LinearAlgebra` | SVD, eigenvalues for MIMO operations |
| `StaticArrays.jl` | Performance for small fixed-size arrays |
| `DelimitedFiles` | CSV/FRD data import |

## Relationship to Other Tools

**[SrgTools.jl](https://github.com/Krebbekx/SrgTools.jl)** (Krebbekx, Tóth, Das) — Focuses on MIMO LTI systems in Linear Fractional Representation for the research frontier. ScaledRelativeGraphs.jl targets a broader audience with industrial benchmarks, measured-data workflows, nonlinearity libraries, and standards compliance — while maintaining a rigorous mathematical core.

**[ControlSystems.jl](https://github.com/JuliaControl/ControlSystems.jl)** — Provides the LTI backbone that ScaledRelativeGraphs.jl builds on. If ControlSystems.jl is MATLAB's Control System Toolbox, ScaledRelativeGraphs.jl is the nonlinear extension.

**MATLAB Robust Control Toolbox** — Offers μ-analysis and IQC tools for linear robust control. SRGs provide a complementary geometric approach that handles a broader class of nonlinearities with less conservatism than IQCs for structured problems, and with visual interpretability that μ-analysis lacks.

## Companion Manuscript

> S. Ramharack and J. Nancoo, "From Nyquist to Scaled Relative Graphs: A Computational Framework for Nonlinear Stability Analysis in Industrial Control Systems," *submitted*, 2026.

Scripts to reproduce all manuscript figures are in `paper/`.

## Roadmap

- [x] Core SRG computation (soft, LTI)
- [x] Classical Nyquist comparison tools
- [x] Static nonlinearity SRGs (saturation, deadzone)
- [x] Publication-quality visualization
- [x] Benchmark system library
- [ ] Hard SRG computation
- [ ] MIMO SRG support
- [ ] Frequency response data import/export
- [ ] Standards compliance framework (IEEE 2800)
- [ ] Empirical SRG from measured data
- [ ] Interactive parameter sweep tools
- [ ] Backlash and hysteresis operators
- [ ] Lyapunov certificate extraction

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
