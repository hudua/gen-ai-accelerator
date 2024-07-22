from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient
from common import embedding, summary

search_endpoint = ''
search_key = ''
index = ''

search_client = SearchClient(search_endpoint, index, AzureKeyCredential(search_key))

# need to do a for loop for each file and for each chunk

data = #take the text from each chunk

embedding_vec = embedding.get_new_embedding(data,...)

with open('common/summary-prompt.txt', 'r') as file:
    prompt = file.read()

prompt = prompt + data

summary_str = summary.generate_prompt(prompt,...)

document = {
    "file_name": file_name,
    "file_name_chunk": file_name_chunk, #id
    "content_text": data,
    "summary": summary_str,
    "vector": embedding_vec
}

result = search_client.upload_documents(documents=[document])
