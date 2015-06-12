library('DoE.base')
z1<-c(0,1,2) #(0:2)
z2<-c(0,1,2) #(0:2)
z3<-c(0,1,2) #(0:2)
z4<-c(0,1,2) #(0:2)
z5<-c(0,1,2) #(0:2)
z6<-c(0,1,2) #(0:2)
o5<-c(0,1,2) #(0:2)
population<-c(11000,13000)
oaTable<-oa.design(
	factor.names=list(z1=z1,z2=z2,z3=z3,z4=z4,z5=z5,z6=z6,o5=o5),
	seed=1
	)
# population<-c(70,500,1000,1500,2000,2500,5000,7500,10000)
# population<-c(3000,4000,6000,7000,8000,9000)
pop_frame <- data.frame(population=population)
write.csv(merge(oaTable, pop_frame), "oaTable_18x9_2.csv", quote=F, row.names=F)
# write.csv(oaTable, "oaTable_test.csv", quote=F, row.names=F)