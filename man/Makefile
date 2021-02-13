
all: hocman

hocman: hocman.pdf
hocman.pdf: hocman.tex
	tex hocman
	dvipdfm hocman

clean:
	rm -f *.dvi *.log

