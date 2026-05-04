## P166246 Muzaffar Izamuddin bin Daud
## Unstructured Test 1 Question 5

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


folder_path <- "C:/Users/PC 14/Desktop/P166246_test/Articles"

my_source <- DirSource(directory = folder_path, pattern = "*.txt")
my_corpus <- VCorpus(my_source)
mycorpus<-t(mycorpus)
data<- sapply(1:ncol(mycorpus),function(x){
	trimws(paste(mycorpus[,x],collapse=""),which="right")
})
print(my_corpus)
inspect(my_corpus[[1]])
inspect(my_corpus[[2]])


#5a perform data cleaning
toSpace <- content_transformer(function(x,pattern){gsub(pattern, " ", x)})
docs <- tm_map(my_corpus, removeNumbers)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, stripWhitespace)

#check document
inspect(docs[[1]])
inspect(docs[[2]])
inspect(docs[[3]])
inspect(docs[[4]])
inspect(docs[[5]])
inspect(docs[[6]])
inspect(docs[[7]])
inspect(docs[[8]])
inspect(docs[[9]])
inspect(docs[[10]])

#after inspecting there are still some characters need to clean, lets clean these special characters
docs <- tm_map(docs, toSpace, "’")
docs <- tm_map(docs, toSpace, "‘")
docs <- tm_map(docs, toSpace, '”')
docs <- tm_map(docs, toSpace, '“')
docs <- tm_map(docs, toSpace, '—')
docs <- tm_map(docs, toSpace, '₂')
docs <- tm_map(docs, toSpace, '²')
docs <- tm_map(docs, toSpace, '₃')
docs <- tm_map(docs, toSpace, '¹')
docs <- tm_map(docs, toSpace, '⅔')

#also there is some words that doesnt mean anything, mostly single letters, lets remove them before lemmatize
docs <- tm_map(docs, content_transformer(function(x) gsub("\\b[[:alpha:]]\\b", " ", x))) #remove single letter
#rerun whitespace
docs <- tm_map(docs, stripWhitespace)

#5b we then use textstem library to lemmatize the strings, a tokenization process
docs_1<- tm_map(docs,content_transformer(lemmatize_strings))

#check the lemmaitized strings
for(i in 1:10){
	print(as.character(docs_1[[i]]))
}

#5c
dtm <- DocumentTermMatrix(docs_1, 
	control = list( wordLengths = c(2,25), bounds=list(global=c(2,1000)) )
)
inspect(dtm)
freq<-colSums(as.matrix(dtm))
ord<- order(freq,decreasing=T)
freq[(ord)]

#build df 
df <- data.frame(names(freq),freq)
names(df) <- c("TERM","FREQ")
head(df)

#inspect terms with minimum 5 frequency
findFreqTerms(dtm,lowfreq=5)

#we use subset to filter the df to minimum 5 frequncy
library(ggplot2)
Subs<- subset(df, FREQ>=5)
#this is printing all the terms with at least 5 frequency, answer for question 5c
print(Subs)

ggplot(Subs, aes(x=reorder(TERM,-FREQ),y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))+
	ggtitle("Words with at least 5 frequency")+
	xlab("Terms")

#lets plot a more manageable amount, increasing Frequency limit to 10
Subs<- subset(df, FREQ>=10)
ggplot(Subs, aes(x=reorder(TERM,-FREQ),y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))+
	ggtitle("Words with at least 5 frequency")+
	xlab("Terms")

#5d we then plot the wordcloud using also min frequency of 5
wordcloud(names(freq),freq,min.freq=5,colors=brewer.pal(12,"Spectral"))
wordcloud2(df)

#5f
findAssocs(dtm,"manager",0.5)










