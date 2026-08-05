library(grid)
library(gridtext)

# get widths from a list of grobs
.get_widths <- function(grobs) {
    purrr::map_dbl(grobs, \(g)
      convertWidth(grobWidth(g), "npc", valueOnly = TRUE))
}


text <- c("woooooo<br>booooo--------------", "pupa")
grid.newpage()
g <- richtext_grob(text, name = "dupa", gp = gpar(fontsize = 40, col = "red"),
                   x = c(0.25, .75), y = 0.5, hjust = 0.5, vjust = 0.5)
grid.draw(g)
convertWidth(grobWidth(g), "npc", valueOnly = TRUE)

t <- textGrob(text, name = "dupa", gp = gpar(fontsize = 40, col = "red"), x = 0.5, y = 0.5, hjust = 0.5, vjust = 0.5)
t <- editGrob(t, gp = gpar(fontsize = 20, col = "blue"))
grid.draw(t)
grid.edit(gPath("dupa"), gp = gpar(fontsize = 20, col = "blue"))

w <- .get_widths(list(g))[[1]]
w
grid.edit(gPath("dupa"), gp = gpar(fontsize = 20, col = "blue"))

w <- .get_widths(list(g))[[1]]
w
box <- rectGrob(x = .5, y = .5, height = w, width = w, gp = gpar(fill = NA, col = "blue", lwd = 2))
grid.draw(box)

