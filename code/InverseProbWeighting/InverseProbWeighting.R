#####################################
### INVERSE PROBABILITY WEIGHTING ###
#####################################

#Load example data
subjData <- readRDS("/data/joy/BBL/tutorials/code/InverseProbWeighting/ExampleDataForIPW.rds")

#Load library
library(mgcv)

#Run a logistic gam model with your covariates as predictors of your group variable
#Note: the group variable is typically coded as 0 = healthy control, 1 = patient
ps.model <- gam(group ~ s(age) + sex, family=binomial, method="REML", data=subjData)

#Get the predicted values from the gam model; type = "response" gives the predicted probabilities
subjData$ps.fits <- as.vector(predict(ps.model, type='response'))

#Calculate the predicted probability scores
#Note: Group has to be binary numeric (not a factor)
subjData$group <- as.numeric(subjData$group)
#Make healthy control = 0 and patient = 1 instead of 1s and 2s
subjData$group <- subjData$group - 1
#Predicted probability scores
subjData$ps.scores <- subjData$group*subjData$ps.fits + (1-subjData$group)*(1-subjData$ps.fits)

#Calculate the inverse probability weights
subjData$ipweights <- 1/subjData$ps.scores

#Make group a factor again
subjData$group <- as.factor(subjData$group)

#Save the data
saveRDS(subjData,"/data/joy/BBL/tutorials/code/InverseProbWeighting/DataWithWeights.rds")
