#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

#units

model_1= Model(Gurobi.Optimizer)

#Producers including 6 Wind farms producing max 200MW looking at the data of several zone at 12 pm
prod_price=[13.32 13.32 20.7 20.93 26.11 10.52 10.52 6.02 5.47 0 10.52 10.89] #0 0 0 0 0 0]
prod_capacity=[152 152 350 591 60 155 155 400 400 300 310 350] # 200*0.703270 200*0.723443 200*0.738949 200*0.635512 200*0.700758 200*0.711764]


demand_max= [95.7 85.6 158.6 65.5 62.9 120.9  110.8 151.1 153.6 171.2 234.2 171.2 279.5 88.1 294.6 161.2 113.3 ]

demand_price= [ 13.0 11.6 21.5 8.9 8.5 16.4 15.0 20.5 20.9 23.2 31.8 23.2 37.9 12.0 40.0 21.9 15.4 ]

P=length(prod_price)
D=length(demand_price)

@variable(model_1, q_prod[1:P]>=0)
@variable(model_1, q_demand[1:D]>=0)


@objective(model_1, Max, sum(demand_price[i]*q_demand[i] for i in 1:D) - sum(prod_price[i]*q_prod[i] for i in 1:P))


@constraint(model_1, Production_limit[p in 1:P], prod_capacity[p]>=q_prod[p])

@constraint(model_1, Demand_limit[d in 1:D], demand_max[d]>=q_demand[d])

@constraint(model_1, Energy_Equilibrium, sum(q_demand[d] for d in 1:D) == sum(q_prod[p] for p in 1:P))

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

    
    # Display other information for the current time step
    Market_price=-dual(Energy_Equilibrium)

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

end
