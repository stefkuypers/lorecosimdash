using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, PlotlyJS, Statistics
#using EconoSim

include("loreco_sim.jl")

app = dash()

app.layout = html_div() do
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    #dcc_graph(id = "spreadsumsy"),
    html_label(children="Gegarandeerd inkomen"),
    dcc_input(id="sumsy_gincome", type="number", min=0, step=100, value=2000),
    html_label(children="Demurragevrije buffer"),
    dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=25000),
    html_label(children="Demurrage percentage"),
    dcc_input(id="sumsy_dem", type="number", min=0, step=0.05,max = 100, value=0.1),
    html_label(children="Periode interval"),
    dcc_input(id="sumsy_interval", type="number", min=1, value=30),
    html_label(children="Start sumsybedrag"),
    dcc_input(id="sumsy_seed", type="number", min=0, step=100, value=5000),
    html_label(children="Aantal consumenten"),
    dcc_input(id="n_consumers", type="number", min=1, value=380),
    html_label(children="Aantal bakkerijen"),
    dcc_input(id="n_bakers", type="number",  min=1, value=15),
    html_label(children="Aantal tv handelaren"),
    dcc_input(id="n_tv_merchants", type="number",  min=1, value=5),
    html_label(children="Aantal periodes"),
    dcc_input(id="n_periods", type="number",  min=10, step=10, value=10),
    html_button(id = "submit-button-state", children = "Run", n_clicks = 0)
end

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

run_server(app, "0.0.0.0", debug = true)
