function init_loreco_model_sumsy(;
                        guaranteed_income::Real = 2000,
                        dem_free::Real = 25000,
                        dem::Real = 0.1,
                        interval::Integer = 30,
                        seed::Real = 5000,
                        consumers::Integer = 380,
                        bakers::Integer = 15,
                        tv_merchants::Integer = 5)
    # Create a standard Econo model.
    model = create_econo_model()

    sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, dem, interval, seed = seed)
    # Add a sumsy property to the model to be used during simulation.
    model.properties[:sumsy] = sumsy

    # Add actors.
    add_consumers(model, consumers)
    add_bakers(model, bakers)
    add_tv_merchants(model, tv_merchants)
    add_governance(model, consumers + bakers + tv_merchants)

    return model
end

function init_loreco_model_sumsy_tiers(;
                        guaranteed_income::Real = 2000,
                        dem_free::Real = 25000,
                        tiersvec::Vector{Tuple{Int64, Float64}} = 0.1,
                        interval::Integer = 30,
                        seed::Real = 5000,
                        consumers::Integer = 380,
                        bakers::Integer = 15,
                        tv_merchants::Integer = 5)
    # Create a standard Econo model.
    model = create_econo_model()
    sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, tiersvec, interval, seed = seed)
    #sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, [(0, dem)], interval, seed = seed)
    # Add a sumsy property to the model to be used during simulation.
    model.properties[:sumsy] = sumsy

    # Add actors.
    add_consumers(model, consumers)
    add_bakers(model, bakers)
    add_tv_merchants(model, tv_merchants)
    add_governance(model, consumers + bakers + tv_merchants)

    return model
end

function init_loreco_model_sumsy_tiers_consumersngi(;
                        guaranteed_income::Real = 2000,
                        dem_free::Real = 25000,
                        tiersvec::Vector{Tuple{Int64, Float64}} = 0.1,
                        interval::Integer = 30,
                        seed::Real = 5000,
                        consumers::Integer = 380,
                        consumersngi::Integer = 380,
                        bakers::Integer = 15,
                        tv_merchants::Integer = 5)
    # Create a standard Econo model.
    model = create_econo_model()
    sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, tiersvec, interval, seed = seed)
    #sumsy::SuMSy = SuMSy(guaranteed_income, dem_free, [(0, dem)], interval, seed = seed)
    # Add a sumsy property to the model to be used during simulation.
    model.properties[:sumsy] = sumsy

    # Add actors.
    add_consumers(model, consumers)
    add_consumers_ngi(model, consumersngi)
    add_bakers(model, bakers)
    add_tv_merchants(model, tv_merchants)
    add_governance(model, consumers + consumersngi + bakers + tv_merchants)

    return model
end

balance(a::Actor) = sumsy_balance(a.balance)
##alternative use  has_type(actor::Actor, type::Symbol) in actor.jl
consumer(a::Actor)::Bool = in(:consumer, getproperty(a, :types)) ? true : false
consumerngi(a::Actor)::Bool = in(:consumerngi, getproperty(a, :types)) ? true : false
#=function consumerngi(a::Actor)::Bool
    println(getproperty(a, :types))
    if in(:consumerngi, getproperty(a, :types))
        println("yes")
    end
    in(:consumerngi, getproperty(a, :types)) ? true : false
end=#
baker(a::Actor)::Bool = in(:baker, getproperty(a, :types)) ? true : false
tvmerchant(a::Actor)::Bool = in(:tv_merchant, getproperty(a, :types)) ? true : false
governance(a::Actor)::Bool = in(:governance, getproperty(a, :types)) ? true : false


function miss5thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.05) end
function miss95thPercentile(values) return isempty(skipmissing(values)) ? NaN : quantile(skipmissing(values), 0.95) end

function isDemurTransaction(comment::String, time::Integer)::Bool
    #println(step)
    if startswith(comment, "Demurrage") #& isequal(time, step)
    #    print(time)
        return true
    else return false
    end
end

function sumsy_demurrage(balance)::Float64
    demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; isDemurTransaction(comment, time) end,
              collect(balance.transactions))
    return isempty(demurrages) ? 0 : sum(-y[4] for y in demurrages)
end

function demurrage(a::Actor)
    sumsy_demurrage(a.balance)
end



function demurrageviamodel(model)::Float64
    sumdemurrage::Float64 = 0
    for x in allagents(model)
        demurrages = filter(tuple-> let (time, type, entry, amount, comment)=tuple; isCurrentDemurTransaction(comment, time, model.step) end,
                      collect(x.balance.transactions))
        isempty(demurrages) ? sumdemurrage = sumdemurrage + 0 : sumdemurrage = sumdemurrage + sum(-y[4] for y in demurrages)
    end
    return sumdemurrage
end
