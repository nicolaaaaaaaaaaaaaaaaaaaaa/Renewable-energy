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

# multiply production matrix by balancing coefficients, having 1 generator = 0, wind farm with increased/decreased production
balancing_coefficients = ones(P,1)
balancing_coefficients[9] = 0
balancing_coefficients[13:15] .= 0.9
balancing_coefficients[16:18] .= 1.15


# compute deltaP
deltaP = sum(prod_capacities[:,time] - prod_capacities[:,time] .*balancing_coefficients)
println("deltaP  ",deltaP)

# upward balancing service for
upward_coefficients = ones(P,1)
upward_coefficients[1:12] .= 1.1
upward_price = prod_price .*upward_coefficients

println(size(prod_price))
println(size(upward_coefficients))

# downward balancing service
# production for task 2, time=12 [0.0, 0.0, 0.0, 0.0, 0.0, 155.0, 155.0, 400.0, 400.0, 300.0, 310.0, 0.0, 134.0, 142.0, 146.0, 0.0, 109.55827499999987, 138.0]
downward_coefficients = zeros(P)
downward_coefficients[6:11] .= 0.85
downward_price = prod_price .*downward_coefficients


#println(upward_price)
#println(downward_price)



#=

""" Variables """

#Quantity of energy producted that goes into the grid in MWh
@variable(model_1, q_prod[1:P,1:T]>=0)

#Quantity of energy consumed by the demand in MWh
@variable(model_1, q_demand[1:D,1:T]>=0)

#Quantity of energy producted by the producers for the wind turbines' electrolyzer in MWh 
@variable(model_1, q_electrolyzer_prod[1:P,1:T]>=0)



""" Objective function """

@objective(model_1, Max, sum(demand_utilities[i,t]*q_demand[i,t] for i in 1:D, t in 1:T) - sum(prod_price[i]*(q_prod[i,t]+ q_electrolyzer_prod[i,t]) for i in 1:P, t in 1:T))

""" Constraints """
#Limit of the quantity of energy producted
@constraint(model_1, Production_limit[p in 1:P, t in 1:T], prod_capacities[p,t]>=q_prod[p,t]+q_electrolyzer_prod[p,t])

#Limit of the quantity of energy consumed
@constraint(model_1, Demand_limit[d in 1:D, t in 1:T], demand_max[d,t]>=q_demand[d,t])

#Equilibrium of the energy on the grid
@constraint(model_1, Energy_Equilibrium[t in 1:T], sum(q_demand[d,t] for d in 1:D) == sum(q_prod[p,t] for p in 1:P))

#Ramp limit constraint on the difference between the total energy producted at t and at t-1 
@constraint(model_1, Ramp_limit[p in 1:P, t in 2:T], ramp_limit[p]>=(q_prod[p,t]+q_electrolyzer_prod[p,t]-q_prod[p,t-1]-q_electrolyzer_prod[p,t-1])>=-ramp_limit[p])

#Electrolyzer constraint, the demand for hydrogen should be met by the end of the day by the concerned wind farm 
@constraint(model_1, Demand_electrolyzer[p in 1:P], demand_electrolyzer[p]==sum(q_electrolyzer_prod[p,t] for t in 1:T)*18/1000)

#Electrolyzer production Limit
@constraint(model_1, Hydrogen_limit[p in 1:P, t in 1:T], hydrogen_limit>=q_electrolyzer_prod[p,t])

# Solving the model
optimize!(model_1)

# Printing the termination status
println("Status: ", JuMP.termination_status(model_1))

# Printing the objective value
println("Objective value: ", JuMP.objective_value(model_1))


if termination_status(model_1) == MOI.OPTIMAL
    println("Optimal solution found")
    
    # Display of the results in a text file
    
    # Get the directory of the current script
    script_directory = @__DIR__
    # Construct the full file path
    file_path = joinpath(script_directory, "output.txt")
    # Open or create a text file
    file = open(file_path, "w")

    # Write inside the text file
    println(file,"Maximal Welfare : $(round.(objective_value(model_1), digits=2))")
    println(file,"-----------------")

    Market_price=zeros(Float64,24)

    # Display other information for the current time step
    for i in 1:T
        Market_price[i]=-dual(Energy_Equilibrium[i])
        println("Step : $(i)    Market price : $(Market_price[i])")  
        println("Prod : $(value.(q_prod[:,i]))")
        println("Elec : $(value.(q_electrolyzer_prod[:,i]))")

    end

end

=#