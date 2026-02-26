using SrgTools
using ControlSystemsBase
using CairoMakie

# Quick smoke test: compute SRG of a simple system
G = tf([1], [1, 1, 1])
alphas = collect(-2:0.1:2)
phis = collect(0:0.02:pi)
freqs = exp10.(collect(-2:0.05:2))
srg_upper = compute_lti_srg_boundary_upperhalfplane(G, alphas, phis, freqs)
println("SRG computed: $(length(srg_upper)) upper-half boundary points")