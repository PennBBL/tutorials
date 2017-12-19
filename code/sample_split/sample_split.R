## Cedric Huchuan Xia ##
## Dec 13 2017 ##

## Sample Split using CARET ##
require('caret')
set.seed(1234)
toydata <- read.csv('/data/joy/BBL/tutorials/exampleData/sample_split/sample_split_data.csv')
sample_1_index <- createDataPartition(toydata$overall_psychopathology_4factor, p = 0.667, list =F,times=1)
sample_1 <- toydata[sample_1_index,]
sample_2 <- toydata[-sample_1_index,]
print(paste0('dimension of sample 1 is',dim(sample_1)))
print(paste0('dimension of sample 2 is',dim(sample_2)))
#hist(sample_1$overaloverall_psychopathology_4factor)
#hist(sample_2$overaloverall_psychopathology_4factor)