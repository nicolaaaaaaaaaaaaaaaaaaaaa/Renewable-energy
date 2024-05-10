using Random
using Distributions
using StatsBase
using Gurobi
Random.seed!(121)
#Load generation Data
L=200
T=60
load_list=zeros(L,T)
load=zeros(L,T)
for i in 1:L
    load[i,1] =rand(200:500)
    load_list[i,1]=load[i,1]
    for j in 2:T
        load[i,j] = load_list[i,j-1] + rand(-25:25)
        load_list[i,j] = max(200, min(500, load[i,j]))
    end
end


#Load selection
#number of selected loads
NSS=50

Index_selected = sample(1:L, NSS, replace=false)
Selected_loads = []
Unseen_loads = []
for k in 1:L
    if in(k,Index_selected)
        push!(Selected_loads,load_list[k,:])
    else
        push!(Unseen_loads,load_list[k,:])
    end
end

println(Selected_loads[4])
