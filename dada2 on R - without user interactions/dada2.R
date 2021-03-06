# DADA2 


# Prerequies : 
# R 3.5.0 or more 

# Load dada2
library(dada2); packageVersion("dada2")


# Assign data path 
path <- "/gs7k1/home/schrieke/Fastq"
setwd(path)
files <- list.files(path)
print(files)
  

# Store forward and reverse reads 
forward <- sort(list.files(path, pattern="_R1_001.fastq.gz", full.names = TRUE))
reverse <- sort(list.files(path, pattern="_R2_001.fastq.gz", full.names = TRUE))


# Store sample names 
sample.names <- sapply(strsplit(basename(forward), "_"), `[`, 1) 


# Reads quality profil to know where truncate
dir.create("plot")
path2 <- "/gs7k1/home/schrieke/Fastq/plot"
setwd(path2)

pdf("1-plotForward.pdf")
plotQualityProfile(forward, aggregate = TRUE) #forward reads
dev.off()

pdf("2-plotReverse.pdf")
plotQualityProfile(reverse, aggregate = TRUE) #reverse reads
dev.off()

setwd(path)

# Filter and trim
filtForward <- file.path(path, "filtered", paste0(sample.names, "_F_filt.fastq.gz"))
filtReverse <- file.path(path, "filtered", paste0(sample.names, "_R_filt.fastq.gz"))

out <- filterAndTrim(forward, filtForward, reverse, filtReverse, truncLen=c(0,240),
                     maxN=0, maxEE=c(2,2), truncQ=2, rm.phix=TRUE,
                     compress=TRUE, multithread=TRUE)
head(out)


# Learn the error rates
errForward <- learnErrors(filtForward, multithread=TRUE)
errReverse <- learnErrors(filtReverse, multithread=TRUE)

setwd(path2)
pdf("3-plotErrors")
plotErrors(errForward, nominalQ=TRUE)
dev.off()

setwd(path)

# Dereplication
derepForward <- derepFastq(filtForward, verbose=TRUE)
derepReverse <- derepFastq(filtReverse, verbose=TRUE)
# Name the derep-class objects by the sample names
names(derepForward) <- sample.names
names(derepReverse) <- sample.names


# Sample Inference
dadaForward <- dada(derepForward, err=errForward, multithread=TRUE)
dadaReverse <- dada(derepReverse, err=errReverse, multithread=TRUE)


# Merge paired reads
mergers <- mergePairs(dadaForward, derepForward, dadaReverse, derepReverse, verbose=TRUE)
# Inspect the merger data.frame from the first sample
head(mergers[[1]])
print("Reads merged.")


# Sequence table 
seqtab <- makeSequenceTable(mergers)
dim(seqtab)
# Inspect distribution of sequence lengths
table(nchar(getSequences(seqtab)))


# Remove chimeras
seqtab.nochim <- removeBimeraDenovo(seqtab, method="consensus", multithread=TRUE, verbose=TRUE)
dim(seqtab.nochim)
sum(seqtab.nochim)/sum(seqtab)
print("Chimeras removed.")


# Track reads through the pipeline
getN <- function(x) sum(getUniques(x))
track <- cbind(out, sapply(dadaForward, getN), sapply(dadaReverse, getN), sapply(mergers, getN), rowSums(seqtab.nochim))

colnames(track) <- c("input", "filtered", "denoisedF", "denoisedR", "merged", "nonchim")
rownames(track) <- sample.names
head(track)
#print(track)
write.table(track,"stats.csv",sep=";",dec=",") 
print("Stats done.")
print("A csv file has been created in your folder : stats.csv")



# Assign taxonomy
# taxa <- assignTaxonomy(seqtab.nochim, "C:/Users/U117-F435/Desktop/silva_nr_v132_train_set.fa.gz", multithread=FALSE)
taxa <- assignTaxonomy(seqtab.nochim, "~/Fastq/silva_nr_v132_train_set.fa.gz", multithread=TRUE)
taxa <- addSpecies(taxa, "~/Fastq/silva_species_assignment_v132.fa.gz")

taxa.print <- taxa # Removing sequence rownames for display only
rownames(taxa.print) <- NULL
head(taxa.print)
#print(taxa)

print ("Taxonomy done.")
