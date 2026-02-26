using ControlSystemsBase
using CairoMakie

# ── Benchmark 2: DC Motor ────────────────────────────────────
# Parameters (small hobby motor, SI units)
La = 0.01      # armature inductance [H]
Ra = 2.0       # armature resistance [Ω]
Kt = 0.05      # torque constant [N⋅m/A]
Kb = 0.05      # back-EMF constant [V⋅s/rad] (= Kt for ideal motor)
J  = 0.001     # rotor + load inertia [kg⋅m²]
b  = 0.001     # viscous friction [N⋅m⋅s/rad]

# Plant TF: G(s) = Kt / [s(J*La*s² + (J*Ra+b*La)s + (b*Ra+Kt*Kb))]
num_motor = [Kt]
den_motor = [J*La, (J*Ra + b*La), (b*Ra + Kt*Kb), 0.0]  # note trailing 0 for integrator
G_motor = tf(num_motor, den_motor)

# PI controller: C(s) = Kp + Ki/s = (Kp*s + Ki)/s
Kp_pi, Ki_pi = 10.0, 5.0
C_pi = tf([Kp_pi, Ki_pi], [1, 0])

# Open loop
L_motor = G_motor * C_pi

println("Open-loop poles: ", poles(L_motor))
println("Open-loop zeros: ", tzeros(L_motor))

# Nyquist plot
ω_motor = exp10.(range(-1, 5, length=5000))
resp_motor = freqresp(L_motor, ω_motor)
Ljw_motor = vec(resp_motor)

fig2 = Figure(size=(900, 700))
ax2 = Axis(fig2[1,1],
    xlabel = "Re[L(jω)]", ylabel = "Im[L(jω)]",
    title  = "Nyquist Diagram — DC Motor with PI Control",
    aspect = DataAspect(),
)

lines!(ax2, real.(Ljw_motor), imag.(Ljw_motor),
    color=:royalblue, linewidth=2, label="L(jω), ω > 0")
lines!(ax2, real.(Ljw_motor), -imag.(Ljw_motor),
    color=:royalblue, linewidth=1, linestyle=:dash, label="L(jω), ω < 0")
scatter!(ax2, [-1], [0], color=:black, markersize=12, marker=:xcross)
θ = range(0, 2π, length=200)
lines!(ax2, cos.(θ), sin.(θ), color=:gray70, linewidth=1, linestyle=:dot)

axislegend(ax2, position=:rt)
fig2
save("nyquist_dc_motor.png", fig2)
