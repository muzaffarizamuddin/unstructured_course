### Text Analysis I: LDA
install.packages("topicmodels")
install.packages("tidytext")
install.packages("tidyr")
install.packages("dplyr")

library(tidytext)
library(topicmodels)
library(tidyr)
library(ggplot2)
library(dplyr)

data("AssociatedPress")

inspect(AssociatedPress)
as.matrix(AssociatedPress)

ap_lda<-LDA(AssociatedPress,k=2,control=list(seed=1234)) #create two-topic LDA model ### must be in dtm format


ap_topics<-tidy(ap_lda,matrix="beta") #Extract the per-topic-per-word-probabilities

#Find terms that are most common within each topics
ap_top_terms <- ap_topics %>% group_by(topic) %>% top_n(10,beta) %>% ungroup () %>% arrange (topic, -beta)
ap_top_terms%>% mutate(term=reorder(term,beta))%>%
ggplot(aes(term,beta,fill=factor(topic)))+geom_col(show.legend=FALSE)+
facet_wrap(~topic,scales="free")+coord_flip() #visualize the above

beta_spread <- ap_topics %>% mutate (topic=paste0("topic",topic)) %>% spread(topic,beta) %>%
filter (topic1>0.003 | topic2 > 0.003) %>% mutate(log_ratio = log2(topic2/topic1))

# Filter for a log2 ratio > 3 (8x difference) or < -3 (1/8th difference)
#beta_spread <- beta_spread %>% filter(abs(log_ratio) > 5)

beta_spread%>% mutate(term=reorder(term,log_ratio))%>%
ggplot(aes(term,log_ratio))+geom_col(show.legend=FALSE)+coord_flip()


ap_documents<-tidy(ap_lda,matrix="gamma") #Extract the per-document-per-topic-probabilities

ap_documents
print(n=20,ap_documents)

tidy(AssociatedPress)%>%filter(document==2)%>%
	arrange(desc(count)) #Check the most common words in the document, eg document 6

#----practice x3-----
ap_lda2<-LDA(AssociatedPress,k=3,control=list(seed=1234)) #create two-topic LDA model ### must be in dtm format

ap_topics2<-tidy(ap_lda2,matrix="beta") #Extract the per-topic-per-word-probabilities

#Find terms that are most common within each topics
ap_top_terms <- ap_topics2 %>% group_by(topic) %>% top_n(20,beta) %>% ungroup () %>% arrange (topic, -beta)
ap_top_terms%>% mutate(term=reorder(term,beta))%>%
ggplot(aes(term,beta,fill=factor(topic)))+geom_col(show.legend=FALSE)+
facet_wrap(~topic,scales="free")+coord_flip() #visualize the above


beta_spread2 <- ap_topics2 %>% mutate (topic=paste0("topic",topic)) %>% spread(topic,beta) %>%
filter (topic2>0.003 | topic3 >0.003) %>% mutate(log_ratio = log2(topic3/topic2))

beta_spread2%>% mutate(term=reorder(term,log_ratio))%>%
ggplot(aes(term,log_ratio))+geom_col(show.legend=FALSE)+coord_flip()

#-------practice x5----

ap_lda5<-LDA(AssociatedPress,k=5,control=list(seed=1234)) #create two-topic LDA model ### must be in dtm format

ap_topics5<-tidy(ap_lda5,matrix="beta") #Extract the per-topic-per-word-probabilities

#Find terms that are most common within each topics
ap_top_terms <- ap_topics5 %>% group_by(topic) %>% top_n(20,beta) %>% ungroup () %>% arrange (topic, -beta)
ap_top_terms%>% mutate(term=reorder(term,beta))%>%
ggplot(aes(term,beta,fill=factor(topic)))+geom_col(show.legend=FALSE)+
facet_wrap(~topic,scales="free")+coord_flip() #visualize the above


beta_spread5 <- ap_topics5 %>% mutate (topic=paste0("topic",topic)) %>% spread(topic,beta) %>%
filter (topic2>0.003 | topic3 >0.003) %>% mutate(log_ratio = log2(topic3/topic2))

beta_spread5%>% mutate(term=reorder(term,log_ratio))%>%
ggplot(aes(term,log_ratio))+geom_col(show.legend=FALSE)+coord_flip()


#------

library(tm)

mytext<- DirSource("C:/Users/PC 14/Desktop/github - muz/unstructured_course/TextMining")
mycorpus<-VCorpus(mytext)
toSpace <- content_transformer(function(x,pattern){gsub(pattern, " ", x)})
docs <- tm_map(mycorpus, removeNumbers)
docs <- tm_map(docs, removePunctuation)
docs <- tm_map(docs, content_transformer(tolower))
docs <- tm_map(docs, removeWords, stopwords("english"))
docs <- tm_map(docs, removeWords, c("can","will","however","one"))
docs <- tm_map(docs, stripWhitespace)

inspect(docs[[1]])
inspect(docs[[2]])
inspect(docs[[3]])
inspect(docs[[4]])
inspect(docs[[5]])

dtm <- DocumentTermMatrix(docs)

ap_lda<-LDA(dtm,k=2,control=list(seed=1234)) #create two-topic LDA model ### must be in dtm format

ap_topics<-tidy(ap_lda,matrix="beta") #Extract the per-topic-per-word-probabilities

#Find terms that are most common within each topics
ap_top_terms <- ap_topics %>% group_by(topic) %>% top_n(30,beta) %>% ungroup () %>% arrange (topic, -beta)
ap_top_terms%>% mutate(term=reorder(term,beta))%>%
ggplot(aes(term,beta,fill=factor(topic)))+geom_col(show.legend=FALSE)+
facet_wrap(~topic,scales="free")+coord_flip() #visualize the above


beta_spread <- ap_topics %>% mutate (topic=paste0("topic",topic)) %>% spread(topic,beta) %>%
filter (topic2>0.003 | topic3 >0.003) %>% mutate(log_ratio = log2(topic3/topic2))

beta_spread%>% mutate(term=reorder(term,log_ratio))%>%
ggplot(aes(term,log_ratio))+geom_col(show.legend=FALSE)+coord_flip()

tm_documents<-tidy(ap_lda,matrix="gamma") #Extract the per-document-per-topic-probabilities

tm_documents
print(n=20,tm_documents)

tm_documents %>% filter(topic==2)

tidy(dtm)%>%filter(document=="bigdata.txt")%>%
	arrange(desc(count)) #Check the most common words in the document, eg document 6












 



























