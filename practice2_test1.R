##------ create data from internet ----------
install.packages('rvest')
library(rvest)
library(stringr)
library(tm)
library(wordcloud)

sermon<-read_html("https://www.napoleon-series.org/research/napoleon/c_speeches.html")
nodes<- html_nodes(sermon,'p')#from selector gadget chrome extension
texts<-html_text(nodes)

clean_text <- str_squish(texts)
clean_text
writeLines(clean_text, "napoleon.txt")
write.csv(clean_text, "napoleon.csv")
getwd()


##--------------Practice-----------------

data <- read.table(file.choose(), fill = T, header = F)
#data2 <- read.csv(file.choose(), header = FALSE, fill = TRUE)



data

data<- t(data)

data_1 <- sapply(1:ncol(data), function(x) {
  trimws(paste(data[, x], collapse = " "), which = "right")
}) 

str_view(data_1,"-")
str_view(data_1,"�")
str_view(data_1,".ab.")

mytext<- VectorSource(data_1)
mycorpus <- VCorpus(mytext)
inspect(mycorpus)

as.character(mycorpus[[5]])

for (i in 1:10){
	print(as.character(mycorpus[[i]]))
}

toSpace <- content_transformer(function(x,pattern){gsub(pattern," ",x)})

docs <- tm_map(mycorpus, toSpace,"-")
docs <- tm_map(docs, toSpace,"�")
docs <- tm_map(docs, toSpace,"]")
docs <- tm_map(docs, toSpace,"[")
docs <- tm_map(docs, toSpace,"©")
docs <- tm_map(docs, toSpace,":")
docs <- tm_map(docs, toSpace,"\n")
docs <- tm_map(docs, toSpace,";")
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))

for (i in 1:10){
	print(as.character(docs[[i]]))
}

docs <- tm_map(docs, removeNumbers)
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeWords, c("m"))
docs <- tm_map(docs, stripWhitespace)

for (i in 1:10){
	print(as.character(docs[[i]]))
}

unname(sapply(docs, as.character))



#----lemmatize
install.packages("textstem")
library(textstem)
docs1 <- tm_map(docs, content_transformer(lemmatize_strings))
unname(sapply(docs1, as.character))

#------DTM

dtm <- DocumentTermMatrix(docs1)
inspect(dtm)

freq <- colSums(as.matrix(dtm))
ord <- order(freq, decreasing=T)
freq[ord]

df<-data.frame(names(freq),freq)
names(df) <- c("TERM", "FREQ")
df <- df[order(-df$FREQ), ]
df

findFreqTerms(dtm,lowfreq=2)
findFreqTerms(dtm,lowfreq=3)
findAssocs(dtm,"address",0.3)

#plot

library(ggplot2)
Subs <- subset(df, FREQ>1)
ggplot(Subs, aes(x=reorder(TERM, -FREQ), y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1,vjust=0.5))

wordcloud(names(freq),freq,min.freq=1,colors=brewer.pal(8,"Dark2"))

wordcloud(names(freq),freq,min.freq=1,colors=brewer.pal(8,"Spectral"))

















