# ============================================================================
# ScaledRelativeGraphs.jl — Benchmark Tutorial: Nyquist + SRG Visualization
#
# This script uses SrgTools.jl (Krebbekx, Toth, Das, 2025) for the core
# SRG boundary computation, and extends it with:
#   - CairoMakie publication-quality visualization (poly! filled regions)
#   - Nyquist overlay comparison
#   - Industrial benchmark systems (not in SrgTools.jl)
#   - Axis-limit tuning for integrator-containing systems
#
# SRG computation:  SrgTools.compute_lti_srg_boundary_upperhalfplane()
# Visualization:    CairoMakie poly!() with filled polygons
# Systems:          ControlSystemsBase.jl transfer functions
#
# Reference:
#   J.P.J. Krebbekx, R. Toth, A. Das, "Graphical Analysis of Nonlinear
#   Multivariable Feedback Systems," arXiv:2507.16513, 2025.
#   https://github.com/Krebbekx/SrgTools.jl
# ============================================================================

using SrgTools          # Krebbekx SRG computation engine
using ControlSystemsBase
using CairoMakie
using LinearAlgebra

# == Helper: convert SrgTools output to CairoMakie polygon ====================
#
# SrgTools returns the SRG upper-half boundary as a Vector{ComplexF64}.
# We reflect it to get the full boundary, then convert to Point2f for poly!().

function srg_to_polygon(srg_upper::Vector{ComplexF64})
    srg_full = vcat(srg_upper, conj.(reverse(srg_upper)))
    pts = [Point2f(real(z), imag(z)) for z in srg_full]
    if !isempty(pts)
        push!(pts, pts[1])  # close the polygon
    end
    return pts
end

# == System Definitions ========================================================

# Benchmark 1: Mass-Spring-Damper (2nd order, underdamped, zeta=0.2)
G_msd = tf([2.0], [1.0, 2*0.2*sqrt(4.0), 4.0])

# Benchmark 2: DC Motor + PI controller
La, Ra, Kt, Kb = 0.01, 2.0, 0.05, 0.05
J, b_motor = 0.001, 0.001
G_dc = tf([Kt], [J*La, J*Ra+b_motor*La, b_motor*Ra+Kt*Kb, 0.0]) * tf([10.0, 5.0], [1, 0])

# Benchmark 3: Tank + Delay (Kp=2, Pade(1,1) approximation, tau=0.5s)
G_tank = 2.0 * tf([1.0], [1, 0]) * tf([-0.25, 1], [0.25, 1])

# Benchmark 4: Op-Amp (linear block for Lure analysis)
G_opamp = tf([10.0], [1.0, 1.0, 4.0])

# == SrgTools parameters ======================================================
# alphas:      real-axis grid for circle-based SRG computation
# phis:        angular resolution in [0, pi] for upper half plane
# frequencies: log-spaced frequency evaluation points

phis = collect(0:0.02:pi)  # angular resolution ~157 points

# Per-system frequency ranges (tuned to avoid integrator blowup)
freq_msd   = exp10.(collect(-1.0:0.02:1.5))
# freq_dc    = exp10.(collect(0.0:0.01:4.0))     # start at 1 rad/s
freq_dc    = exp10.(collect(0.5:0.01:4.0))   # start at ~3 rad/s
# freq_tank  = exp10.(collect(-0.5:0.02:1.5))     # start at ~0.3 rad/s
freq_tank  = exp10.(collect(0.0:0.02:1.5))   # start at 1 rad/s
freq_opamp = exp10.(collect(-1.0:0.02:2.0))

# Per-system alpha ranges (real-axis sweep for circle computation)
alphas_msd   = collect(-1.0:0.05:1.0)
# alphas_dc    = collect(-5.0:0.1:3.0)
alphas_dc  = collect(-3.0:0.1:1.0)           # narrower
# alphas_tank  = collect(-6.0:0.1:3.0)
alphas_tank = collect(-3.0:0.1:1.0)          # narrower
alphas_opamp = collect(-1.0:0.05:3.0)

# == Compute SRG boundaries using SrgTools =====================================
println("Computing SRG boundaries via SrgTools.jl...")

srg_upper_msd   = compute_lti_srg_boundary_upperhalfplane(G_msd,   alphas_msd,   phis, freq_msd)
srg_upper_dc    = compute_lti_srg_boundary_upperhalfplane(G_dc,    alphas_dc,    phis, freq_dc)
srg_upper_tank  = compute_lti_srg_boundary_upperhalfplane(G_tank,  alphas_tank,  phis, freq_tank)
srg_upper_opamp = compute_lti_srg_boundary_upperhalfplane(G_opamp, alphas_opamp, phis, freq_opamp)

println("  MSD upper boundary: $(length(srg_upper_msd)) points")
println("  DC  upper boundary: $(length(srg_upper_dc)) points")
println("  Tank upper boundary: $(length(srg_upper_tank)) points")
println("  OpAmp upper boundary: $(length(srg_upper_opamp)) points")

# Convert to CairoMakie polygons
poly_msd   = srg_to_polygon(srg_upper_msd)
poly_dc    = srg_to_polygon(srg_upper_dc)
poly_tank  = srg_to_polygon(srg_upper_tank)
poly_opamp = srg_to_polygon(srg_upper_opamp)

# == Compute Nyquist points (fine grid for smooth curves) ======================
H_msd   = vec(freqresp(G_msd,   exp10.(range(-1.5, 1.5, length=2000))))
H_dc    = vec(freqresp(G_dc,    exp10.(range(0, 4, length=3000))))
H_tank  = vec(freqresp(G_tank,  exp10.(range(-0.5, 1.5, length=2000))))
H_opamp = vec(freqresp(G_opamp, exp10.(range(-1.0, 2.0, length=2000))))

# == Figure: 2x2 grid with CairoMakie =========================================
fig = Figure(size=(1400, 1200), fontsize=13)

function plot_panel!(fig, row, col, H, srg_pts, name, color; xlim=nothing, ylim=nothing)
    ax = Axis(fig[row, col],
        xlabel="Re[L(jw)]", ylabel="Im[L(jw)]",
        title=name, aspect=DataAspect())

    # SRG filled region (from SrgTools computation)
    poly!(ax, srg_pts, color=(color, 0.20), strokewidth=0)

    # SRG boundary outline
    srg_x = [p[1] for p in srg_pts]; srg_y = [p[2] for p in srg_pts]
    lines!(ax, srg_x, srg_y, color=(color, 0.5), linewidth=1, label="SRG (SrgTools.jl)")

    # Nyquist curve (positive frequencies)
    lines!(ax, real.(H), imag.(H), color=color, linewidth=2.5, label="Nyquist G(jw)")
    # Negative frequencies (reflection)
    lines!(ax, real.(H), -imag.(H), color=color, linewidth=1, linestyle=:dash, label="w < 0")

    # Critical point -1+0j
    scatter!(ax, [-1], [0], color=:black, markersize=12, marker=:xcross)

    if xlim !== nothing; xlims!(ax, xlim...); end
    if ylim !== nothing; ylims!(ax, ylim...); end

    axislegend(ax, position=:rt, framevisible=false, labelsize=10)
    return ax
end

# Panel 1: Mass-Spring-Damper
plot_panel!(fig, 1, 1, H_msd, poly_msd,
    "Mass-Spring-Damper (z=0.2)", :royalblue)

# Panel 2: DC Motor + PI (zoomed around critical point)
plot_panel!(fig, 1, 2, H_dc, poly_dc,
    "DC Motor + PI", :forestgreen,
    xlim=(-5, 2), ylim=(-4, 4))

# Panel 3: Tank + Delay (zoomed)
plot_panel!(fig, 2, 1, H_tank, poly_tank,
    "Tank + Delay (Kp=2)", :darkorange,
    xlim=(-5, 2), ylim=(-5, 5))

# Panel 4: Op-Amp (full view)
plot_panel!(fig, 2, 2, H_opamp, poly_opamp,
    "Op-Amp (G only)", :purple)

save("srg_intro.png", fig, px_per_unit=2)
#save("srg_intro.pdf", fig)
println("Saved srg_intro.png")