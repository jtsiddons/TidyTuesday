using CairoMakie
using Colors
using CSV
using DataFrames


# Generate football image with world cup photos
include("./world_cup_ball_graphic.jl")


## Set-up
WIDTH::Int16 = 1500
HEIGHT::Int16 = 1000
RATIO = WIDTH/HEIGHT;
backgroundcolor = :gray80

## Set axis scale so that points are 1:1
xlims = (-2.2f0, 4.3f0)
ylim_val = 0.5f0*(xlims[2]-xlims[1])/RATIO
ylims = (-ylim_val, ylim_val)


## Shapes to cover components of football image
square_with_hole = BezierPath([
    MoveTo(Point(1, 1)),
    LineTo(Point(1, -1)),
    LineTo(Point(-1, -1)),
    LineTo(Point(-1, 1)),
    LineTo(Point(1, 1)),
    MoveTo(Point(0, 0.25)),
    EllipticalArc(Point(0, 0), 0.25, 0.25, 0, 0, 2pi),
    ClosePath(),
])

circle_with_circle_hole = BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 0.5, 0.5, 0, 0, 2π),
    MoveTo(Point(0.45, 0)),
    # EllipticalArc(Point(0, 0), 0.4655, 0.4655, 0, 0, -2pi),
    EllipticalArc(Point(0, 0), 0.48, 0.48, 0, 0, -2π),
    ClosePath(),
])

## Load Data
wcmatches_file = "./data/wcmatches.csv"
wcmatches_df = DataFrame(CSV.File(wcmatches_file, stringtype=String));

worldcups_file = "./data/worldcups.csv"
worldcups_df = DataFrame(CSV.File(worldcups_file, stringtype=String));

## Count world cup wins by world cup winner
winner_num = combine(
    groupby(worldcups_df, :winner),
    :year => (x -> size(x, 1)) => :count
)
sort!(winner_num, :winner)
sort!(winner_num, :count, rev=true)


# Use custom colours (combine Germany, Gold for Brazil)
winner_num.color = [
    colorant"#ffd700",  # Brazil
    colorant"#007A33",  # Italy
    colorant"#000000",  # Germany / West Germany
    colorant"#6CACE4",  # Argentina
    colorant"#0055a4",  # France
    colorant"#001489",  # Uruguay
    colorant"#ffffff",  # England
    colorant"#000000",  # Germany / West Germany
    colorant"#EF3340",  # Spain
]

worldcups_df.color = leftjoin(select(worldcups_df, [:winner]), select(winner_num, [:winner, :color]), on=:winner).color

num_world_cups = size(worldcups_df, 1)

## Initiate Figure
begin
    F = Figure(resolution=(WIDTH, HEIGHT), figure_padding=0);

    Ax = Axis(
        F[1, 1], 
        limits=(xlims, ylims),
        backgroundcolor=backgroundcolor,    
    )

    hidedecorations!(Ax)
    hidespines!(Ax)

    # Set up for ball
    ball_radius = 1
    tick_radius = 1.2
    
    # Tick locations
    θs = range(π/2, -3π/2, num_world_cups+1)[1:end-1]
    xs = cos.(θs)
    ys = sin.(θs)
    positions = [[ball_radius.*(x, y), tick_radius.*(x, y)] for (x, y) in zip(xs, ys)]
    
    # Ball labels|
    ball_labels = ["$(host)\n$(year)" for (host, year) in zip(worldcups_df.host, worldcups_df.year)]
   
    # Alignment of labels
    label_halign = fill(:center, num_world_cups)
    label_valign = fill(:bottom, num_world_cups)
    
    # label_halign[(θs .> π/4)] .= :center
    label_halign[-π/4 .< θs .<= π/4] .= :left
    # label_halign[-3π/4 .< θs .<= -π/4] .= :center
    label_halign[-5π/4 .< θs .<= -3π/4] .= :right
    
    label_valign[-π/4 .< θs .<= π/4] .= :center
    label_valign[-3π/4 .< θs .<= -π/4] .= :top
    label_valign[-5π/4 .< θs .<= -3π/4] .= :center
    
    label_align = [zip(label_halign, label_valign)...]
    
    # Draw the ball
    poly!(Ax, Circle(Point2f(0, 0), ball_radius), color=:black)
        
    image!(Ax, [-1, 1], [-1, 1], projection)

    # Add in svg that hides image content outside of ball
    scatter!(Ax, (0, 0), marker=square_with_hole, markersize=4*ball_radius, color=backgroundcolor, markerspace=:data)
    
    # Add ticks and labels to football
    for (pos, label, align, col) in zip(positions, ball_labels, label_align, worldcups_df.color)
        lines!(Ax, pos, color=col, linewidth=5)
        text!(Ax, 1.025.*pos[2], text=label, align=align, justification=:center)
    end
    
    # Add in svg that adds border to football
    scatter!(Ax, (0, 0), marker=circle_with_circle_hole, markersize=2*ball_radius, color=:black, markerspace=:data)
    
    ## World Cup Winner Stars
    text_v_pos = range(tick_radius, -tick_radius, size(winner_num, 1))
    text_h_pos = 3f0
    
    star_size = 0.2
    star_separation = 0.02

    for (row, pos) in zip(eachrow(winner_num), text_v_pos)
        text!(
            Ax, 
            text_h_pos, 
            pos, 
            text=row.winner, 
            align=(:left, :center),
            textsize=40,
        )
        # Location for each star (one per win for the winner)
        star_pos = Point2f[(text_h_pos-(star_size + star_separation)*i, pos) for i in 1:row.count]
        scatter!(
            Ax, 
            star_pos, 
            marker=:star5, 
            color=row.color, 
            markersize=star_size, 
            markerspace=:data
        )
    end

    # Top label (title)
    text!(
        Ax,
        xlims[1]+0.05,
        ylims[2], 
        text = "FIFA World Cup Hosts and Winners",
        justification=:left,
        align=(:left, :top),
        textsize=75,
    )

    when_best_nation_won = worldcups_df.year[worldcups_df.winner .== winner_num.winner[1]]
    when_best_nation_won_string = join(when_best_nation_won,", ", ", and ")

    # Subtitle
    text!(
        Ax,
        xlims[1]+0.06,
        ylims[2]-0.38, 
        text = "$(winner_num.winner[1]) is the most successful nation, having won $(winner_num.count[1]) times in $(when_best_nation_won_string).",
        justification=:left,
        align=(:left, :top),
        textsize=35,
    )

    # Bottom label (citations/etc)
    text!(
        Ax,
        xlims[1]+0.05,
        ylims[1]+0.05, 
        text = "@JTSiddons\nData available from \"https://www.kaggle.com/datasets/evangower/fifa-world-cup\"\nMore Information available at \"https://www.kaggle.com/datasets/evangower/fifa-world-cup/code\"",
        justification=:left,
        align=(:left, :bottom),
        textsize=33,
    )

    F
end

save("./figs/world_cup_hosts_and_winners.png", F, px_per_unit=2.0)
