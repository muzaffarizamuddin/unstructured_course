#Using library rvest
install.packages('rvest')
library(rvest)
sermon<-read_html("https://www.iium.edu.my/deed/articles/thelastsermon.html")
nodes<- html_nodes(sermon,'p')#from selector gadget chrome extension
texts<-html_text(nodes)

class(texts)

mytext<- VectorSource(texts)
mycorpus <- VCorpus(mytext)

for (i in 1:18){
	print(as.character(mycorpus[[i]]))
}

#Data cleaning 
toSpace <- content_transformer(function(x,pattern){ gsub(pattern, " ", x)})

docs_1 <- tm_map(mycorpus, toSpace,"-") #change all dash to space
docs_1 <- tm_map(docs_1, removePunctuation)
docs_1 <- tm_map(docs_1, content_transformer(tolower))
docs_1 <- tm_map(docs_1, removeNumbers)
docs_1 <- tm_map(docs_1, removeWords,stopwords("english"))
docs_1 <- tm_map(docs_1, removeWords,c('ayam'))
docs_1 <- tm_map(docs_1, stripWhitespace)

unname(sapply(docs_1, as.character))

#------------Lemmatize--------
library(textstem)
docs_3 <- tm_map(docs_1, content_transformer(lemmatize_strings))
unname(sapply(docs_3, as.character))

dtm<- DocumentTermMatrix(docs_3)
inspect(dtm)
freq<- colSums(as.matrix(dtm))
ord<-order(freq,decreasing=T)
freq[(ord)]

#build df
df<-data.frame(names(freq),freq)
names(df)<-c("TERM","FREQ")
head(df)

findFreqTerms(dtm,lowfreq=2) #find words with minimum frequency
findAssocs(dtm,"allah",0.3) #kaitan dgn perkataan lain


library(ggplot2)
Subs<- subset(df,FREQ>=3) #how to filter freq
ggplot(Subs, aes(x=reorder(TERM,-FREQ),y=FREQ))+
	geom_bar(stat="identity")+
	theme(axis.text.x=element_text(angle=90,hjust=1, vjust=0.5))


library(wordcloud2)
wordcloud2(df)

library(htmlwidgets)
my_cloud <- wordcloud2(df)
# Change selfcontained to FALSE
saveWidget(my_cloud, "index.html", selfcontained = FALSE)

