######################## Text Exploration ##################

#Regular expression - a languange to identify pattern/sequence of character

##grep functions (without use any package)
ww<-c("statistics","estate","castrate","catalyst","Statistics")
ss<-c("I like statistics","I like bananas","Estates and statues are expensive")

#1st function - grep() -give the location of pattern
grep(pattern="stat",x=ww) #x is the document, will return the location only
grep(pattern="stat",x=ww,ignore.case=T) #ignore the capital/small letter, will return the location only
grep(pattern="stat",x=ww,ignore.case=T,value=T) #ignore the capital/small letter, return to that particular words

#2nd function - grepl() - give logical expression
grepl(pattern="stat",x=ww) #Return true/false
grepl(pattern="stat",x=ss)

#3rd function - regexpr()
#return a vector of two attributes; position of the first match and its length
#if not, it returns -1
regexpr(pattern="stat",ww)
regexpr(pattern="stat",ss)

#4th function - gregexpr()
gregexpr(pattern="stat",ss)

#5th function - regexec()
regexec(pattern="(st)(at)",ww)

#6th function - sub()
sub("stat","STAT",ww,ignore.case=T)
sub("stat","STAT",ss,ignore.case=T)

#7th function - gsub()
gsub("stat","STAT",ss,ignore.case=T)


library(stringr)
words #dataset related to words
fruit #dataset fruit available in package stringr
sentences #dataset sentences

#Common function in package stringr
str_length("This is STQD6114") #str_length()-gives the length of that string
str_split(sentences," ") #str_split()-split the function by space & return the list
str_c("a","b","c") #combine string to become a long ist
str_c("A",c("li","bu","ngry")) #combine A to each vector
str_c("one for all","All for one",sep=",") #combine these string and separate by comma
str_c("one for all","All for one",collapse=",") #combine the string to be one sentences

x<-c("Apple","Banana","Pear")

#str_sub() gives subset
str_sub(x,1,3) #Gives from 1st to 3rd letter
str_sub(x,-3,-1) #Gives the last three letter

str_to_upper(x) #Return the string to upper case letter
str_to_lower(x) #Return the string to lower case letter
str_to_title("unstructured data analytics") #Return upper case letter to the string 
str_to_title(x)

#Note: str_view give the output in another browser
str_view(fruit,"an") #view the pattern (for the first time) of dataset 
str_view_all(fruit,"an") #view all pattern (including repeated observation)

# "." refers to anything
str_view(fruit,".a.") #refers to dataset fruit, find any fruit that have letter a
str_view(x,".a.")
str_view(sentences,".a.") #refers to dataset sentences, find any sentence that have letter a that is seen 1st time 
str_view_all(sentences,"\'") #find the symbol('), put backlash(\) or not is ok

#Anchors - ^ refers to the start of a string, $ refers to the end of a string
str_view(x,"^A")
str_view(x,"a$")
str_view(fruit,"^a") #find the fruit that has first word "a" in fruit dataset
str_view(fruit,"a$") #find the fruit that has end word "a" in fruit dataset
str_view_all(fruit,"^...$") #find the fruits with 3 character(letter), doesn't matter what letter as a start and end

#Note:\\b-boundary, \\d-digits, \\s-white space (space,tab,newlines).
ee<-c("sum","summarize","rowsum","summary")
str_view(ee,"sum")
str_view(ee,"\\bsum") #if let say we want to put boundaries, means the earlier/start words with sum. So, rowsum is not included
str_view(ee,"sum\\b") #if let say we want to put boundaries, means the end words with sum.
str_view(ee,"\\bsum\\b")

str_view(sentences,"\\d") #find digits in dataset sentences
ss<-c("This is a class with students","There are 18 students","This class is from 11.00 am")
str_view(ss,"\\d") #Find any sentences that have digits
str_view(ss,"\\s") #Find any sentences that have white space

str_view_all(fruit,"[abc]") #[abc] match to all a/b/c. Can also use "(a|b|c)"
str_view_all(fruit,"^[abc]") #any fruit that is started with any a/b/c
str_view_all(fruit,"^(g|h)")

#repetition
#? means 0 or 1 repetition
#+ means 1 or more repetition
#* means 0 or more repetition
#{n} means n times repetition
#{n,} means n or more times repetition
#{,m} means m or less times repetition
#{n,m} means between n to m times repetition

ex<-"aabbbccddddeeeee"
str_view(ex,"aab?") #gives 0 or 1 aab
str_view(ex,"aac?") #gives 0 or 1 aac. The output gives aa because can be 0
str_view(ex,"(a|d){2}") #Find a or d that occur 2 times
str_view_all(ex,"de+") #Find d and e, the letter e can be once or more
str_view_all(ex,"de+?") #Find d and e, and gives the shortest
str_view_all(ss,"\\d+") #Find digits at least once
str_view_all(ss,"\\d{2,}") #Find digits, 2 times or more

#grouping and backreferencing
str_view(fruit,"(a).\\1") #Find a, after a any letter (one dot=one letter),then repeat a once
str_view(fruit,"(a).+\\1") #Follow above, between a must have more than one repetition (the longest repetition)
str_view(fruit,"(a)(.)\\1\\2") #Find a, followed by any characters,then repeat a gain, then repeat any characters
str_view(fruit,"(.)(.)\\2\\1") #Find any two character, repeat the second one first, then repeat the first one

#Exercise using other dataset, eg. words
str_view(words,"^(.).*\\1$") #Find any character, that is started with anything, and have any character inside (can be 0/more because 
#use *),and end with the 1st letter
str_view(words,"(..).*\\1") #Find a pair of characters that is repeat in that word (will end with that pair of words)

#Other function in package str
str_detect(fruit,"e") #Return true/false that consists of words that have e inside
str_detect(fruit,"[aeiou]$") #a/e/i/o/u at the end
str_count(fruit,"e") #Cound the letter e in the word
fruit[5] #just check the fruit no 5
str_replace(fruit,"^a","A") #replace a with capital letter A
str_replace_all(fruit, c("^a"="A", "^e"="E")) #replace a with capital letter A, e with E


#####
#Other function
library(stringr)
library(tidyverse)

a<-"Hello World"
a<-'Hello World'
a<-"Strings are \"scary\""
writeLines(a)
a<-"\u00b5" #represent specific Unicode. Try to google other Unicode, eg. alpha, lambda, etc.
writeLines(a)

### Cleaning and preprocessing #

library(tm)
#docs<-VCorpus(VectorSource(sentences))
docs<-Corpus(VectorSource(sentences))

writeLines(as.character(docs[[30]]))

getTransformations()

#Create custom transformation
toSpace<-content_transformer(function(x,pattern){return(gsub(pattern," ",x))})

as.character(docs[[133]]) #check line 133 
docs<-tm_map(docs,toSpace,"-")
as.character(docs[[133]])

docs<-tm_map(docs,removePunctuation)
docs<-tm_map(docs,content_transformer(tolower))
docs<-tm_map(docs,removeNumbers)
docs<-tm_map(docs,removeWords,stopwords("english")) #remove stop words

as.character(docs[[2]])

docs<-tm_map(docs,removeWords,"gp")
docs<-tm_map(docs,stripWhitespace)

library(SnowballC)
docs2<-tm_map(docs,stemDocument) #for stemming the documents

library(textstem)
docs3<-stem_strings(docs)
a<-unlist(str_split(docs3,"[,]"))
docs4<-lemmatize_strings(docs)
b<-unlist(str_split(docs4,"[,]"))

dtm<-DocumentTermMatrix(docs)
inspect(dtm[1:2,1:100])
freq<-colSums(as.matrix(dtm))
length(freq)
ord<-order(freq,decreasing=T)
head(ord)
freq[head(ord)]

dtm<-DocumentTermMatrix(docs,control=list(wordLengths=c(2,20),
                                          bounds=list(global=c(2,30))))
inspect(dtm[1:2,1:100])
freq<-colSums(as.matrix(dtm))
length(freq)
ord<-order(freq,decreasing=T)
head(ord)
freq[head(ord)]

#once we have all above, we can insert to data frame
wf<-data.frame(names(freq),freq)
names(wf)<-c("TERM","FREQ")
head(wf)

findFreqTerms(dtm,lowfreq=10)
findAssocs(dtm,"get",0.3)

library(ggplot2)
Subs<-subset(wf,FREQ>=10)
ggplot(Subs,aes(x=TERM,y=FREQ))+geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=45,hjust=1))
ggplot(wf,aes(x=TERM,y=FREQ))+geom_bar(stat="identity")+
  theme(axis.text.x=element_text(angle=45,hjust=1)) #Show all, include terms that hv small freq

library(wordcloud)
wordcloud(names(freq),freq) #in general
wordcloud(names(freq),freq.min.freq=10) #if we want to focus on the min freq of 10
wordcloud(names(freq),freq,colors=brewer.pal(8,"Darker"))
wordcloud(names(freq),freq,colors=brewer.pal(12,"Paired"))

library(wordcloud2)
wordcloud2(wf)
wordcloud2(wf,size=0.5)
wordcloud2(wf,size=0.5,color="random-light",backgroundColor="black")
wordcloud2(wf,shape="star",size=0.5)
wordcloud2(wf,figPath="love.png",color="skyblue",backgroundColor="black")
#wordcloud2(wf,figPath="cat.png",color="skyblue",backgroundColor="black")

letterCloud(wf,word="R",color="random-light",backgroundColor="black")
letterCloud(wf,word="SDA",color="random-light",backgroundColor="black")



###########################
library(textstem)
docs3<-stem_strings(docs)[1]
a<-unlist(str_split(docs3,"[,]"))
docs4<-lemmatize_strings(docs)[1]
b<-unlist(str_split(docs4,"[,]"))