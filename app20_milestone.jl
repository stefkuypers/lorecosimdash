using DataFrames, Dash, DashHtmlComponents, DashCoreComponents, DashBootstrapComponents, PlotlyJS, Statistics
#using EconoSim

include("loreco_sim.jl")
include("loreco_app.jl")

app = dash(external_stylesheets=[dbc_themes.BOOTSTRAP])

app.layout = dbc_container(html_div([
    dbc_row(dbc_col([
        #html_div("A single column"),
        html_h1("LoREco Simulation"),
        dbc_alert("Input parameters", color="success"),
        html_div([
            dbc_row([
                dbc_col([
                    html_label(children="Gegarandeerd inkomen "),
                    dcc_input(id="sumsy_gincome", type="number", min=0, step=100, value=2000),
                    html_br(),
                    html_label(children="Demurragevrije buffer "),
                    dcc_input(id="sumsy_demfree", type="number", min=0, step=500, value=25000),
                    html_br(),
                    html_label(children="Demurrage percentage "),
                    dcc_input(id="sumsy_dem", type="number", min=0, step=0.25,max = 100, value=10),
                    html_br(),
                    html_label(children="Startbedrag deelnemers "),
                    dcc_input(id="sumsy_seed", type="number", min=0, step=100, value=5000),
                ], width=5),
                dbc_col([

                    html_label(children="Aantal consumenten met gegarandeerd inkomen "),
                    dcc_input(id="n_consumers_gi", type="number", min=1, value=200),
                    html_br(),
                    html_label(children="Aantal consumenten zonder gegarandeerd inkomen "),
                    dcc_input(id="n_consumers_notgi", type="number", min=0, value=180),
                    html_br(),
                    html_label(children="Aantal bakkerijen "),
                    dcc_input(id="n_bakers", type="number",  min=1, value=15),
                    html_br(),
                    html_label(children="Aantal tv handelaren "),
                    dcc_input(id="n_tv_merchants", type="number",  min=1, value=5),
                    html_br(),
                    html_label(children="Simulatieduur in aantal maanden "),
                    dcc_input(id="n_periods", type="number",  min=1, step=1, value=2),
                    html_button(id = "submit-button-state", children = "Run", n_clicks = 0),
                ], width=7),
                dbc_col([
                    html_label(children="Inflow common good"),
                    dcc_input(id="commongood_perc", type="number", min=0, step=0.25,max = 100, value=50),
                    html_label(children="Frequency common good project decision (in months)"),
                    dcc_input(id="projectdecision_periods", type="number", min=1, step=1, value=4),
                    html_label(children="Allowed project per decision"),
                    dcc_input(id="projects_count", type="number", min=1, step=1, value=4),
                ], width=6)
            ])
        ])
    ])),
    html_br(),
    dbc_alert("Data visualizations", color="success"),
    dbc_row([
        dbc_col([html_h3("Per period SumSy balance"), dcc_graph(id = "totalsumsy")], width=12),
        dbc_col([html_h3("Per period Consumers SumSy balance"), dcc_graph(id = "sumsyconsumers")], width=12),
        dbc_col([html_h3("Per period Bakers SumSy balance"), dcc_graph(id = "sumsybakers")], width=12),
        dbc_col([html_h3("Per period TV Merchants SumSy balance"), dcc_graph(id = "sumsytvmerchants")], width=12),
        dbc_col([html_h3("Per period Governance balance"), dcc_graph(id = "sumsygovernance")], width=12),
    ]),
    dbc_row([
        dbc_col([html_h3("Per period SumSy Demurrage"), dcc_graph(id = "totaldemurrage")], width=12),
        dbc_col([html_h3("Per period Consumers SumSy Demurrage"), dcc_graph(id = "demurrageconsumers")], width=12),
        dbc_col([html_h3("Per period Bakers SumSy Demurrage"), dcc_graph(id = "demurragebakers")], width=12),
        dbc_col([html_h3("Per period TV Merchants SumSy Demurrage"), dcc_graph(id = "demurragetvmerchants")], width=12),
        dbc_col([html_h3("Per period Governance Demurrage"), dcc_graph(id = "demurragegovernance")], width=12),
    ]),
]), className="p-5")

callback!(
    app,
    Output("totalsumsy", "figure"),
    Output("sumsyconsumers", "figure"),
    Output("sumsybakers", "figure"),
    Output("sumsytvmerchants", "figure"),
    Output("sumsygovernance", "figure"),
    Output("totaldemurrage", "figure"),
    Output("demurrageconsumers", "figure"),
    Output("demurragebakers", "figure"),
    Output("demurragetvmerchants", "figure"),
    Output("demurragegovernance", "figure"),
    Input("submit-button-state", "n_clicks"),
    State("n_periods", "value"),
    State("sumsy_gincome", "value"),
    State("sumsy_demfree", "value"),
    State("sumsy_dem", "value"),
    State("sumsy_seed", "value"),
    State("n_consumers_gi", "value"),
    State("n_consumers_notgi", "value"),
    State("n_bakers", "value"),
    State("n_tv_merchants", "value"),
    State("commongood_perc", "value"),
    State("projectdecision_periods", "value"),
    State("projects_count", "value"),
) do n_clicks, n_periods, sumsy_gincome, sumsy_demfree, sumsy_dem, sumsy_seed, n_consumers_gi, n_consumers_notgi, n_bakers, n_tv_merchants, commongood_perc, projectdecision_periods, projects_count
    adata= [(balance,sum), (demurrage, sum), (balance, sum, governance), (demurrage, sum, governance),
        (balance, minimum, consumer), (balance, maximum, consumer), (balance, mean, consumer), (balance, median, consumer),
        (balance, minimum, baker), (balance, maximum, baker), (balance, mean, baker), (balance, median, baker),
        (balance, minimum, tvmerchant), (balance, maximum, tvmerchant), (balance, mean, tvmerchant), (balance, median, tvmerchant),
        (demurrage, minimum, consumer), (demurrage, maximum, consumer), (demurrage, mean, consumer), (demurrage, median, consumer),
        (demurrage, minimum, baker), (demurrage, maximum, baker), (demurrage, mean, baker), (demurrage, median, baker),
        (demurrage, minimum, tvmerchant), (demurrage, maximum, tvmerchant), (demurrage, mean, tvmerchant), (demurrage, median, tvmerchant)]
    #adata = [(balance,minimum),(balance,sum),(balance,maximum), (balance, mean),(balance, median), (balance, std)]    
    model = init_loreco_model(SuMSy(sumsy_gincome, sumsy_demfree, sumsy_dem, 30, seed = sumsy_seed),
    n_consumers_gi, n_bakers, n_tv_merchants)
    data, _ = run!(model, actor_step!, econo_model_step!, n_periods*30; adata)
    #print(data[1:5,:])

    dataM = stack(data, :sum_balance, :step)
    dataMC = stack(data, [:minimum_balance_consumer, :maximum_balance_consumer, :mean_balance_consumer, :median_balance_consumer], :step)
    dataMB = stack(data, [:minimum_balance_baker, :maximum_balance_baker, :mean_balance_baker, :median_balance_baker], :step)
    dataMT = stack(data, [:minimum_balance_tvmerchant, :maximum_balance_tvmerchant, :mean_balance_tvmerchant, :median_balance_tvmerchant], :step)
    dataMG = stack(data, :sum_balance_governance, :step)
    dataD = stack(data, :sum_demurrage, :step)
    dataDC = stack(data, [:minimum_demurrage_consumer, :maximum_demurrage_consumer, :mean_demurrage_consumer, :median_demurrage_consumer], :step)
    dataDB = stack(data, [:minimum_demurrage_baker, :maximum_demurrage_baker, :mean_demurrage_baker, :median_demurrage_baker], :step)
    dataDT = stack(data, [:minimum_demurrage_tvmerchant, :maximum_demurrage_tvmerchant, :mean_demurrage_tvmerchant, :median_demurrage_tvmerchant], :step)
    dataDG = stack(data, :sum_demurrage_governance, :step)

    #print(dataG[:,:])
    plotMoney = Plot(dataM, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyConsumers = Plot(dataMC, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyBakers = Plot(dataMB, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyTVMerchants = Plot(dataMT, x = :step, y = :value, group = :variable ,mode="lines")
    plotMoneyGovernance = Plot(dataMG, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrage = Plot(dataD, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageConsumers = Plot(dataDC, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageBakers = Plot(dataDB, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageTVMerchants = Plot(dataDT, x = :step, y = :value, group = :variable ,mode="lines")
    plotDemurrageGovernance = Plot(dataDG, x = :step, y = :value, group = :variable ,mode="lines")
    return (plotMoney, plotMoneyConsumers, plotMoneyBakers, plotMoneyTVMerchants, plotMoneyGovernance,
        plotDemurrage, plotDemurrageConsumers, plotDemurrageBakers, plotDemurrageTVMerchants, plotDemurrageGovernance)

end

#run_server(app, "0.0.0.0", parse(Int,ARGS[1]); debug = true)
run_server(app, "0.0.0.0"; debug = true)
