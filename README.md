# Goodreads AI Review Summaries

A command-line tool that generates AI-powered summaries of book reviews from the [Goodreads dataset](https://mengtingwan.github.io/data/goodreads.html) (2006–2017). Inspired by [Amazon's AI review summaries](https://www.aboutamazon.com/news/amazon-ai/amazon-improves-customer-reviews-with-generative-ai).

This is a lightweight example of **Retrieval Augmented Generation (RAG)** — extracting relevant data from a large corpus and passing it to an LLM for summarization — implemented entirely in shell.

## Dataset

The Goodreads dataset contains:

| File | Description | Size | Records |
|------|-------------|------|---------|
| `goodreads_reviews_dedup.json.gz` | User reviews | ~5.1 GB | 15.7M reviews |
| `goodreads_books.json.gz` | Book metadata | ~2.1 GB | 2.3M books |

Both files are in [JSON Lines](https://jsonlines.org/) format (one JSON object per line, gzip-compressed).

## How It Works

```
┌──────────────────┐     grep       ┌───────────────┐
│ goodreads_books  │ ──────────────▶│ matching books │
│    .json.gz      │  title prefix  │   (book_ids)  │
└──────────────────┘                └───────┬───────┘
                                            │
                                            │ build regex
                                            ▼
┌──────────────────┐    grep -E     ┌───────────────┐    head -n20    ┌─────┐
│goodreads_reviews │ ──────────────▶│   matching    │ ──────────────▶│ LLM │
│   _dedup.json.gz │  book_id regex │   reviews     │   + jq         │     │
└──────────────────┘                └───────────────┘                └──┬──┘
                                                                       │
                                                                       ▼
                                                                   Summary
```

1. **Find books** — Prefix-matches the given title in `goodreads_books.json.gz` to find all editions (hardcover, paperback, audio, etc.)
2. **Extract IDs** — Pulls all `book_id` values and builds a regex with alternation (`|`)
3. **Find reviews** — Searches `goodreads_reviews_dedup.json.gz` for reviews matching any of those `book_id`s
4. **Summarize** — Sends 20 sampled reviews to an LLM for a 2–3 sentence summary

All intermediate files are stored in a temporary directory that is cleaned up automatically.

## Requirements

- **Linux/macOS** with standard utilities (`zcat`, `grep`, `sed`, `head`, `wc`, `mktemp`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **[llm](https://llm.datasette.io/)** — CLI tool for interacting with LLMs
- **Goodreads dataset** — expected at `/data-fast/goodreads/`

## Usage

```bash
sh summarize_reviews.sh "Book Title"
```

### Examples

```bash
sh summarize_reviews.sh "The Name of the Wind"
sh summarize_reviews.sh "The Wealth of Nations"
sh summarize_reviews.sh "Democracy in America"
```

### Sample Output

```
Searching for books matching: The Name of the Wind
Found 35 edition(s)
Searching for reviews...
Found 5992 review(s)
Generating AI summary from 20 of 5992 reviews...

Readers overwhelmingly praise The Name of the Wind for its beautiful prose,
masterful world-building, and compelling magic system, frequently calling it
one of the best fantasy novels they've ever read. While some found the pacing
slow in parts and noted the story-within-a-story structure isn't for everyone,
the vast majority were captivated by Kvothe's journey and immediately sought
out the sequel.
```

## Key Concepts

| Concept | Description |
|---------|-------------|
| `zcat` | Decompress `.gz` files to stdout (streaming, $O(1)$ memory) |
| `grep -E` | Filter lines matching an extended regular expression |
| `jq '.field'` | Extract a specific field from each JSON line |
| `sed 's/ /\|/g'` | Build alternation regex (`id1\|id2\|id3`) |
| `$(...)` | Command substitution — embed command output in a string |
| `$1` | First positional argument to the shell script |
| `mktemp -d` | Create a temporary directory for intermediate files |

## Customization

To change the data location, edit the variables at the top of `summarize_reviews.sh`:

```bash
BOOKS_FILE="/path/to/goodreads_books.json.gz"
REVIEWS_FILE="/path/to/goodreads_reviews_dedup.json.gz"
```

To change the number of reviews sent to the LLM, modify the `head -n20` in step 4.

## License

MIT
