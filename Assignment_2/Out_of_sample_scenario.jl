using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("Two_price_scheme_risk_analysis.jl")
include("One_price_scheme_risk_analysis.jl")
#we pick a beta
beta=0.7

#
expected_profit,_,p_bid=two_price_risk_analysis(beta)
println(p_bid)

NUS=length(Unseen_scenarios)
println(NUS)
expected_profit_us=0
for scenario in Unseen_scenarios
    global expected_profit_us+=sum((scenario[2][t]*p_bid[t]+(0.9 + 0.1*(scenario[3][t]))*scenario[2][t]*max(0,scenario[1][t]-p_bid[t])-(1.2+0.2*(scenario[3][t]-1))*scenario[2][t]*max(0,p_bid[t]-scenario[1][t])) for t in 1:T)/NUS
end

println("expected profit selected scenarios $(expected_profit)")
println("expected profit unseen scenarios $(expected_profit_us)")

valeurs=[expected_profit,expected_profit_us]
bar(["in-sample scenarios","out-of sample scenarios"], [expected_profit,expected_profit_us], color= couleurs = ["blue", "green"], bar_width=1, xlabel="case", ylabel="Expected profit (DKK)", legend=false, title="Comparison of the average out-of-sample profit with the in-sample expected profit ")
