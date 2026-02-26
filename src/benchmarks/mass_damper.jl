# using Pkg;
# Pkg.add("ControlSystemsBase")
# Pkg.add("CairoMakie")
using ControlSystemsBase
using CairoMakie

# ── Benchmark 1: Mass-Spring-Damper ──────────────────────────
# Plant: G(s) = 1/(ms² + cs + k),  Controller: C(s) = Kp
# Open-loop: L(s) = Kp/(ms² + cs + k)

m, k, Kp = 1.0, 4.0, 2.0

# Three damping cases
damping_cases = [
    (ζ = 0.2, label = "Underdamped (ζ=0.2)",  color = :crimson),
    (ζ = 1.0, label = "Critical (ζ=1.0)",     color = :royalblue),
    (ζ = 2.0, label = "Overdamped (ζ=2.0)",   color = :forestgreen),
]

# Frequency vector: log-spaced from 0.01 to 100 rad/s
ω = exp10.(range(-2, 3, length=2000))

fig = Figure(size=(900, 700))
ax = Axis(fig[1,1],
    xlabel = "Re[L(jω)]",
    ylabel = "Im[L(jω)]",
    title  = "Nyquist Diagram — Mass-Spring-Damper",
    aspect = DataAspect(),
)

# Plot each damping case
for case in damping_cases
    c_damp = 2 * case.ζ * sqrt(m * k)          # damping coefficient
    L = tf([Kp], [m, c_damp, k])                # open-loop TF
    resp = freqresp(L, ω)                       # complex frequency response
    Ljw = vec(resp)                              # extract as vector

    # Positive frequencies
    lines!(ax, real.(Ljw), imag.(Ljw),
        color=case.color, linewidth=2, label=case.label)
    # Negative frequencies (reflection)
    lines!(ax, real.(Ljw), -imag.(Ljw),
        color=case.color, linewidth=1, linestyle=:dash)
end

# Critical point
scatter!(ax, [-1], [0], color=:black, markersize=12, marker=:xcross)
text!(ax, Point2f(-1.05, 0.08), text="−1", fontsize=14)

# Unit circle for reference
θ = range(0, 2π, length=200)
lines!(ax, cos.(θ), sin.(θ), color=:gray70, linewidth=1, linestyle=:dot)

axislegend(ax, position=:rt)
fig
save("nyquist_mass_spring_damper.png", fig)
