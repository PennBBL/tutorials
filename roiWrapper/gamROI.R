##############################################################################
################                                               ###############
################                GAM ROI Wrapper                ###############
################           Angel Garcia de la Garza            ###############
################              angelgar@upenn.edu               ###############
################                 05/02/2017                    ###############
##############################################################################

suppressMessages(require(optparse))

##############################################################################
################                 Option List                   ###############
##############################################################################


option_list = list(
  make_option(c("-c", "--covariates"), action="store", default=NA, type='character',
              help="Full path to RDS covariate file."),
  make_option(c("-o", "--output"), action="store", default=NA, type='character',
              help="Full path to output directory"), 
  make_option(c("-p", "--inputpaths"), action="store", default=NA, type='character',
              help="Path to the input dataset to be analyzed.
              It must contain those id columns first.
              Must only contain those columns to be analyzed"), 
  make_option(c("-i", "--inclusion"), action="store", default=NA, type='character',
              help="Name of inclusion variable on dataset. By default 1 means include. 
              This will subset your rds file"),
  make_option(c("-u", "--subjId"), action="store", default=NA, type='character',
              help="subjID name on the covariates dataset to merge covariates and input dataset.
              If merging by more than one subjID please separate by a comma 'bblid,scanid'"), 
  make_option(c("-f", "--formula"), action="store", default=NA, type='character',
              help="Formula for covariates to be used, should only include the right hand side of the formula.
              Example: ~ stai_stai_tr+sex+s(age)+s(age,by=sex)"),
  make_option(c("-a", "--padjust"), action="store", default="none", type='character',
              help="method used to adjust pvalues, default is `none`"),
  make_option(c("-r", "--residual"), action="store", default=FALSE, type='logical',
              help="Option to output residual 4D image.
              Default (FALSE) means to not generate residual maps"),
  make_option(c("-n", "--numbercores"), action="store", default=10, type='numeric',
              help="Number of cores to be used, default is 10")
  )

opt = parse_args(OptionParser(option_list=option_list))

for (i in 1:length(opt)){
  if (is.na(opt)[i] == T) {
    cat('User did not specify all arguments.\n')
    cat('Use gamROI.R -h for an expanded usage menu.\n')
    quit()
  }
}


print("##############################################################################")
print("################                 GAM ROI Script                ###############")
print("################            Angel Garcia de la Garza           ###############")
print("################              angelgar@upenn.edu               ###############")
print("################                 Version 3.0.1                 ###############")
print("##############################################################################")

##############################################################################
################                  Load Libraries               ###############
##############################################################################

print("Loading Libraries")

suppressMessages(require(ggplot2))
suppressMessages(require(base))
suppressMessages(require(reshape2))
suppressMessages(require(nlme))
suppressMessages(require(lme4))
suppressMessages(require(gamm4))
suppressMessages(require(stats))
suppressMessages(require(knitr))
suppressMessages(require(mgcv))
suppressMessages(require(plyr))
suppressMessages(require(oro.nifti))
suppressMessages(require(parallel))
suppressMessages(require(optparse))
suppressMessages(require(fslr))
suppressMessages(require(voxel))



##############################################################################
################              Declare Variables               ###############
##############################################################################

print("Reading Arguments")

subjDataName <- opt$covariates
OutDirRoot <- opt$output
inputPath <- opt$inputpaths
inclusionName <- opt$inclusion
subjID <- opt$subjId
covsFormula <- opt$formula
pAdjustMethod <- opt$padjust
ncores <- opt$numbercores
residualMap <- opt$residual


methods <- c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY","fdr", "none")
if (!any(pAdjustMethod == methods)) {
  print("p.adjust.method is not a valid one, reverting back to 'none'")
  pAdjustMethod <- "none"
}

##############################################################################
################         Load covariates data                  ###############
##############################################################################

print("Loading covariates file")
covaData<-readRDS(subjDataName) ##Read Data
subset <- which(covaData[inclusionName] == 1) ##Find subset for analysis
covaData <- covaData[subset, ] #subset data


##############################################################################
################         Load and merge input dataset          ###############
##############################################################################

print("Loading input dataset")
subjID <- unlist(strsplit(subjID, ","))
inputData <- read.csv(inputPath)
dataSubj <- merge(covaData, inputData, by=subjID)


##############################################################################
################    Create Analysis Directory                  ###############
##############################################################################

print("Creating Analysis Directory")

subjDataOut <- strsplit(subjDataName, ".rds")[[1]][[1]]
subjDataOut <- strsplit(subjDataOut, "/")[[1]][[length(subjDataOut <- strsplit(subjDataOut, "/")[[1]])]]

inputPathOut <- strsplit(inputPath, ".csv")[[1]][[1]]
inputPathOut <- strsplit(inputPathOut, "/")[[1]][[length(inputPathOut <- strsplit(inputPathOut, "/")[[1]])]]

OutDir <- paste0(OutDirRoot, "/n",dim(dataSubj)[1],"_rds_",subjDataOut,"_inclusion_",inclusionName,"_ROI_",inputPathOut)
dir.create(OutDir)
setwd(OutDir)


print("Creating output directory")
outName <- gsub("~", "", covsFormula)
outName <- gsub(" ", "", outName)
outName <- gsub("\\+","_",outName)
outName <- gsub("\\(","",outName)
outName <- gsub("\\)","",outName)
outName <- gsub(",","",outName)
outName <- gsub("\\.","",outName)
outName <- gsub("=","",outName)
outName <- gsub("\\*","and",outName)
outName <- gsub(":","and",outName)

outsubDir <- paste0("gam_formula_",outName)
outsubDir<-paste(OutDir,outsubDir,sep="/")

##############################################################################
################         Execute Models on ROI Dataset         ###############
##############################################################################


print("Analyzing Dataset")

model.formula <- mclapply((dim(covaData)[2] + 1):dim(dataSubj)[2], function(x) {
  
  as.formula(paste(paste0(names(dataSubj)[x]), covsFormula, sep=""))
  
}, mc.cores=ncores)

m <- mclapply(model.formula, function(x) {
  
  foo <- gam(formula = x, data=dataSubj, method="REML")
  summary <- summary(foo)
  residuals <- foo$residuals
  missing <- as.numeric(foo$na.action)
  return(list(summary,residuals, missing))
  
}, mc.cores=ncores)

##############################################################################
################           Generate Residual Dataset           ###############
##############################################################################



if (residualMap) {
  
  print("Generating residuals")
  resiData <- dataSubj
  ids.index <- which(names(resiData) == subjID)
  resiData <- resiData[,ids.index]
  
  for (i in 1:length(m)) {
    
    resiData[, dim(resiData)[2] + 1] <- NA
    resiData[-m[[i]][[3]], dim(resiData)[2]] <- m[[i]][[2]] 
    
  }
  
  names(resiData)[(length(ids.index) + 1):dim(resiData)[2]] <- names(inputData)[-which(names(inputData) == subjID)]
  
  write.csv(resiData, paste0(outsubDir, "_residual.csv"), row.names=F)
}



##############################################################################
################           Generate parameter dataset          ###############
##############################################################################


print("Generating parameters")
## Pull only the first object in list of models (only summary)
m <- mclapply(m, function(x) {
  x[[1]]
}, mc.cores=ncores)


## This code generates a table for the p.table object in gam 
length.names.p <- length(rownames(m[[1]]$p.table))                 

output <- as.data.frame(matrix(NA, 
                               nrow = length((dim(covaData)[2] + 1):dim(dataSubj)[2]), 
                               ncol= (1+3*length.names.p)))

names(output)[1] <- "names"

#For each row in the p.table (for each parameter)
for (i in 1:length.names.p) {
  
  dep.val <- rownames(m[[1]]$p.table)[i]
  names(output)[2 + (i-1)*3 ] <- paste0("tval.",dep.val)
  names(output)[3 + (i-1)*3 ] <- paste0("pval.",dep.val)
  names(output)[4 + (i-1)*3 ] <- paste0("pval.",pAdjustMethod,dep.val)
  
  val.tp <- t(mcmapply(function(x) {
    x$p.table[which(rownames(x$p.table) == dep.val), 3:4]
  }, m, mc.cores=ncores))
  
  output[,(2 + (i-1)*3):(3 + (i-1)*3)] <- val.tp
  output[,(4 + (i-1)*3)] <- p.adjust(output[,(3 + (i-1)*3)], pAdjustMethod)
  
}

output$names <- names(dataSubj)[(dim(covaData)[2] + 1):dim(dataSubj)[2]]
p.output <- output

## If there's a s.table then do the same, merge both datasets and output
## Otherwise just output the p.table dataset (there are no splines in model)

if (is.null(m[[1]]$s.table)) {
  
  write.csv(p.output, paste0(outsubDir, "_coefficients.csv"), row.names=F)
  
} else {
  
  length.names.s <- length(rownames(m[[1]]$s.table))
  output <- as.data.frame(matrix(NA, 
                                 nrow = length((dim(covaData)[2] + 1):dim(dataSubj)[2]), 
                                 ncol= (1+2*length.names.s)))
  
  names(output)[1] <- "names"
  
  for (i in 1:length.names.s) {
    
    dep.val <- rownames(m[[1]]$s.table)[i]
    names(output)[2 + (i-1)*2 ] <- paste0("pval.",dep.val)
    names(output)[3 + (i-1)*2 ] <- paste0("pval.",pAdjustMethod,dep.val)
    
    val.tp <- mcmapply(function(x) {
      x$s.table[which(rownames(x$s.table) == dep.val), 4]
    }, m, mc.cores=ncores)
    
    output[,(2 + (i-1)*2)] <- val.tp
    output[,(3 + (i-1)*2)] <- p.adjust(output[,(2 + (i-1)*2)], pAdjustMethod)
    
  }
  
  output$names <- names(dataSubj)[(dim(covaData)[2] + 1):dim(dataSubj)[2]]
  output <- merge(p.output, output, by="names")
  write.csv(output, paste0(outsubDir, "_coefficients.csv"), row.names=F)
  
}

print("Script Ran Succesfully")
