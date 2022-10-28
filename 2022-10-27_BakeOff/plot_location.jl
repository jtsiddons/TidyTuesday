using CSV
using CairoMakie
using DataFrames
using Downloads: download
using GeoMakie
using GeoMakie.GeoJSON

df = CSV.File("./data/bakers.csv", stringtype=String) |> DataFrame;

# countries_www = "http://geoportal1-ons.opendata.arcgis.com/datasets/6638c31a8e9842f98a037748f72258ed_3.geojson"
# countries = download(countries_www)
# countries = GeoJSON.read(read(countries, String))

begin
    F = Figure(resolution=(700, 540))
    A = Axis(F[1:20, 1:20])

    loc_df = combine(
        groupby(df, [:lon, :lat]),
        nrow => "n_contestants"
    )

    poly!(A, countries, color=:gray80)
    # datalims!(A)
    # hidedecorations!(A)

    shape = Point2f[
        (-0.8, 51),
        (-0.8, 52),
        (0.3, 52),
        (0.3, 51)
    ]

    poly!(A, shape, strokecolor=:gray30, color=(:white, 0), strokewidth=1)

    h = scatter!(A, loc_df.lon, loc_df.lat, color=loc_df.n_contestants, colormap=:plasma, markersize=10 .+ 2 .* loc_df.n_contestants)
    london_df = filter([:lon, :lat] => (x, y) -> -0.8 <= x <= 0.3 && 51 <= y <= 52, loc_df)
    miniA = Axis(F[5:9, 15:19])
    miniA.backgroundcolor = :gray80
    scatter!(miniA, london_df.lon, london_df.lat, color=london_df.n_contestants, colormap=:plasma, markersize=10 .+ 2 .* london_df.n_contestants)

    Colorbar(F[1:20, 21], h)
    lines!(A, [-0.8, -0.47], [52, 56.55], linestyle=:dash, color=:black, linewidth=0.5)
    lines!(A, [0.3, 1.76], [52, 56.55], linestyle=:dash, color=:black, linewidth=0.5)

    lat_func = x -> string(abs(x)) * "°" * (x >= 0 ? "N" : "S")
    lon_func = x -> string(abs(x)) * "°" * (x >= 0 ? "E" : "W")
    xticks = collect(-7.5:2.5:0.0)
    yticks = collect(50:2:60)
    A.xticks = (xticks, lon_func.(xticks))
    A.yticks = (yticks, lat_func.(yticks))

    minixticks = [-0.6, 0.0]
    miniyticks = collect(51.2:0.2:52.0)
    miniA.xticks = (minixticks, lon_func.(minixticks))
    miniA.yticks = (miniyticks, lat_func.(miniyticks))
    F
end

save("./figs/baker_map.png", F, px_per_unit=2.0)