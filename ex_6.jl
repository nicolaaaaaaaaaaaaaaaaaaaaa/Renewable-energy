#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

# step 5

T=24

model_1= Model(Gurobi.Optimizer)
model_2= Model(Gurobi.Optimizer)


""" Production """
#Producers including 6 Wind farms producing max 200MW looking at the data of several zone at 12 pm
prod_price=[13.32 13.32 20.7 20.93 26.11 10.52 10.52 6.02 5.47 0 10.52 10.89 0 0 0 0 0 0]
prod_capacity=[152 152 350 591 60 155 155 400 400 300 310 350 200 200 200 200 200 200]

#production size
P=length(prod_price)

#Implementation of coefficient for making change the wind power
zone = [0.59	0.70	0.68	0.51	0.66	0.61;
        0.68	0.71	0.72	0.60	0.68	0.65;
        0.74	0.73	0.74	0.65	0.67	0.67;
        0.77	0.73	0.75	0.69	0.66	0.67;
        0.77	0.73	0.75	0.69	0.67	0.68;
        0.78	0.73	0.76	0.69	0.68	0.70;
        0.79	0.73	0.76	0.68	0.68	0.69;
        0.78	0.72	0.74	0.65	0.68	0.69;
        0.77	0.72	0.75	0.65	0.69	0.69;
        0.75	0.73	0.74	0.65	0.70	0.70;
        0.70	0.72	0.74	0.64	0.70	0.71;
        0.67	0.71	0.73	0.63	0.69	0.69;
        0.65	0.70	0.71	0.61	0.69	0.69;
        0.64	0.72	0.71	0.61	0.71	0.69;
        0.65	0.71	0.72	0.64	0.71	0.68;
        0.64	0.72	0.71	0.63	0.71	0.68;
        0.64	0.71	0.71	0.62	0.71	0.67;
        0.66	0.72	0.71	0.62	0.72	0.70;
        0.67	0.72	0.73	0.64	0.73	0.72;
        0.68	0.73	0.74	0.65	0.72	0.73;
        0.70	0.74	0.77	0.68	0.72	0.72;
        0.68	0.71	0.74	0.67	0.68	0.68;
        0.69	0.68	0.71	0.65	0.66	0.66;
        0.65	0.59	0.64	0.61	0.59	0.59]

wind_coef = ones(T, P)
for i in 1:T
    for j in 13:P  # Last 6 columns
        wind_coef[i, j] = zone[i, j-12] 
    end
end

#Compute the production capacities matrix with time dependancy
prod_capacities=(wind_coef.*(repeat(prod_capacity,T,1)))'


""" Demand """
#Prices at hour 12 that were used in task 1 
demand_utility= [13.0 11.6 21.5 8.9 8.5 16.4 15.0 20.5 20.9 23.2 31.8 23.2 37.9 12.0 40.0 21.9 15.4 ]

#Demand coefficient repartition
demand_repartition= [3.8 3.4 6.3 2.6 2.5 4.8 4.4 6 6.1 6.8 9.3 6.8 11.1 3.5 11.7 6.4 4.5]

#Time dependancy of the overall Load
Time_load = [1775.835   1669.815	1590.300	1563.795	1563.795	1590.300	1961.370	2279.430	2517.975	2544.480	2544.480	2517.975	2517.975	2517.975	2464.965	2464.965	2623.995	2650.500	2650.500	2544.480	2411.955	2199.915	1934.865	1669.815]

#Compute the demand matrix with time dependancy
demand_max= (Time_load' * demand_repartition/100)'


#For step one we looked at hour 12 so now we are just creating a coefficient in order to make the utility time dependent
coefficient=Time_load/Time_load[12]

#Time dependent utility
demand_utilities = (coefficient' * demand_utility)'

#Demand size
D=length(demand_utility)


""" Task 6 constraints """

# upward and downward reserve requirements
r_req_up = zeros(T)
r_req_down = zeros(T)

for t in 1:T
    r_req_up[t] = sum(demand_utilities[:,t])*0.15
    r_req_down[t] = sum(demand_utilities[:,t])*0.10
end

# upward and downward reserve limit, from table 1
r_prod_limit_up =   [40 40  70  180 60  30  30  0   0   0   60  40 0 0 0 0 0 0 ]
r_prod_limit_down = [40 40  70  180 60  30  30  0   0   0   60  40 0 0 0 0 0 0 ]

# upward and downward reserve prices, from table 2
r_price_up =  [15 15  24  25  28  16  16  0   0   0   14  16 0 0 0 0 0 0 ]
r_price_down =[11 11  16  17  23  7   7   0   0   0   8   8  0 0 0 0 0 0 ]
# wind turbines 0 ????


""" MODEL 1 """

""" Variables """

#Quantity of energy requested for upward and downward reserve
@variable(model_1, r_prod_up[1:P,1:T]>=0)
@variable(model_1, r_prod_down[1:P,1:T]>=0)


""" Objective function """

@objective(model_1, Min, sum(r_price_up[i]*r_prod_up[i,t] for i in 1:P, t in 1:T) + sum(r_price_down[i]*r_prod_down[i,t] for i in 1:P, t in 1:T))


""" Constraints """
#Limit of the quantity of energy reserved
@constraint(model_1, Reserve_limit_up[p in 1:P, t in 1:T],   r_prod_limit_up[p]>=r_prod_up[p,t])
@constraint(model_1, Reserve_limit_down[p in 1:P, t in 1:T], r_prod_limit_down[p]>=r_prod_down[p,t])

#Equilibrium of the energy reserved up and down
@constraint(model_1, Energy_Equilibrium_up[t in 1:T], sum(r_prod_up[p,t] for p in 1:P)== r_req_up[t])
@constraint(model_1, Energy_Equilibrium_down[t in 1:T], sum(r_prod_down[p,t] for p in 1:P)== r_req_down[t])

# Solving the model

optimize!(model_1)

# Printing the termination status
#println("Status: ", JuMP.termination_status(model_1))
#println("Objective value: ", JuMP.objective_value(model_1))


if termination_status(model_1) == MOI.OPTIMAL
    println("Optimal solution for step 1 found")

    Market_price_up=zeros(Float64,(T))
    Market_price_down=zeros(Float64,(T))
    reserve_optimal_up = zeros(Float64,(P,T))
    reserve_optimal_down = zeros(Float64,(P,T))
    

    # Display other information for the current time step
    for t in 1:T
        Market_price_up[t]=dual(Energy_Equilibrium_up[t])
        Market_price_down[t]=dual(Energy_Equilibrium_down[t])

        reserve_optimal_up[:,t] = value.(r_prod_up[:,t])
        reserve_optimal_down[:,t] = value.(r_prod_down[:,t])

        println("")
        println("model 1: time $(t)")
        println("Market price up  : $(Market_price_up[t])") 
        println("Market price down: $(Market_price_down[t])") 
        println("reserve up       : $(reserve_optimal_up[:,t]),  $(round.(sum(reserve_optimal_up[:,t]), digits=2)) = $(round.(r_req_up[t], digits=2)) ") 
        println("reserve down     : $(reserve_optimal_down[:,t]), $(round.(sum(reserve_optimal_down[:,t]), digits=2)) = $(round.(r_req_down[t], digits=2)) ")
    end




    """ MODEL 2 """
    """ Variables """

    #Quantity of energy produced and demanded 
    @variable(model_2, q_prod2[1:P,1:T]>=0)
    @variable(model_2, q_demand2[1:D,1:T]>=0)


    """ Objective function """

    @objective(model_2, Max, sum(demand_utilities[i,t]*q_demand2[i,t] for i in 1:D, t in 1:T) - sum(prod_price[i]*q_prod2[i,t] for i in 1:P, t in 1:T))

    """ Constraints """
    #Limit of the quantity of energy produced and consumed
    @constraint(model_2, Production_limit[p in 1:P, t in 1:T],  reserve_optimal_down[p,t] <= q_prod2[p,t] <= prod_capacities[p,t] - reserve_optimal_up[p,t])
    @constraint(model_2, Demand_limit[d in 1:D, t in 1:T], demand_max[d,t]>=q_demand2[d,t])

    #Equilibrium of the energy on the grid
    @constraint(model_2, Energy_Equilibrium[t in 1:T], sum(q_demand2[d,t] for d in 1:D) == sum(q_prod2[p,t] for p in 1:P))

    # Solving the model

    optimize!(model_2)

    # Printing the termination status
    #println("Status: ", JuMP.termination_status(model_2))
    #println("Objective value: ", JuMP.objective_value(model_2))

    Market_price2=zeros(Float64,(T))
    production = zeros(Float64,(P,T))
    demand = zeros(Float64,(D,T))

    if termination_status(model_2) == MOI.OPTIMAL
        println("")
        println("")
        println("Optimal solution for step 2 found")

        # Display other information for the current time step
        for t in 1:T
            Market_price2[t]=-dual(Energy_Equilibrium[t])
            production[:,t] = value.(q_prod2[:,t])
            demand[:,t] = value.(q_demand2[:,t])

            println("")
            println("model 2: time $(t)")
            println("Market price : $(Market_price2[t])") 
            println("production   : $(round.(production[:,t], digits=2))") 
            println("demand       : $(round.(demand[:,t], digits=2))")
        end

    end
end