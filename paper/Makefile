default: pdf

MDFILE=paper.md
BIBFILE=paper.bib
LATEXFILE=paper.tex

# some variables for the paper
REPOSITORY="https://github.com/octapps/octapps"
ARCHIVE="http://dx.doi.org/10.5281/zenodo.1283525"
REVIEW="https://github.com/openjournals/joss-reviews/issues/707"
ARCHIVEDOI="http://dx.doi.org/10.5281/zenodo.1283525"
FORMATTEDDOI="10.21105/joss.00707"
YEAR="2018"
TITLE="OctApps: a library of Octave functions for continuous gravitational-wave data analysis"
AUTHOR="Wette et al."
ISSUE="26"
VOLUME="3"
PAGE="707"
JOURNALNAME="Journal of Open Source Software"
PUBLISHED="06 June 2018"
SUBMITTED="10 April 2018"
PAPERURL="https://www.theoj.org/joss-papers/joss.00707/10.21105.joss.00707.pdf"

# get JOSS template and logo
latex.template joss-logo.png:
	curl "https://raw.githubusercontent.com/openjournals/whedon/master/resources/$@" > $@

# use pandoc and pandoc-citeproc to create LaTeX source
latex: latex.template joss-logo.png $(MDFILE) $(BIBFILE)
	pandoc --filter pandoc-citeproc --bibliography=$(BIBFILE) -V repository=$(REPOSITORY) -V journal_name=$(JOURNALNAME) -V paper_url=$(PAPERURL) -V archive_doi=$(ARCHIVEDOI) -V review_issue_url=$(REVIEW) -V formatted_doi=$(FORMATTEDDOI) -V logo_path=joss-logo.png -V year=$(YEAR) -V paper_title=$(TITLE) -V citation_author=$(AUTHOR) -V issue=$(ISSUE) -V volume=$(VOLUME) -V page=$(PAGE) -V submitted=$(SUBMITTED) -V published=$(PUBLISHED) -V graphics=true -V papersize=a4paper -V geometry:margin=1in -t latex -s $(MDFILE) -o $(LATEXFILE) --template latex.template

pdf: latex
	pdflatex paper.tex
	pdflatex paper.tex

clean:
	rm paper.bcf paper.aux paper.log paper.out paper.run.xml

clean_downloads:
	rm latex.template joss-logo.png
