using ControlSystemsBase
using CairoMakie
using LinearAlgebra

# == SRG Boundary via Hyperbolic Convex Hull ====================
function srg_boundary(H; n_arc_points=15)
    n = length(H)
    upper = Point2f[]
    for i in 1:n-1
        z1, z2 = H[i], H[i+1]
        dre = real(z2) - real(z1)
        if abs(dre) < 1e-14
            for t in range(0, 1, length=n_arc_points)
                z = z1 + t * (z2 - z1)
                push!(upper, Point2f(real(z), imag(z)))
            end
        else
            c = (abs2(z2) - abs2(z1)) / (2 * dre)
            R = abs(z1 - c)
            theta1 = atan(imag(z1), real(z1) - c)
            theta2 = atan(imag(z2), real(z2) - c)
            dtheta = theta2 - theta1
            if dtheta > pi; dtheta -= 2pi
            elseif dtheta < -pi; dtheta += 2pi; end
            for t in range(0, 1, length=n_arc_points)
                theta = theta1 + t * dtheta
                push!(upper, Point2f(c + R * cos(theta), R * sin(theta)))
            end
        end
    end
    lower = [Point2f(p[1], -p[2]) for p in reverse(upper)]
    boundary = vcat(upper, lower)
    if !isempty(boundary); push!(boundary, boundary[1]); end
    return boundary
end

function subsample(H::Vector{ComplexF64}, n_max::Int)
    n = length(H)
    n <= n_max && return H
    idx = round.(Int, range(1, n, length=n_max))
    return H[idx]
end

# == Systems ====================================================
G_msd = tf([2.0], [1.0, 2*0.2*sqrt(1.0*4.0), 4.0])

La, Ra, Kt, Kb = 0.01, 2.0, 0.05, 0.05
J, b_motor = 0.001, 0.001
G_dc = tf([Kt], [J*La, J*Ra+b_motor*La, b_motor*Ra+Kt*Kb, 0.0]) * tf([10.0, 5.0], [1, 0])

G_tank = 2.0 * tf([1.0], [1, 0]) * tf([-0.25, 1], [0.25, 1])

G_opamp = tf([10.0], [1.0, 1.0, 4.0])

# == Frequency ranges ===========================================
omega_msd   = exp10.(range(-1.0, 1.5, length=2000))
omega_dc    = exp10.(range(0, 4, length=3000))
omega_tank  = exp10.(range(-0.5, 1.5, length=2000))
omega_opamp = exp10.(range(-1.0, 2.0, length=2000))

# == Nyquist points =============================================
H_msd   = vec(freqresp(G_msd, omega_msd))
H_dc    = vec(freqresp(G_dc, omega_dc))
H_tank  = vec(freqresp(G_tank, omega_tank))
H_opamp = vec(freqresp(G_opamp, omega_opamp))

# == SRG boundaries (subsampled: 200 pts for polygon speed) ====
N_SUB = 200
srg_msd   = srg_boundary(subsample(H_msd, N_SUB))
srg_dc    = srg_boundary(subsample(H_dc, N_SUB))
srg_tank  = srg_boundary(subsample(H_tank, N_SUB))
srg_opamp = srg_boundary(subsample(H_opamp, N_SUB))

println("Polygon sizes: MSD=$(length(srg_msd)) DC=$(length(srg_dc)) Tank=$(length(srg_tank)) OpAmp=$(length(srg_opamp))")

# == Plot =======================================================
fig = Figure(size=(1400, 1200), fontsize=13)

function plot_panel!(fig, row, col, H, srg_pts, name, color; xlim=nothing, ylim=nothing)
    ax = Axis(fig[row, col],
        xlabel="Re[L(jw)]", ylabel="Im[L(jw)]",
        title=name, aspect=DataAspect())
    poly!(ax, srg_pts, color=(color, 0.20), strokewidth=0)
    srg_x = [p[1] for p in srg_pts]; srg_y = [p[2] for p in srg_pts]
    lines!(ax, srg_x, srg_y, color=(color, 0.5), linewidth=1, label="SRG boundary")
    lines!(ax, real.(H), imag.(H), color=color, linewidth=2.5, label="Nyquist G(jw)")
    lines!(ax, real.(H), -imag.(H), color=color, linewidth=1, linestyle=:dash, label="w < 0")
    scatter!(ax, [-1], [0], color=:black, markersize=12, marker=:xcross)
    if xlim !== nothing; xlims!(ax, xlim...); end
    if ylim !== nothing; ylims!(ax, ylim...); end
    axislegend(ax, position=:rt, framevisible=false, labelsize=10)
    return ax
end

plot_panel!(fig, 1, 1, H_msd, srg_msd, "Mass-Spring-Damper (z=0.2)", :royalblue)
plot_panel!(fig, 1, 2, H_dc, srg_dc, "DC Motor + PI", :forestgreen, xlim=(-5, 2), ylim=(-4, 4))
plot_panel!(fig, 2, 1, H_tank, srg_tank, "Tank + Delay (Kp=2)", :darkorange, xlim=(-5, 2), ylim=(-5, 5))
plot_panel!(fig, 2, 2, H_opamp, srg_opamp, "Op-Amp (G only)", :purple)

save("srg_intro.png", fig, px_per_unit=2)
println("Saved srg_intro.png")