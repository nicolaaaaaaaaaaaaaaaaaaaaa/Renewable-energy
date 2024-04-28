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
    println("running beta =")
    println(betas[n])
    benefits_1[n], CVAR_1[n] = one_price_risk_analysis(betas[n])
    benefits_2[n], CVAR_2[n] = two_price_risk_analysis(Selected_scenarios, betas[n])
end

plot(CVAR_1,benefits_1, label="one price scheme", xlabel="CVAR (DKK)", ylabel="expected profit (DKK)", title="CVAR vs expected profit", linewidth=2)
plot!(CVAR_2,benefits_2, label="two price scheme", xlabel="CVAR (DKK)", ylabel="expected profit (DKK)", title="CVAR vs expected profit", linewidth=2)

filepath = joinpath(@__DIR__, "risk_analysis_CVAR_profit.png")
savefig(filepath)

min_CVAR_1 = minimum(CVAR_1)
max_CVAR_1 = maximum(CVAR_1)
min_CVAR_2 = minimum(CVAR_2)
max_CVAR_2 = maximum(CVAR_2)

min_ex_profit_1 = minimum(benefits_1)
max_ex_profit_1 = maximum(benefits_1)
int_ex_profit_1 = max_ex_profit_1 - min_ex_profit_1
min_ex_profit_2 = minimum(benefits_2)
max_ex_profit_2 = maximum(benefits_2)
int_ex_profit_2 = max_ex_profit_2 - min_ex_profit_2


# Print the computed values
println("1-price scheme: Minimum CVAR: $min_CVAR_1")
println("1-price scheme: Maximum CVAR: $max_CVAR_1")
println("2-price scheme: Minimum CVAR: $min_CVAR_2")
println("2-price scheme: Maximum CVAR: $max_CVAR_2")
println()
println("1-price scheme: Minimum expected profit: $min_ex_profit_1")
println("1-price scheme: Maximum expected profit: $max_ex_profit_1")
println("1-price scheme: interval: $int_ex_profit_1")
println("1-price scheme: Maximum expected profit: $max_ex_profit_1")
println("2-price scheme: Minimum expected profit: $min_ex_profit_2")
println("2-price scheme: Maximum expected profit: $max_ex_profit_2")
println("2-price scheme: interval: $int_ex_profit_2")