using ControlSystemsBase
using CairoMakie

# ── Benchmark 4: LTI + Saturation (Lur'e) ───────────────────
# Linear part: second-order with moderate damping
G_opamp = tf([10], [1, 1, 4])   # G(s) = 10/(s² + s + 4)

# Saturation nonlinearity (for simulation, not Nyquist)
saturate(x; lim=1.0) = clamp(x, -lim, lim)

# The Nyquist analysis uses G(s) alone — the nonlinearity
# enters through the circle criterion
ω_op = exp10.(range(-2, 3, length=3000))
resp_op = freqresp(G_opamp, ω_op)
Ljw_op = vec(resp_op)

fig4 = Figure(size=(900, 700))
ax4 = Axis(fig4[1,1],
    xlabel = "Re[G(jω)]", ylabel = "Im[G(jω)]",
    title  = "Nyquist + Circle Criterion — Op-Amp with Saturation",
    aspect = DataAspect(),
)

# Nyquist plot of G
lines!(ax4, real.(Ljw_op), imag.(Ljw_op),
    color=:royalblue, linewidth=2, label="G(jω)")
lines!(ax4, real.(Ljw_op), -imag.(Ljw_op),
    color=:royalblue, linewidth=1, linestyle=:dash)

# Circle criterion forbidden region for sector [0, 1]:
# Nyquist must not enter Re < -1 (half-plane to left of -1)
vlines!(ax4, [-1], color=:red, linewidth=2, linestyle=:dash,
    label="Circle criterion boundary")
# Shade the forbidden region
band!(ax4, [-4, -1], [-4, -4], [4, 4],
    color=(:red, 0.08))

scatter!(ax4, [-1], [0], color=:black, markersize=12, marker=:xcross)
axislegend(ax4, position=:rt)
fig4
save("nyquist_sat_opamp.png", fig4)
