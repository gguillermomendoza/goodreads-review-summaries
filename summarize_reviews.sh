#!/bin/sh

# summarize_reviews.sh — AI-powered book review summarizer
# Uses the Goodreads dataset to find and summarize reviews for any book title.
#
# Usage:
#   sh summarize_reviews.sh "Book Title"
#
# Requirements:
#   - Access to the Goodreads dataset at /data-fast/goodreads/
#   - jq (https://jqlang.github.io/jq/)
#   - llm CLI tool (https://llm.datasette.io/)

if [ -z "$1" ]; then
    echo "Usage: sh summarize_reviews.sh \"Book Title\""
    echo "Example: sh summarize_reviews.sh \"The Name of the Wind\""
    exit 1
fi

BOOKS_FILE="/data-fast/goodreads/goodreads_books.json.gz"
REVIEWS_FILE="/data-fast/goodreads/goodreads_reviews_dedup.json.gz"

# Create a temporary directory for intermediate files
tempdir=$(mktemp -d)
cd "$tempdir"

echo "Searching for books matching: $1"

# Step 1: Find all book entries matching the title (prefix match)
zcat "$BOOKS_FILE" | grep "\"title\": \"$1" > books.json
num_books=$(wc -l < books.json)
echo "Found $num_books edition(s)"

if [ "$num_books" -eq 0 ]; then
    echo "Error: No books found matching \"$1\""
    rm -rf "$tempdir"
    exit 1
fi

# Step 2: Extract book_ids and build a grep regex with alternation
regex=$(echo $(cat books.json | jq '.book_id') | sed 's/ /|/g')

echo "Searching for reviews..."

# Step 3: Find all reviews matching any of those book_ids
zcat "$REVIEWS_FILE" | grep -E "$regex" > reviews.json
num_reviews=$(wc -l < reviews.json)
echo "Found $num_reviews review(s)"

if [ "$num_reviews" -eq 0 ]; then
    echo "Error: No reviews found for \"$1\""
    rm -rf "$tempdir"
    exit 1
fi

echo "Generating AI summary from $([ "$num_reviews" -gt 20 ] && echo "20 of $num_reviews" || echo "$num_reviews") reviews..."
echo ""

# Step 4: Pass a sample of 20 reviews to the LLM for summarization
echo "Write a short 2-3 sentence summary of the following book reviews. The reviews are: $(cat reviews.json | head -n20 | jq '.review_text')" | llm

# Clean up temporary directory
rm -rf "$tempdir"
