using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

include("loads generation.jl")
include("task_2_1.jl")

c_up_0 = FCR_D_Cvar(Unseen_loads,0.1)
c_up = FCR_D_Also_X(Unseen_loads,0.1)
println(c_up_0)
println(c_up)
q=(L-NSS)*T*0.1
global nb_0=0
for el in Unseen_loads
    for t in 1:length(el)
        if el[t]<c_up_0
            global nb_0=nb_0+1
        end
    end
end

println(nb_0)
println(q)

global nb=0
for el in Unseen_loads
    for t in 1:length(el)
        if el[t]<c_up
            global nb=nb+1
        end
    end
end

println(nb)