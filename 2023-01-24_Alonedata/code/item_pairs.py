# This script will look at the loadout of contestants.
# I will constuct a matrix which will contain counts of times that the pair of
# items is inculded in a contestant's loadout.
# I will also constuct a matrix where the ijth entry will be the mean number of
# days survived if a contestant has that pair of items in their loadout
# Different locations will require a different loadout, so I may want to
# somehow consider that in my analysis, not sure how at this point in time.
import numpy as np
import networkx as nx
import polars as pl
import seaborn as sns
import matplotlib.pyplot as plt
sns.set_theme(style="ticks", palette="pastel")
plt.rcParams['figure.figsize'] = [10.0, 10.0]
plt.rcParams['figure.dpi'] = 140


# I think I only need survivalist and loadout data.
survivalists_file = "./data/survivalists.csv"
survivalists_df = pl.read_csv(survivalists_file)
survivalists_df.describe()

loadouts_file = "./data/loadouts.csv"
loadouts_df = pl.read_csv(loadouts_file)
loadouts_df.describe()

# From the eda.py, I know that there are 27 unique items. Let's just verify
# that.
items = loadouts_df['item'].unique()
print(items.len())
# Yep - 27 items. This will mean that I will have a 27 x 27 matrix

# Not sure of an optimal approach...
# Let's start by unstacking the items, i.e. pivoting wider such that we have
# columns for each item, with a 1 or 0 if the item is a part of the
# contestant's loadout.
# Modify the command to  account for series 5 - group by `season` too.
loadout_wider = (
    loadouts_df
    .select(['name', 'item', 'season'])
    .groupby(['name', 'item', 'season'])
    .agg(pl.count())
    .pivot(values='count', index=['name', 'season'], columns='item')
    .with_column(
        pl.all().fill_null(pl.lit(0))
    )
)
print(loadout_wider)

# QUESTION: Have contestants appeared on multiple seasons?
multiple_season_contestants = (
    survivalists_df
    .groupby('name')
    .agg([
        pl.col('season').count().alias('season_count'),
        pl.col('season').list().alias('seasons'),
    ])
    .filter(pl.col('season_count') > 1)
    .sort('season_count', reverse=True)
)

# So, we have 10 contestants returning in season 5. It appears this may be
# similar to a `Champions of Champions` style of season. Let's have a look to
# see how each contestant's loadout differred between their original season and
# season 5.
loadout_improvement = (
    loadouts_df
    .join(
        multiple_season_contestants,
        left_on='name',
        right_on='name',
        how='inner'
    )
    .groupby(['name', 'season', 'item'])
    .agg(pl.count())
    .groupby(['name', 'item'])
    .agg(pl.count().alias('item_count'))
    .filter(pl.col('item_count') > 1)
    .groupby('name')
    .agg(pl.count().alias('num_repeated_items'))
    .join(
        (
            survivalists_df
            .filter(pl.col('season') == 5)
            .select([
                'name',
                pl.col('days_lasted').alias('days_return'),
            ])
        ),
        left_on='name',
        right_on='name'
    )
    .join(
        (
            survivalists_df
            .filter(pl.col('season') < 5)
            .select([
                'name',
                pl.col('days_lasted').alias('days_original'),
            ])
        ),
        left_on='name',
        right_on='name',
        how='left'
    )
    .with_columns([
        (
            (pl.col('days_return') - pl.col('days_original'))
            .alias('days_difference')
        ),
        (
            pl.when(pl.col('days_return') > pl.col('days_original'))
            .then(1)
            .otherwise(0)
            .alias('improved_bin')
        ),
        (
            pl.when(pl.col('days_return') > pl.col('days_original'))
            .then('yes')
            .otherwise('no')
            .alias('improved')
        ),
    ])
)

# QUESTION: Did contestants who change their loadout improve?
(
    loadout_improvement
    .groupby('improved')
    .agg([
        pl.col('num_repeated_items').mean().alias('mean_num_items'),
        pl.col('num_repeated_items').median().alias('median_num_items'),
    ])
)
# Contestants who performed better in season 5 changed 4 items in their.
# loadout.

# Plotting
# So... I wanted to experiment with bokeh this week too. I experimented a
# little and was annoyed by the i/o system, it essentially plots to a browser
# window. Saving of plots is performed using `selenium`, so exporting to png
# effectively takes a screenshot, and retains the plot widgets...
# Furthermore, it does not interact nicely with polars. I'll look into bokeh
# another week.
# I'll use seaborn which apparently interacts with polars nicely.
sns.boxplot(
    y='num_repeated_items',
    x='improved',
    data=loadout_improvement.to_pandas(),
)
plt.show()

# Back to the co-occurence stuff. I modified the query to account for the
# repeated season.
# To construct a co-occurence matrix of M I need to calculate:
# transpose(M) dot M
# And set the diagonal of the result to 0.
# `loadout_wider`
loadout_wider.head()

use_data = (
    loadout_wider
    .select(pl
            .exclude(['name', 'season']))
    .to_numpy()
    .astype(float)
)
use_data[use_data > 1] = 1

coocc = use_data.T.dot(use_data)
node_size = [50 + coocc[i][i] for i in range(len(coocc))]
node_labels = loadout_wider.select(pl.exclude(['name', 'season'])).columns

for i in range(len(coocc)):
    coocc[i] = coocc[i] / coocc[i][i]

min_freq = 0.9
coocc[coocc < min_freq] = 0
np.fill_diagonal(coocc, 0)
coocc_df = pl.from_numpy(
    coocc,
    columns=loadout_wider.select(pl.exclude(['name', 'season'])).columns,
)
coocc_df.head()

G = nx.DiGraph(coocc)
pos = nx.spring_layout(G)
node_labels = {n: l for n, l in zip(G.nodes(), node_labels)}

# NOTE: Errors from the LSP here are erroneous. It appears not to be able to
# detect the type of `G.nodes()` for example.
edge_width = [0.1 + 10*(coocc[i][j]-min_freq) for i, j in G.edges()]

nodes = nx.draw_networkx_nodes(
    G,
    pos,
    node_size=node_size,
    node_color='#fe8019',
)
edges = nx.draw_networkx_edges(
    G,
    pos,
    arrowstyle="->",
    arrowsize=10,
    width=edge_width,
    edge_color='lightgray'
)
labels = nx.draw_networkx_labels(
    G,
    pos,
    node_labels,
)

plt.savefig('./figs/item_pair_graph.png')
