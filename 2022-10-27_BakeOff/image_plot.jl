begin
    using CairoMakie
    using Colors
    using CSV
    using DataFrames
    using FileIO
end

begin
    set_theme!(theme_light())

    ASPECT = 1.69
    FIG_WIDTH = 960

    # Bake off colours
    bakeoff_blue = colorant"#197b9f"
    bakeoff_pink = colorant"#c73d67"
    bakeoff_gray = colorant"#d3d2cb"

    expand_extrema = x -> (Int(floor(minimum(x)) - 5), Int(floor(maximum(x)) + 5))

    file = "./data/bakers.csv"
    df = CSV.File(file, stringtype=String) |> DataFrame
    winner_df = filter(:series_winner => ==(1), df)
end

## Shapes for scatter plot
square_with_hole = BezierPath([
    MoveTo(Point(1, 1)),
    LineTo(Point(1, -1)),
    LineTo(Point(-1, -1)),
    LineTo(Point(-1, 1)),
    LineTo(Point(1, 1)),
    MoveTo(Point(0.85, 0)),
    EllipticalArc(Point(0, 0), 0.85, 0.85, 0, 0, 2pi),
    ClosePath(),
])

circle_circle = BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 1.0, 1.0, 0, 0, 2π),
    MoveTo(Point(0.85, 0)),
    EllipticalArc(Point(0, 0), 0.85, 0.85, 0, 0, -2pi),
    ClosePath(),
])

## Plot of winner ages
begin
    F = Figure(resolution=(FIG_WIDTH, FIG_WIDTH / ASPECT))
    A = Axis(F[1, 1], aspect=ASPECT)
    xlims = (0, 11)
    ylims = expand_extrema(winner_df.age)
    A.limits = (xlims, ylims)

    # Get sive for images
    HALF_IMG_WIDTH = 0.4
    pix_width = xlims[2] - xlims[1]
    pix_height = ylims[2] - ylims[1]
    HALF_IMG_HEIGHT = HALF_IMG_WIDTH * (pix_height / pix_width) * ASPECT


    for row in eachrow(winner_df)
        local name = row.baker
        local series = row.series
        local age = row.age
        local filename = "./data/baker_img/" * name * "_" * string(series) * ".jpg"
        local img = load(filename)
        s = size(img)
        if s[2] > s[1]
            # Shrink width -trim ends
            x = (s[2] - s[1])
            m = x ÷ 2
            img = img[:, (1+m):(end-m-(x%2))]
        elseif s[1] > s[2]
            # Shrink height -trim ends
            x = (s[1] - s[2])
            m = x ÷ 2
            img = img[(1+m):(end-m-(x%2)), :]
        end

        image!(
            A,
            [series - HALF_IMG_WIDTH, series + HALF_IMG_WIDTH],
            [age - HALF_IMG_HEIGHT, age + HALF_IMG_HEIGHT],
            rotr90(img)
        )
    end

    A.title = "Bake-Off!"
    A.subtitle = "Age of series winners across series 1 to 10."
    A.xlabel = "Series"
    A.ylabel = "Age"
    A.xticks = (collect(1:10), string.(collect(1:10)))

    # Find pixel size for markersize
    A_width = A.scene.px_area.val.widths[1]
    half_img_width = ceil(HALF_IMG_WIDTH * A_width / pix_width)

    scatter!(A, winner_df.series, winner_df.age, marker=square_with_hole, markersize=half_img_width, color=:white)
    scatter!(A, winner_df.series, winner_df.age, marker=circle_circle, markersize=half_img_width, color=bakeoff_pink)

    F
end

# save("figs/baker_age.png", F, px_per_unit=2.0)

## Star Baker - The data is incorrect so create based on the episode data
begin
    episodes_df = CSV.File("./data/episodes.csv", stringtype=String) |> DataFrame

    star_baker = Vector{Int32}(undef, nrow(winner_df))
    for (i, row) in enumerate(eachrow(winner_df))
        local name = row.baker
        local series = row.series
        star_baker[i] = filter(
            [:series, :sb_name] => (x, y) -> x == series && occursin(name, y),
            episodes_df
        ) |> nrow
    end
    winner_df.star_baker = star_baker
    winner_df.star_baker_percent = 100 .* star_baker ./ winner_df.total_episodes_appeared

    highest_star_percent = maximum(winner_df.star_baker_percent)
    most_successful = findall(==(highest_star_percent), winner_df.star_baker_percent)

    global best_string = winner_df.baker[most_successful[1]]
    for i in 2:length(most_successful)
        global best_string *= " & " * winner_df.baker[most_successful[i]]
    end
end

## Star Baker Plot
begin
    ylims = (-0.5, 4)
    yticks = collect(0:3)
    xlims = (0.5, 10.5)

    F = Figure(resolution=(FIG_WIDTH, FIG_WIDTH / (0.7 * ASPECT)))
    A = Axis(F[1, 1], aspect=ASPECT)
    A.limits = (xlims, ylims)

    A.title = "Bake-Off!"
    A.titlealign = :left
    A.titlesize = 25
    A.subtitle = "How many times did the series winner achieve star baker. Series 1 did not award star baker.\n$(winner_df.baker[10]) won their series without achieving star baker in any episode.\nSeries 1 had 6 episodes, series 2 had 8. All following series have 10 episodes.\n$(best_string) are the most successful bakers, achieving star baker $(winner_df.star_baker[most_successful[1]]) times.\n "
    A.xlabel = "Series"
    A.ylabel = "Number of Star Baker Awards"
    A.xticks = (collect(1:10), string.(collect(1:10)))
    A.yticks = (yticks, string.(yticks))

    HALF_IMG_WIDTH = 0.45
    pix_width = xlims[2] - xlims[1]
    pix_height = ylims[2] - ylims[1]
    HALF_IMG_HEIGHT = HALF_IMG_WIDTH * (pix_height / pix_width) * ASPECT

    for row in eachrow(winner_df)
        local name = row.baker
        local series = row.series
        local star_baker = row.star_baker
        local filename = "./data/baker_img/" * name * "_" * string(series) * ".jpg"
        local img = load(filename)
        s = size(img)
        if s[2] > s[1]
            # Shrink width -trim ends
            x = (s[2] - s[1])
            m = x ÷ 2
            img = img[:, (1+m):(end-m-(x%2))]
        elseif s[1] > s[2]
            # Shrink height -trim ends
            x = (s[1] - s[2])
            m = x ÷ 2
            img = img[(1+m):(end-m-(x%2)), :]
        end

        image!(
            A,
            [series - HALF_IMG_WIDTH, series + HALF_IMG_WIDTH],
            [star_baker - HALF_IMG_HEIGHT, star_baker + HALF_IMG_HEIGHT],
            rotr90(img)
        )
    end

    A_width = A.scene.px_area.val.widths[1]
    half_img_width = ceil(HALF_IMG_WIDTH * A_width / pix_width)

    # Add border to image
    scatter!(A, winner_df.series, winner_df.star_baker, marker=square_with_hole, markersize=half_img_width, color=:white)
    scatter!(A, winner_df.series, winner_df.star_baker, marker=circle_circle, markersize=half_img_width, color=bakeoff_pink)

    scatter!(A, winner_df.series[most_successful], winner_df.star_baker[most_successful], marker=circle_circle, markersize=half_img_width, color=:gold)

    scatter!(A, winner_df.series[1], winner_df.star_baker[1], marker=square_with_hole, markersize=half_img_width, color=:white)
    scatter!(A, winner_df.series[1], winner_df.star_baker[1], marker=circle_circle, markersize=half_img_width, color=bakeoff_gray)

    # Add winner name
    for row in eachrow(winner_df)
        tooltip!(
            A,
            row.series,
            row.star_baker .+ HALF_IMG_HEIGHT,
            row.baker,
            offset=0,
            outline_color=bakeoff_blue,
            overdraw=true,
            triangle_size=10
        )
    end

    # Lines for channel changes
    vlines!(A, [4.5, 7.5], linewidth=1, linestyle=:dash, color=:gray30)
    text!(A, [0.5, 4.5, 7.5] .+ 0.1, [4.0, 4.0, 4.0], text=["BBC2", "BBC1", "Channel 4"], align=(:left, :top))

    Label(F[2, 1],
        "© JTSiddons\nData available from \"https://bakeoff.netlify.app/\".\nBaker images from \"https://thegreatbritishbakeoff.co.uk\"",
        justification=:left,
        # tellheight=false,
        tellwidth=false
    )

    F
end

save("./figs/baker_star_baker.png", F, px_per_unit=2.0)
