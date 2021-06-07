using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, PlotlyJS, Statistics
#using EconoSim

include("loreco_sim.jl")

app = dash()

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

app.layout = html_div() do

    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    html_div(id="tableresults"),
    #dcc_graph(id = "spreadsumsy"),
    html_p(id = "display-parameters", style=Dict("whiteSpace" => "pre-line")),
    dcc_dropdown(
        id = "countries-radio",
        options = [(label = i, value = i) for i in keys(all_parameters)],
        value = "Gegarandeerd inkomen",
        clearable=false,
        style=Dict("display" => "none") #just to hide it because we don't need it in the example
    ),

    html_hr()


end

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

callback!(
    app,
    Output("tableresults", "children"),
    Output("display-parameters", "children"),
    Output("totalsumsy", "figure"),
    Input("countries-radio", "value"),
) do selected_country
    adata = [(balance, sum)]
    data, _ = paramscan(abm_parameters, init_loreco_model_sumsy; adata, agent_step! = actor_step!, model_step! = econo_model_step!, n = 10)
    data1 = stack(data, [:sum_balance], [:step, :guaranteed_income])
    #data1.guaranteed_income = "Gegarandeerd inkomen = " .* string(data1.guaranteed_income)
    
    print(data1[:,:])
    pMin = Plot(data1, x = :step, y = :value, group = :guaranteed_income ,mode="markers")

    return (generate_table(data, 50),parameterstext(), pMin)
end

#run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
run_server(app, "0.0.0.0"; debug = true)
