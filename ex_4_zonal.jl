#Import packages
using Random
using JuMP
using Gurobi
using Printf
using XLSX

#units

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
demand_utility= [13.0 11.6 21.5 8.9 8.5 16.4 15.0 20.5 20.9 23.2 31.8 23.2 37.9 12.0 40.0 21.9 15.4]

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
ramp_limit = [120   120 350	240	60	155	155	280	280	300	180	240 200 200 200 200 200 200]


#Electrolyzer demand
demand_electrolyzer = zeros(P)
demand_electrolyzer[P] = 28 #in T
demand_electrolyzer[P-1] = 45 #in T
demand_electrolyzer[P-2] = 50 #in T

""" Task 4 constraints nodal"""
#Number of busses
B=24

#Load and gnerator location
Load_location = [1	2	3	4	5	6	7	8	9	10	11	12	13	14	15	16	17;
1	2	3	4	5	6	7	8	9	10	13	14	15	16	18	19	20]

Generator_location = [1	2	3	4	5	6	7	8	9	10	11	12 13 14 15 16 17 18;
1	2	7	13	15	15	16	18	21	22	23	23  3   5   7   16  21  23]

#Generate lists which will contain at index i a list of every generator or load that is connected to node i
generator_to_nodes = []
load_to_nodes = []

#Go through the busses
for i in 1:B    
    list1=Int[]
    #go through every generator    
    for k in 1:length(Generator_location[1,:])
        #check if the generator k is located on bus i
        if Generator_location[2,k]==i
            #Add generator to the list
            push!(list1,k)
        end
    end

    #Do the same for the Loads
    list2=Int[]
    for k in 1:length(Load_location[1,:])
        
        if Load_location[2,k]==i
            push!(list2,k)
        end
        
    end

    #Add the lists of generators and loads at the i element of the lists
    push!(generator_to_nodes,list1)
    push!(load_to_nodes, list2) 
end

#create the list of lists of generators by node for the first element and of loads by node for the second element
nodes=[generator_to_nodes,load_to_nodes]



#Lines data
Lines_data = [1	1	1	2	2	3	3	4	5	6	7	8	8	9	9	10	10	11	11	12	12	13	14	15	15	15	16	16	17	17	18	19	20	21;
2	3	5	4	6	9	24	9	10	10	8	9	10	11	12	11	12	13	14	13	23	23	16	16	21	24	17	19	18	22	21	20	23	22;
0.0146	0.2253	0.0907	0.1356	0.205	0.1271	0.084	0.111	0.094	0.0642	0.0652	0.1762	0.1762	0.084	0.084	0.084	0.084	0.0488	0.0426	0.0488	0.0985	0.0884	0.0594	0.0172	0.0249	0.0529	0.0263	0.0234	0.0143	0.1069	0.0132	0.0203	0.0112	0.0692;
175	175	350	175	175	175	400	175	350	175	350	175	175	400	400	400	400	500	500	500	500	500	500	500	1000	500	500	500	500	500	1000	1000	1000	500]


#Generate matrices representing the busses which will contain the Reactance and the capacity for every connection line that exist between busses i and j
Lines_Reactance = zeros(B,B)
Lines_Capacity = zeros(B,B)

for i in 1:length(Lines_data[1,:])
    #Write the symetrical matrix
    Lines_Reactance[floor(Int,Lines_data[1,i]),floor(Int,Lines_data[2,i])]=1/Lines_data[3,i]
    Lines_Reactance[floor(Int,Lines_data[2,i]),floor(Int,Lines_data[1,i])]=1/Lines_data[3,i]
end



for i in 1:length(Lines_data[1,:])
    #Write the symetrical matrix
    Lines_Capacity[floor(Int,Lines_data[1,i]),floor(Int,Lines_data[2,i])]=Lines_data[4,i]
    Lines_Capacity[floor(Int,Lines_data[2,i]),floor(Int,Lines_data[1,i])]=Lines_data[4,i]
end

""" Task 4 constraints Zonal """

#Define the zones
List_zones = [[1,2,3,4,5,6,7,8,9,10],[11,12,13,14,19,20,23],[15,16,17,18,21,22,24]]
#List_zones = [[1,2,3,4,5,6,7,8,9,10],[11,12,13,14,15,16,19,20,23,24],[17,18,21,22]]
Z=length(List_zones)

#Define the ATC between every zones
ATC_zones = [0 sum(Lines_Capacity[m,n] for m in List_zones[2], n in List_zones[1]) sum(Lines_Capacity[m,n] for m in List_zones[3], n in List_zones[1]);
sum(Lines_Capacity[m,n] for m in List_zones[1], n in List_zones[2]) 0 sum(Lines_Capacity[m,n] for m in List_zones[3], n in List_zones[2]);
sum(Lines_Capacity[m,n] for m in List_zones[1], n in List_zones[3]) sum(Lines_Capacity[m,n] for m in List_zones[2], n in List_zones[3]) 0]

""" Variables """

#Quantity of energy producted that goes into the grid in MWh
@variable(model_1, q_prod[1:P,1:T]>=0)

#Quantity of energy consumed by the demand in MWh
@variable(model_1, q_demand[1:D,1:T]>=0)

#Quantity of energy producted by the producers for the wind turbines' electrolyzer in MWh 
@variable(model_1, q_electrolyzer_prod[1:P,1:T]>=0)

#Angle 
@variable(model_1, f_a_b[1:Z, 1:Z, 1:T])

""" Objective function """

@objective(model_1, Max, sum(demand_utilities[i,t]*q_demand[i,t] for i in 1:D, t in 1:T) - sum(prod_price[i]*(q_prod[i,t]) for i in 1:P, t in 1:T))

""" Constraints """
#Limit of the quantity of energy producted
@constraint(model_1, Production_limit[p in 1:P, t in 1:T], prod_capacities[p,t]>=q_prod[p,t]+q_electrolyzer_prod[p,t])

#Limit of the quantity of energy consumed
@constraint(model_1, Demand_limit[d in 1:D, t in 1:T], demand_max[d,t]>=q_demand[d,t])

#Equilibrium of the energy on the grid
@constraint(model_1, Energy_Equilibrium[z in 1:Z, t in 1:T], sum(sum(q_demand[d,t] for d in nodes[2][k]) for k in List_zones[z]) + sum(f_a_b[z,y,t] for y in Z) == sum(sum(q_prod[p,t] for p in nodes[1][k]) for k in List_zones[z]))

#Ramp limit constraint on the difference between the total energy producted at t and at t-1 
@constraint(model_1, Ramp_limit[p in 1:P, t in 2:T], ramp_limit[p]>=(q_prod[p,t]-q_prod[p,t-1])>=-ramp_limit[p])

#Electrolyzer constraint, the demand for hydrogen should be met by the end of the day by the concerned wind farm 
@constraint(model_1, Demand_electrolyzer[p in 1:P], demand_electrolyzer[p]==sum(q_electrolyzer_prod[p,t] for t in 1:T)*18/1000)

# capacity constraints
@constraint(model_1, Capacity_constraint[z in 1:Z, y in 1:Z, t in 1:T], -ATC_zones[z,y]<= f_a_b[z,y,t] <= ATC_zones[z,y])

#Exchanges between two busses
@constraint(model_1, Exchanges[z in 1:Z, y in 1:Z, t in 1:T], -f_a_b[z,y,t] == f_a_b[y,z,t])


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

    Market_price=zeros(Float64,(T,Z))
    Power_Exchanges=zeros(Float64,(T,Z,Z))
    Production=zeros(Float64,(T,Z))
    Demand=zeros(Float64,(T,Z))
    # Display other information for the current time step
    for i in 1:T
        println("Step : $(i)")
        for z in 1:Z
            Market_price[i,z]=-dual(Energy_Equilibrium[z,i])
            for y in 1:Z    
                Power_Exchanges[i,z,y]=value.(f_a_b[z,y,i])
            end
            for k in List_zones[z]
                for p in nodes[1][k]
                    Production[i,z]+=value.(q_prod[p,i])
                    
                end
                for d in nodes[2][k]
                    Demand[i,z]+=value.(q_demand[d,i])
                end                
            end
        end
        println("Power Exchanges : $(Power_Exchanges[i,:,:])") 
        println("Market Price : $(Market_price[i,:])") 
        println("Demand : $(Demand[i,:])")
        println("Production : $(Production[i,:])")
        println("Prod : $(sum(value.(q_prod[p,i]) for p in 1:P))")
        println("Demand : $(sum(value.(q_demand[d,i]) for d in 1:D))")
        println("Elec : $(value.(q_electrolyzer_prod[:,i]))")

    end

end

