export myviolin!, channel_scatter, circle_circle, circle_with_hole, square_with_hole

"""
    myviolin!(Ax::Axis, t::DataFrame, factor_y::Symbol, factor_x::Symbol; quants::Vector{Float64}=[0.25, 0.50, 0.75], scale::Float64=0.45, side::Symbol=:both, col::Symbol=:gray30)

# myviolin!

Generates a customised Violin plot in Makie. This allows for the inclusion of quantile lines and strokearounds on the violins. 

Utilises Makie 'poly!' and `kde` from `KernelDensity`

## Inputs

* `Ax` - Makie Axis
* `t` - DataFrame containing the factors of interest
* `factor_y` - The main column of interest, for which I will draw the violins
* `factor_x` - A column on which I will split the violins

## Optional arguments 

* `quants` - The points at which to draw quantile lines. Defaults to `[0.25, 0.5, 0.75]`. Values at even indices will be drawn with a solid line, odd indices with a dashed line.
* `scale` - The max width of a violin (this is double for `:both` sided violin). Defaults to `0.45`.
* `side` - Which side to draw the violin. Default to `:both`.
* `col` - Colour of the violins and lines. Default is `:gray30`

"""
function myviolin!(Ax::Axis, t::DataFrame, factor_y::Symbol, factor_x::Symbol; quants::Vector{Float64}=[0.25, 0.50, 0.75], scale::Float64=0.45, side::Symbol=:both, col::Symbol=:gray30)

    ms = t[:, factor_x] |> unique
    for m in ms
        tt = filter(factor_x => ==(m), t)
        # Get density of factor_y
        k = kde(tt[:, factor_y])
        r = length(k.x)
        pts = 1:10:r
        x = k.x[pts]
        y = k.density[pts]
        # Get location of quantiles
        qs = quantile(tt[:, factor_y], quants)
        qlocs = [findfirst(>=(q), x) for q in qs]
        qlocsx = [x[q] for q in qlocs]
        # Scale the density so that it fits in the column
        if (side == :left && scale > 0) || (side == :right && scale < 0)
            scale = -scale
        end
        mx = maximum(y)
        y = scale .* y ./ (mx)
        # Width of quantile lines
        qlocs = [y[q] for q in qlocs]
        # Build polygon
        lstyles = [:dash, :solid, :dash]
        if side == :both
            coords = vcat([Point2f(m + y[i], x[i]) for i in eachindex(y)], [Point2f(m - y[i], x[i]) for i in reverse(eachindex(y))])
            poly!(Ax, coords, strokearound=true, strokewidth=1.5, strokecolor=col, color=(col, 0.3))
            # Add quantile linse
            for i in 1:3
                lines!(Ax, [m - qlocs[i], m + qlocs[i]], [qlocsx[i], qlocsx[i]], linewidth=(2 - (i % 2)), color=col, linestyle=lstyles[i])
            end
        else
            # Add a shift so that the violins do not overlap
            m2 = m + flipsign(0.025, scale)
            coords = [Point2f(m2 + y[i], x[i]) for i in eachindex(y)]
            poly!(Ax, coords, strokearound=true, strokewidth=1.5, strokecolor=col, color=(col, 0.3))
            # Add quantile lines
            for i in 1:3
                lines!(Ax, [m2, m2 + qlocs[i]], [qlocsx[i], qlocsx[i]], linewidth=(2 - (i % 2)), color=col, linestyle=lstyles[i])
            end
        end
    end
end


"""
    channel_scatter(F::Figure, df::DataFrame, range::Tuple{Int,Int}, color::Symbol, ylims::Tuple{Float64, Float64})

# channel_scatter

## Description

Creates a scatter and axis coloured for a channel. 
Plots a scatter 

## Inputs

* `F` - The Figure environment on which to create a temporary axis
* `df` - The DataFrame
* `factor` - The factor on which to create a scatter chart.
* `color` - The color for the scatter and axis ticks
* `ylims` - The y-axis limits. So that all new axis are to the same scale.

### Optional
* `xlims` - The x-axis limits. Defaults to `(0.5, 10.5)`

"""
function channel_scatter(F::Figure, df::DataFrame, range::Tuple{Int,Int}, factor::Symbol, color::Symbol, ylims::Tuple{Float64,Float64}; xlims::Tuple{Float64,Float64}=(0.5, 10.5))
    local A = Axis(F[1, 1], limits=(xlims, ylims))
    local series = collect(range[1]:range[2])
    A.xticks = (series, string.(series))
    A.xtickcolor = color
    A.xticklabelcolor = color
    hideydecorations!(A)
    local f_df = filter(:series => x -> range[1] ≤ x ≤ range[2], df)
    scatter!(A, f_df.series, f_df[:, factor], color=color)
end

## Scatter Shapes
circle_with_hole = BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 1, 1, 0, 0, 2pi),
    MoveTo(Point(0.5, 0.5)),
    LineTo(Point(0.5, -0.5)),
    LineTo(Point(-0.5, -0.5)),
    LineTo(Point(-0.5, 0.5)),
    ClosePath(),
])

square_with_hole = BezierPath([
    MoveTo(Point(1, 1)),
    LineTo(Point(1, -1)),
    LineTo(Point(-1, -1)),
    LineTo(Point(-1, 1)),
    LineTo(Point(1, 1)),
    MoveTo(Point(0.75, 0)),
    EllipticalArc(Point(0, 0), 0.75, 0.75, 0, 0, 2pi),
    ClosePath(),
])

circle_circle = BezierPath([
    MoveTo(Point(1, 0)),
    EllipticalArc(Point(0, 0), 1.0, 1.0, 0, 0, 2π),
    MoveTo(Point(0.75, 0)),
    EllipticalArc(Point(0, 0), 0.75, 0.75, 0, 0, -2pi),
    ClosePath(),
])