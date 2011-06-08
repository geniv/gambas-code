FILE=main

TEXFILE=${FILE}.tex
DVIFILE=${FILE}.dvi
PDFFILE=${FILE}.pdf
PSFILE=${FILE}.ps

C_FILES=*.c
C_TEX_FILES=$(patsubst %.c,%.tex,$(wildcard $(C_FILES)))

XFIG_FIG=*.fig
PSTEX_FIG=*.fig.ltx
EPSGZ_FIG=*.eps.gz

EPS_XFIG=$(patsubst %.fig,%.eps,$(wildcard $(XFIG_FIG)))
PSTEX_XFIG=$(patsubst %.fig.ltx,%.pstex,$(wildcard $(PSTEX_FIG)))
PSTEX_T_XFIG=$(patsubst %.fig.ltx,%.pstex_t,$(wildcard $(PSTEX_FIG)))
EPS_EPSGZ=$(patsubst %.eps.gz,%.eps,$(wildcard $(EPSGZ_FIG)))

IMAGES= $(EPS_XFIG) $(PSTEX_XFIG) $(PSTEX_T_XFIG) $(EPS_EPSGZ)

help:
	@echo "Available make options are:"
	@echo "  dvipdfm         generate and view a PDF document with dvipdfm"
	@echo "  gen_dvipdfm     generate a PDF document with dvipdfm"
	@echo "  ps2pdf          generate and view a PDF document with ps2pdf"
	@echo "  gen_ps2pdf      generate a PDF document with ps2pdf"
	@echo "  ps              generate and view a PostScript document"
	@echo "  gen_ps          generate a PostScript document"
	@echo "  dvi             generate and view a DVI document"
	@echo "  gen_dvi         generate a DVI document"
	@echo "  clean           remove temp files"
	@echo "  cleanall        remove temp files and generated documents"

dvipdfm: gen_dvipdfm
	acroread ${PDFFILE}

gen_dvipdfm: $(IMAGES) ${C_TEX_FILES}
	touch MakeDVIPDFM
	${RM} MakePSTOPDF
	${RM} MakePS
	latex ${TEXFILE}
	bibtex ${FILE} ; true
	latex ${TEXFILE} ; true
	latex ${TEXFILE} ; true
	dvipdfm -p a4 -o ${PDFFILE} ${DVIFILE}
	${RM} MakeDVIPDFM

ps2pdf: gen_ps2pdf
	acroread ${PDFFILE}

gen_ps2pdf: $(IMAGES) ${C_TEX_FILES}
	touch MakePSTOPDF
	${RM} MakeDVIPDFM
	${RM} MakePS
	latex ${TEXFILE} ; true
	bibtex ${FILE} ; true
	latex ${TEXFILE} ; true
	latex ${TEXFILE} ; true
	dvips ${DVIFILE} -o ${PSFILE}
	${RM} -r MakePSTOPDF
	ps2pdf -sPAPERSIZE=a4 ${PSFILE} ${PDFFILE}

ps: gen_ps
	gv ${PSFILE}

gen_ps: $(IMAGES) ${C_TEX_FILES}
	touch MakePS
	${RM} MakeDVIPDFM
	${RM} MakePSTOPDF
	latex ${TEXFILE}
	bibtex ${FILE} ; true
	latex ${TEXFILE}
	latex ${TEXFILE}
	${RM} MakePS
	dvips -o ${PSFILE} ${DVIFILE}

dvi: gen_dvi
	xdvi ${DVIFILE}

gen_dvi: $(IMAGES) ${C_TEX_FILES}
	touch MakePS
	${RM} MakeDVIPDFM
	${RM} MakePSTOPDF
	latex ${TEXFILE}
	bibtex ${FILE} ; true
	latex ${TEXFILE}
	latex ${TEXFILE}
	${RM} MakePS

clean:
	rm -f *.log *.out *~ *.bak *.aux *.dvi *.bbl *.blg 
	rm -f *.cb  *.lof *.los *.lot *.toc 
	rm -f MakePS MakePSTOPDF MakeDVIPDFM
	rm -f *.eps *.pstex *.pstex_t
	rm -f *.bak *~ 
	rm -f $(STYCONFIG)

cleanall:
	${MAKE} clean
	rm -rf ${PDFFILE} ${PSFILE} ${C_TEX_FILES}


$(EPS_XFIG): %.eps: %.fig
	  fig2dev -L eps $< $@

$(PSTEX_XFIG): %.pstex: %.fig.ltx
	  fig2dev -L pstex $< $@

$(PSTEX_T_XFIG): %.pstex_t: %.fig.ltx
	  fig2dev -L pstex_t -p $*.pstex $< $@

$(EPS_EPSGZ): %.eps: %.eps.gz
	  zcat $< > $@

${C_TEX_FILES}: %.tex: %.c
	c++2latex +ansi-c -o $@ $<


