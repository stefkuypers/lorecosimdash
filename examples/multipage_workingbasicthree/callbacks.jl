using DashCoreComponents, DataFrames, Statistics, PlotlyJS

include("loreco_sim.jl")
include("app.jl")

all_parameters = Dict(
    "Gegarandeerd inkomen" => [2000, 3000],
    "Demurragevrije buffer" => [25000],
    "Demurrage percentage" => [0.1],
    "Periode interval" => [30],
    "Start sumsybedrag" => [5000],
    "Aantal consumenten" => [380],
    "Aantal bakkerijen" => [15],
    "Aantal tv handelaren" => [5],
    "Aantal periodes" => [10]
)

abm_parameters = Dict(
    :guaranteed_income => [2000,3000],
    :dem_free => (25000),
    :dem => (0.1),
    :interval => (30),
    :seed => (5000),
    :consumers => [380], # expanded
    :bakers => [15],         # expanded
    :tv_merchants => [5],            # not Vector = not expanded
)

function generate_table(dataframe, max_rows = 10)
    html_table([
        html_thead(html_tr([html_th(col) for col in names(dataframe)])),
        html_tbody([
            html_tr([html_td(dataframe[r, c]) for c in names(dataframe)]) for r = 1:min(nrow(dataframe), max_rows)
        ]),
    ])
end

function parameterstext()
    fixedParams = "Fixed parameters are:\n"
    scannedParams = "Scanned parameters are:\n"
    for (key, value) in all_parameters
        #println(key)
        valuestext = string(value[1])
        for i in value[2:end]
            valuestext = valuestext * ", " * string(i)
        end
        #println(valuestext)
        if size(value,1) > 1
            scannedParams = scannedParams * key * " = " * valuestext * "\n"
        else
            fixedParams = fixedParams * key * " = " * valuestext * "\n"
        end
    end
    #for i in all_parameters[]]
    return string(scannedParams , "\n", fixedParams)
end
#callback 1
callback!(
    app,
    Output("tableresults", "children"),
    Output("display-parameters", "children"),
    Output("totalsumsy", "figure"),
    Input("countries-radio", "value")
) do selected_country
    adata = [(balance, sum)]
    data, _ = paramscan(abm_parameters, init_loreco_model_sumsy; adata, agent_step! = actor_step!, model_step! = econo_model_step!, n = 10)
    data1 = stack(data, [:sum_balance], [:step, :guaranteed_income])
    #print(data1[:,:])
    pMin = Plot(data1, x = :step, y = :value, group = :guaranteed_income ,mode="markers")

    return (generate_table(data, 50),parameterstext(), pMin)
end

#callback 2
callback!(
    app,
    Output("sumsymeasures", "figure"),
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
    #print(data[1:5,:])

    pSum = Plot(data, x = :step, y = :sum_balance, name="total")
    pMin = Plot(data, x = :step, y = :minimum_balance, name="minimum")
    pMax = Plot(data, x = :step, y = :maximum_balance, name="maximum")
    pMedian = Plot(data, x = :step, y = :median_balance, name="median")
    return ([pSum pMedian
     pMin pMax])
end

#callback 3
callback!(
    app,
    Output("totalsumsy_multirun", "figure"),
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
    State("n_runs", "value"),
) do n_clicks, n_periods, sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, sumsy_seed, n_consumers, n_bakers, n_tv_merchants, n_runs
    adata = [(balance,sum)]
    models = [init_loreco_model(SuMSy(sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_interval, seed = sumsy_seed),
    n_consumers, n_bakers, n_tv_merchants) for i = 1:n_runs]
    data, _ = ensemblerun!(models, actor_step!, econo_model_step!, n_periods; adata)
    #print(data[:,:])

    pSum = Plot(data, x = :step, y = :sum_balance, group = :ensemble)
    return ([pSum])
end
