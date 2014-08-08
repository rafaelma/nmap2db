#
# Makefile
#

VERSION="1.0.0"

all:	clean html man pdf

html:	
	rst2html -gdt --stylesheet-path=style.css manual.rst > nmap2db-manual-$(VERSION).html

man:
	rst2man manual.rst > nmap2db-manual-$(VERSION).man

pdf:
	rst2pdf --output nmap2db-manual-$(VERSION).pdf manual.rst

clean:
	rm -f nmap2db-manual-$(VERSION)*.html
	rm -f nmap2db-manual-$(VERSION)*.man
	rm -f nmap2db-manual-$(VERSION)*.pdf
	rm -f *~
