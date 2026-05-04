## P166246 Muzaffar Izamuddin bin Daud
## Unstructured Test 1 Question 4

install.packages("tm")
install.packages("textstem")
install.packages("SnowballC")
install.packages("wordcloud2")
install.packages("wordcloud")
install.packages("stringr")

library(tm)
library(textstem)
library(SnowballC)
library(wordcloud)
library(wordcloud2)
library(stringr)

data <- read.csv(file.choose(),fill=T, header=F)
data<-t(data)
data<- sapply(1:ncol(data),function(x){
	trimws(paste(data[,x],collapse=""),which="right")
})
head(data)

#4a
str_view(data,"!")
#bread, me,lane, skill

#4b
str_view(data,"(.)\\1")

#4c
#we use boundary to denote word endings so things like called and danced shows up
str_view(data,"ed\\b")

#4d
data_1<-data
str_view(data_1,"\\bKeeper\\b")
data_teacher <- str_replace(data_1,"Keeper","Teacher")
str_view(data_teacher,"Teacher")

#4e
#to find location lets use grep
grep(pattern="squir",x=data) #this only shows the first squir in each line
#lets use gregexpr to also show all squir locations
gregexpr(pattern="squir",data)


#4f
str_count(data, "squirrel") #14 instances with lower case
str_count(data, "Squirrel") #1 instance with upper case

total_count = sum(str_count(data, "squirrel")) + sum(str_count(data, "Squirrel"))
print(total_count)