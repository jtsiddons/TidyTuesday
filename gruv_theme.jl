
using Colors, CairoMakie

function theme_gruvbox_light(bg=colorant"#ebdbb2")
	fg = colorant"#3c3836"
	bl = colorant"#458588"
	rd = colorant"#cc241d"
	gr = colorant"#98971a"
	pu = colorant"#b16286"
	aq = colorant"#689b61"
	or = colorant"#af3a03"
	yl = colorant"#d79221"
	gy = colorant"#7c6f64"

	cols = [bl, rd, gr, pu, aq, or, gy, yl]
	mkrs = [:circle, :rect, :utriangle, :dtriangle]
	
	return Theme(
		backgroundcolor = bg,
		Axis = (
			backgroundcolor = bg,
	        # leftspinevisible = false,
	        rightspinevisible = false,
	        # bottomspinevisible = false,
	        topspinevisible = false,
			xgridcolor = (gy, 0.3),
			ygridcolor = (gy, 0.3),
			palette = (color = cols, marker = mkrs),
			leftspinecolor = fg,
			bottomspinecolor = fg,
			topspinecolor = fg,
			rightspinecolor = fg,
			spinewidth = 2.0,
			titlealign = :left,
			font = "Noto Sans",
			titlefont = "Noto Sans",
			titlesize = 28,
			titlecolor = fg,
			padding = 0,
			xlabelcolor=fg, xtickcolor=fg, xticklabelcolor=fg,
			ylabelcolor=fg, ytickcolor=fg, yticklabelcolor=fg,
		),
		# # cycle = Cycle([:color, :marker], covary=true)
		Lines = (
	        linewidth = 4,
	        # linestyle = :dash,
			cycle = Cycle([:color, :marker, :linestyle], covary=true)
		),
		Text = (
				align = (:left, :center),
				cycle = Cycle(:color)
				),
		fontcolor=fg,
		
	)
end

function theme_gruvbox_dark(bg=colorant"#282828")
	fg = colorant"#ebdbb2"
	bl = colorant"#458588"
	rd = colorant"#cc241d"
	gr = colorant"#98971a"
	pu = colorant"#b16286"
	aq = colorant"#689b61"
	or = colorant"#fe8019"
	yl = colorant"#d79221"
	gy = colorant"#a89984"

	cols = [bl, rd, gr, pu, aq, or, gy, yl]
	mkrs = [:circle, :rect, :utriangle, :dtriangle]
	
	return Theme(
		backgroundcolor = bg,
		Axis = (
			backgroundcolor = bg,
	        # leftspinevisible = false,
	        rightspinevisible = false,
	        # bottomspinevisible = false,
	        topspinevisible = false,
			xgridcolor = (gy, 0.3),
			ygridcolor = (gy, 0.3),
			palette = (color = cols, marker = mkrs),
			leftspinecolor = fg,
			bottomspinecolor = fg,
			topspinecolor = fg,
			rightspinecolor = fg,
			spinewidth = 2.0,
			titlealign = :left,
			font = "Noto Sans",
			titlefont = "Noto Sans",
			titlesize = 28,
			titlecolor = fg,
			padding = 0,
			xlabelcolor=fg, xtickcolor=fg, xticklabelcolor=fg,
			ylabelcolor=fg, ytickcolor=fg, yticklabelcolor=fg,
		),
		# # cycle = Cycle([:color, :marker], covary=true)
		Lines = (
	        linewidth = 4,
	        # linestyle = :dash,
			cycle = Cycle([:color, :marker, :linestyle], covary=true)
		),
		Text = (
				align = (:left, :center),
				cycle = Cycle(:color)
				),
		fontcolor=fg,
		
	)
end
