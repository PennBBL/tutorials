# input variables
lin.mod<-commandArgs(T)[1]
data<-read.csv(commandArgs(T)[2]) # data file with demographic stuff
file=commandArgs(T)[3] # output name
gmc=commandArgs(T)[4] # 1 or leave empty for gray matter covariate

# this is important. removes quotes from linear model string.
# quotes are need to get the variable into R as a string for some reason.
lin.mod<-gsub('\\"', '', lin.mod)	

dir.create(file, showWarnings=FALSE)
# check if subject list is shorter than one that was specified
# if it is make a subject list file for subjects in this model
vars = sapply(strsplit(lin.mod, "[+~]"), gsub, pattern="^\\s+|\\s+$", replacement="")
data = data[complete.cases(data[, names(data) %in% vars]),]
write.table(paste(data$bblid, data$datexscanid, sep="/"), file.path(file, 'subjlist.txt'), quote=F, row.names=F, col.names=F)
X<-model.matrix( as.formula(lin.mod) , data=data)

library(R.matlab)
writeMat(file.path(file, 'X.mat'), X=X) # matlab file for design matrix.
cat(colnames(X), '\n', sep=' ', file=file.path(file, 'design_colnames.txt')) # this is for us, just so we can see what is what for contrasts

# for contrasts
cnames<-colnames(X)
vars<-gsub(" ", "", gsub('\\~', '', unlist(strsplit(lin.mod, split='\\+'))))
print(cnames)
print(vars)
if(vars=="1" & cnames=="(Intercept)"){
	cmat = 1
	filet<-file.path(file, 'contrast1.mat')
	write.table(cmat, file=filet, row.names=FALSE, col.names=FALSE, quote=FALSE, append=FALSE)
	quit()
}
for(curvar in vars){
	cols<-grep(paste("^", curvar, "[a-z0-9A-Z\\-]*$", sep=''), cnames)
	cmat<-rep(0, ncol(X) )
	if(length(cols)>1){
		cmat[cols[1]]<-(-1)
		cmat<-t(cbind(cmat, sapply(2:length(cols), function(x){cmat2<-rep(0, ncol(X));
						cmat2[cols[(x-1):x]]<-c(1, -1);
						cmat2
						})
				))
	
	# for all pairwise contrasts-- will do contrasts of all factors-- only relevant for factors
	cmat2<-rbind(matrix(0, ncol=ncol(X), nrow=length(cols)), cmat[-1,])
	cmat2[cbind(1:length(cols),cols)]<-1
	rows2sum<-length(cols)+1:(length(cols)-1)
	seques<-expand.grid(rows2sum, rows2sum)
	seques<-seques[,2:1]
	seques<-seques[ -which(seques[,1]==seques[2]),]
	if(nrow(seques)!=0){
		seques<-seques[ !duplicated(cbind(apply(seques, 1, min), apply(seques, 1, max))),]
		cmat2<-rbind(cmat2, t(apply(seques, 1, function(x){ colSums(cmat2[x[1]:x[2],]) }) ))
	}

	for(curcon in 1:nrow(cmat2)){
		filet<-file.path(file, paste('contrast',which(vars %in% curvar), '_',curcon ,'.mat', sep=''))
		write.table(cmat2[curcon,,drop=FALSE], file=filet, row.names=FALSE, col.names=FALSE, quote=FALSE, append=FALSE)
	}

	}else{
		cmat[cols[1]]<-1
		cmat<-matrix(cmat, nrow=1)
	}
	filet<-file.path(file, paste('contrast',which(vars %in% curvar) ,'.mat', sep=''))
	write.table(cmat, file=filet, row.names=FALSE, col.names=FALSE, quote=FALSE, append=FALSE)
	
} 
