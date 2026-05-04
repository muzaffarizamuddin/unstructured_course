install.packages("tm")
install.packages("textstem")
install.packages("SnowballC")
install.packages("stringr")

library(tm)
library(textstem)
library(SnowballC)
library(stringr)

data <- read.csv(file.choose(), fill=T, header=F)
data<-t(data)
data_1 <- sapply(1:ncol(data), function(x){
	trimws(paste(data[,x],collapse=" "),which="right")
})

str_view(data_1,"muz")
str_view(data_1,"aisha")
str_view(data_1,"yusuf")
str_view(data_1,"liyana")
str_view(data_1,"-")
str_view(data_1,"/")
str_view(data_1,"&")

mytext <- VectorSource(data_1)
mycorpus <- VCorpus(mytext)
inspect(mycorpus)

unname(sapply(mycorpus[50],as.character))

for(i in 1:15){
	print(as.character(mycorpus[[i]]))
}

toSpace <- content_transformer(function(x,pattern){gsub(pattern, " ", x)})
docs <- tm_map(mycorpus, toSpace, "-")
docs <- tm_map(docs, toSpace, ":")
docs <- tm_map(docs, toSpace, "_")
docs <- tm_map(docs, toSpace, "\\\\\\\\")
docs <- tm_map(docs, toSpace, "\\#")
docs <- tm_map(docs, toSpace, "/")
docs <- tm_map(docs, toSpace, ">")
docs <- tm_map(docs, toSpace, "<")
docs <- tm_map(docs, toSpace, "\\*")
docs <- tm_map(docs, toSpace, "\n")
docs <- tm_map(docs, toSpace, '"')
docs <- tm_map(docs, toSpace, '\\{')
docs <- tm_map(docs, toSpace, '\\}')
docs <- tm_map(docs, toSpace, '"')
docs <- tm_map(docs, toSpace, '\t')
docs <- tm_map(docs, toSpace, '\\]')
docs <- tm_map(docs, toSpace, '\\[')
docs <- tm_map(docs, toSpace, '\\)')
docs <- tm_map(docs, toSpace, '\\(')
docs <- tm_map(docs, toSpace, '\\\\')
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeNumbers)
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeWords, c('xpa','n','v', 'p'))
docs <- tm_map(docs, content_transformer(function(x) gsub("\\b[[:alpha:]]\\b", " ", x))) #remove single letter words
docs <- tm_map(docs, removeWords, c('acbf','bbd','cf', 'ab','adddb','ad','daae','ids','eae','ebef'))
docs <- tm_map(docs, removeWords, c('dee','ef','dc', 'fcc','bae','beb','ff','aecfcf','ea','fcd','ece','ee','bcbbbdfbd'))
docs <- tm_map(docs, stripWhitespace)

for(i in 40:80){
	print(as.character(docs[[i]]))
}
for(i in 80:120){
	print(as.character(docs[[i]]))
}
for(i in 120:156){
	print(as.character(docs[[i]]))
}

unname(sapply(docs, as.character))[60:80]

docs_1 <- tm_map(docs,lemmatize_strings)


for(i in 120:156){
	print(as.character(docs_1[[i]]))
}

dtm <- DocumentTermMatrix(docs,control=list(wordLengths=c(2,25),bounds=list(global=c(2,1000))))
inspect(dtm)
freq<-colSums(as.matrix(dtm))
ord<-order(freq,decreasing=T)
freq[(ord)]

df<-data.frame(names(freq),freq)
names(df) <- c("TERM","FREQ")
df<-df[order(-df$FREQ),]
head(df)
df

findFreqTerms(dtm,lowfreq=3)
findAssocs(dtm,"muzaffar",0.3)

library(ggplot2)
Subs <- subset(df,FREQ>=60)
ggplot(Subs,aes(x=reorder(TERM,-FREQ),y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))+
	ggtitle("Debug1 words")
 	xlab("terms")
	ylab("Frequency")

library(wordcloud)
library(wordcloud2)
wordcloud(names(freq),freq,min.freq=4)
wordcloud(names(freq),freq,min.freq=4,colors=brewer.pal(12,"Spectral"))

wordcloud2(df)




















