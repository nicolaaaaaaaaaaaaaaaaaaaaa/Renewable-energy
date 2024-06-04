using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("Scenario generation.jl")

function one_price_strategy()
    prob = 1/NSS

    model_1= Model(Gurobi.Optimizer)

    #declare Variables
    @variable(model_1, p_DA[1:T]>=0)
    @variable(model_1, Delta[1:T,1:NSS])
    @variable(model_1, Delta_up[1:T,1:NSS]>=0)
    @variable(model_1, Delta_down[1:T,1:NSS]>=0)

    #Objective function
    #@objective(model_1,Max,sum(prob*(Selected_scenarios[w][2][t]*p_DA[t]+(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_up[t,w]-(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_down[t,w]) for w in 1:NSS,t in 1:T))
    @objective(model_1,Max,sum(prob*(Selected_scenarios[w][2][t]*p_DA[t]+(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*(Delta_up[t,w]-Delta_down[t,w])) for w in 1:NSS,t in 1:T))

    #Constraints
    @constraint(model_1,DA_production[t in 1:T],p_DA[t]<= Capacity)
    @constraint(model_1,production_uncertainty[t in 1:T,w in 1:NSS],Delta[t,w]==Selected_scenarios[w][1][t]-p_DA[t])
    @constraint(model_1,production_inbalanced[t in 1:T,w in 1:NSS],Delta[t,w]==Delta_up[t,w]-Delta_down[t,w])


    # Solving the model
    optimize!(model_1)

    # Printing the termination status
    #println("Status: ", JuMP.termination_status(model_1))

    # Printing the objective value
    #println("Objective value: ", JuMP.objective_value(model_1))

    #displaying the wanted results
    if termination_status(model_1) == MOI.OPTIMAL
        println("Optimal solution found")
        expected_profit = JuMP.objective_value(model_1)

        power_production = [value.(p_DA[t]) for t in 1:T ]

        scenarios_profit=zeros(NSS)
        for w in 1:NSS
            scenarios_profit[w]=sum(Selected_scenarios[w][2][t]*value.(p_DA[t])+(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*value.(Delta_up[t,w])-(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*value.(Delta_down[t,w]) for t in 1:T)/1000000 #/expected_profit
        end

        return power_production, scenarios_profit
    end
end


function two_price_strategy()
    prob = 1/NSS

    model_1= Model(Gurobi.Optimizer)

    #declare Variables
    @variable(model_1, p_DA[1:T]>=0)
    @variable(model_1, Delta[1:T,1:NSS])
    @variable(model_1, Delta_up[1:T,1:NSS]>=0)
    @variable(model_1, Delta_down[1:T,1:NSS]>=0)

    @objective(model_1,Max,sum(prob*(Selected_scenarios[w][2][t]*p_DA[t]+(0.9 + 0.1*(Selected_scenarios[w][3][t]))*Selected_scenarios[w][2][t]*Delta_up[t,w]-(1.2+0.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_down[t,w]) for w in 1:NSS,t in 1:T))

    #Constraints
    @constraint(model_1,DA_production[t in 1:T],p_DA[t]<= Capacity)
    @constraint(model_1,production_uncertainty[t in 1:T,w in 1:NSS],Delta[t,w]==Selected_scenarios[w][1][t]-p_DA[t])
    @constraint(model_1,production_inbalanced[t in 1:T,w in 1:NSS],Delta[t,w]==Delta_up[t,w]-Delta_down[t,w])

    # Solving the model
    optimize!(model_1)

    #displaying the wanted results
    if termination_status(model_1) == MOI.OPTIMAL
        println("Optimal solution found")


        # Calculate y values (sine of x)
        power_production = [value.(p_DA[t]) for t in 1:T ]

        scenarios_profit=zeros(NSS)
        for w in 1:NSS
            scenarios_profit[w]=sum(Selected_scenarios[w][2][t]*value.(p_DA[t])+(0.9 + 0.1*(Selected_scenarios[w][3][t]))*Selected_scenarios[w][2][t]*value.(Delta_up[t,w])-(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*value.(Delta_down[t,w]) for t in 1:T)/1000000 #/expected_profit
        end
    
        return power_production, scenarios_profit

    end
end

power_production1, scenarios_profit1 = one_price_strategy()
power_production2, scenarios_profit2 = two_price_strategy()

println(maximum(scenarios_profit1))
println(maximum(scenarios_profit2))

# generate plots

Plots.scalefontsizes(1.2)

time = collect(Int,1:T)
plot(time, power_production1, label="one-price", xlabel="t (h)", ylabel="power (MW)", title="Day ahead production (MW)", linewidth=2)
plot!(time, power_production2, label="two-price", xlabel="t (h)", ylabel="power (MW)", title="Day ahead production (MW)", linewidth=2)
filepath = joinpath(@__DIR__, "comparison_price_scheme_strategy.png")
savefig(filepath)

x_w = collect(Int, 1:NSS)
plot(x_w,  sort(scenarios_profit1), label="one-price", xlabel="scenarios", ylabel="Profit (MDKK)", title="profit distribution scenarios (DKK)", linewidth=2)
plot!(x_w, sort(scenarios_profit2), label="two-price", xlabel="scenarios", ylabel="Profit (MDKK)", title="profit distribution scenarios (DKK)", linewidth=2)
filepath = joinpath(@__DIR__, "comparison_price_scheme_profit.png")
savefig(filepath)
