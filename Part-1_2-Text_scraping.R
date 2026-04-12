install.packages("xml2", type = "binary")
install.packages("rvest", type = "binary")
packageVersion("xml2")

##------- Part 1: Extract Text from Files ------------

eg1<-read.table(file.choose(),fill=T,header=F) #Data CG.txt
eg1[1,]
eg2<-read.csv(file.choose(),header=F) #Data CG.csv
eg2[1,]

#Example 1
#Using tm package
install.packages('tm')
library(tm)
eg3<-c("Hi!","Welcome to STQD6114","Tuesday, 11-1pm")
mytext<-VectorSource(eg3)
mycorpus<-VCorpus(mytext)
inspect(mycorpus)   #will only show the structure
as.character(mycorpus[[1]])  #will display specific text


#Example using VectorSource
eg4<-t(eg1) #From example 1
ncol(eg4)  #end column
a<-sapply(1:ncol(eg4),function(x)
	trimws(paste(eg4[,x],collapse=" "),"right"))
mytext<-VectorSource(a)
mycorpus<-VCorpus(mytext)
inspect(mycorpus)
as.character(mycorpus[[2]])

#Example using VectorSource
eg4b<-t(eg2) #From example 1
ncol(eg4b)  #end column
b<-sapply(1:ncol(eg4b),function(x)
	trimws(paste(eg4b[,x],collapse=" "),"right"))
mytext2<-VectorSource(b)
mycorpus2<-VCorpus(mytext2)
inspect(mycorpus2)
as.character(mycorpus2[[2]])


#Example using DataFrameSource
eg5<-read.csv(file.choose(),header=F) #Using doc6.csv
docs<-data.frame(doc_id=c("doc_1","doc_2"),
	text=c(as.character(eg5[1,]),as.character(eg5[2,])),
	dmeta1=1:2,dmeta2=letters[1:2],stringsAsFactors=F)
mytext<-DataframeSource(docs)
mycorpus<-VCorpus(mytext)
inspect(mycorpus)
as.character(mycorpus[[2]])

eg5b<-read.csv(file.choose(),header=F) #Using CG.csv
docs<-data.frame(doc_id=c("doc_1","doc_2","doc_3","doc_4","doc_5","doc_6","doc_7"),
	text=c(as.character(eg5b[1,]),as.character(eg5b[2,]),as.character(eg5b[3,]),
		as.character(eg5b[4,]),as.character(eg5b[5,]),
		as.character(eg5b[6,]),as.character(eg5b[7,])),
	dmeta1=1:7,dmeta2=letters[1:7],stringsAsFactors=F)
mytext<-DataframeSource(docs)
mycorpus<-VCorpus(mytext)
inspect(mycorpus)
as.character(mycorpus[[3]])

#Example using DirSource. this for reading a whole folder
mytext<-DirSource("movies")
mytext<-DirSource("C:/Users/PC03/Desktop/Unstructured - Muz") #alternative directory pointing
mycorpus<-VCorpus(mytext)
inspect(mycorpus)
as.character(mycorpus[[1]])
as.character(mycorpus[[2]])
as.character(mycorpus[[3]])
as.character(mycorpus[[4]])


#### --------Part 2: Web scrapping------------------

eg6<-readLines("https://en.wikipedia.org/wiki/Data_science")
eg6[grep("\\h2",eg6)]
eg6[grep("\\p",eg6)] #paragraph
#Using library XML
library(XML)
doc<-htmlParse(eg6)
doc.text<-unlist(xpathApply(doc,'//p',xmlValue))
unlist(xpathApply(doc,'//h2',xmlValue))
#Using library httr
eg7<-GET("https://www.edureka.co/blog/what-is-data-science/")
doc<-htmlParse(eg7)
doc.text<-unlist(xpathApply(doc,'//p',xmlValue))


#Using library rvest
install.packages('rvest')
library(rvest)
eg8<-read_html("https://www.edureka.co/blog/what-is-data-science/")
nodes<-html_nodes(eg8,'.color-4a div span , .btn-become-profesional-link+ p')
texts<-html_text(nodes)
#Selecting multiple pages
pages<-
paste0('https://www.amazon.co.jp/s?k=skincare&crid=28HIW1TYLV9UM&sprefix=skincare%2Caps%2C268&r
ef=nb_sb_noss_1&page=',0:9)
eg10<-read_html(pages[1])
nodes<-html_nodes(eg10,'.a-price-whole')
texts<-html_text(nodes)
Price<-function(page){
url<-read_html(page)
nodes<-html_nodes(url ,'.a-price-whole ')
html_text(nodes)}
sapply(pages,Price)
do.call("c",lapply(pages,Price))
