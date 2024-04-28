using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("Scenario generation.jl")
include("Two_price_scheme_risk_analysis.jl")

Random.seed!()


function scenario_generation(Scenario_list, frac)

    Random.seed!()

    # creates a seen and un-seen scenario list depending on the fraction of seen w.r.t total
    Ntot = length(Scenario_list)
    NSS = round(Int, Ntot*frac)

    Index_selected = sample(1:Ntot, NSS, replace=false)

    Selected_scenarios =[]
    Unseen_scenarios = [] 
    for k in 1:Ntot
        if in(k,Index_selected)
            push!(Selected_scenarios,Scenario_list[k])
        else
            push!(Unseen_scenarios,Scenario_list[k])
        end
    end
    return Selected_scenarios, Unseen_scenarios
end

beta = 0.1


# part a => v same number of scenarios but different scenarios 
repetitions = 100       

expected_profit_list = []
p_general = zeros(24)
x = collect(1:24)

plot()
for i in 1:repetitions

    Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list, 0.2)
    expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

    p_general .+= p_bid/repetitions

    plot!(x, p_bid, linewidth=1, alpha = 0.1, label=nothing, color=:blue)

    push!(expected_profit_list, expected_profit)
    println("done with repetition $i /$repetitions")
end


plot!(x, p_general, label="Iteration", linewidth=1, color=:blue)
plot!(x, p_general, label="Mean", linewidth=3, color=:red)
xlabel!("Time [h]")
ylabel!("Power [MW]")
title!("DA Production for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_price.png")
savefig(filepath)
# plot of the different scenarios and mean value overimposed

# mean and standard deviation of the expected profit
expected_mean = mean(expected_profit_list)
expected_std = std(expected_profit_list)  
println("expected_profit:    mean =$expected_mean and std = $expected_std") 



# part b => different fraction seen / unseen
fraction = range(start=0.1, stop=0.95, step=0.01)
#fraction = [0.1, 0.2]

expected_profit_list = []
expected_profit_us_list = []
computational_time_list = []

for frac in fraction
    elapsed_time = @elapsed begin
        Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list, frac)
        expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

        NUS=length(Unseen_scenarios)

        expected_profit_us=0
        for scenario in Unseen_scenarios
            expected_profit_us+=sum((scenario[2][t]*p_bid[t]+(0.9 + 0.1*(scenario[3][t]))*scenario[2][t]*max(0,scenario[1][t]-p_bid[t])-(1.2+0.2*(scenario[3][t]-1))*scenario[2][t]*max(0,p_bid[t]-scenario[1][t])) for t in 1:T)/NUS
        end

        push!(expected_profit_list, expected_profit)
        push!(expected_profit_us_list, expected_profit_us)

        println("done with fraction $frac /0.95")
    end
    push!(computational_time_list, elapsed_time)
end

plot(fraction, expected_profit_list, label="Seen Senarios", linewidth=2, ylabel="Profit")
plot!(fraction, expected_profit_us_list, label="Unseen Scenarios", linewidth=2)
#plot!(twinx(),fraction[2:end], computational_time_list[2:end], alpha=0.8,  label="Computational Time", color=:red, ylabel="Computational Time (s)", linewidth=2)

xlabel!("Fraction")
title!("Expected Profit vs Fraction")
#plot!(legend=:outerbottom, legendcolumns=3)
filepath = joinpath(@__DIR__, "task_1_5_expected_profit.png")
savefig(filepath)
# time can be added into the plot but does not add significant meaning

