# Find all nodes that follow or precede the nodes for which the mask is TRUE

Find all nodes that follow or precede the nodes for which the mask is
TRUE

## Usage

``` r
find_children(vtree, mask)

find_parents(vtree, mask)
```

## Arguments

- vtree:

  A vtree graph object.

- mask:

  A logical vector indicating which nodes to consider for finding their
  following or preceding nodes.

## Value

A logical vector indicating which nodes follow or precede the nodes

## Details

`find_children` identifies all nodes in a vtree graph that follow the
nodes for which the provided mask is TRUE.

`find_parents` identifies all nodes in a vtree graph that precede the
nodes for which the provided mask is TRUE.

## Examples

``` r
vt <- vtree_from_freqtable(Titanic, Class, Sex, Survived)
mask <- find_nodes(vt, path == "Class:1st/Sex:Male")
follow <- find_children(vt, mask)
precede <- find_parents(vt, mask)
vt |> mutate(fill =
            ifelse(path == "Class:1st/Sex:Male", "green", "white")) |>
      mutate(fill =
            ifelse(follow, "red",
                   ifelse(precede, "blue", fill))) |>
      plot()
#> ℹ palette attribute is NULL
#> legend will be black and white

```
