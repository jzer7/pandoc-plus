---
title: Title in front matter of Markdown file
author: Author Name
date: 2024-06-10
fontsize: 12pt
geometry: margin=1in
documentclass: article
header-includes: |
    \usepackage{fancyhdr}
    \pagestyle{fancy}
    \fancyhead[CO,CE]{This is a fancy header}
    \fancyfoot[CO,CE]{A fancy footer}
    \fancyfoot[LE,RO]{\thepage}
abstract: This text corresponds to the abstract section from front matter of the Markdown file.
---

<!-- There can only be 1 title in a document. Define it in the front matter, or in the body, but not both.
# Title in body of Markdown file
-->

This is the first paragraph in the body of the test document.
We use this document to verify functionality that produces a PDF from Markdown using Pandoc with LaTeX.

## Front matter

The front matter looks like:

```yaml
---
title: Title in front matter of Markdown file
author: Author Name
date: 2024-06-10
fontsize: 12pt
geometry: margin=0.5in
documentclass: article
header-includes: |
    \latexcommand...
abstract: some text here ...
---
```

These values are used by the template used to render Markdown to PDF.
Look at [variables for LaTeX](https://pandoc.org/MANUAL.html#variables-for-latex) for information on how these values are interpreted.

This image includes additional LaTeX packages, so we can test:

- math:

  $$\int_a^b f(x)dx = F(b) - F(a)$$

  $$
    \binom{n}{k} = \frac{n!}{k!(n-k)!}
  $$

- expressions with color:
  $${
    {\color{red}E} = {\color{green}m} \times {\color{blue}c^2}
  }$$

- code syntax highlighting:

 ```go
package main
import "fmt"
func main() {
    msg := "Hello, World!")
    fmt.Println(msg)
}
```

- nested lists:
  - level 2
    - level 3
      - level 4

1. markdown ordered lists
1. with multiple
   1. levels
      1. of
         1. indentation
   1. are
   1. supported
   1. and
1. numbered
1. correctly

- tables:

  | Header 1 | Header 2 |
  |----------|----------|
  | Cell 1   | Cell 2   |
  | Cell 3   | Cell 4   |

- a line break

---

- other stuff
