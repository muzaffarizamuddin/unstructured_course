install.packages("tm")
install.packages("wordcloud")
install.packages("httr")
install.packages("rvest")
install.packages("stringr")

library(tm)
library(wordcloud)
library(stringr)

data <- read.csv(file.choose(), fill=T, header=F) #this is for csv file
data <- read.table(file.choose(), fill=T, header=F) #this is for text file
data <- t(data)
data_1 <- sapply(1:ncol(data),function(x){
	trimws(paste(data[,x],collapse=" "),which="right")
})

str_view(data_1,"-") #check pattern
str_view(data_1,".ab.")
str_view(data_1,"/")
str_view(data_1,"'")
str_view(data_1,",")

#change to corpus
mytext<- VectorSource(data_1)
mycorpus <- VCorpus(mytext)

#inspect corpus
as.character(mycorpus[[3]])
for (i in 1:5){
	print(as.character(mycorpus[[i]]))
}
unname(sapply(mycorpus, as.character))

#Data cleaning 
toSpace <- content_transformer(function(x,pattern){ gsub(pattern, " ", x)})

docs_1 <- tm_map(mycorpus, toSpace,"-") #change all dash to space
docs_1 <- tm_map(docs_1, removePunctuation)
docs_1 <- tm_map(docs_1, content_transformer(tolower))
docs_1 <- tm_map(docs_1, removeNumbers)
docs_1 <- tm_map(docs_1, removeWords,stopwords("english"))
docs_1 <- tm_map(docs_1, removeWords,c('ayam'))
docs_1 <- tm_map(docs_1, stripWhitespace)


#inspect
as.character(docs_1[[2]])
unname(sapply(docs_1, as.character))
unname(sapply(docs_1, as.character))[3:5]

#------------Stemming---------
install.packages("SnowballC")
library(SnowballC)
docs_2 <- tm_map(docs_1, stemDocument)
inspect(docs_2)
unname(sapply(docs_2, as.character))

#------------Lemmatize--------
install.packages("textstem")
library(textstem)
docs_3 <- tm_map(docs_1, content_transformer(lemmatize_strings))
unname(sapply(docs_3, as.character))

#---------DTM-----
docs_3<-docs_2
dtm<- DocumentTermMatrix(docs_3)

dtm<-DocumentTermMatrix(docs_3,control=list(wordLengths=c(2,20),  #only words with 2-20 letters	
                         bounds=list(global=c(1,30))))#freq control


inspect(dtm)

freq<- colSums(as.matrix(dtm))
ord<-order(freq,decreasing=T)
freq[(ord)]

#build df
df<-data.frame(names(freq),freq)
names(df)<-c("TERM","FREQ")
df <- df[order(-df$FREQ),]#sort
head(df)

findFreqTerms(dtm,lowfreq=2) #find words with minimum frequency
findAssocs(dtm,"napoleon",0.1) #kaitan dgn perkataan lain


#plot
install.packages('ggplot2')
library(ggplot2)
Subs<- subset(df,FREQ>=2) #how to filter freq
ggplot(Subs, aes(x=reorder(TERM,-FREQ),y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1, vjust=0.5))+
	ggtitle("Document term Frequency")+
	xlab("Terms")
	ylab("Frequency")

library(wordcloud)
wordcloud(names(freq),freq, min.freq=1) #in general
wordcloud(names(freq),freq.min.freq=10) #if we want to focus on the min freq of 10
wordcloud(names(freq),freq,colors=brewer.pal(8,"Dark2"))
wordcloud(names(freq),freq,colors=brewer.pal(12,"Paired"))

display.brewer.all()
wordcloud(names(freq),freq,colors=brewer.pal(12,"Spectral"))
wordcloud(names(freq),freq,colors=brewer.pal(12,"BrBG"))

install.packages("wordcloud2")
library(wordcloud2)
wordcloud2(df)
wordcloud2(df,size=0.5)
wordcloud2(df,size=0.5,color="random-light",backgroundColor="black")
wordcloud2(df,shape="star",size=0.5)
wordcloud2(df,shape="horse",size=0.5)
wordcloud2(df,figPath="love.png",color="skyblue",backgroundColor="black") #follow a specified shape
#wordcloud2(df,figPath="cat.png",color="skyblue",backgroundColor="black")
























