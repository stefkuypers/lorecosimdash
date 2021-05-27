using DashHtmlComponents, DashCoreComponents

include("app8.jl")
include("app1.jl")
include("app2.jl")

app.layout = html_div() do
    dcc_location(id="url"),
    html_div(id="page-content")
end



callback!(app, Output("page-content", "children"), Input("url", "pathname")) do pathname
    println(pathname)
    if pathname == "/app1"
        app1.layout
    elseif pathname == "/app2"
        app2.layout
    elseif pathname =="/"
        html_div() do
            dcc_link("Navigate to /page-1", href="app1"),
            html_br(),
            dcc_link("Navigate to /page-2", href="app2")
        end
    else
        "404"
    end
end



run_server(app, "0.0.0.0", debug=true)
