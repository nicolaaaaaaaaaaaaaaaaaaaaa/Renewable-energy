using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots
using StatsBase
using StatsPlots

include("Scenario generation.jl")
include("Two_price_scheme_risk_analysis.jl")


Random.seed!()


function scenario_generation(Scenario_list, frac)

    Random.seed!()

    # creates a seen and un-seen scenario list depending on the fraction of seen w.r.t total
    Ntot = length(Scenario_list)
    NSS = round(Int, Ntot*frac)     # number selected scenarios

    # a list of NSS indexes is randomly selected, the one inside creates the seen scenarios, the others the unseen scenarios
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

beta = 0.7      # we just need to stick with one


#=
# part a: same number of scenarios but different chosen scenarios 
# computes the optimal DA production repetitions time, plots mean, 25th and 75th quantile

repetitions = 500

expected_profit_list = []
p_all = zeros(repetitions, 24)
time = collect(1:24)


for i in 1:repetitions

    Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list, 250/length(Scenario_list))
    #println(length(Selected_scenarios))
    expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

    p_all[i,:] = p_bid

    #plot!(x, p_bid, linewidth=1, alpha = 0.1, label=nothing, color=:blue)

    push!(expected_profit_list, expected_profit)
    println("done with repetition $i / $repetitions")
end

p_all_means = mean(p_all, dims=1)[:]
p_all_q25 = [quantile(col, 0.25) for col in eachcol(p_all)]
p_all_q75 = [quantile(col, 0.75) for col in eachcol(p_all)]

#plot(time, q_all_means, ribbon=(q_all_q25, q_all_q75), label="Mean ± CI", linewidth=2, ribbon_color=:blue, linecolor=:red)

plot(time, p_all_q25, linecolor=:transparent, fillrange=p_all_q75, fillalpha=0.3, label=nothing, color=:blue)
plot!(time, p_all_means, label="Seen + CI", color=:red, linewidth=2)

xlabel!("time [h]")
ylabel!("Power [MW]")
title!("DA Production for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_DA_production.png")
savefig(filepath)

# mean and standard deviation of the expected profit
expected_mean = mean(expected_profit_list)
expected_std = std(expected_profit_list)  
println("expected_profit:    mean =$expected_mean and std = $expected_std = $(expected_std/expected_mean*100)%") 

#expected_profit_list = expected_profit_list./100000
#histogram(expected_profit_list, normalize=true, legend=false, bins=20)
#xlabel!("Expected Profit [*10^5 DKK]")
#ylabel!("Frequency")
#title!("Distribution of Expected Profit")
#filepath = joinpath(@__DIR__, "task_1_5_value_distribution.png")
#savefig(filepath)

expected_profit_array = collect(expected_profit_list./100000)

mu = mean(expected_profit_array)
sigma = std(expected_profit_array)
x_vals = range(minimum(expected_profit_array), stop=maximum(expected_profit_array), length=100)
y_vals = pdf(Normal(mu, sigma), x_vals)

#density(expected_profit_list, label="density")
histogram(expected_profit_array, label="histogram",normalize=true, bins=25)
plot!(x_vals, y_vals, label="Gaussian Distribution", linewidth=2, color=:red)
xlabel!("Expected Profit [*10^5 DKK]")
ylabel!("Density")
title!("Distribution of Expected Profit")
filepath = joinpath(@__DIR__, "task_1_5_value_distribution.png")
savefig(filepath)
=#


#=
# part b: different fraction seen / unseen
start = 0.01    # it's the lowest
stop = 0.99
fraction = range(start=start, stop=stop, step=0.02)
#fraction = [0.1, 0.2, 0.3]

expected_profit_list = []
expected_profit_us_list = []

for frac in fraction
    Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list, frac)
    expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

    NUS=length(Unseen_scenarios)

    expected_profit_us=0
    for scenario in Unseen_scenarios
        expected_profit_us+=sum((scenario[2][t]*p_bid[t]+(0.9 + 0.1*(scenario[3][t]))*scenario[2][t]*max(0,scenario[1][t]-p_bid[t])-(1.2+0.2*(scenario[3][t]-1))*scenario[2][t]*max(0,p_bid[t]-scenario[1][t])) for t in 1:T)/NUS
    end

    println(expected_profit)
    println(expected_profit_us)

    push!(expected_profit_list, expected_profit)
    push!(expected_profit_us_list, expected_profit_us)

    println("done with fraction $frac /$stop")
end

plot(fraction, expected_profit_list, label="Seen Senarios", linewidth=2, ylabel="Profit")
plot!(fraction, expected_profit_us_list, label="Unseen Scenarios", linewidth=2)
vline!([250/length(Scenario_list)], linestyle=:dot, label="previous ratio")

xlabel!("Fraction")
title!("Expected Profit vs Fraction")
#plot!(legend=:outerbottom, legendcolumns=3)
filepath = joinpath(@__DIR__, "task_1_5_expected_profit.png")
savefig(filepath)
=#


#=
# part b with repetitions
# same as above but it is repeated repetitions time to avalate mean, 25th, 75th quantile
repetitions = 10
start = 0.01    # it's the lowest
stop = 0.99
fraction = range(start=start, stop=stop, step=0.05)
#fraction = [0.1, 0.2, 0.3]

profit = zeros(repetitions, length(fraction))
profit_us = zeros(repetitions, length(fraction))

for i in 1:repetitions

    expected_profit_list = []
    expected_profit_us_list = []

    for frac in fraction
        Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list, frac)
        expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

        NUS=length(Unseen_scenarios)

        expected_profit_us=0
        for scenario in Unseen_scenarios
            expected_profit_us+=sum((scenario[2][t]*p_bid[t]+(0.9 + 0.1*(scenario[3][t]))*scenario[2][t]*max(0,scenario[1][t]-p_bid[t])-(1.2+0.2*(scenario[3][t]-1))*scenario[2][t]*max(0,p_bid[t]-scenario[1][t])) for t in 1:T)/NUS
        end

        #println(expected_profit)
        #println(expected_profit_us)

        push!(expected_profit_list, expected_profit)
        push!(expected_profit_us_list, expected_profit_us)

        println("done with fraction $frac /$stop of repetition $i / $repetitions")
    end

    profit[i,:] = collect(expected_profit_list)
    profit_us[i,:] = collect(expected_profit_us_list)
end

profit = profit./100000
profit_us = profit_us./100000



profit_means = mean(profit, dims=1)[:]
profit_q25 = [quantile(sort(col), 0.25) for col in eachcol(profit)]
profit_q75 = [quantile(sort(col), 0.75) for col in eachcol(profit)]

profit_us_means = mean(profit_us, dims=1)[:]
profit_us_q25 = [quantile(sort(col), 0.25) for col in eachcol(profit_us)]
profit_us_q75 = [quantile(sort(col), 0.75) for col in eachcol(profit_us)]

plot(fraction, profit_means, label="Seen + CI", color=:blue, linewidth=2)
plot!(fraction, profit_q25, linecolor=:transparent, fillrange=profit_q75, fillalpha=0.3, label=nothing, color=:blue)

plot!(fraction, profit_us_means, label="Unseen + CI", color=:red, linewidth=2)
plot!(fraction, profit_us_q25, linecolor=:transparent, fillrange=profit_us_q75, fillalpha=0.3, label=nothing, color=:red)

vline!([250/length(Scenario_list)], linestyle=:dot, label="previous ratio")

xlabel!("Fraction")
ylabel!("Profit (*10^5 DKK)")
title!("Expected Profit vs Fraction")
filepath = joinpath(@__DIR__, "task_1_5_expected_profit_deviation.png")
savefig(filepath)
=#



#=
# evaluate effect of total scenario size 
# ratio seen/total constant, but total decreases to Scenario_list[:max_index]

tot = length(Scenario_list)

start = 0.1
stop = 1
fraction_total = range(start=start, stop=stop, step=0.1)
#fraction_total = [0.9, 1]

expected_profit_list = []
expected_profit_us_list = []

used_fraction = 0.4



for frac in fraction_total
    max_index = round(Int, tot*frac)
    println("max index $(max_index) / 5488")

    Selected_scenarios, Unseen_scenarios = scenario_generation(Scenario_list[1:max_index], used_fraction)
    expected_profit,_,p_bid=two_price_risk_analysis(Selected_scenarios, beta)

    NUS=length(Unseen_scenarios)

    expected_profit_us=0
    for scenario in Unseen_scenarios
        expected_profit_us+=sum((scenario[2][t]*p_bid[t]+(0.9 + 0.1*(scenario[3][t]))*scenario[2][t]*max(0,scenario[1][t]-p_bid[t])-(1.2+0.2*(scenario[3][t]-1))*scenario[2][t]*max(0,p_bid[t]-scenario[1][t])) for t in 1:T)/NUS
    end

    push!(expected_profit_list, expected_profit)
    push!(expected_profit_us_list, expected_profit_us)

    println("done with fraction $frac / 1 ")
end


plot(fraction_total, expected_profit_list./100000, label="Seen Senarios", linewidth=2)
plot!(fraction_total, expected_profit_us_list./100000, label="Unseen Scenarios", linewidth=2)
ylabel!("Profit [*10^5 DKK]")
xlabel!("Fraction of total scenarios")
title!("Expected Profit VS fraction of total scenarios")
filepath = joinpath(@__DIR__, "task_1_5_effect_total_size.png")
savefig(filepath)
=#




