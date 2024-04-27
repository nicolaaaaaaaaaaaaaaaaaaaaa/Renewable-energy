using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("Scenario generation.jl")

function two_price_risk_analysis(Selected_scenarios, beta)
    prob = 1/NSS
    alpha = 0.9
    model_1= Model(Gurobi.Optimizer)

    # remove printing statement
    set_optimizer_attribute(model_1, "OutputFlag", 0)

    #declare Variables
    @variable(model_1, p_DA[1:T]>=0)
    @variable(model_1, Delta[1:T,1:NSS])
    @variable(model_1, Delta_up[1:T,1:NSS]>=0)
    @variable(model_1, Delta_down[1:T,1:NSS]>=0)
    @variable(model_1, eta[1:NSS]>=0)
    @variable(model_1, zeta)

    #Objective function
    #with the (1-beta) beta goes from 0 to 1
    @objective(model_1,Max,(1-beta)*sum(prob*(Selected_scenarios[w][2][t]*p_DA[t]+(0.9 + 0.1*(Selected_scenarios[w][3][t]))*Selected_scenarios[w][2][t]*Delta_up[t,w]-(1.2+0.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_down[t,w]) for w in 1:NSS,t in 1:T)
    + beta*(zeta-1/(1-alpha)*sum(prob*eta[w] for w in 1:NSS)))

    #Constraints
    @constraint(model_1,DA_production[t in 1:T],p_DA[t]<= Capacity)
    @constraint(model_1,production_uncertainty[t in 1:T,w in 1:NSS],Delta[t,w]==Selected_scenarios[w][1][t]-p_DA[t])
    @constraint(model_1,production_inbalanced[t in 1:T,w in 1:NSS],Delta[t,w]==Delta_up[t,w]-Delta_down[t,w])
    @constraint(model_1,zeta_limit[w in 1:NSS],-sum(Selected_scenarios[w][2][t]*p_DA[t]+(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_up[t,w]-(0.9*Selected_scenarios[w][3][t] - 1.2*(Selected_scenarios[w][3][t]-1))*Selected_scenarios[w][2][t]*Delta_down[t,w] for t in 1:T)+zeta-eta[w]<=0)


    # Solving the model
    optimize!(model_1)

    # Printing the termination status
    #println("Status: ", JuMP.termination_status(model_1))

    # Printing the objective value
    #println("Objective value: ", JuMP.objective_value(model_1))

    #displaying the wanted results
    if termination_status(model_1) == MOI.OPTIMAL
        #println("Optimal solution found")
        
        p_bid = (value.(p_DA))
        cvar = (value.(zeta)-1/(1-alpha)*sum(prob*value.(eta[w]) for w in 1:NSS))
        expected_profit = (JuMP.objective_value(model_1)-beta*cvar)/(1-beta)

        return expected_profit, cvar, p_bid
    end
end

