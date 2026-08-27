# Vtree2 Developers Guide

## 1 Vtree2 objects

The main class is `vtree` and inherits from `tbl_graph` - the tidygraph
object. However, it overloads a number of methods (including `mutate`
and `rename`), certain columns in the nodes data frame have specific
meaning and properties are added.

### 1.1 Node cols

### 1.2 Attributes

## 2 Plotting

Plotting vtrees uses directly the `grid` package. I tried to work with
`ggplot2` at first, but hit a major bump: `ggplot2` does not autofit
text, which means that one would have to experiment with the device
geometry and fontsizes before getting it right.

### 2.1 Layouts

The basic idea is this. The device (plot window, PDF etc.) has in grid x
and y coordinates from `0` to `1`. Before plotting starts, the
[`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md)
calls one a function from the `layout_*` family of functions to
generates the `x` and `y` positions of the nodes and edges (later
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) also attaches a
legend, but that is a different story). The layout coordinates are
stored as columns in the nodes data frame (x, y, width, height, full_w,
full_h) and in the edges data frame (x1, y1, x2, y2 and height). The
height/full_h and width/full_w determine the visible node width/height
and the total space allocated to the node (so basically full_w - width
is the margin of the node).

Once `layout_*` (by default, `layout_regular`) returns to
[`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md),
the positions are laid out in the left-to-right direction (some, like
`layout_tight`, need to know about the eventual direction, but still
they lay out the objects in the left-to-right fashion).

Then the
[`add_layout()`](https://january3.github.io/vtree2/reference/add_layout.md)
function transforms the positions: transposes, mirrors, fits to margins.
At that point, the final x and y screen positions, widths and heights of
the labels are all fixed and will not change.

### 2.2 Creating grobs

Next step is called from
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) as the last
step. The function is called `make_children` (`grob.R`), and its job is
to create the grid graphical objects - grobs - that make up the plot. It
takes a `params` list as an argument, where all the additional
information about the plot is stored (like the fontsizes chosen, line
width, lwidth and lheight).

`make_children` reads the data frames from the layout and legends,
interprets the x, y, width, height, label, shape, fill, color columns
and creates the node rectangles, the arrows for the edges and the
labels.

It also creates a `specs` object that it stores along the data-frame
like information about the objects. This will become necessary in the
next step.

All that is returned as a bundled
[`grid::gTree`](https://rdrr.io/r/grid/grid.grob.html) object, with all
the extra info stored as `x$params` and `x$layout`. The object gets the
class `vtree_plot`.

It is important to understand that at this stage the labels are not yet
fit into the nodes. This is because at this stage, the graphical device
on which the vtree will be plotted might not be present yet, so its
geometry is still unknown. You cannot know how large your text will be
on that device!

### 2.3 Actual plotting

When [`plot()`](https://rdrr.io/r/graphics/plot.default.html) returns
the `vtree_plot` object created by `make_children`, and it should get
printed to the screen, `print.vtree_plot` is called. This, in turn,
calls `grid.newpage()` to clear the device and `grid.draw(x)` to do the
actual plotting.

But that is not the finish yet. There is a special method called
`makeContent` which gets called when the device is ready for plotting.
This is the point when we finally know what the actual geometry of the
device is: what is its size in inches, pixels, cm or furlongs.

And only now it is possible to make sure that the text fits into its
bounding box. This is taken care by the function
[`makeContent.vtree_plot()`](https://january3.github.io/vtree2/reference/makeContent.vtree_plot.md)
in `grob.R`. It will get called from `grid.draw()`, and using the label
text, and bounding box widths and heights it will try to find font sizes
that fit the bounding box - by repeatedly creating text grobs and
measuring their size with `convertWidth(grobWidth())` (function
`.adapt_fontsize_single_full()` in `grob.R`).

## 3 Development tools

A number of developer helpers, which are not exported, are defined in
`R/helpers.R` and `R/attributes.R`. The latter file features functions
called `get_*` which allow the inspection of the vtree attributes.

## 4 Programming

### 4.1 Conventions

I suck at creating and following conventions in programming, but here
are some rules of thumb I tried to follow:

- `snake_case` function names
- functions that are used only within other functions *in the same file*
  should have a dot in front (but some times, “the same file” means “the
  family of related files”, e.g. `layout.R` refers to functions from
  `layout_helpers.R` and they start with a dot).
- try to write a test ASAP
- whenever you hit a bug, before fixing it, write a test that fails if
  this bug is present

### 4.2 Vtree construction

The construction of the vtree follows one of three paths:

- from a cases data frame, using
  [`vtree()`](https://january3.github.io/vtree2/reference/vtree.md)
- from a frequency table, using
  [`cases_from_freqtable()`](https://january3.github.io/vtree2/reference/cases_from_freqtable.md)
  and then
  [`vtree()`](https://january3.github.io/vtree2/reference/vtree.md)
- from a frequency table, using
  [`vtree_from_freqtable()`](https://january3.github.io/vtree2/reference/vtree.md)

The
[`vtree_from_freqtable()`](https://january3.github.io/vtree2/reference/vtree.md)
function is a convenience function that combines the two steps of
creating a cases data frame with
[`cases_from_freqtable()`](https://january3.github.io/vtree2/reference/cases_from_freqtable.md)
and then calling
[`vtree()`](https://january3.github.io/vtree2/reference/vtree.md).

At the core of both
[`vtree()`](https://january3.github.io/vtree2/reference/vtree.md) and
[`cases_from_freqtable()`](https://january3.github.io/vtree2/reference/cases_from_freqtable.md)
is the function `.colprocess()`. It processes the cases data frame and
the caller-provided tidy selection / tidy evaluation arguments (see
below) provided as the second argument (quosure list), and returns the
processed cases containing only the selected columns in the correct
order.

### 4.3 Tidy evaluation and selection

#### 4.3.1 Tidy evaluation

`vtree2` makes heavy use of the tidy selection and tidy evaluation
mechanisms. For example, the mask argument for many functions is treated
as an expression to be evaluated in the context of the nodes data frame.
Of course, a logical vector works as well.

Here is how it works, with an example of a regular data frame:

``` r
myfilter <- function(df, condition=NULL) {

  # first defuse the condition so that R does not try to evaluate it
  # prematurely
  condition <- rlang::enquo(condition)

  # since the argument is optional, we need to make sure it is not NULL;
  # however we cannot simply use `is.null` since by now it is a quosure
  if(!rlang::quo_is_null(condition)) {
    # evaluate the condition in the context of the data frame df
    # so any column name in the df can be used as a variable in the
    # condition expression
    mask <- rlang::eval_tidy(condition, data = df)
  } else {
    mask <- rep(TRUE, nrow(df))
  }

  df[mask, ]
}

myfilter(ToothGrowth, dose == 1.0)
#>     len supp dose
#> 11 16.5   VC    1
#> 12 16.5   VC    1
#> 13 15.2   VC    1
#> 14 17.3   VC    1
#> 15 22.5   VC    1
#> 16 17.3   VC    1
#> 17 13.6   VC    1
#> 18 14.5   VC    1
#> 19 18.8   VC    1
#> 20 15.5   VC    1
#> 41 19.7   OJ    1
#> 42 23.3   OJ    1
#> 43 23.6   OJ    1
#> 44 26.4   OJ    1
#> 45 20.0   OJ    1
#> 46 25.2   OJ    1
#> 47 25.8   OJ    1
#> 48 21.2   OJ    1
#> 49 14.5   OJ    1
#> 50 27.3   OJ    1
```

This evaluation is likewise responsible for the `expr` arguments to
functions such as
[`add_labels()`](https://january3.github.io/vtree2/reference/add_labels.md)
or
[`fmt_label()`](https://january3.github.io/vtree2/reference/summarize_by_node.md).

A more complex case of tidy evaluation can be found in `prune.R`. Here
the idea is that the condition is evaluated in the context of a special
data frame. Apart from the columns such as `freq`, `node_col`, `path`,
this data frame includes “virtual” columns for each of the variables
from which the tree was selected. The idea is to be able to find nodes
with expressions such as `Sex == "Male"`, as in
`prune(vt, Sex == "Male")`.

Creating the virtual columns is simple enough, but it gives rise to a
problem. If the node corresponds to the `Sex` variable, the comparison
between the node value and `"Male"` can give `FALSE` (if the node value
is `Female`), `TRUE` (if the node value is `Male`) or `NA` (if the node
value is `NA`). But not all nodes correspond to the `Sex` variable. E.g.
the comparison `Sex == "Male"` does not make sense for the node
`Class:1st`, and yet the virtual column must have *a* value. One
solution could have been to create a special value, like
`____not_applicable`; but there is no guarantee that a user would not
have such a value in their data. Also, what if the user wants to find
all nodes for which `Sex` is *not* `NA`?

A similar problem occurs with `%in%`: say we want to prune all `Class`
nodes where the Class is not `1st` or `2nd`. We would expect the
following to work correctly: `!Class %in% c("1st", "2nd")`. However, for
a node that does not correspond to the variable `Class` this expression
will also be true - and we will end up pruning more nodes than
necessary.

The solution the `prune.R` takes is as follows: the virtual columns get
a special class, `vtree_vcol`, with an attribute `applicable`. Now, a
function that inspects the comparison between a value and a virtual
column can check whether a comparison makes sense.

However, functions like `is.na` or `%in%` do not check that. Therefore,
it was necessary to do two things:

- create drop-in replacement for this functions which check whether a
  virtual column value is “applicable” and if so, return `NA` rather
  than `TRUE` or `FALSE`,
- manipulate the environment used for `eval_tidy` such that if the user
  specifies `is.na(Class)` the drop-in replacement will be used.

Here is more or less how the implementation looks like:

``` r
# drop in replacement
in_vtree_vcol <- function(x, table) {
  # determine what the regular `%in%` would say
  ret <- base::`%in%`(x, table)

  # for virtual columns, check the applicable attribute
  # for all "non-applicable" values, return NA
  if(inherits(x, "vtree_vcol")) {
    applicable <- attr(x, "applicable")
    ret[!applicable] <- NA
  }

  ret
}

# this is the function that actually evaluates the condition in the context
# of the virtual data frame
.get_mask <- function(vtree, condition) {

  # we need these cols to be able to naturally evaluate the condition using
  # data vars
  nodes <- as_tibble(vtree)

  # here the virtual columns are constructed
  vcols <- .add_virt_cols(nodes)

  # rather than passing vcols as the argument to eval_tidy, we construct
  # the data mask explicitly
  data_mask <- rlang::as_data_mask(vcols)

  # and replace is.na and %in% in that data mask
  # (a data mask is the environment in which the condition is evaluated).
  rlang::env_poke(data_mask, "%in%", in_vtree_vcol)

  # is_na_vtree_col is a similar solution: first get the regular is.na to
  # do the work, and then for all non-applicable values replace them with
  # NA
  rlang::env_poke(data_mask, "is.na", is_na_vtree_vcol)

  # here we create the pruning mask
  mask <- eval_tidy(condition, data = data_mask)

  # some more checks etc.
  # look into prune.R to find out
  # ...
}
```

#### 4.3.2 Tidy selection

Where the parameter of a function calls for columns of a data frame, we
use the tidy select syntax. Note that tidy select and tidy evaluation
are related and similar, but different.

``` r
myselect <- function(df, cols) {

  # again, we defuse the cols parameter
  cols <- rlang::enquo(cols)
  cols <- tidyselect::eval_select(cols, data=df)

  # cols is now an integer vector, values correspond to column positions in
  # the df data frame, and names correspond to the selected column names

  df[ , cols ]
}

myselect(titanicNA, Class:Age) |> head()
#> # A tibble: 6 × 3
#>   Class Sex   Age  
#>   <fct> <fct> <fct>
#> 1 3rd   Male  Child
#> 2 3rd   Male  Child
#> 3 3rd   NA    Child
#> 4 3rd   Male  Child
#> 5 3rd   Male  Child
#> 6 NA    NA    Child
```

Now cols can be any tidy select expression, like `-Age`, `Class:Sex`,
`all_of(c("Age", "Class"))` etc. However, in the above function, this
still needs to be one single argument, so you can’t do
`myselect(titanicNA, Class, Age)`. To interpret the arguments from the
ellipsis (`...`), following code can be used:

``` r
myselect2 <- function(df, ...) {

  # again, we defuse the ... parameter
  # note that now we use enquos (plural!)
  cols <- rlang::enquos(...)

  # eval_select requires just one argument, but cols can have many - we
  # need to construct a defused expression. The `!!!` means we are
  # injecting all arguments from cols into c(), then all this is defused
  # by expr
  cols <- rlang::expr(c(!!!cols))

  # now we can eval_select this thing
  cols <- tidyselect::eval_select(cols, data=df)

  # cols is now an integer vector, values correspond to column positions in
  # the df data frame, and names correspond to the selected column names

  df[ , cols ]
}

myselect(titanicNA, Class:Age) |> head()
#> # A tibble: 6 × 3
#>   Class Sex   Age  
#>   <fct> <fct> <fct>
#> 1 3rd   Male  Child
#> 2 3rd   Male  Child
#> 3 3rd   NA    Child
#> 4 3rd   Male  Child
#> 5 3rd   Male  Child
#> 6 NA    NA    Child
```

The [`vtree()`](https://january3.github.io/vtree2/reference/vtree.md)
function, however, features a more sophisticated mechanism. Before the
`eval_select()`, the `...` arguments are split into those which are
named and those which are not:

``` r
dots <- rlang::enquos(...)
dotnames <- names(dots)

# these args have no names
is_deriv <- nzchar(dotnames)

# they will be used in eval_select
dots_tidysel <- dots[!is_deriv]
```

Now these which are not named are passed on to `eval_select()` just like
in the example above:

``` r
# just as in the above example for myselect2
cols <- tidyselect::eval_select(
  rlang::expr(c(!!!dots_tidysel)),
  data = cases
)

cnms_ts <- names(cols)
```

However, arguments which are named are treated as an expression to be
evaluated with
[`rlang::eval_tidy`](https://rlang.r-lib.org/reference/eval_tidy.html),
and the result will be injected in the `cases` data frame creating a new
column. The purpose of this is to be able to create and rename columns
on the fly:

``` r
for (i in which(is_deriv)) {
  cases[[dotnames[[i]]]] <- rlang::eval_tidy(
    dots[[i]],
    data = cases
  )
}

cnms_deriv <- dotnames[is_deriv]
```

After that, it is necessary to reorder the `cnms_ts` and `cnms_deriv`
such that the arguments are in the same order as in `dotnames`, but that
is simply done.
