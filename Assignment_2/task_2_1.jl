using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots
# Import the redirect_stdout function
using Base: redirect_stdout

include("loads generation.jl")


function FCR_D_Also_X(F_up,epsilon)
    
    model_1= Model(Gurobi.Optimizer)

    W=50
    T=60
    q=900
    M=100000000
    q=epsilon*W*T
    println(F_up[W][T])
    #declare Variables
    @variable(model_1, c_up>=0)
    @variable(model_1, y[m in 1:T,w in 1:W], Bin)

    #Objective function
    @objective(model_1,Max,c_up)

    #Constraints
    @constraint(model_1,M[m in 1:T, w in 1:W],c_up-F_up[w][m]<= y[m,w]*M)
    @constraint(model_1,Limit_errors,sum(y[m,w] for m in 1:T, w in 1:W)<=q)

    # Solving the model
    optimize!(model_1)

    # Printing the objective value
    return JuMP.objective_value(model_1)
end

function FCR_D_Cvar(F_up,epsilon)

    model_1= Model(Gurobi.Optimizer)

    W=50
    T=60
    #declare Variables
    @variable(model_1, c_up>=0)
    @variable(model_1, Beta<=0)
    @variable(model_1, zeta[m in 1:T, w in 1:W])


    #Objective function
    @objective(model_1,Max,c_up)

    #Constraints
    @constraint(model_1,Zeta[m in 1:T,w in 1:W],c_up-F_up[w][m]<=zeta[m,w])
    @constraint(model_1,Default_number,1/(T*W)*sum(zeta[m,w] for m in 1:T, w in 1:W)<=(1-epsilon)*Beta)
    @constraint(model_1,Betas[m in 1:T,w in 1:W], Beta<=zeta[m,w])

    # Solving the model
    optimize!(model_1)

    # Printing the objective value
    return JuMP.objective_value(model_1)

end

#=
epsilon=0.1


opt_Also_x = zeros(50)
opt_CVar = zeros(50)
for k in 1:50

    include("loads generation.jl")
    # Define a dummy sink
    struct DummySink end
    Base.show(io::DummySink, x...) = nothing

    # Redirect stdout to the dummy sink
    old_stdout = Base.stdout
    stdout = IOBuffer()

    opt_Also_x[k] = FCR_D_Also_X(Selected_loads,0.1)

    opt_CVar[k] = FCR_D_Cvar(Selected_loads,0.1)
end

x=[k for k in 1:50]

# Plot the sine function
plot(x, opt_Also_x, label="Also x", xlabel="scenario", ylabel="Also_x", title="Day ahead production (MW)", linewidth=2)
plot!(x, opt_CVar, label="C_var", xlabel="scenario", ylabel="CVar")
#savefig("One_price_scheme_strategy.png")
#println("Expected profit: $(expected_profit)")

=#