layout1 = html_div() do
    #dcc_input(id = "input-3", value = "initial value", type = "text"),
    #html_div(id="output-1")
    html_h3("App 1_"),
    # represents the URL bar, doesn't render anything
    dcc_input(id = "input-3", value = "initial value", type = "text"),
    html_div(id="output-1"),


    dcc_link("Navigate to /", href="/"),
    html_br(),
    dcc_link("Navigate to /page-2", href="app2")

    # content will be rendered in this element
    #html_div(id="page-content")


end

layout2 = html_div() do

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
    html_button(id = "submit-button-state", children = "Run", n_clicks = 0),
    html_br(),

    dcc_link("Navigate to /", href="/"),
    html_br(),
    dcc_link("Navigate to /page-1", href="app1")

end
