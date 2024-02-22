import boto3
from pypdf import PdfReader
from io import BytesIO
from sklearn.feature_extraction.text import TfidfVectorizer
import pandas as pd
import nltk
from nltk.corpus import stopwords
import gensim
from gensim import corpora
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
import nltk
import os

# nltk.download("punkt")
# nltk.download("stopwords")
french_stop_words = list(stopwords.words("french"))
fr_en_stop_words = french_stop_words + list(stopwords.words("english"))


def extract_keywords_from_documents(documents):
    # Create a TfidfVectorizer
    vectorizer = TfidfVectorizer(stop_words=fr_en_stop_words)

    # Fit and transform the documents
    tfidf_matrix = vectorizer.fit_transform(documents)

    # Create a DataFrame with the words and their TF-IDF scores
    df = pd.DataFrame(
        tfidf_matrix.toarray(), columns=vectorizer.get_feature_names_out()
    )
    df = df.sum().sort_values(ascending=False)

    # Return the top 10 words with the highest TF-IDF scores
    return df.head(50)


def extract_documents(file_name, line_chunk_size):
    # Read the text file and split it into chunks of fixed line numbers
    with open(file_name, "r", encoding="utf-8-sig") as f:
        lines = [line for line in f.readlines() if line.strip() != ""]
        documents = [
            "".join(lines[i : i + line_chunk_size])
            for i in range(0, len(lines), line_chunk_size)
        ]
    return documents


def fetch_files_from_s3(bucket_name, folder_name):
    # Fetch the list of files from the bucket
    files = s3.list_objects(Bucket=bucket_name, Prefix=folder_name)["Contents"]

    output = "output.txt"
    # delete file if it exists
    try:
        os.remove(output)
    except OSError:
        pass
    for file in files:
        file_name = file["Key"]
        if file_name.endswith(".pdf"):
            # Download the file
            file_obj = s3.get_object(Bucket=bucket_name, Key=file_name)
            file_content = file_obj["Body"].read()

            # Create a file-like object for PyPDF2 to read
            pdf_file = BytesIO(file_content)

            # Create a PDF file reader object
            pdf_reader = PdfReader(pdf_file)

            # Extract text from each page and print it

            with open(output, "a", encoding="utf-8-sig") as f:
                for i in range(len(pdf_reader.pages)):
                    page_obj = pdf_reader.pages[i]
                    f.write(page_obj.extract_text())


if __name__ == "__main__":
    BUCKET = "levio-demo-fev-storage-dev"
    FOLDER = "ski-regulations"

    s3 = boto3.client("s3", region_name="us-east-1")
    fetch_files_from_s3(BUCKET, FOLDER)
    documents = extract_documents("output.txt", 500)
    print(extract_keywords_from_documents(documents))
    # apply_lda(documents)
