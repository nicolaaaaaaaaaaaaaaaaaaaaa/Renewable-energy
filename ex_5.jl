#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

# step 5

T=24

model_1= Model(Gurobi.Optimizer)


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

# Update the last 6 columns of the matrix with the Excel data
for i in 1:T
    for j in 13:P  # Last 6 columns
        wind_coef[i, j] = zone[i, j-12]  # Adjust column index to match Excel data
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


""" Task 2 constraints """
# do we need them???


#ramp limit in MW/h
ramp_limit = [120  120 350	240	60	155	155	280	280	300	180	240 200 200 200 200 200 200]

#Electrolyzer demand
demand_electrolyzer = zeros(P)
demand_electrolyzer[P] = 28 #T
demand_electrolyzer[P-1] = 40 #T
demand_electrolyzer[P-2] = 43 #T

#Installed capacity
hydrogen_limit = 100 #MW







""" Task 5 constraints """
# set hour of interest
time = 12
day_ahead_prod = [0.0,  0.0, 0.0, 0.0, 0.0, 155.0, 155.0, 400.0, 400.0, 300.0, 310.0, 0.0, 134.0, 142.0, 146.0, 0.0, 109.57, 138.0]
#  prod_capacity=[152   152  350  591  60   155    155    400    400     300    310    350 200     200    200    200   200    200]

day_ahead_demand = [95.68, 85.61, 158.63, 0.0,     0.0, 120.86, 110.79, 151.08, 153.6, 171.22, 234.17, 171.22, 279.5, 88.13, 294.6, 161.15, 113.31]
#                  [95.68, 85.61, 158.63, 65.47, 62.95, 120.86, 110.79, 151.08, 153.6, 171.22, 234.17, 171.22, 279.5, 88.13, 294.6, 161.15, 113.31]
#println(round.(demand_max[:, time], digits=2))
# which one is the proper one???


# compute actual production
actual_coefficients = ones(P)
actual_coefficients[9] = 0
actual_coefficients[13:15] .= 0.9
actual_coefficients[16:18] .= 1.15
actual_prod_capacities = prod_capacities[:,time] .*actual_coefficients

# compute deltaP
deltaP = sum(prod_capacities[:,time] - actual_prod_capacities)


# compute upward and downward capacity limit (producecer 9 is the failure)
prod_capacities_up = zeros(P)
prod_capacities_down = zeros(P)
for i in 1:P-6
    prod_capacities_up[i] = actual_prod_capacities[i] - day_ahead_prod[i]
    prod_capacities_down[i] = day_ahead_prod[i]
end

prod_capacities_up[9] = 0
prod_capacities_down[9] = 0

#println(prod_capacities_up)
#println(prod_capacities_down)

# compute curtailment capacity
#demand_capacities_up = demand_max[:, time]
demand_capacities_up = day_ahead_demand

# upward price producer
upward_coefficients = zeros(P)
upward_coefficients[1:12] .= 1.1
upward_price = prod_price' .*upward_coefficients

# downward price producer
downward_coefficients = zeros(P)
for i in 1:P-6
    if day_ahead_prod[i] != 0
        downward_coefficients[i] = 0.87
    end
end
downward_price = prod_price' .*downward_coefficients
#println(downward_price)


# curtailment cost
curt_cost = ones(D)*400




""" Variables """

#Quantity of energy producted that goes into the grid in MWh
@variable(model_1, q_prod_up[1:P]>=0)
@variable(model_1, q_prod_down[1:P]>=0)

#Quantity of energy consumed by the demand in MWh
@variable(model_1, q_demand[1:D]>=0)

# other task 2 variables are considered in the day-ahead production and demand


""" Objective function """

@objective(model_1, Max, sum(q_prod_up[i]*upward_price[i] - q_prod_down[i]*downward_price[i] for i in 1:P) + sum(q_demand[j]*curt_cost[j] for j in 1:D))


""" Constraints """
#Limit of the quantity of energy producted
@constraint(model_1, Production_limit_up[p in 1:P], prod_capacities_up[p]>= q_prod_up[p])
@constraint(model_1, Production_limit_down[p in 1:P], prod_capacities_down[p]>= q_prod_down[p])

# curtailed energy 
@constraint(model_1, Demand_limit[d in 1:D], demand_capacities_up[d]>= q_demand[d])

#Equilibrium of the energy on the grid
@constraint(model_1, Energy_Equilibrium, sum(q_prod_up[p] - q_prod_down[p] for p in 1:P) + sum(q_demand[d] for d in 1:D) == deltaP)

# #Ramp limit constraint on the difference between the total energy producted at t and at t-1 
# @constraint(model_1, Ramp_limit[p in 1:P, t in 2:T], ramp_limit[p]>=(q_prod[p,t]+q_electrolyzer_prod[p,t]-q_prod[p,t-1]-q_electrolyzer_prod[p,t-1])>=-ramp_limit[p])
# 
# #Electrolyzer constraint, the demand for hydrogen should be met by the end of the day by the concerned wind farm 
# @constraint(model_1, Demand_electrolyzer[p in 1:P], demand_electrolyzer[p]==sum(q_electrolyzer_prod[p,t] for t in 1:T)*18/1000)
# 
# #Electrolyzer production Limit
# @constraint(model_1, Hydrogen_limit[p in 1:P, t in 1:T], hydrogen_limit>=q_electrolyzer_prod[p,t])

# Solving the model
optimize!(model_1)

# Printing the termination status
println("Status: ", JuMP.termination_status(model_1))

# Printing the objective value
println("Objective value: ", JuMP.objective_value(model_1))


if termination_status(model_1) == MOI.OPTIMAL
    println("Optimal solution found")
    
    #script_directory = @__DIR__
    #file_path = joinpath(script_directory, "output.txt")
    #file = open(file_path, "w")
    #println(file,"Maximal Welfare : $(round.(objective_value(model_1), digits=2))")
    #println(file,"-----------------")
    #Market_price=zeros(Float64,24)
    


    Market_price=-dual(Energy_Equilibrium)
    println("Market price : $(Market_price)")
    println("Prod up : $(value.(q_prod_up))")
    println("Prod down : $(value.(q_prod_down))")
    println("Prod curt : $(value.(q_demand))")

end
