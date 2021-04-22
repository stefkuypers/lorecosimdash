using DashCoreComponents, DataFrames, Statistics, PlotlyJS

include("loreco_sim.jl")
include("app8.jl")

#callback 1
callback!(app, Output("output-1", "children"), Input("input-3", "value")) do input_value
    print("test")
    return "You've entered $(input_value)"
end

#callback 2
callback!(
    app,
    Output("totalsumsy", "figure"),
    #Output("spreadsumsy", "figure"),
    Input("submit-button-state", "n_clicks"),
    State("n_periods", "value"),
    State("sumsy_gincome", "value"),
    State("sumsy_demfree", "value"),
    State("sumsy_dem", "value"),
    State("sumsy_interval", "value"),
    State("sumsy_seed", "value"),
    State("n_consumers", "value"),
    State("n_bakers", "value"),
    State("n_tv_merchants", "value"),
) do n_clicks, n_periods, sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, sumsy_seed, n_consumers, n_bakers, n_tv_merchants
    adata = [(balance,minimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]
    model = init_loreco_model(SuMSy(sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, seed = sumsy_seed),
    n_consumers, n_bakers, n_tv_merchants)
    data, _ = run!(model, actor_step!, econo_model_step!, n_periods; adata)
    print(data[1:5,:])

    pSum = Plot(data, x = :step, y = :sum_balance, name="total")
    pMin = Plot(data, x = :step, y = :minimum_balance, name="minimum")
    pMax = Plot(data, x = :step, y = :maximum_balance, name="maximum")
    pMedian = Plot(data, x = :step, y = :median_balance, name="median")
    return ([pSum pMedian
     pMin pMax])
end
