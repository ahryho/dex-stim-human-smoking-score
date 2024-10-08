# For more infromation, please refer to 
# https://htmlpreview.github.io/?https://github.com/sailalithabollepalli/EpiSmokEr/blob/master/vignettes/epismoker.html#installation

library(devtools)
install_github("sailalithabollepalli/EpiSmokEr")

library(Epi0SmokEr)
library(dplyr)

source("02_epigenetic_smoking_score_estimation_binderCode.R") # Illig paper
# Set up variables

mgp.dir.pre  <- "/binder/mgp/datasets/2020_DexStim_Array_Human/methylation/"
src.data.pre <- "/binder/mgp/datasets/2020_DexStim_Array_Human/methylation/10_final_qc_data/"
beta.mtrx.fn <- "dex_methyl_qn_beta_mtrx.rds" # "dex_methyl_bmiq_quantileN.rds" # "dex_methyl_bmiq_beta_mtrx.rds" # "dex_methyl_beta_combat_mtrx.rds"

# Load normalized beta matrix and samplesheet

beta.mtrx   <- readRDS(paste0(src.data.pre, beta.mtrx.fn))
samplesheet <- read.csv(paste0("/binder/mgp/datasets/2020_DexStim_Array_Human/methylation/00_sample_sheets/", "pheno_with_pcs.csv"), sep = ";", header = T)

# Mapping table Individual - Sample_Name

sample.map.tbl <- samplesheet[, c("Individual", "Sample_Name")]

# Take only baseline (veh)

samplesheet <- samplesheet[samplesheet$Group == "veh", ]
beta.mtrx   <- beta.mtrx[, colnames(beta.mtrx) %in% samplesheet$Sample_Name]

# Adjust gender format: of 1 and 2 representing men and women respectively

colnames(samplesheet)[4] <- "sex"
samplesheet$sex[samplesheet$sex == "M"] <- 1
samplesheet$sex[samplesheet$sex == "W"] <- 2

# Rownames of samplesheet must be equivalent to column names of methylation dataset

rownames(samplesheet) <- samplesheet$Sample_Name

# Calculate smoking scores 

epismoke.score.df <- epismoker(dataset = beta.mtrx, samplesheet = samplesheet, method = "all")

score.df <- epismoke.score.df[c("SampleName", "smokingScore", "methylationScore", "PredictedSmokingStatus")] 

colnames(score.df) <- c("SampleName", "smokingScoreElliott", "smokingScoreZhang", "PredictedSmokingStatus")


# Calculate smoking score based oc CpGs from Illig paper
smoking.illig <- SmokingScoreIllig(beta.mtrx)
score.df      <- left_join(score.df, smoking.illig)

# Merge with original samplesheet
score.df <- left_join(score.df, sample.map.tbl, by = c("SampleName" = "Sample_Name"))
score.df <- inner_join(score.df, sample.map.tbl) 
score.df <- score.df[c("Sample_Name", "Individual", "smokingScoreElliott", "smokingScoreIllig", "smokingScoreZhang", "PredictedSmokingStatus")]

write.csv2(score.df, 
          paste0(mgp.dir.pre, "30_Epigenetic_Smoking_Score/", "smoking_score_DexStim_EPIC_2020_QN.csv"), 
          quote = F, row.names = F)
