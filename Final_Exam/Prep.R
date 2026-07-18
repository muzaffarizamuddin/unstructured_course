# Run once at the start of the exam
pkgs <- c("tm","wordcloud","wordcloud2","RColorBrewer","topicmodels","tidytext","tidyr","dplyr","ggplot2","proxy","dbscan","cluster","colorspace",
          "ggrepel","ape","syuzhet","stringr","SnowballC")
install.packages(pkgs)   # uncomment if a package is missinginvisible(lapply(pkgs, library, character.only = TRUE))


install.packages(c("rlang", "vctrs"))


unlink("C:/Users/PC03/AppData/Local/R/win-library/4.5/00LOCK", recursive = TRUE)
