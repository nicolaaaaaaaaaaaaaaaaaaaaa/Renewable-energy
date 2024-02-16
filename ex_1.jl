#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

#units
P=12
D=17 
model_1= Model(Gurobi.Optimizer)

prod_price=[13.32 13.32 20.7 20.93 26.11 10.52 10.52 6.02 5.47 0 10.52 10.89]

prod_capacity=[152 152 350 591 60 155 155 400 400 300 310 350]



demand_max= [95.7 85.6 158.6 65.5 62.9 120.9  110.8 151.1 153.6 171.2 234.2 171.2 279.5 88.1 294.6 161.2 113.3 ]

demand_price= [ 13.0 11.6 21.5 8.9 8.5 16.4 15.0 20.5 20.9 23.2 31.8 23.2 37.9 12.0 40.0 21.9 15.4 ]


@variable(model_1, q_prod[1:P]>=0)
@variable(model_1, q_demand[1:D]>=0)


@objective(model_1, Max, sum(demand_price[i]*q_demand[i] for i in 1:D) - sum(prod_price[i]*q_prod[i] for i in 1:P))


@constraint(model_1, Production_limit[p in 1:P], prod_capacity[p]>=q_prod[p])

@constraint(model_1, Demand_limit[d in 1:D], demand_max[d]>=q_demand[d])

@constraint(model_1, Send_recieved, sum(q_demand[d] for d in 1:D) == sum(q_prod[p] for p in 1:P))

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

    Market_price=0
    # Display other information for the current time step
    for p in 1:P 
        println(file,"Producer $p : Produce $(value.(q_prod[p])) / Price $(prod_price[p])")
        if value.(q_prod[p]) != 0 && value.(q_prod[p]) != prod_capacity[p]
            global Market_price=value.(prod_price[p])
        end
    end

    for d in 1:D 
        println(file,"Demand $d : Consume $(value.(q_demand[d])) / Price $(demand_price[d])")
        if value.(q_demand[d]) != 0 && value.(q_demand[d]) != demand_max[d] 
            global Market_price=value.(demand_price[d])
        end
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
    

    # Open a new Excel file
    output_file = XLSX.openxlsx()

    # Add a new sheet to the Excel file
    sheet = XLSX.addsheet(output_file, "Results")

    # Write the objective value to the Excel file
    XLSX.writestring(sheet, "A1", "Maximal Welfare")
    XLSX.writenumber(sheet, "B1", JuMP.objective_value(model_1))

    # Write other information about producers and demands to the Excel file
    producer_row = 3
    demand_row = 3
    for p in 1:P 
        global producer_row
        XLSX.writestring(sheet, "A$(producer_row)", "Producer $p")
        XLSX.writenumber(sheet, "B$(producer_row)", value.(q_prod[p]))
        XLSX.writenumber(sheet, "C$(producer_row)", prod_price[p])
        producer_row += 1
    end

    for d in 1:D 
        global demand_row
        XLSX.writestring(sheet, "E$(demand_row)", "Demand $d")
        XLSX.writenumber(sheet, "F$(demand_row)", value.(q_demand[d]))
        XLSX.writenumber(sheet, "G$(demand_row)", demand_price[d])
        demand_row += 1
    end

    # Write the market price to the Excel file
    XLSX.writestring(sheet, "A$producer_row", "Market Price")
    XLSX.writenumber(sheet, "B$producer_row", Market_price)

    # Save and close the Excel file
    XLSX.save(output_file, "output.xlsx")


end
#=
else
    return error("No solution.")
end

end
=#