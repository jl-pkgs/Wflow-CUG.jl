# unpack the paths to the netCDF files
static_path = input_path(config, config.input.path_static)
dataset = NCDataset(static_path)

reader = prepare_reader(config)
clock = Clock(config, reader)

modelsettings = (;
    snow=get(config.model, "snow__flag", false)::Bool,
    gravitational_snow_transport=get(
        config.model,
        "snow_gravitional_transport__flag",
        false,
    )::Bool,
    glacier=get(config.model, "glacier__flag", false)::Bool,
    lakes=get(config.model, "lake__flag", false)::Bool,
    reservoirs=get(config.model, "reservoir__flag", false)::Bool,
    pits=get(config.model, "pit__flag", false)::Bool,
    water_demand=haskey(config.model, "water_demand"),
    drains=get(config.model, "drain__flag", false)::Bool,
    kh_profile_type=get(
        config.model,
        "saturated_hydraulic_conductivity_profile",
        "exponential",
    )::String,
    min_streamorder_river=get(config.model, "river_streamorder__min_count", 6),
    min_streamorder_land=get(config.model, "land_streamorder__min_count", 5),
)

@info "General model settings" modelsettings[keys(modelsettings)[1:7]]...

routing_types = get_routing_types(config)
domain = Domain(dataset, config, modelsettings, routing_types)

land_hydrology = LandHydrologySBM(dataset, config, domain.land)
routing = Routing(dataset, config, domain, land_hydrology.soil, routing_types, type)

(; maxlayers) = land_hydrology.soil.parameters
modelmap = (land=land_hydrology, routing)
writer = prepare_writer(config, modelmap, domain, dataset;
    extra_dim=(name="layer", value=Float64.(1:(maxlayers))),
)
close(dataset)

model = Model(config, domain, routing, land_hydrology, clock, reader, writer, SbmModel())
set_states!(model)

@info "Initialized model"
# return model
