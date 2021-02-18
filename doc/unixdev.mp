
input boxes;

outputtemplate := "%j-%c.mps";

beginfig(1)
interim defaultdy:=0pt;
interim defaultdx:=0pt;
boxjoin(a.e+(10mm,0)=b.w);
boxit.empty(btex \strut({\it empty\/}) etex);
boxit.two(btex \strut{\tt2} etex);
boxit.add(btex \strut{\tt+} etex);
boxit.three(btex \strut{\tt3} etex);
boxit.mul(btex \strut{\tt*} etex);
boxit.four(btex \strut{\tt4} etex);
boxit.newline(btex \strut{\tt\char"5Cn} etex);
boxjoin();
empty.c = origin;
boxit.list(btex\strut{\it list}etex);       list.s = empty.n+(0,4mm);
boxit.numtwo(btex\strut{\tt NUMBER}etex);   numtwo.s = two.n+(0,4mm);
boxit.numthree(btex\strut{\tt NUMBER}etex); numthree.s = three.n+(0,4mm);
boxit.numfour(btex\strut{\tt NUMBER}etex);  numfour.s = four.n+(0,4mm);
boxit.mulexpr(btex\strut{\it expr}etex);
  mulexpr.s = .5[numthree.n,numfour.n]+(0,5mm);
boxit.addexpr(btex\strut{\it expr}etex);
  addexpr.s = .6[numtwo.n,mulexpr.n]+(0,6mm);
boxit.root(btex\strut{\it list}etex);
  root.s = addexpr.n+(0,5mm);
drawunboxed(empty, two, add, three, mul, four, newline);
drawunboxed(list, numtwo, numthree, numfour);
drawunboxed(mulexpr, addexpr, root);
draw empty.n--list.s;
draw two.n--numtwo.s;
draw three.n--numthree.s;
draw four.n--numfour.s;
draw mulexpr.c--numthree.c cutbefore bpath mulexpr cutafter bpath numthree;
draw mulexpr.c--mul.n      cutbefore bpath mulexpr;
draw mulexpr.c--numfour.c  cutbefore bpath mulexpr cutafter bpath numfour;
draw addexpr.c--numtwo.c  cutbefore bpath addexpr cutafter bpath numtwo;
draw addexpr.c{dir260}..{down}add.n cutbefore bpath addexpr;
draw addexpr.c--mulexpr.c cutbefore bpath addexpr cutafter bpath mulexpr;
draw root.c{dir220}..{dir240}list.c cutbefore bpath root cutafter bpath list;
draw root.c--addexpr.n cutbefore bpath root;
draw root.c{dir320}..{dir280}newline.n cutbefore bpath root;
endfig;

beginfig(2)
interim defaultdy:=0pt;
interim defaultdx:=0pt;
boxjoin(a.e+(10mm,0)=b.w);
boxit.empty(btex\strut({\it empty\/})etex);
boxit.xeqone(btex\strut{\tt x = 1}etex);
boxit.newline(btex\strut{\tt\char"5Cn}etex);
boxjoin();
boxit.list(btex\strut{\it list}etex);  list.s=empty.n+(0,5mm);
boxit.asgn(btex\strut{\it asgn}etex);  asgn.s=xeqone.n+(0,5mm);
boxit.aexp(btex\strut{\it expr}etex);  aexp.s=asgn.n+(0,5mm);
boxit.root(btex\strut{\it list}etex);  root.s=aexp.n+(0,5mm);
empty.c = origin;
drawunboxed(empty, xeqone, newline, list, asgn, aexp, root);
draw empty.n--list.s;
draw xeqone.n--asgn.s;
draw asgn.n--aexp.s;
draw root.c{dir225}..{dir260}list.c cutbefore bpath root cutafter bpath list;
draw root.c..aexp.c cutbefore bpath root cutafter bpath aexp;
draw root.c{dir315}..{dir280}newline.c
  cutbefore bpath root cutafter bpath newline;
endfig;

beginfig(3)
interim defaultdy:=0pt;
interim defaultdx:=2pt;
boxjoin(a.e+(10mm,0)=b.w);
boxit.empty(btex\strut({\it empty\/})etex);
boxit.xeqone(btex\strut{\tt x = 1}etex);
boxit.newline(btex\strut{\tt\char"5Cn}etex);
boxjoin();
boxit.list(btex\strut{\it list}etex); list.s=empty.n+(0,6mm);
boxit.asgn(btex\strut{\it asgn}etex); asgn.s=xeqone.n+(0,6mm);
boxit.root(btex\strut{\it list}etex); root.s=asgn.n+(0,6mm);
empty.c = origin;
drawunboxed(empty, xeqone, newline, list, asgn, root);
draw empty.n--list.s;
draw xeqone.n--asgn.s;
draw root.c--list.c cutbefore bpath root cutafter bpath list;
draw root.c--asgn.c cutbefore bpath root cutafter bpath asgn;
draw root.c{dir300}..{dir280}newline.c
  cutbefore bpath root cutafter bpath newline;
endfig;

end

