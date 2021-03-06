#install.packages("assertthat")
library(ggplot2)
library(reshape2)
library(scales)
library(assertthat)
library(plyr)
library(vegan)

x <- read.table("/home/sbi6dap/Projects/ACS/analysis/dpos/profile_TSS_heatmap/TSS_full_u.txt", header=TRUE)
x <- read.table("/home/sbi6dap/Projects/ALD/MNase-seq-80/RAWDATA/mean_ARA11_TSS.xls", header=TRUE, check.names = FALSE)
x <- read.table("/home/sbi6dap/Projects/ALD/MNase-seq-80/RAWDATA/mean_ARA11_TSS_heatmap/ES10_80.Fnor.smooth.wig.heatmap.xls-1nucl_align-full.txt", header=TRUE)

x <- read.table("/home/sbi6dap/Projects/AGM/MNaseseq/lt120/lt120_norm/WholeGenome_TSS_heatmap/Araport_AGM_filtered_isoforms.genepred.tss.AGM07_lt120.Fnor.smooth.wig.heatmap.xls", header=TRUE)

winsorize <-
  function(x, q=0.01)
  {
    assert_that(is.numeric(x))
    assert_that(is.number(q), q>=0, q<=1)
    
    lohi <- quantile(x, c(q, 1-q), na.rm=TRUE)
    if(diff(lohi) < 0) lohi <- rev(lohi)
    
    #x[!is.na(x) & x < lohi[1]] <- lohi[1]
    x[!is.na(x) & x > lohi[2]] <- lohi[2]
    x
  }

x.annots <- x[1:4]
rownames(x) <- x[,1]
x[,1] <- NULL           ### DO 4 TIMES UNTIL I WORK OUT HOW TO REPEAT!
x[,1] <- NULL           ### DO 4 TIMES UNTIL I WORK OUT HOW TO REPEAT!
x[,1] <- NULL           ### DO 4 TIMES UNTIL I WORK OUT HOW TO REPEAT!
x[,1] <- NULL           ### DO 4 TIMES UNTIL I WORK OUT HOW TO REPEAT!

x$name <-NULL
x.win <- x
x.win[, -1] <- sapply(x.win[,-1], winsorize)

#x.sub <- subset(x.win, , -c(c(1:3)))
x.dec <- decostand(x.win[100:201], 'range', MARGIN=1)

#x.samp <- x.dec[sample(row(x.dec), 1000),]
#summary(x.dec)
#head(x.dec, 10)

k <- kmeans(x.dec,8, iter.max=100)
x.k <- cbind(x.dec, cluster=k$cluster)

x.ksub <- ddply(x.k, .(cluster), subset, sample(seq_along(cluster)<=2000))
x.ksub2 <- na.omit(x.ksub)

#summary(x.ksub)
x.sort <- x.ksub2[order(x.ksub2[,103]),]        #### MUST CHANGE BASED ON COLUMN NUMBER
x.sort <- cbind(x.sort, "idsort"=1:nrow(x.sort))
#head(x.sort, 100)


## Output gene cluster names
x.genes <- subset(x.sort, , c(103:104))        ######### Loot at column number
rownames(x.sort) <- x.sort[,104]
x.annots <- x.k[103]
write.table(x.annots, file = "/home/sbi6dap/Projects/AGM/MNaseseq/AGM07-lt120clusters.txt")

x.melt <- melt(x.sort, id=c("cluster","idsort"))
#summary(x.melt)
#head(x.melt, 10)


ggplot(x.melt) + 
  geom_tile(aes(x=variable, y=idsort, fill=value)) +
  scale_fill_gradient2(low="white", high="black") +
  geom_vline(xintercept=50) +
  scale_x_discrete(breaks=c(0, 103, by=10)) +
  ggtitle("1kb span around TSS of <120bp bound particles (AGM07)")

### MDS 

x.dis <- vegdist(exp(x.samp))
x.mds0 <- monoMDS(x.dis)
stressplot(x.mds0, x.dis)
plot(x.mds, type = "p", xlim=c(-0.2,0.25), ylim=c(-0.2,0.3))

### kml based clustering
library("longitudinalData")
install.packages("kml")
install.packages("rgl")                           # sudo apt-get build-dep r-cran-rgl
library(rgl)
library(kml)


x.cld <- cld(x.samp)
x.kml <- kml(x.cld,nbRedrawing=3,toPlot="none")
plotAllCriterion(k.clust)
summary(x.cld)

X11(type="Xlib")

NMDS.scree<-function(x) { #where x is the name of the data frame variable
  plot(rep(1,10),replicate(10,metaMDS(x,autotransform=F,k=1)$stress/100),xlim=c(1,20),ylim=c(0,0.5),xlab="# of Dimensions",ylab="Stress",main="NMDS stress plot")
  for (i in 1:(nrow(x)-2)) {
    points(rep(i+1,10),replicate(10,metaMDS(x,autotransform=F,k=i+1)$stress/100))
  }
}
MDS.scree(x.samp)

x.gene <- x.dec["4704.AT5G36658",]
x.gene["gene"] <- rownames(x.gene)
x.genemelt <- melt(x.gene)
x.gene
p <- ggplot(x.genemelt, aes(x=as.factor(variable), y=value)) + theme(panel.grid.major = element_line(size = .5, color = "grey")) #+ coord_cartesian(ylim = c(0, 25), xlim = c(, 300))# + geom_vline(xintercept = 0, colour="blue", size = 2, linetype="dotted")
p + geom_ribbon(aes(ymin=0, ymax=1)) + labs(title = "At genome - All Data", x="Distance from 5'UTR modal peak", y="Nucleosome abundance count")


## Generate new dataframes from kmeans

cl <- split(x.k, x.k$cluster)
y6 <- cl[[6]]

y6$cluster <- NULL
ky <- kmeans(y6, 8)
y.k <- cbind(y6, cluster=ky$cluster)


#x.ksub <- ddply(x.k, .(cluster), subset, sample(seq_along(cluster)<=1000))
#x.ksub2 <- na.omit(x.ksub)

summary(y.k)
y.sort <- y.k[order(y.k[,301]),]
y.sort <- cbind(y.sort, "idsort"=1:nrow(y.sort))

y.genes <- subset(y.sort, , c(301:302))
#rownames(x.sort) <- x.sort[,302]
#x.x <- subset(x.sort, , -c(c(301:302)))

y.melt <- melt(y.sort, id=c("cluster","idsort"))
summary(y.melt)
#head(x.melt, 10)


ggplot(y.melt) + 
  geom_tile(aes(x=variable, y=idsort, fill=value)) + 
  scale_fill_gradient2(low="white", high="black") +
  geom_vline(xintercept=150, linetype = "longdash") +
  scale_x_discrete(breaks=c(0, 300, by=10)) + 
  theme(strip.background = element_blank(), strip.text = element_blank()) +
  facet_wrap(~cluster, ncol = 1, scales="free")

## Ward Hierarchical Clustering
d <- dist(y6, method = "euclidean") # distance matrix
fit <- hclust(d, method="ward") 
plot(fit) # display dendogram
groups2 <- cutree(fit, k=9) # cut tree into 5 clusters
rect.hclust(fit, k=9, border="red")
summary(fit, 5)

y6.h <- cbind(y6, groups=as.matrix(groups))
y6.h <- cbind(y6.h, order=fit$order)
y6.h$cluster <-NULL

y.sort <- y6.h[order(y6.h[,302]),]
y.melt <- melt(y.sort, id=c("order", "groups"))

head(y.melt, n=5)

ggplot(y.melt) + 
  geom_tile(aes(x=variable, y=order, fill=value)) + 
  scale_fill_gradient2(low="white", high="black") +
  geom_vline(xintercept=150) +
  scale_x_discrete(breaks=c(0, 300, by=10))
