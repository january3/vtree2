# Package index

## Creating vtree objects

- [`vtree()`](https://january3.github.io/vtree2/reference/vtree.md)
  [`vtree_from_freqtable()`](https://january3.github.io/vtree2/reference/vtree.md)
  : Create a vtree object from a data frame
- [`cases_from_freqtable()`](https://january3.github.io/vtree2/reference/cases_from_freqtable.md)
  : Convert a frequency table to a data frame of cases
- [`as_tbl_graph(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/as_tbl_graph.vtree.md)
  : Convert a vtree_graph to a tbl_graph
- [`as_vtree()`](https://january3.github.io/vtree2/reference/as_vtree.md)
  : Convert a tbl_graph to a vtree
- [`mutate(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/mutate.vtree.md)
  : Create, modify, and delete node columns
- [`is_vp()`](https://january3.github.io/vtree2/reference/is_vp.md) : Is
  the vtree based on valid percentages?
- [`levels(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/levels.vtree.md)
  : Get the levels of a vtree object
- [`names(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/names.vtree.md)
  : Get the variable names of a vtree object
- [`nodecols()`](https://january3.github.io/vtree2/reference/nodecols.md)
  : Get the column names of a vtree object
- [`print(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/print.vtree.md)
  : Print a vtree object
- [`summary(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/summary.vtree.md)
  : Show per-variable summaries of a vtree object data

## Patterns

- [`pattern()`](https://january3.github.io/vtree2/reference/pattern.md)
  : Convert a vtree to a pattern
- [`print(`*`<vtree_pattern>`*`)`](https://january3.github.io/vtree2/reference/print.vtree_pattern.md)
  : Print a vtree pattern
- [`plot(`*`<vtree_pattern>`*`)`](https://january3.github.io/vtree2/reference/plot.vtree_pattern.md)
  : Plot a pattern object

## Pruning, keeping, marking, searching

- [`prune()`](https://january3.github.io/vtree2/reference/prune.md)
  [`retain()`](https://january3.github.io/vtree2/reference/prune.md)
  [`mark()`](https://january3.github.io/vtree2/reference/prune.md)
  [`find_nodes()`](https://january3.github.io/vtree2/reference/prune.md)
  : Find nodes and prune a vtree graph
- [`find_children()`](https://january3.github.io/vtree2/reference/find_children.md)
  [`find_parents()`](https://january3.github.io/vtree2/reference/find_children.md)
  : Find all nodes that follow or precede the nodes for which the mask
  is TRUE

## Summaries

- [`summary_vt()`](https://january3.github.io/vtree2/reference/summary_vt.md)
  [`summary_vt_df()`](https://january3.github.io/vtree2/reference/summary_vt.md)
  : Summarize a case variable for each node of a vtree
- [`summary_at_var()`](https://january3.github.io/vtree2/reference/summary_at_var.md)
  : Summarize a variable at a given node of a vtree
- [`vtree_apply()`](https://january3.github.io/vtree2/reference/vtree_apply.md)
  : Apply a function to a data frame by nodes in the vtree
- [`label_var_levels()`](https://january3.github.io/vtree2/reference/label_var_levels.md)
  : Get a value list as character vector

## Labels and aliases

- [`add_aliases()`](https://january3.github.io/vtree2/reference/add_aliases.md)
  : Add aliases columns to vtree
- [`add_labels()`](https://january3.github.io/vtree2/reference/add_labels.md)
  : Add labels to a plot

## Layouts, colors, plotting

- [`plot(`*`<vtree>`*`)`](https://january3.github.io/vtree2/reference/plot.vtree.md)
  [`plot_vtree()`](https://january3.github.io/vtree2/reference/plot.vtree.md)
  : Plot a vtree
- [`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md)
  : Prepare a layout for plotting a vtree
- [`vtree_palette()`](https://january3.github.io/vtree2/reference/vtree_palette.md)
  [`var_palette()`](https://january3.github.io/vtree2/reference/vtree_palette.md)
  [`add_palette()`](https://january3.github.io/vtree2/reference/vtree_palette.md)
  : Color palettes for a variable levels
- [`contrast_color()`](https://january3.github.io/vtree2/reference/contrast_color.md)
  : Get a contrasting color
- [`makeContent(`*`<vtree_plot>`*`)`](https://january3.github.io/vtree2/reference/makeContent.vtree_plot.md)
  : Hook for vtree plots

## Datasets

- [`titanicNA`](https://january3.github.io/vtree2/reference/titanicNA.md)
  : titanicNA dataset
