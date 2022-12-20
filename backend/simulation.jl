using EconoSim
using Agents
using JSON
using DataFrames

TYPE = "type"
NUMBER = "number"
CURRENCY_DEMAND = "currency_demand"
CURRENCY_AMOUNT = "currency_amount"
SUMSY_OVERRIDES = "sumsy_overrides"
PRICES = "prices"
NEEDS = "needs"

OWN_WAGE = "own_wage"
EMPLOYEES = "employees"
WAGE = "wage"
MAX_CUSTOMERS = "max_customers"
MAX_NON_PROFIT = "max_non_profit"
MAX_VOLUNTEERS = "max_volunteers"
LINKED_TO = "linked_to"
NON_PROFIT_DONATION = "non_profit_donation"
VOLUNTEER_NEED = "volunteer_need"
PAYOUT = "payout"

INCOME = "income"
DEM_FREE = "dem_free"
DEMURRAGE = "demurrage"

CONFIGURATION = :configuration

COMMERCIAL = "commercial"
NON_PROFIT = "non_profit"
INSTITUTION = "institution"
PRIVATE = "private"
ACTOR_CATEGORIES = [COMMERCIAL, NON_PROFIT, INSTITUTION, PRIVATE]

CATEGORY_DICT = Dict{String, Set{Symbol}}([COMMERCIAL => Set{Symbol}(),
                                        NON_PROFIT => Set{Symbol}(),
                                        INSTITUTION => Set{Symbol}(),
                                        PRIVATE => Set{Symbol}()])

DONORS = :donors
VOLUNTEERING = :volunteering

function log_transaction_statistics(model, actor::Actor)
    if process_ready(model.sumsy, model.step)
        actor.transactions_in = actor.balance.transactions_in
        actor.transaction_volume_in = actor.balance.transaction_volume_in
        actor.transactions_out = actor.balance.transactions_out
        actor.transaction_volume_out = actor.balance.transaction_volume_out

        actor.balance.transactions_in = 0
        actor.balance.transaction_volume_in = Currency(0)
        actor.balance.transactions_out = 0
        actor.balance.transaction_volume_out = Currency(0)
    end
end

function init_transaction_statistics_trigger(balance::Balance)
    balance.transactions_in = 0
    balance.transaction_volume_in = Currency(0)
    balance.transactions_out = 0
    balance.transaction_volume_out = Currency(0)

    return transaction_statistics_trigger
end

function transaction_statistics_trigger(balance::Balance,
                                        entry::BalanceEntry,
                                        type::EntryType,
                                        amount::Real,
                                        timestamp::Integer,
                                        comment::String,
                                        value::Currency,
                                        transaction::Union{Transaction, Nothing})
    if comment != "Net income"
        if amount > 0
            balance.transactions_in += 1
            balance.transaction_volume_in += Currency(amount)
        elseif amount < 0
            balance.transactions_out += 1
            balance.transaction_volume_out -= Currency(amount)
        end
    end
end

function acquire_currency(model, actor::Actor)
    demands = process(actor.currency_demand)

    if demands > 0
        transfer_asset!(model.currency_balance, actor.balance, SUMSY_DEP, demands * actor.currency_amount, model.step)
    end
end

function create_actors!(model,
                        actor_dict::Dict{Symbol, Vector{Actor}},
                        type::Symbol,
                        overrides::SuMSyOverrides,
                        currency_demand::Marginality,
                        currency_amount::Real,
                        needs::Needs,
                        prices::Prices,
                        number::Integer;
                        additional_behaviors::Vector{<:Function} = Vector{Function}())
    new_actors = Vector{Actor}()

    for counter = 1:number
        stock = InfiniteStock(keys(prices))
        actor =  make_marginal(Actor(types = type, stock = stock), needs = needs, select_supplier = select_supplier)
        set_sumsy_overrides!(actor.balance, overrides)
        add_triggers!(actor.balance, init_transaction_statistics_trigger)

        actor.currency_demand = currency_demand
        actor.currency_amount = currency_amount

        actor.transactions_in = 0
        actor.transaction_volume_in = Currency(0)
        actor.transactions_out = 0
        actor.transaction_volume_out = Currency(0)

        for behavior in additional_behaviors
            add_behavior!(actor, behavior)
        end

        add_behavior!(actor, acquire_currency)
        add_behavior!(actor, log_transaction_statistics)
        add_agent!(actor, model)
        push!(new_actors, actor)
    end

    actors = get!(Vector{Actor}, actor_dict, type)
    union!(actors, new_actors)

    return new_actors
end

function update_offers_demands!(actor,
                                offer_dict::Dict{<:Blueprint, Vector{Actor}},
                                demand_dict::Dict{<:Blueprint, Vector{Actor}})    
    if hasproperty(actor, :prices)    
        for blueprint in keys(actor.prices)
            push!(get!(offer_dict, blueprint, Vector{Actor}()), actor)
        end
    end

    for blueprint in get_wants(actor.needs)
        push!(get!(demand_dict, blueprint, Vector{Actor}()), actor)
    end
end

function donate(model, merchant::Actor)
    if process_ready(model.sumsy, model.step)
        non_profits = Vector{Actor}(merchant.non_profit)

        # Donate to non_profit in random order
        while !isempty(non_profits)
            index = rand(1:length(non_profits))
            non_profit = non_profits[index]
            transfer_sumsy!(merchant.balance, non_profit.balance, model.sumsy, merchant.non_profit_donation, model.step)
            deleteat!(non_profits, index)
        end
    end
end

function pay_wages(model, merchant::Actor)
    if process_ready(model.sumsy, model.step)
        if !isnothing(merchant.linked_actor)
            transfer_sumsy!(merchant.balance, merchant.linked_actor.balance, model.sumsy, merchant.own_wage, model.step)
        end

        employees = Vector{Actor}(merchant.employees)

        # Pay wages to employees
        while !isempty(employees)
            index = rand(1:length(employees))
            employee = employees[index]
            transfer_sumsy!(merchant.balance, employee.balance, model.sumsy, merchant.wage, model.step)
            deleteat!(employees, index)
        end
    end
end

function create_commercial!(model,
                            type::Symbol,
                            actor_dict::Dict{Symbol, Vector{Actor}},
                            offer_dict::Dict{<:Blueprint, Vector{Actor}},
                            demand_dict::Dict{<:Blueprint, Vector{Actor}},
                            linked_to::Vector{Any},
                            currency_demand::Marginality,
                            currency_amount::Real,
                            needs::Needs,
                            overrides::SuMSyOverrides,
                            prices::Prices,
                            own_wage::Currency,
                            employees::Integer,
                            wage::Currency,
                            max_customers::Integer,
                            max_non_profit::Integer,
                            non_profit_donation::Currency,
                            number::Integer = 1)
    merchants = create_actors!(model, actor_dict, type, overrides, currency_demand, currency_amount, needs, prices, number, additional_behaviors = [donate, pay_wages])

    for i in 1:length(linked_to)
        linked_to[i] = Symbol(linked_to[i])
    end

    for merchant in merchants
        merchant.linked_actor = linked_to
        merchant.prices = prices
        merchant.max_customers = max_customers
        merchant.num_customers = 0
        merchant.own_wage = own_wage
        merchant.employees = employees
        merchant.wage = wage
        merchant.non_profit = Vector{Actor}()
        merchant.max_non_profit = max_non_profit
        merchant.non_profit_donation = non_profit_donation
        merchant.merchants = Dict{Blueprint, Vector{Actor}}()
        update_offers_demands!(merchant, offer_dict, demand_dict)
    end

    return actor_dict
end

function pay_volunteers(model, non_profit::Actor)
    if process_ready(model.sumsy, model.step)
        volunteers = Vector{Actor}(non_profit.volunteers)

        # Pay to volunteers in random order
        while !(isempty(volunteers))
            index = rand(1:length(volunteers))

            if rand() <= non_profit.volunteer_need
                volunteer = volunteers[index]
                transfer_sumsy!(non_profit.balance, volunteer.balance, model.sumsy, non_profit.payout, model.step)
            end

            deleteat!(volunteers, index)
        end
    end
end

function create_non_profit!(model,
                            type::Symbol,
                            actor_dict::Dict{Symbol, Vector{Actor}},
                            offer_dict::Dict{<:Blueprint, Vector{Actor}},
                            demand_dict::Dict{<:Blueprint, Vector{Actor}},
                            currency_demand::Marginality,
                            currency_amount::Real,
                            needs::Needs,
                            overrides::SuMSyOverrides,
                            max_volunteers::Integer,
                            volunteer_need::Real,
                            payout::Currency,
                            max_customers::Integer,
                            prices::Prices,
                            number::Integer)
    non_profit = create_actors!(model, actor_dict, type, overrides, currency_demand, currency_amount, needs, prices, number, additional_behaviors = [pay_volunteers])

    for non_profit in non_profit
        non_profit.volunteers = Vector{Actor}()
        non_profit.max_volunteers = max_volunteers
        non_profit.volunteer_need = Percentage(volunteer_need)
        non_profit.payout = payout
        non_profit.prices = prices
        non_profit.max_customers = max_customers == 0 ? INF : max_customers
        non_profit.num_customers = 0
        non_profit.donors = 0
        non_profit.merchants = Dict{Blueprint, Vector{Actor}}()
        update_offers_demands!(non_profit, offer_dict, demand_dict)
    end

    return actor_dict
end

function create_institution!(model,
                            type::Symbol,
                            actor_dict::Dict{Symbol, Vector{Actor}},
                            offer_dict::Dict{<:Blueprint, Vector{Actor}},
                            demand_dict::Dict{<:Blueprint, Vector{Actor}},
                            currency_demand::Marginality,
                            currency_amount::Real,
                            needs::Needs,
                            overrides::SuMSyOverrides,
                            prices::Prices,
                            max_customers::Integer,
                            number::Integer = 1)
    governances = create_actors!(model, actor_dict, type, overrides, currency_demand, currency_amount, needs, prices, number)

    for governance in governances
        governance.prices = prices
        governance.max_customers = max_customers == 0 ? INF : max_customers
        governance.num_customers = 0
        governance.merchants = Dict{Blueprint, Vector{Actor}}()
        update_offers_demands!(governance, offer_dict, demand_dict)
    end

    return actor_dict
end

function create_private!(model,
                            type::Symbol,
                            actor_dict::Dict{Symbol, Vector{Actor}},
                            offer_dict::Dict{<:Blueprint, Vector{Actor}},
                            demand_dict::Dict{<:Blueprint, Vector{Actor}},
                            currency_demand::Marginality,
                            currency_amount::Real,
                            needs::Needs,
                            overrides::SuMSyOverrides,
                            prices::Prices,
                            number::Integer = 1)
    civilians = create_actors!(model, actor_dict, type, overrides, currency_demand, currency_amount, needs, prices, number)

    for civilian in civilians
        civilian.merchants = Dict{Blueprint, Vector{Actor}}()
        update_offers_demands!(civilian, offer_dict, demand_dict)
        civilian.prices = prices
        civilian.volunteering = 0
    end

    return actor_dict
end

function create_prices!(price_dict, blueprints::Dict{String, Blueprint})
    prices = Dict{Blueprint, Price}()

    for product in keys(price_dict)
        blueprint = get!(blueprints, product, ConsumableBlueprint(product))
        prices[blueprint] = Price(SUMSY_DEP, price_dict[product])
    end

    return prices
end

function create_marginality(input)
    marginality = Marginality()

    for pair in input
        push!(marginality, (pair[1], pair[2]))
    end

    return marginality
end

function create_needs(needs_dict, blueprints)
    needs = Needs()

    for product in keys(needs_dict)
        if haskey(blueprints, product)
            want_marginality = Marginality()
            use_marginality = Marginality()

            for pair in needs_dict[product]
                push!(want_marginality, (pair[1], pair[2]))
                push!(use_marginality, (pair[1], 1)) # Always use everything
            end

            push!(needs, want, blueprints[product], want_marginality)
            push!(needs, usage, blueprints[product], use_marginality)
        end
    end

    return needs
end

function select_supplier(model, customer::Actor, blueprint::Blueprint)

    if hasproperty(customer, :merchants) & haskey(customer.merchants, blueprint)
        suppliers = customer.merchants[blueprint]

        return suppliers[rand(1:length(suppliers))]
    else
        return select_random_supplier(model, customer, blueprint)
    end
end

function create_overrides(sumsy::SuMSy, params)
    income = params[INCOME]
    dem_free = params[DEM_FREE]
    demurrage = params[DEMURRAGE]

    if typeof(demurrage) == Vector{Any}
        dem_tiers = Vector{Tuple{Real, Real}}()

        for pair in demurrage
            push!(dem_tiers, (pair[1], pair[2]/100))
        end
    else
        dem_tiers = demurrage/100
    end

    return sumsy_overrides(sumsy, guaranteed_income = income, dem_free = dem_free, dem_tiers = dem_tiers)
end

function collect_category(actor_dict::Dict{Symbol, Vector{Actor}}, category::String)
    actors = Set{Actor}()

    for type in CATEGORY_DICT[category]
        if haskey(actor_dict, type)
            union!(actors, actor_dict[type])
        end
    end

    return collect(actors)
end

function link_customers!(actor_dict::Dict{Symbol, Vector{Actor}}, offers::Dict{<:Blueprint, Vector{Actor}})
    for actors in values(actor_dict)
        for actor in actors
            wants = get_wants(actor.needs)

            while !isempty(wants)
                want = wants[1]
                deleteat!(wants, 1)

                if haskey(offers, want)
                    merchants = offers[want]

                    if length(merchants) > 0
                        m_index = rand(1:length(merchants))
                        merchant = merchants[m_index]
                        merchant.num_customers += 1

                        if merchant.num_customers == merchant.max_customers
                            deleteat!(merchants, m_index)
                        end

                        want_suppliers = get!(actor.merchants, want, Vector{Actor}())

                        if !(merchant in want_suppliers)
                            push!(want_suppliers, merchant)
                        end

                        # Choose the same merchant if they offer other products the consumer wants.
                        for offer in keys(merchant.prices)
                            index = findfirst(bp -> bp == offer, wants)

                            if !isnothing(index)
                                want_suppliers = get!(actor.merchants, offer, Vector{Actor}())

                                if !(merchant in want_suppliers)
                                    push!(want_suppliers, merchant)
                                end

                                deleteat!(wants, index)
                            end
                        end
                    end
                end
            end
        end
    end
end

function link_employees!(actor_dict::Dict{Symbol, Vector{Actor}})
    available = collect_category(actor_dict, PRIVATE)
    employers = collect_category(actor_dict, COMMERCIAL)

    # delete employers from available
    for employer in employers
        filter!(e -> e != employer.linked_to, available)
    end

    for employer in employers
        num_employees = employer.employees
        employer.employees = Vector{Actor}()

        while !isempty(available) && length(employer.employees) < num_employees
            index = rand(1:length(available))
            push!(employer.employees, available[index])
            deleteat!(available, index)
        end
    end
end

function link_actors(source, destination, link_indicator::Symbol, target::Integer)
    source = Vector{Actor}(source)

    while !isempty(source) && length(destination) < target
        link_index = rand(1:length(source))
        link = source[link_index]
        setproperty!(link, link_indicator, getproperty(link, link_indicator) + 1)
        deleteat!(source, link_index)
        push!(destination, link)
    end
end

function link_actors(actor_dict::Dict{Symbol, Vector{Actor}}, offers, demands)
    selected_linked = Set{Actor}()
    
    # Link a commercial actor with their non commercial actor
    for commercial in collect_category(actor_dict, COMMERCIAL)
        linked_group = Set{Actor}()

        # Create the collection of all elegible actors
        for linked_type in commercial.linked_actor
            union!(linked_group, actor_dict[linked_type])
        end

        # Remove actors already linked. Change this code if 1 non commercial actor can be linked to more than one commercial actor.
        setdiff!(linked_group, selected_linked)
        if !isempty(linked_group)
            commercial.linked_actor = collect(linked_group)[rand(1:length(linked_group))]
            push!(selected_linked, commercial.linked_actor)
        else
            commercial.linked_actor = nothing
        end

        # Link non profits to the commercial actor
        link_actors(collect_category(actor_dict, NON_PROFIT), commercial.non_profit, DONORS, commercial.max_non_profit)
    end

    link_customers!(actor_dict, offers)
    link_employees!(actor_dict)

    for non_profit in collect_category(actor_dict, NON_PROFIT)
        link_actors(collect_category(actor_dict, PRIVATE), non_profit.volunteers, VOLUNTEERING, non_profit.max_volunteers)
    end

    return actor_dict
end

function klaver_balance(actor::Actor)
    return asset_value(actor.balance, SUMSY_DEP)
end

function actor_type(actor::Actor)
    return first(setdiff(actor.types, [:marginal]))
end

function extra_income(actor::Actor)
    if !isempty(intersect(actor.types, CATEGORY_DICT[PRIVATE]))
        return actor.volunteering
    elseif !isempty(intersect(actor.types, CATEGORY_DICT[NON_PROFIT]))
        return actor.donors
    else
        return 0
    end
end

function extra_expense(actor::Actor)
    if !isempty(intersect(actor.types, CATEGORY_DICT[COMMERCIAL]))
        return length(actor.non_profit) + length(actor.employees)
    elseif !isempty(intersect(actor.types, CATEGORY_DICT[NON_PROFIT]))
        return length(actor.volunteers)
    else
        return 0
    end
end

function load_configuration(model, file_path::String)
    model.properties[:currency_balance] = Balance()
    typemin_asset!(model.currency_balance, SUMSY_DEP)
    sumsy = model.sumsy
    actors = Dict{Symbol, Vector{Actor}}()
    offers = Dict{Blueprint, Vector{Actor}}()
    demands = Dict{Blueprint, Vector{Actor}}()

    file = open(file_path)

    blueprints = Dict{String, Blueprint}()

    for settings in JSON.parse(file)
        type = Symbol(settings[TYPE])

        if type == CONFIGURATION
            for actor_category in ACTOR_CATEGORIES
                if haskey(settings, actor_category)
                    for actor_type in settings[actor_category]
                        push!(CATEGORY_DICT[actor_category], Symbol(actor_type))
                    end
                end
            end
        else
            number = haskey(settings, NUMBER) ? settings[NUMBER] : 1
            currency_demand = haskey(settings, CURRENCY_DEMAND) ? create_marginality(settings[CURRENCY_DEMAND]) : Marginality([(0, 0)])
            currency_amount = haskey(settings, CURRENCY_AMOUNT) ? settings[CURRENCY_AMOUNT] : 0
            overrides = haskey(settings, SUMSY_OVERRIDES) ? create_overrides(sumsy, settings[SUMSY_OVERRIDES]) : sumsy_overrides(sumsy)

            prices = haskey(settings, PRICES) ? create_prices!(settings[PRICES], blueprints) : Dict{Blueprint, Price}()
            needs = haskey(settings, NEEDS) ? create_needs(settings[NEEDS], blueprints) : Needs()

            if type in CATEGORY_DICT[COMMERCIAL]
                max_customers = haskey(settings, MAX_CUSTOMERS) ? settings[MAX_CUSTOMERS] : INF
                own_wage = haskey(settings, OWN_WAGE) ? Currency(settings[OWN_WAGE]) : Currency(0)
                employees = haskey(settings, EMPLOYEES) ? settings[EMPLOYEES] : 0
                wage = haskey(settings, WAGE) ? Currency(settings[WAGE]) : Currency(0)
                non_profit_donation = haskey(settings, NON_PROFIT_DONATION) ? Currency(settings[NON_PROFIT_DONATION]) : Currency(0)
                max_non_profit = haskey(settings, MAX_NON_PROFIT) && non_profit_donation > 0 ? settings[MAX_NON_PROFIT] : 0

                linked_to = haskey(settings, LINKED_TO) ? settings[LINKED_TO] : []
                create_commercial!(model,
                                type,
                                actors,
                                offers,
                                demands,
                                linked_to,
                                currency_demand,
                                currency_amount,
                                needs,
                                overrides,
                                prices,
                                own_wage,
                                employees,
                                wage,
                                max_customers,
                                max_non_profit,
                                non_profit_donation,
                                number)
            elseif type in CATEGORY_DICT[NON_PROFIT]
                max_customers = haskey(settings, MAX_CUSTOMERS) ? settings[MAX_CUSTOMERS] : INF
                max_volunteers = haskey(settings, MAX_VOLUNTEERS) ? settings[MAX_VOLUNTEERS] : INF
                volunteer_need = haskey(settings, VOLUNTEER_NEED) ? settings[VOLUNTEER_NEED] : 0
                payout = haskey(settings, PAYOUT) ? Currency(settings[PAYOUT]) : Currency(0)
                create_non_profit!(model,
                                    type,
                                    actors,
                                    offers,
                                    demands,
                                    currency_demand,
                                    currency_amount,
                                    needs,
                                    overrides,
                                    max_volunteers,
                                    volunteer_need,
                                    payout,
                                    max_customers,
                                    prices,
                                    number)
            elseif type in CATEGORY_DICT[INSTITUTION]
                max_customers = haskey(settings, MAX_CUSTOMERS) ? settings[MAX_CUSTOMERS] : INF
                create_institution!(model,
                                    type,
                                    actors,
                                    offers,
                                    demands,
                                    currency_demand,
                                    currency_amount,
                                    needs,
                                    overrides,
                                    prices,
                                    max_customers,
                                    number
                                    )
            elseif type in CATEGORY_DICT[PRIVATE]
                create_private!(model,
                                type,
                                actors,
                                offers,
                                demands,
                                currency_demand,
                                currency_amount,
                                needs,
                                overrides,
                                prices,
                                number)
            end
        end
    end

    return actors, offers, demands
end

function run_simulation(sumsy::SuMSy, file_path::String, sim_length::Integer)
    model = create_sumsy_model(sumsy)
    actors, offers, demands = load_configuration(model, file_path)
    link_actors(actors, offers, demands)    

    data, _ = run_econo_model!(model, sim_length,
                    adata = [klaver_balance,
                                extra_income,
                                extra_expense,
                                actor_type,
                                :transactions_in,
                                :transaction_volume_in,
                                :transactions_out,
                                :transaction_volume_out])

    return data
end

function analyse_money_stock(data)
    groups = groupby(data, :step)

    # Create data frame
    analysis = DataFrame(cycle = Int64[],
                        money_stock = Fixed(4)[])

    for group in groups
        rows = eachrow(group)
        money_stock = 0

        for row in eachrow(group)
            if :governance != row[:actor_type]
                money_stock += row[:klaver_balance]
            end
        end

        push!(analysis, [[rows[1][:step]] [money_stock]])
    end

    return analysis
end

function analyse_wealth(data)
    wealth_distribution = Dict{Symbol, NamedTuple}()
    groups = groupby(data, :step)

    for group in groups
        type_groups = groupby(group, :actor_type)

        for type_group in type_groups
            type = type_group[!, :actor_type][1]

            wealth = get!(wealth_distribution, type,
                        (poorest = Vector{Currency}(),
                            average = Vector{Currency}(),
                            richest = Vector{Currency}()))

            poorest = Currency(INF)
            average = sum(type_group[!, :klaver_balance]) / length(eachrow(type_group))
            richest = Currency(0)

            for row in eachrow(type_group)
                poorest = min(row[:klaver_balance], poorest)
                richest = max(row[:klaver_balance], richest)
            end

            push!(wealth.poorest, poorest)
            push!(wealth.average, average)
            push!(wealth.richest, richest)
        end
    end

    return wealth_distribution
end

function analyse_wealth_distribution(data)
    groups = groupby(data, :step)
    num_actors = size(collect(groups)[1])[1]
    bottom_10 = 1:max(1, Int(round(num_actors/10)))
    low_40 = length(bottom_10) + 1:Int(round(num_actors / 2))
    high_40 = length(bottom_10) + length(low_40) + 1:num_actors - length(bottom_10)
    top_10 = length(bottom_10) + length(low_40) + length(high_40) + 1:num_actors

    percentile_symbols = [:bottom_10, :low_40, :high_40, :top_10]
    percentiles = [bottom_10, low_40, high_40, top_10]

    wealth_distribution = Dict{Symbol, Vector{Real}}(:bottom_10 => Vector{Real}(),
                                                :low_40 => Vector{Real}(),
                                                :high_40 => Vector{Real}(),
                                                :top_10 => Vector{Real}())
    type_distribution = Dict{Symbol, Dict{Symbol, Vector{Real}}}(:bottom_10 => Dict{Symbol, Vector{Real}}(),
                                                                :low_40 => Dict{Symbol, Vector{Real}}(),
                                                                :high_40 => Dict{Symbol, Vector{Real}}(),
                                                                :top_10 => Dict{Symbol, Vector{Real}}())
    
    for types in values(CATEGORY_DICT)
        for type in types
            for percentile_symbol in percentile_symbols
                type_distribution[percentile_symbol][type] = Vector{Real}()
            end
        end
    end    

    for group in groups
        total_wealth = sum(group[!, :klaver_balance])

        if total_wealth > 0
            rows = eachrow(sort(group, :klaver_balance))
            index = 1

            for tier in percentiles
                wealth = Currency(0)
                tier_actors = 0
                type_counter = Dict{Symbol, Integer}()

                for i in tier
                    wealth += rows[i][:klaver_balance]
                    actor_type = Symbol(rows[i][:actor_type])
                    type_counter[actor_type] = get!(type_counter, actor_type, 0) + 1
                    tier_actors += 1
                end

                percentile_symbol = percentile_symbols[index]
                push!(wealth_distribution[percentile_symbol], 100 * wealth / total_wealth)

                for type in keys(type_distribution[percentile_symbol])
                    push!(type_distribution[percentile_symbol][type], get(type_counter, type, 0) * 100 / tier_actors)
                end

                index += 1
            end
        end
    end 

    return wealth_distribution, type_distribution
end

function analyse_transaction_data(data)
    transaction_analysis = Dict{Symbol, NamedTuple}()
    groups = groupby(data, :step)

    for group in groups
        type_groups = groupby(group, :actor_type)

        for type_group in type_groups
            type = type_group[!, :actor_type][1]

            transactions = get!(transaction_analysis, type,
                        (min_transactions_in = Vector{Integer}(),
                            average_transactions_in = Vector{Real}(),
                            max_transactions_in = Vector{Integer}(),
                            min_transaction_volume_in = Vector{Currency}(),
                            average_transaction_volume_in = Vector{Currency}(),
                            max_transaction_volume_in = Vector{Currency}(),
                            min_transactions_out = Vector{Integer}(),
                            average_transactions_out = Vector{Real}(),
                            max_transactions_out = Vector{Integer}(),
                            min_transaction_volume_out = Vector{Currency}(),
                            average_transaction_volume_out = Vector{Currency}(),
                            max_transaction_volume_out = Vector{Currency}()))

            num_actors = length(eachrow(type_group))

            min_transactions_in = INF
            average_transactions_in = sum(type_group[!, :transactions_in]) / num_actors
            max_transactions_in = 0
            min_transaction_volume_in = Currency(INF)
            average_transaction_volume_in = sum(type_group[!, :transaction_volume_in]) / num_actors
            max_transaction_volume_in = Currency(0)

            min_transactions_out = INF
            average_transactions_out = sum(type_group[!, :transactions_in]) / num_actors
            max_transactions_out = 0
            min_transaction_volume_out = Currency(INF)
            average_transaction_volume_out = sum(type_group[!, :transaction_volume_in]) / num_actors
            max_transaction_volume_out = Currency(0)

            for row in eachrow(type_group)
                min_transactions_in = min(row[:transactions_in], min_transactions_in)
                max_transactions_in = max(row[:transactions_in], max_transactions_in)
                min_transaction_volume_in = min(row[:transaction_volume_in], min_transaction_volume_in)
                max_transaction_volume_in = max(row[:transaction_volume_in], max_transaction_volume_in)

                min_transactions_out = min(row[:transactions_in], min_transactions_out)
                max_transactions_out = max(row[:transactions_in], max_transactions_out)
                min_transaction_volume_out = min(row[:transaction_volume_out], min_transaction_volume_out)
                max_transaction_volume_out = max(row[:transaction_volume_out], max_transaction_volume_out)
            end

            push!(transactions.min_transactions_in, min_transactions_in)
            push!(transactions.average_transactions_in, round(average_transactions_in, digits = 2))
            push!(transactions.max_transactions_in, max_transactions_in)

            push!(transactions.min_transaction_volume_in, min_transaction_volume_in)
            push!(transactions.average_transaction_volume_in, average_transaction_volume_in)
            push!(transactions.max_transaction_volume_in, max_transaction_volume_in)

            push!(transactions.min_transactions_out, min_transactions_out)
            push!(transactions.average_transactions_out, round(average_transactions_out, digits = 2))
            push!(transactions.max_transactions_out, max_transactions_out)

            push!(transactions.min_transaction_volume_out, min_transaction_volume_out)
            push!(transactions.average_transaction_volume_out, average_transaction_volume_out)
            push!(transactions.max_transaction_volume_out, max_transaction_volume_out)
        end
    end

    return transaction_analysis
end

function run_sim()
    BASIC_SUMSY = SuMSy(2000, 0, 0.01, 30)
    run_simulation(BASIC_SUMSY, "../lorecosimdash.jl/sim_configurations/abm_test_config.json", 100)
end

function run_conservative()
    BASIC_SUMSY = SuMSy(2000, 0, 0.01, 30)
    run_simulation(BASIC_SUMSY, "../lorecosimdash.jl/sim_configurations/loreco_conservative.json", 100)
end

function run_basic_associations()
    BASIC_SUMSY = SuMSy(2000, 0, 0.01, 30)
    run_simulation(BASIC_SUMSY, "../lorecosimdash.jl/sim_configurations/loreco_basic_associations.json", 500)
end

function run_loreco()
    BASIC_SUMSY = SuMSy(2000, 0, 0.01, 1)
    
    model = create_sumsy_model(BASIC_SUMSY)
    actors, offers, demands = load_configuration(model, "../lorecosimdash.jl/sim_configurations/loreco_baseline_plus_vereniging.json")
    link_actors(actors, offers, demands)    

    data, _ = run_econo_model!(model, 1000,
                    adata = [klaver_balance,
                                extra_income,
                                extra_expense,
                                actor_type,
                                :transactions_in,
                                :transaction_volume_in,
                                :transactions_out,
                                :transaction_volume_out])

    return data, model.currency_balance
end

# analyse_wealth(run())

# analyse_transaction_data(run_loreco()) 

# analyse_wealth_distribution(run_sim())

# run_basic_associations()

# run_loreco()

# run_sim()