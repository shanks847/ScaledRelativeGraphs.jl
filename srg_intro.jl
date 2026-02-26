using ControlSystemsBase
using CairoMakie
using LinearAlgebra

# ── SRG Boundary via Hyperbolic Convex Hull ──────────────────
# For a stable SISO LTI system, SRG(G) = hconv(Nyquist diagram)
# The boundary between consecutive Nyquist points is a circular
# arc centered on the real axis.
#
# Key insight: the arc always bulges AWAY from the real axis
# (outward), filling in concavities of the Nyquist curve.

function srg_boundary(H; n_arc_points=30)
    """
    Given Nyquist points H (complex vector, ordered by frequency),
    compute the SRG boundary as a closed polygon suitable for poly!().
    
    Returns Vector{Point2f} tracing the upper boundary (ω > 0),
    then the lower boundary (ω < 0, reflected), forming a closed region.
    """
    n = length(H)
    
    # Compute upper boundary: arcs between consecutive Nyquist points
    upper = Point2f[]
    
    for i in 1:n-1
        z1, z2 = H[i], H[i+1]
        dre = real(z2) - real(z1)
        
        if abs(dre) < 1e-14
            # Vertical segment — no circular arc, just interpolate
            for t in range(0, 1, length=n_arc_points)
                z = z1 + t * (z2 - z1)
                push!(upper, Point2f(real(z), imag(z)))
            end
        else
            # Circle centered at (c, 0) on real axis through z1 and z2
            c = (abs2(z2) - abs2(z1)) / (2 * dre)
            R = abs(z1 - c)
            
            theta1 = atan(imag(z1), real(z1) - c)
            theta2 = atan(imag(z2), real(z2) - c)
            
            # Choose the shorter arc
            dtheta = theta2 - theta1
            if dtheta > pi
                dtheta -= 2pi
            elseif dtheta < -pi
                dtheta += 2pi
            end
            
            for t in range(0, 1, length=n_arc_points)
                theta = theta1 + t * dtheta
                zz = c + R * cos(theta) + im * R * sin(theta)
                push!(upper, Point2f(real(zz), imag(zz)))
            end
        end
    end
    
    # Lower boundary: reflect upper boundary about real axis, reversed
    lower = [Point2f(p[1], -p[2]) for p in reverse(upper)]
    
    # Close the polygon: upper path forward, lower path backward
    boundary = vcat(upper, lower)
    
    # Close it
    if !isempty(boundary)
        push!(boundary, boundary[1])
    end
    
    return boundary
end

# ── System Definitions ───────────────────────────────────────

# Benchmark 1: Mass-Spring-Damper (2nd order, underdamped)
# G(s) = Kp / (ms² + cs + k), ζ = 0.2
m, k, Kp_msd = 1.0, 4.0, 2.0
zeta = 0.2
c_damp = 2 * zeta * sqrt(m * k)
G_msd = tf([Kp_msd], [m, c_damp, k])

# Benchmark 2: DC Motor + PI
La, Ra, Kt, Kb = 0.01, 2.0, 0.05, 0.05
J, b_motor = 0.001, 0.001
G_motor = tf([Kt], [J*La, J*Ra + b_motor*La, b_motor*Ra + Kt*Kb, 0.0])
C_pi = tf([10.0, 5.0], [1, 0])
G_dc = G_motor * C_pi

# Benchmark 3: Tank + Delay (Kp=2)
# G(s) = (K/s) * Pade(1,1) delay, with Kp=2
tau_delay = 0.5
G_tank = 2.0 * tf([1.0], [1, 0]) * tf([-tau_delay/2, 1], [tau_delay/2, 1])

# Benchmark 4: Op-Amp (linear block only)
G_opamp = tf([10.0], [1.0, 1.0, 4.0])

# ── Frequency ranges (tuned per system) ─────────────────────
omega_msd   = exp10.(range(-1.0, 1.5, length=2000))
omega_dc    = exp10.(range(0, 4, length=3000))       # start at 1 rad/s to avoid integrator blowup
omega_tank  = exp10.(range(-0.5, 1.5, length=2000))  # start at ~0.3 rad/s
omega_opamp = exp10.(range(-1.0, 2.0, length=2000))

# ── Compute Nyquist points ──────────────────────────────────
H_msd   = vec(freqresp(G_msd, omega_msd))
H_dc    = vec(freqresp(G_dc, omega_dc))
H_tank  = vec(freqresp(G_tank, omega_tank))
H_opamp = vec(freqresp(G_opamp, omega_opamp))

# ── Compute SRG boundaries ──────────────────────────────────
srg_msd   = srg_boundary(H_msd)
srg_dc    = srg_boundary(H_dc)
srg_tank  = srg_boundary(H_tank)
srg_opamp = srg_boundary(H_opamp)

# ── Figure: 2×2 grid, each panel shows Nyquist + SRG ────────
fig = Figure(size=(1400, 1200), fontsize=13)

function plot_nyquist_srg!(fig, row, col, H, srg_pts, name, color;
                           xlim=nothing, ylim=nothing)
    ax = Axis(fig[row, col],
        xlabel = "Re[L(jω)]",
        ylabel = "Im[L(jω)]",
        title  = name,
        aspect = DataAspect(),
    )
    
    # SRG as filled polygon (the key fix!)
    poly!(ax, srg_pts, color=(color, 0.20), strokewidth=0)
    
    # Nyquist curve (positive frequencies)
    lines!(ax, real.(H), imag.(H),
        color=color, linewidth=2.5, label="Nyquist G(jω)")
    # Negative frequencies (reflection)
    lines!(ax, real.(H), -imag.(H),
        color=color, linewidth=1, linestyle=:dash, label="ω < 0")
    
    # SRG boundary outline
    srg_x = [p[1] for p in srg_pts]
    srg_y = [p[2] for p in srg_pts]
    lines!(ax, srg_x, srg_y,
        color=(color, 0.5), linewidth=1, label="SRG boundary")
    
    # Critical point
    scatter!(ax, [-1], [0], color=:black, markersize=12, marker=:xcross)
    
    # Set axis limits if provided
    if xlim !== nothing
        xlims!(ax, xlim...)
    end
    if ylim !== nothing
        ylims!(ax, ylim...)
    end
    
    axislegend(ax, position=:rt, framevisible=false, labelsize=10)
    
    return ax
end

# Panel 1: Mass-Spring-Damper — full view, no clipping needed
plot_nyquist_srg!(fig, 1, 1, H_msd, srg_msd,
    "Mass-Spring-Damper (ζ=0.2)", :royalblue)

# Panel 2: DC Motor + PI — zoom to region around -1
plot_nyquist_srg!(fig, 1, 2, H_dc, srg_dc,
    "DC Motor + PI", :forestgreen,
    xlim=(-5, 2), ylim=(-4, 4))

# Panel 3: Tank + Delay — zoom to region around -1
plot_nyquist_srg!(fig, 2, 1, H_tank, srg_tank,
    "Tank + Delay (Kp=2)", :darkorange,
    xlim=(-5, 2), ylim=(-5, 5))

# Panel 4: Op-Amp (linear block)
plot_nyquist_srg!(fig, 2, 2, H_opamp, srg_opamp,
    "Op-Amp (G only)", :purple)

save("srg_intro.png", fig, px_per_unit=2)  # high-res output
println("Saved srg_intro.png")