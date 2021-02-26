
all: unixdev

unixdev: unixdev.pdf
unixdev.pdf: unixdev.tex unixdev.mp
	mpost unixdev
	tex unixdev
	dvipdfm unixdev

clean:
	rm -f *.dvi *.log *.mpx mpxerr.tex *.mps

