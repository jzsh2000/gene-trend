gene-trend
==========

This project is aimed to deal with human and mouse gene sets input by user,
return detailed information about the gene set (synonyms, description, number
of associated publications et al.)

The origin data are either downloaded from [NCBI FTP site][ncbiftp] or fetched
using NCBI's [Entrez Direct][edirect] command line toolkit. Data analysis is
performed in the [R][R] programming environment.

<!-- Markdown doesn't support FTP link -->
[ncbiftp]: http://bit.ly/2HJyRfL
[edirect]: https://www.ncbi.nlm.nih.gov/news/02-06-2014-entrez-direct-released/
[R]: https://cran.r-project.org/

---

Currently two shiny applications are included:

1. [gene](./shiny/gene/)

    * Match and convert gene information to their standard names
    * Order gene list by number of associated articles in a specified research
      domain (e.g. immunology)
    

2. [gene-trend](./shiny/gene-trend/)

    * Find 10 most studied genes each year
    * Count number of publications for a specified gene
