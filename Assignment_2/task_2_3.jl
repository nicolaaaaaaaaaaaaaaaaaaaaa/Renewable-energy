using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots
using StatsBase

using LinearAlgebra

include("task_2_1.jl")
resolution=0.01
expected_reserve_shortfall=zeros((floor(Int64,0.2/resolution)+1,5))
global l=1
for epsilon in collect(0:floor(Int64,0.2/resolution))*resolution
    
    c_up = FCR_D_Also_X(Selected_loads,epsilon)
    matrix_us = transpose(hcat(Unseen_loads...))
    matrix_s = transpose(hcat(Selected_loads...))
 
    reserve_shortfall = zeros(L-NSS)
    
    for l in 1:(L-NSS)
        for k in 1:T
            reserve_shortfall[l]+=max(c_up-matrix_us[l,k],0)/T
        end
    end
    
    expected_reserve_shortfall[l,1]=c_up
    expected_reserve_shortfall[l,2]=mean(reserve_shortfall)
    expected_reserve_shortfall[l,3]=expected_reserve_shortfall[l,2]+0.5*std(reserve_shortfall)#quantile(sort(reserve_shortfall), 0.75)
    expected_reserve_shortfall[l,4]=expected_reserve_shortfall[l,2]-0.5*std(reserve_shortfall)#quantile(sort(reserve_shortfall), 0.5)
    expected_reserve_shortfall[l,5]=epsilon
    
    
    #println(quantile(sort!(reserve_shortfall,dims=1), 0.25))
    #price_given_q25 = [quantile(sort(col), 0.25) for col in eachcol(price_given)]
    #price_given_q75 = [quantile(sort(col), 0.75) for col in eachcol(price_given)]
    
    #plot(time, price_given_q25, linecolor=:transparent, fillrange=price_given_q75, fillalpha=0.3, label=nothing, color=:blue)
    

    global l+=1
end
println(expected_reserve_shortfall[:,2])
println(expected_reserve_shortfall[:,5])

#=
plot(expected_reserve_shortfall[:,5],expected_reserve_shortfall[:,2])
plot!(expected_reserve_shortfall[:,5], expected_reserve_shortfall[:,3], linecolor=:transparent, fillrange=expected_reserve_shortfall[:,4], fillalpha=0.3, label=nothing, color=:blue)
xlabel!("Power bid (kW)")
ylabel!("Production [MW]")
title!("Given production for different scenarios")
scatter!(expected_reserve_shortfall[:,5],expected_reserve_shortfall[:,2], marker=:circle, markersize=5, markercolor=:blue)
xlims!(0, 0.2)
filepath = joinpath(@__DIR__, "task_2_3_Expected_shortfall.png")
savefig(filepath)
=#
plot(expected_reserve_shortfall[:,1],expected_reserve_shortfall[:,2], label="Average reserve shortfall")
plot!(expected_reserve_shortfall[:,1], expected_reserve_shortfall[:,3], linecolor=:transparent, fillrange=expected_reserve_shortfall[:,4], fillalpha=0.3, label="50% confidence interval", color=:blue)
xlabel!("optimal reserve capacity bid [kW]")
ylabel!("Expected reserve shortfall [kWh]")
labels=["ε = $(expected_reserve_shortfall[1,5])", "ε = $(expected_reserve_shortfall[6,5])", "ε = $(expected_reserve_shortfall[11,5])", "ε = $(expected_reserve_shortfall[16,5])", "ε = $(expected_reserve_shortfall[21,5])"]
scatter!([expected_reserve_shortfall[1,1], expected_reserve_shortfall[6,1], expected_reserve_shortfall[11,1], expected_reserve_shortfall[16,1], expected_reserve_shortfall[21,1]],[expected_reserve_shortfall[1,2], expected_reserve_shortfall[6,2], expected_reserve_shortfall[11,2], expected_reserve_shortfall[16,2], expected_reserve_shortfall[21,2]], marker=:circle, markersize=8, markercolor=:blue, label=nothing)
scatter!([expected_reserve_shortfall[1,1], expected_reserve_shortfall[6,1], expected_reserve_shortfall[11,1], expected_reserve_shortfall[16,1], expected_reserve_shortfall[21,1]],[expected_reserve_shortfall[1,2]+0.75, expected_reserve_shortfall[6,2]+1.5, expected_reserve_shortfall[11,2]+1, expected_reserve_shortfall[16,2]+1, expected_reserve_shortfall[21,2]+1 ], text=labels, dpi=300, text_offset=10, marker=:circle, markersize=0, markercolor=:blue, label=nothing)
xlims!(200, 300)
filepath = joinpath(@__DIR__, "task_2_3_Expected_shortfall.pdf")
savefig(filepath)


plot(expected_reserve_shortfall[:,5],expected_reserve_shortfall[:,1], label="Power bid")
xlabel!("Epsilon")
ylabel!("Power (kW)")
ylims!(200, 300)
filepath = joinpath(@__DIR__, "task_2_3_Power_bid.pdf")
savefig(filepath)
