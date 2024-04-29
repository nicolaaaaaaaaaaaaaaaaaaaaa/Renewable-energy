using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots



function FCR_D_Also_X(F_up,epsilon)
    
    model_1= Model(Gurobi.Optimizer)

    W=length(F_up[:,1])
    T=length(F_up[1,:])
    M=100000000
    q=epsilon*W*T

    #declare Variables
    @variable(model_1, c_up>=0)
    @variable(model_1, 1>=y[T,W]>=0)

    #Objective function
    @objective(model_1,Max,c_up)

    #Constraints
    @constraint(model_1,M[m in 1:T, w in 1:W],c_up-F_up[m,w]<= y[m,w]*M)
    @constraint(model_1,Limit_errors,sum(y[m,W] for m in 1:T, w in 1:W)<=q)

    # Solving the model
    optimize!(model_1)

    # Printing the termination status
    println("Status: ", JuMP.termination_status(model_1))

    # Printing the objective value
    println("Objective value: ", JuMP.objective_value(model_1))

end

function FCR_D_Cvar(F_up,epsilon)

    model_1= Model(Gurobi.Optimizer)

    W=length(F_up[:,1])
    T=length(F_up[1,:])
    #declare Variables
    @variable(model_1, c_up>=0)
    @variable(model_1, Beta<=0)
    @variable(model_1, zeta[T,W]<=0)


    #Objective function
    @objective(model_1,Max,c_up)

    #Constraints
    @constraint(model_1,Zeta[m in 1:T,w in 1:W],c_up-F_up[m,w]<=zeta[m,w])
    @constraint(model_1,Default_number,1/(T*W)*sum(zeta[m,W] for m in 1:T, w in 1:W)<=(1-espilon)*Beta)
    @constraint(model_1,Betas[m in 1:T,w in 1:W], Beta<=zeta[m,w])

    # Solving the model
    optimize!(model_1)

    # Printing the termination status
    println("Status: ", JuMP.termination_status(model_1))

    # Printing the objective value
    println("Objective value: ", JuMP.objective_value(model_1))


end
