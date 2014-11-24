COMPILER=latexmk

all: $(NAME).tex
	$(COMPILER) -pdf -use-make -auxdir=file -outdir=file $(NAME) ;
	shopt -s extglob ;
	mv file/*.pdf file/pdf
