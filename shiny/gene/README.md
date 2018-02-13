gene (shiny application)
========================

About
-----
This shiny application will be mainly used to sort human and mouse genes in
various orders.

Currently following orders are supported:

* NCBI gene weight
* PubMed articles
* PubMed articles ([immunology][immunology])
* PubMed articles ([tumour][tumour])

The human genes can be filtered to show the [surface markers][surface_marker].

[immunology]: https://www.ncbi.nlm.nih.gov/pubmed/?term=immunology%5BMeSH+Subheading%5D
[tumour]: https://www.ncbi.nlm.nih.gov/pubmed/?term=neoplasms%5Bmesh%5D
[surface_marker]: http://www.proteinatlas.org/search/protein_class:Predicted+membrane+proteins

Dependencies
------------

R packages:

* [shiny](https://github.com/rstudio/shiny)
* [shinyjs](https://github.com/daattali/shinyjs)
* [DT](https://github.com/rstudio/DT)
* [tidyverse](https://github.com/tidyverse/tidyverse)
* [glue](https://github.com/tidyverse/glue)
* [rvest](https://github.com/hadley/rvest)

Deploy
------
1. clone this repository
2. run `make update` in the project root directory, which will download and
   create data used by this application.
3. start shiny application in [rstudio](https://www.rstudio.com/)

Live Demo
---------
This application is deployed on `shinyapps.io`, you could access the following
link to have a try: <https://jzsh2000.shinyapps.io/gene>
