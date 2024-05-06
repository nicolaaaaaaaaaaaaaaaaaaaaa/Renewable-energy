using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

using LinearAlgebra

include("task_2_1.jl")

c_up_0 = FCR_D_Cvar(Unseen_loads,0.1)
c_up = FCR_D_Also_X(Unseen_loads,0.1)
println("C_up CVAR = $c_up_0")
println("C_up D_Also_X = $c_up")
q=(L-NSS)*T*0.1
global nb_0=0
for el in Unseen_loads
    for t in 1:length(el)
        if el[t]<c_up_0
            global nb_0=nb_0+1
        end
    end
end

global nb=0
for el in Unseen_loads
    for t in 1:length(el)
        if el[t]<c_up
            global nb=nb+1
        end
    end
end

matrix = hcat(Selected_loads...)

# Flatten the matrix into a single list
combined_list = collect(Iterators.flatten(matrix))

overbid_minutes=[]
frequency = zeros(61)
for load in Unseen_loads
    nb=0
    for t in 1:length(load)
        if load[t]<c_up
            nb=nb+1
        end
    end
    push!(overbid_minutes,nb)
    frequency[nb+1]+=1
end
println(overbid_minutes)
println(frequency)

x=collect(1:60)
plot(x,Unseen_loads[1], title="load 1")
plot!(ones(60)*c_up)
plot!(ones(60)*c_up_0)

#=
bar(collect(1:60),frequency[2:61],title="frqcy")
vline!([6], color=:red, linestyle=:dash, label="Vertical Line")
=#