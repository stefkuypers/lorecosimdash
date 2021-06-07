using DataFrames, Statistics
#using EconoSim

include("loreco_sim.jl")

adata = [(balance, sum)]

parameters = Dict(
    :guaranteed_income => [2000,3000],
    :dem_free => (25000),
    :dem => (0.1),
    :interval => (30),
    :seed => (5000),
    :consumers => [100, 300], # expanded
    :bakers => [5, 15],         # expanded
    :tv_merchants => [0, 5],            # not Vector = not expanded
)

data, _ = paramscan(parameters, init_loreco_model_sumsy; adata, agent_step! = actor_step!, model_step! = econo_model_step!, n = 3)
print(data[:,:])



#adata = [(balance,minimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]
#model = init_loreco_model(SuMSy(sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, seed = sumsy_seed),
#n_consumers, n_bakers, n_tv_merchants)
#data, _ = run!(model, actor_step!, econo_model_step!, n_periods; adata)


#run_server(app, "0.0.0.0"; debug = true)
