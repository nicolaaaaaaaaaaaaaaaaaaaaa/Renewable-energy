using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

using LinearAlgebra

include("task_2_1.jl")
resolution=0.01
expected_reserve_shortfall=zeros((Int(0.2/resolution)+1,2))
global l=1
for epsilon in collect(0:(0.2/resolution))*resolution
    
    c_up = FCR_D_Also_X(Selected_loads,epsilon)
    matrix_us = hcat(Unseen_loads...)
    matrix_s = hcat(Selected_loads...)

    reserve_shortfall = matrix_us-ones(size(matrix_us))*c_up

    expected_reserve_shortfall[l,1]=c_up
    expected_reserve_shortfall[l,2]=sum(reserve_shortfall[t,k] for t in 1:T, k in 1:(L-NSS))/(T*L-NSS)
    global l+=1
end
print(expected_reserve_shortfall[:,1])
plot(expected_reserve_shortfall[:,2],expected_reserve_shortfall[:,1])
