using Colors
using FileIO

## Code to generate the football used in the world cup plot

WIDTH::Int16 = 900
HEIGHT::Int16 = 900

# The resulting image
projection = fill(RGB(0.0, 0.0, 0.0), WIDTH, HEIGHT)

# Want square images - crop accordingly
function square_image(img)
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
    return img
end

"""
    orthographic_project(image, destination, longrange::Tuple{Number,Number}, latrange::Tuple{Number,Number}; destWidth=WIDTH, destHeight=HEIGHT, origin::Tuple{Number,Number}=(0, 0))

## Information

Orthorgraphically project `image` onto `destination`
"""
function orthographic_project(image, destination, longrange::Tuple{Number,Number}, latrange::Tuple{Number,Number}; destWidth=WIDTH, destHeight=HEIGHT, origin::Tuple{Number,Number}=(0, 0))
    ball_radius = destWidth / 2

    ## Functions for coordinate conversion
    x_ball(long, lat) = ball_radius * (cosd(lat) * sind(long - origin[1]))
    y_ball(long, lat) = ball_radius * (cosd(origin[2]) * sind(lat) - sind(origin[2]) * cosd(lat) * cosd(long - origin[2]))
    dont_plot_point(long, lat) = (sind(origin[2]) * sind(lat) + cosd(origin[2]) * cosd(lat) * cosd(long - origin[2])) < 0

    ## Convert image index to long, lat
    image_width = longrange[2] - longrange[1]
    image_height = latrange[2] - latrange[1]
    image_size = size(image)
    image_index_to_longlat(i::Int, j::Int) = (
        i * (image_width / image_size[1]) + longrange[1],
        j * (image_height / image_size[2]) + latrange[1],
    )

    ## Convert conversion coord to destination index
    ball_coord_to_ball_index(ball_x, ball_y) = (Int(round(ball_x)) + (destWidth ÷ 2), Int(round(ball_y)) + (destHeight ÷ 2))

    ## Loop thorugh image indices and add to destination
    for i in 1:image_size[1], j in 1:image_size[2]
        current_long, current_lat = image_index_to_longlat(i, j)
        if dont_plot_point(current_long, current_lat)
            continue
        end
        ball_x_coord = x_ball(current_long, current_lat)
        ball_y_coord = y_ball(current_long, current_lat)

        ball_i, ball_j = ball_coord_to_ball_index(ball_x_coord, ball_y_coord)
        destination[ball_i, ball_j] = image[i, j]
    end

end

## Add some images to the football

# Bottom

Uru = load("./figs/1930-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Uru), projection, (-75, -25), (-75, -25))

Switz = load("./figs/1954-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Switz), projection, (-25, 25), (-75, -25))

Chile = load("./figs/1962-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Chile), projection, (25, 75), (-75, -25))

# Centre

Sweden = load("./figs/1958-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Sweden), projection, (-75, -25), (-25, 25))

Eng = load("./figs/1966-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Eng), projection, (-25, 25), (-25, 25))

Mexico = load("./figs/1970-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Mexico), projection, (25, 75), (-25, 25))

# Top

USA = load("./figs/1994-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(USA), projection, (-75, -25), (25, 75))

Japan = load("./figs/2002-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Japan), projection, (-25, 25), (25, 75))

Brazil = load("./figs/2014-World-Cup-Final.jpg") |> square_image
orthographic_project(rotr90(Brazil), projection, (25, 75), (25, 75))

projection