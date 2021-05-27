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
    :consumers => [100, 300], # expanded
    :bakers => [5, 15],         # expanded
    :tv_merchants => [0, 5],            # not Vector = not expanded
)

app.layout = html_div() do

    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    #dcc_graph(id = "spreadsumsy"),
    html_p(id = "display-parameters", style=Dict("whiteSpace" => "pre-line")),
    dcc_dropdown(
        id = "countries-radio",
        options = [(label = i, value = i) for i in keys(all_parameters)],
        value = "Gegarandeerd inkomen",
        clearable=false
    ),

    html_hr(),
    dcc_radioitems(id = "cities-radio")

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
    Output("cities-radio", "options"),
    Output("display-parameters", "children"),
    Input("countries-radio", "value"),
) do selected_country

    return ([(label = i, value = i) for i in all_parameters[selected_country]], parameterstext())
end

#run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
run_server(app, "0.0.0.0"; debug = true)
