using Random
using JuMP
using Gurobi
using Printf
using Clustering
using Distances
using Plots

using LinearAlgebra

include("task_2_1.jl")

c_up_0 = FCR_D_Cvar(Selected_loads,0.1)
c_up = FCR_D_Also_X(Selected_loads,0.1)
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




# For FCR_D_Cvar
overbid_minutes_cvar = []
frequency_cvar = zeros(61)
for load in Unseen_loads
    nb = 0
    for t in 1:length(load)
        if load[t] < c_up_0
            nb += 1
        end
    end
    push!(overbid_minutes_cvar, nb)
    frequency_cvar[nb + 1] += 1
end

# For FCR_D_Also_X
overbid_minutes_also_x = []
frequency_also_x = zeros(61)
for load in Unseen_loads
    nb = 0
    for t in 1:length(load)
        if load[t] < c_up
            nb += 1
        end
    end
    push!(overbid_minutes_also_x, nb)
    frequency_also_x[nb + 1] += 1
end
#=
# Plot for FCR_D_Cvar
x = collect(1:60)
plot(x, Selected_loads[4], title="load 1")
plot!(ones(60) * c_up_0, label="CVar")
plot!(ones(60) * c_up,label="ALSO-X")
=#
# Plot for FCR_D_Also_X
# You can plot the frequency and overbid_minutes for FCR_D_Also_X here if needed

#calculations

avg_cvar = mean(overbid_minutes_cvar)
avg_alsox = mean(overbid_minutes_also_x)

# Print the average
println("Average CVar:", avg_cvar)
println("Average ALSO_X:", avg_alsox)

# Print the results
println("FCR_D_Cvar Overbid Minutes:", overbid_minutes_cvar)
println("FCR_D_Cvar Frequency:", frequency_cvar)

println("FCR_D_Also_X Overbid Minutes:", overbid_minutes_also_x)
println("FCR_D_Also_X Frequency:", frequency_also_x)

#Cvar plots
#=
#To plot frequency plots with not overbided loads
bar(0:60, frequency_cvar, color=ifelse.(1:length(frequency_cvar) .== 1, :green, :blue), labels=["Loads not being overbided", "Loads being overbided"], title="CVar",xlabel="Total minutes overbided", ylabel="Times repeated")



#To plot frequency plots only  with overbided loads
bar(collect(0:60),frequency_cvar[2:61],title="CVaR",xlabel="Total minutes overbided", ylabel="Times repeated")


vline!([6], color=:red, linestyle=:dash, label="Vertical Line")
vline!([avg_cvar], color=:black, linestyle=:dash, label="mean")
=#
#ALSO-X plots
#To plot frequency plots with not overbided loads
bar(0:60, frequency_also_x, color=ifelse.(1:length(frequency_cvar) .== 1, :green, :blue), labels=["Loads not being overbided", "Loads being overbided"], title="ALSO-X",xlabel="Total minutes overbided", ylabel="Times repeated")


#=
#To plot frequency plots only  with overbided loads
bar(collect(0:60),frequency_also_x[2:61],title="ALSO-X",xlabel="Total minutes overbided", ylabel="Times repeated")

=#
vline!([6], color=:red, linestyle=:dash, label="Vertical Line")
vline!([avg_alsox], color=:black, linestyle=:dash, label="mean")