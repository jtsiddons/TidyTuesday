import polars as pl


# Load in the data - polars uses the same function name as pandas There is also
# the `scan_csv` function, which is used for lazy loading. This delays parsing
# the file. This can be useful for large data, we can set-up a query and see
# the graph of its structure before requesting that the query proceed. I may
# experiment with that later. Although none of the data files are large this
# week.
survivalists_file = "./data/survivalists.csv"
survivalists_df = pl.read_csv(survivalists_file)
survivalists_df.describe()

loadouts_file = "./data/loadouts.csv"
loadouts_df = pl.read_csv(loadouts_file)
loadouts_df.describe()

# Episode data has a date column, let's ensure we parse that correctly.
# We also want to ensure some columns are categorical - this would absolutely
# be required if we were using the rust crate, so I'll consider it to be good
# practice now.
episodes_file = "./data/episodes.csv"
episodes_df = pl.read_csv(episodes_file, parse_dates=True)
episodes_df.describe()

seasons_file = "./data/seasons.csv"
seasons_df = pl.read_csv(seasons_file, parse_dates=True)
seasons_df.describe()

# Let's look at how `imdb_rating` changed over the season.
# Here I am calculating a season rating by computing the average of all ratings
# over the season.
rating_query = (
    episodes_df.lazy()
    .groupby('season')
    .agg([
        pl.count().alias('n_episodes'),
        pl.col('n_ratings').sum().alias('n_ratings_season'),
        (
            (pl.col('imdb_rating') * pl.col('n_ratings'))
            .sum()
            .alias('rating_by_num_ratings')
        ),
    ])
    .with_columns([
        (pl.col('rating_by_num_ratings') /
            pl.col('n_ratings_season')).alias('mean_rating'),
    ])
    .select([
        pl.col('season'),
        pl.col('n_episodes'),
        pl.col('mean_rating'),
    ])
    .sort('season')
)
average_rating = rating_query.collect()

# Let's get mean and standard deviation episode ratings, by season, and look at
# where each season was located. I will also get mean and standard deviation of
# viewer numbers.
rating_location_query = (
    episodes_df.lazy()
    .groupby('season')
    .agg([
        pl.col('imdb_rating').mean().alias('mean_rating'),
        pl.col('imdb_rating').std().alias('std_rating'),
        pl.col('imdb_rating').max().alias('peak_rating'),
        pl.col('viewers').mean().alias('mean_viewers'),
        pl.col('viewers').std().alias('std_viewers'),
        pl.col('viewers').max().alias('peak_viewers'),
    ])
    .sort('season')
    .join(seasons_df.lazy(), left_on='season', right_on='season')
    .select(
        pl.col([
            'season',
            'mean_rating',
            'std_rating',
            'peak_rating',
            'mean_viewers',
            'std_viewers',
            'peak_viewers',
            'location',
            'lat',
            'lon',
        ]),
    )
)
season_details = rating_location_query.collect()

# Thoughts on polars...
# So far I am liking it. It is quick, and I quite like the lazy query, of
# course, that can be omitted, but it is nice to experiment with that feature.
# Whilst the syntax and structure of the data operations is very, very, similar
# to pandas, I think that I am preferring polars at the moment!

# Let's look at value counts. The loadouts data will be useful for this, let's
# see which items were favoured by contestants. Can we then determine which
# items were most useful for the contestant's chance of surviving?
# It appears that I cannot find a simple value_counts function. We can do it
# using standard methods though.
loadout_item_count = (
    loadouts_df
    .groupby('item')
    .count()
    .sort('count', reverse=True)
)
print(loadout_item_count)

# Ok, let's now try to see how long each item lasted - how useful are the 
# items? This isn't the most useful analysis, since there will be some 
# relationship between items that will help a contestant, we can look at that
# later
item_person_df = (
    loadouts_df
    .join(survivalists_df, left_on='name', right_on='name')
    .select([
        'item',
        'season',
        'name',
        'days_lasted',
        'gender',
        'age',
    ])
)

item_usefulness_query = (
    item_person_df
    .groupby('item')
    .agg([
        pl.count(),
        pl.col('days_lasted').median().alias('median_days'),
        pl.col('days_lasted').mean().alias('mean_days'),
        pl.col('days_lasted').std().alias('std_days'),
    ])
    .sort('median_days', reverse=True)
)
print(item_usefulness_query.limit(10))
