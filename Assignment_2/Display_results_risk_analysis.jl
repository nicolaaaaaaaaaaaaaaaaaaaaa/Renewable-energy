using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("Two_price_scheme_risk_analysis.jl")
include("One_price_scheme_risk_analysis.jl")

betas=[(k-1)/100 for k in 1:100]
N=length(betas)
step=1/100
benefits_1 = zeros(N)
CVAR_1 = zeros(N)
benefits_2 = zeros(N)
CVAR_2 = zeros(N)
for n in 1:N
    benefits_1[n], CVAR_1[n] = one_price_risk_analysis(betas[n])
    benefits_2[n], CVAR_2[n] = two_price_risk_analysis(betas[n])
end

plot(CVAR_1,benefits_1, label="one price scheme", xlabel="CVAR (DKK)", ylabel="expected profit (DKK)", title="CVAR vs expected profit", linewidth=2)
plot!(CVAR_2,benefits_2, label="two price scheme", xlabel="CVAR (DKK)", ylabel="expected profit (DKK)", title="CVAR vs expected profit", linewidth=2)

filepath = joinpath(@__DIR__, "risk_analysis_CVAR_profit.png")
savefig(filepath)