#############################
## Load Relevant Libraries ##
#############################
require(ggplot2)
require(mgcv)
require(visreg)
require(RLRsim)

##########################################################
## Define sample of participants with CNB factor scores ##
##########################################################

## Load in csv with demographics, structural brain network and cognitive measures
n882_net_df <- read.csv("/data/joy/BBL/tutorials/exampleData/gam/Baum_currBiol_n882_cog_structNet_20171212.csv")

## Define appropriate variable classes
n882_net_df$Sex <- as.ordered(as.factor(n882_net_df$Sex)) # in order to fit interaction term in GAM, factor must be ordered
n882_net_df$F1_Complex_Reasoning_Efficiency <- as.numeric(as.character(n882_net_df$F1_Complex_Reasoning_Efficiency))
n882_net_df$F2_Memory_Efficiency <- as.numeric(as.character(n882_net_df$F2_Memory_Efficiency))
n882_net_df$F3_Executive_Efficiency <- as.numeric(as.character(n882_net_df$F3_Executive_Efficiency))
n882_net_df$F4_Social_Cognition_Efficiency <- as.numeric(as.character(n882_net_df$F4_Social_Cognition_Efficiency))

#################################################
## Remove subjects with missing cognitive data ##
#################################################
n880_cog_df <- n882_net_df[!is.na(n882_net_df$F3_Executive_Efficiency),]

####################################
## Examine data for non-linearity ##
####################################
model<-gamm(F3_Executive_Efficiency~s(age_in_yrs)+Sex, data=n880_cog_df)
exactRLRT(model$lme, nsim=10000)

#############################################################
## Fit GAM to estimate Age effects on Executive Efficiency ##
#############################################################
ExecEff_Age_gam <- gam(F3_Executive_Efficiency ~ s(age_in_yrs, k=4) + Sex, method="REML", data = n880_cog_df)

#####################
## Look at results ##
#####################
summary(ExecEff_Age_gam)

## Nonlinear age effect
Age_pval <- summary(ExecEff_Age_gam)$s.table[1,4]
Age_pval

####################################
## Visualize Nonlinear Age Effect ##
####################################
plotdata <- visreg(ExecEff_Age_gam,'age_in_yrs',type = "conditional",scale = "linear", plot = FALSE)
smooths <- data.frame(Variable = plotdata$meta$x, 
                      x=plotdata$fit[[plotdata$meta$x]], 
                      smooth=plotdata$fit$visregFit, 
                      lower=plotdata$fit$visregLwr, 
                      upper=plotdata$fit$visregUpr)
predicts <- data.frame(Variable = "dim1", 
                       x=plotdata$res$age,
                       y=plotdata$res$visregRes)

ExecEff_Age_plot <- ggplot() +
  geom_point(data = predicts, aes(x, y), colour = "darksalmon", alpha=0.7, size = 1.6 ) +
  geom_line(data = smooths, aes(x = x, y = smooth), colour = "midnightblue",size=2) +
  geom_line(data = smooths, aes(x = x, y=lower), linetype="dashed", colour = "midnightblue", alpha = 0.9, size = 0.9) + 
  geom_line(data = smooths, aes(x = x, y=upper), linetype="dashed",colour = "midnightblue", alpha = 0.9, size = 0.9) +
  theme(legend.position = "none") +
  labs(x = "Age (years)", y = "Executive Efficiency (z-score)") +
  theme(axis.title.x = element_text(size = rel(1.6))) +
  theme(axis.title.y = element_text(size = rel(1.6))) + 
  theme(axis.text = element_text(size = rel(1.4))) + theme(axis.line = element_line(colour = 'black', size = 1.5), axis.ticks.length = unit(.25, "cm")) +
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(), panel.background = element_blank())

dev.off()

## Export image
png(filename="/data/joy/BBL/tutorials/exampleData/gam/ExecEfficiency_Age_GAM_fit.png")
ExecEff_Age_plot
dev.off()

#############################################
## Fit GAM to estimate Age*Sex interaction ##
#############################################

# Note again that Sex must me an *ordered* factor
ExecEff_AgeSex_gam <- gam(F3_Executive_Efficiency ~ s(age_in_yrs, k=4)+ s(age_in_yrs, by=Sex, k=4) + Sex, method="REML", data = n880_cog_df)

#####################
## Look at results ##
#####################
summary(ExecEff_AgeSex_gam)$s.table
