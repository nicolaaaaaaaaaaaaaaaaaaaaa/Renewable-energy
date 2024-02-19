#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

#units
P=18
D=17
T=24

model_1= Model(Gurobi.Optimizer)

#Producers including 6 Wind farms producing max 200MW looking at the data of several zone at 12 pm
prod_price=[13.32 13.32 20.7 20.93 26.11 10.52 10.52 6.02 5.47 0 10.52 10.89 0 0 0 0 0 0]
prod_capacity=[152 152 350 591 60 155 155 400 400 300 310 350 200*0.703270 200*0.723443 200*0.738949 200*0.635512 200*0.700758 200*0.711764]

"""Be careful we need to modify the capacity of the Wind farm"""

prod_capacities=(repeat(prod_capacity,24,1))'



demand_price= [13.0 11.6 21.5 8.9 8.5 16.4 15.0 20.5 20.9 23.2 31.8 23.2 37.9 12.0 40.0 21.9 15.4 ]
demand_repartition= [3.8 3.4 6.3 2.6 2.5 4.8 4.4 6 6.1 6.8 9.3 6.8 11.1 3.5 11.7 6.4 4.5]

Time_load = [1775.835   1669.815	1590.300	1563.795	1563.795	1590.300	1961.370	2279.430	251.975	2544.480	2544.480	2517.975	2517.975	2517.975	2464.965	2464.965	2623.995	2650.500	2650.500	2544.480	2411.955	2199.915	1934.865	1669.815]

#Time dependent demand
demand_max= (Time_load' * demand_repartition/100)'

#For step one we looked at hour 12 so now we are just creating a coefficient in order to make the utility time dependent
coefficient=Time_load/Time_load[12]

#Time dependent utility
demand_prices = (coefficient' * demand_price)'

println(size(prod_capacity))
println(size(prod_capacities))
println(size(demand_prices))
@variable(model_1, q_prod[1:P,1:T]>=0)
@variable(model_1, q_demand[1:D,1:T]>=0)


@objective(model_1, Max, sum(demand_prices[i,t]*q_demand[i,t] for i in 1:D, t in 1:T) - sum(prod_price[i]*q_prod[i,t] for i in 1:P, t in 1:T))


@constraint(model_1, Production_limit[p in 1:P, t in 1:T], prod_capacities[p,t]>=q_prod[p,t])

@constraint(model_1, Demand_limit[d in 1:D, t in 1:T], demand_max[d,t]>=q_demand[d,t])

@constraint(model_1, Energy_Equilibrium[t in 1:T], sum(q_demand[d,t] for d in 1:D) == sum(q_prod[p,t] for p in 1:P))

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
    end

end

#=
    for p in 1:P 
        println(file,"Producer $p : Produces $(round.(value.(q_prod[p]),digits=2)) / Profit $(round.(value.(q_prod[p])*(Market_price-prod_price[p]),digits=2))")
        
    end

    for d in 1:D 
        println(file,"Demand $d : Consumes $(round.(value.(q_demand[d]),digits=2)) / Benefit $(round.(value.(q_demand[d])*(demand_price[d]-Market_price),digits=2))")
    end
   
    println(file,"-----------------")  # Separator between time steps
    println(file,"Price $(Market_price)")
    println(file,"-----------------")  # Separator between time steps
    # Flush the file to ensure all data is written
    flush(file)
    # Close the file
    close(file)
    # Open the file 
    run(`cmd /c start notepad $file_path`)


=#