# #install.packages("qgraph")
# install.packages("psych")
library(psych)
cw<-read.csv("out_result.csv")
sel<-data.frame(cw[1:7],cw[14],cw[16],cw[18])
z<-cor(sel)

print(z)
cor.plot(z)



# # install.package("corrplot")
# library(corrplot)
# corrplot(z)
