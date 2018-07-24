library(ceg)
#df.orig <- read.csv("180112_BEST_EQ5D3L_ALLTIMEPOINTS.csv",stringsAsFactors = F)
df.orig <- read.csv("180112_BEST_EQ5D3L_ALLTIMEPOINTS_TX.csv", stringsAsFactors = F)


df <- df.orig[-which(df.orig==-99,arr.in=TRUE),]#remove 99s
df <- df[-which(is.na(df)==TRUE),]#remove incompletes
df[which(df==3,arr.ind = TRUE)]<- 2 #binned into any problems
df <- as.data.frame(lapply(df, factor))#factorized  
df <- CheckAndCleanData(df)
df0.wcode <- df[,c(2:6,22)] #initial time point
df3<- df[,c(7:11,22)] #3 month time point
df6<- df[,c(12:16,22)] #6 month time point
df12.wcode<- df[,c(17:21,22)] # 12 month time point

# ordering
ordering <- c(2,4,3,5,1)
df0.am <- df0.wcode[which(df0.wcode$randcode=="am"),ordering]
df0.amcbt <- df0.wcode[-which(df0.wcode$randcode=="am"),ordering]
df12.am <- df12.wcode[which(df12.wcode$randcode=="am"),ordering]
df12.amcbt <- df12.wcode[-which(df12.wcode$randcode=="am"),ordering]

#import Jane's code here
df0.am.sst <- jCEG.AHC(df0.am)
df0.amcbt.sst <- jCEG.AHC(df0.amcbt)

df0.am.sst$lik  
df0.amcbt.sst$lik
#several orders of magnitude off. damn. 

df12.am.sst <- jCEG.AHC(df12.am)
df12.amcbt.sst <- jCEG.AHC(df12.amcbt)

df12.amcbt.sst$pach- df0.amcbt.sst$pach
df12.am.sst$pach- df0.am.sst$pach

df12.am.sst$lik
df12.amcbt.sst$lik

