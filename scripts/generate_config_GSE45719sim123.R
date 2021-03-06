suppressPackageStartupMessages(library(rjson))

## Generate configuration file
L <- list(mae = "data/GSE45719sim123.rds", 
          subfile = "subsets/GSE45719sim123_subsets.rds",
          resfilebase = "results/GSE45719sim123",
          figfilebase = "figures/diffexpression/GSE45719sim123", 
          truthfile = "data/GSE45719sim123_truth.rds",
          groupid = "group", 
          keepgroups = c("16-cell stage blastomere",
                         "Mid blastocyst cell (92-94h post-fertilization)"), 
          seed = 42, 
          sizes = c(50, 24, 12, 6), 
          nreps = c(1, 5, 5, 5))
write(toJSON(L), file = "config/GSE45719sim123.json")
