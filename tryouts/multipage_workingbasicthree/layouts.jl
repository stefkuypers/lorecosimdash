layout1 = html_div() do

    dcc_link("Home", href="/"),
    html_br(),
    dcc_link("ABM run", href="app2"),
    html_br(),
    dcc_link("ABM multi-run", href="app3"),
    html_hr(),
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy"),
    html_div(id="tableresults"),
    #dcc_graph(id = "spreadsumsy"),
    html_p(id = "display-parameters", style=Dict("whiteSpace" => "pre-line")),
    dcc_input(id = "countries-radio",type="text"
        ,style=Dict("display" => "none") #just to hide it because we don't need it in the example
    )


end


layout2 = html_div() do
    dcc_link("Home", href="/"),
    html_br(),
    dcc_link("Parameter space", href="app1"),
    html_br(),
    dcc_link("ABM multi-run", href="app3"),
    html_hr(),
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "sumsymeasures"),
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

layout3 = html_div() do
    dcc_link("Home", href="/"),
    html_br(),
    dcc_link("Parameter space", href="app1"),
    html_br(),
    dcc_link("ABM run", href="app2"),
    html_hr(),
    html_h1("Per period SumSy balance"),
    dcc_graph(id = "totalsumsy_multirun"),
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
    html_label(children="Aantal runs"),
    dcc_input(id="n_runs", type="number",  min=10, step=10, value=10),
    html_button(id = "submit-button-state", children = "Run", n_clicks = 0)
end
