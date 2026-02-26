using ControlSystemsBase
using CairoMakie
# ── Benchmark 3: Tank Level with Delay ───────────────────────
K_tank = 1.0    # process gain [m/s per m³/s]
τ = 0.5         # transport delay [s]

# Padé(1,1) approximation of delay
G_tank = tf([K_tank], [1, 0]) * tf([-τ/2, 1], [τ/2, 1])

# P controller — vary gain to show stability boundary
gains_tank = [1.0, 3.0, 6.0]
colors_tank = [:forestgreen, :orange, :crimson]
labels_tank = ["Kp=1 (stable)", "Kp=3 (marginal)", "Kp=6 (unstable)"]

ω_tank = exp10.(range(-1, 2, length=3000))  # extend lower for integrator

fig3 = Figure(size=(900, 700))
# ax3 = Axis(fig3[1,1],
#     xlabel = "Re[L(jω)]", ylabel = "Im[L(jω)]",
#     title  = "Nyquist Diagram — Tank Level (Integrator + Delay)",
#     aspect = DataAspect(),
# )

ax3 = Axis(fig3[1,1],
    xlabel = "Re[L(jω)]", ylabel = "Im[L(jω)]",
    title  = "Nyquist Diagram — Tank Level (Integrator + Delay)",
    aspect = DataAspect(),
)
xlims!(ax3, -4, 2)
ylims!(ax3, -4, 4)

for (Kp_t, col, lab) in zip(gains_tank, colors_tank, labels_tank)
    L_tank = Kp_t * G_tank
    resp_t = freqresp(L_tank, ω_tank)
    Ljw_t = vec(resp_t)

    lines!(ax3, real.(Ljw_t), imag.(Ljw_t),
        color=col, linewidth=2, label=lab)
    lines!(ax3, real.(Ljw_t), -imag.(Ljw_t),
        color=col, linewidth=1, linestyle=:dash)
end


scatter!(ax3, [-1], [0], color=:black, markersize=12, marker=:xcross)
theta = range(0, 2π, length=200)
lines!(ax3, cos.(theta), sin.(theta), color=:gray70, linewidth=1, linestyle=:dot)
axislegend(ax3, position=:rb)
save("nyquist_tank_level.png", fig3)
