using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots
using StatsBase

include("Scenario generation.jl")
include("tasK_1_5.jl")



time = collect(1:24)


# plot given price distribution
price_given = lambda_t_omega_DA

price_given_means = mean(price_given, dims=1)[:]
price_given_q25 = [quantile(sort(col), 0.25) for col in eachcol(price_given)]
price_given_q75 = [quantile(sort(col), 0.75) for col in eachcol(price_given)]

plot(time, price_given_q25, linecolor=:transparent, fillrange=price_given_q75, fillalpha=0.3, label=nothing, color=:blue)
plot!(time, price_given_means, label="Mean ± CI", linewidth=2, linecolor=:red)



xlabel!("time [h]")
ylabel!("Price [DKK/MW]")
title!("Given price for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_price_distribution.png")
savefig(filepath)


# plot given production distribution
prod_given = P_t_omega_real
prod_given_means = mean(prod_given, dims=1)[:]

prod_given_q25 = [quantile(sort(col), 0.25) for col in eachcol(prod_given)]
prod_given_q75 = [quantile(sort(col), 0.75) for col in eachcol(prod_given)]

plot(time, prod_given_q25, linecolor=:transparent, fillrange=prod_given_q75, fillalpha=0.3, label=nothing, color=:blue)
plot!(time, prod_given_means, label="Mean ± CI", linewidth=2, linecolor=:red)

xlabel!("time [h]")
ylabel!("Production [MW]")
title!("Given production for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_prod_distribution.png")
savefig(filepath)




# plot given price and production distribution over the hour
# different plotting, worse looking
#=
x = collect(1:24)


L = length(lambda_t_omega_DA[:,1])
price_general = zeros(24)

plot()
for i in 1:L
    price_i = lambda_t_omega_DA[i,:]
    price_general .+= price_i/L
    plot!(x, price_i, linewidth=1, alpha = 0.1, label=nothing, color=:blue)
end

plot!(x, price_general, label="Iteration", linewidth=1, color=:blue)
plot!(x, price_general, label="Mean", linewidth=3, color=:red)
xlabel!("Time [h]")
ylabel!("Price [??]")
title!("Price for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_price_given.png")
savefig(filepath)



plot()
prod_general = zeros(24)
L = length(P_t_omega_real[:,1])

for i in 1:L
    prod_i = P_t_omega_real[i,:]
    prod_general .+= prod_i/L
    plot!(x, prod_i, linewidth=1, alpha = 0.1, label=nothing, color=:blue)
end

plot!(x, prod_general, label="Iteration", linewidth=1, color=:blue)
plot!(x, prod_general, label="Mean", linewidth=3, color=:red)
xlabel!("Time [h]")
ylabel!("Production [??]")
title!("Production for different scenarios")
filepath = joinpath(@__DIR__, "task_1_5_prod_given.png")
savefig(filepath)
=#


# evaluate effect of total scenario size 
# ratio seen/total constant, but total decreases to Scenario_list[:max_index]

#=
tot = length(Scenario_list)

start = 0.25
stop = 1
fraction_total = range(start=start, stop=stop, step=0.05)
#fraction_total = [0.9, 1]

used_fraction_list = [0.1, 0.2, 0.3]


plot()
for used_fraction in used_fraction_list
    expected_profit_list = []
    expected_profit_us_list = []

    #used_fraction = 0.2

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

        #println(expected_profit)
        #println(expected_profit_us)

        push!(expected_profit_list, expected_profit)
        push!(expected_profit_us_list, expected_profit_us)

        println("done with fraction $frac / 1 ")
    end



    plot!(fraction_total, expected_profit_list, label="Seen $(used_fraction)", linewidth=2)
    plot!(fraction_total, expected_profit_us_list, label="Unseen $(used_fraction)", linewidth=2)

end

ylabel!("Profit")
xlabel!("Fraction of total scenarios")
title!("Expected Profit VS fraction of total scenarios")
#plot!(legend=:outerbottom, legendcolumns=3)
filepath = joinpath(@__DIR__, "task_1_5_effect_total_size_multiple.png")
savefig(filepath)
=#


