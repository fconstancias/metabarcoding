# dada2 installation 
# SCHRIEKE Hans 


  if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos = "http://cran.us.r-project.org")
BiocManager::install("dada2", version = "3.8")
