library('DoE.base')
# for( i in 1:10){
#     assign(paste("x", i, sep=""), c(0,1,2))
# }

# for( i in 1:10){
#     print(get(paste("x", i, sep="")))
# }

# z1<-c(0,1) #(0:2)
# z2<-c(0,1) #(0:2)
# z3<-c(0,1) #(0:2)
# z4<-c(0,1) #(0:2)
# z5<-c(0,1) #(0:2)
# z6<-c(0,1) #(0:2)
# z7<-c(0,1) #(0:2)
# z8<-c(0,1) #(0:2)
# z9<-c(0,1) #(0:2)
# z10<-c(0,1) #(0:2)
# z11<-c(0,1) #(0:2)
# z12<-c(0,1) #(0:2)
# z13<-c(0,1) #(0:2)
# z14<-c(0,1) #(0:2)
# z15<-c(0,1) #(0:2)
# z16<-c(0,1) #(0:2)
# z17<-c(0,1) #(0:2)
# z18<-c(0,1) #(0:2)
# z19<-c(0,1) #(0:2)
# z20<-c(0,1) #(0:2)
# z21<-c(0,1) #(0:2)
# z22<-c(0,1) #(0:2)

# oaTable<-oa.design(
# 	factor.names=list(
# 		z1=z1,z2=z2,z3=z3,z4=z4,z5=z5,z6=z6,z7=z7,z8=z8,z9=z9,z10=z10,z11=z11,
# 		z12=z12,z13=z13,z14=z14,z15=z15,z16=z16,z17=z17,z18=z18,z19=z19,z20=z20,
# 		z21=z21,z22=z22
# 		),
# 	seed=1
# 	)
# oaTable


# q("no")

z1<-c(0,1,2) #(0:2)
z2<-c(0,1,2) #(0:2)
z3<-c(0,1,2) #(0:2)
z4<-c(0,1,2) #(0:2)
z5<-c(0,1,2) #(0:2)
z6<-c(0,1,2) #(0:2)
o5<-c(0,1,2) #(0:2)
population<-c(5000,7500)
oaTable<-oa.design(
	factor.names=list(z1=z1,z2=z2,z3=z3,z4=z4,z5=z5,z6=z6,o5=o5),
	seed=1
	)
oaTable
# population<-c(70,500,1000,1500,2000,2500,5000,7500,10000)
# population<-c(3000,4000,6000,7000,8000,9000)
# pop_frame <- data.frame(population=population)
# write.csv(merge(oaTable, pop_frame), "oaTable_18x9_2.csv", quote=F, row.names=F)
write.csv(oaTable, "oaTable_test.csv", quote=F, row.names=F)