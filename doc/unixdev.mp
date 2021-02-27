
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
draw root.c{dir330}..{dir280}newline.c
  cutbefore bpath root cutafter bpath newline;
endfig;

% machine code for while
beginfig(4)
interim defaultdy := 1pt;
boxjoin(a.sw=b.nw; a.se=b.ne);
boxit.pre(btex\hbox to 5em{\hss\dots\hss}etex); pre.dy = 10pt;
boxit.whilecode(btex\strut{\tt whilecode}etex);
boxit.ptrbody(btex\strut{}etex);
boxit.ptrnext(btex\strut{}etex);
boxit.cond(btex\strut{\it cond}etex);
boxit.morecond(btex{\dots}etex); morecond.dy = 14pt;
boxit.stopcond(btex\strut{\tt STOP}etex);
boxit.body(btex\strut{\it body}etex);
boxit.morebody(btex{\dots}etex); morebody.dy = 14pt;
boxit.stopbody(btex\strut{\tt STOP}etex);
boxit.next(btex\strut{\it next stmt}etex);
boxit.post(btex{\dots}etex); post.dy = 10pt;
boxjoin();
drawboxed(whilecode, ptrbody, ptrnext, cond, morecond,
          stopcond, body, morebody, stopbody, next);
drawunboxed(pre, post);
draw pre.nw--post.sw;
draw pre.ne--post.se;
drawarrow .5[ptrbody.c,ptrbody.e]--ptrbody.e{right}..{dir215}body.e;
drawarrow .5[ptrnext.c,ptrnext.e]--ptrnext.e{right}..{dir215}next.e;
endfig;

% data structures for procedure call
beginfig(5)
interim defaultdy := 1pt;
%% Machine:
boxjoin(a.sw=b.nw; a.se=b.ne);
boxit.mpre(); mpre.dy=10pt; mpre.dx=24pt;
boxit.mcall(btex\strut{\tt call}etex);
boxit.mpsym(btex\strut{\tt *sym}etex);
boxit.mnargs(btex\strut{\tt nargs}etex);
boxit.mpost(); mpost.dy=10pt;
boxjoin();
boxit.mpc(btex\strut{\tt pc}etex); mpc.e+(4mm,0)=mpsym.w;
drawboxed(mcall, mpsym, mnargs);
drawunboxed(mpc);
draw mpre.nw--mpost.sw;
draw mpre.ne--mpost.se;
drawarrow mpc.e--mpsym.w;
%% Frame:
boxjoin(a.sw=b.nw; a.se=b.ne);
boxit.fpre(); fpre.dy=10pt; fpre.dx=24pt;
boxit.fargn(btex\strut{\tt argn}etex);
boxit.fnargs(btex\strut{\tt nargs}etex);
boxit.fretpc(btex\strut{\tt retpc}etex);
boxit.fsp(btex\strut{\tt sp}etex);
boxit.fpost(); fpost.dy=10pt;
boxjoin();
mpre.c + (54mm,0) = fpre.c;
drawboxed(fargn, fnargs, fretpc, fsp);
draw fpre.nw--fpost.sw;
draw fpre.ne--fpost.se;
%% Stack:
boxjoin(a.sw=b.nw; a.se=b.ne);
boxit.spre(); spre.dy=10pt; spre.dx=24pt;
boxit.argiii(btex\strut{\tt arg3}etex);
boxit.argii(btex\strut{\tt arg2}etex);
boxit.argi(btex\strut{\tt arg1}etex);
boxit.more(btex\strut{}etex);
boxit.spost(); spost.dy=10pt;
boxjoin();
boxit.stackp(btex\strut{\tt stackp}etex);
1.5[argiii.se,argiii.ne]+(4mm,0)=stackp.w;
fpre.c + (28mm,0) = spre.c;
drawboxed(argiii, argii, argi, more);
drawunboxed(stackp);
draw spre.nw--spost.sw;
draw spre.ne--spost.se;
%% symtab entry:
boxit.empty(btex\strut etex); empty.dx=24pt;
boxit.defn(btex\strut{\tt*defn}etex); defn.dy=8pt;
empty.c = .5[mpre.c,fpre.c]-(0,36mm);
defn.nw=empty.sw; defn.ne=empty.se;
drawboxed(empty, defn);
%% pointers and labels:
label.top("Machine", mpre.n);
label.top("Frame", fpre.n);
label.top("Stack", spre.n);
label.top(btex\vbox{\parindent=0pt\hsize=48pt
  \parfillskip=0pt\baselineskip=10pt
  \leftskip=2pt plus 8pt \rightskip=2pt plus 8pt
  Symbol Table Entry}etex, empty.n);
drawarrow mpc.e--mpsym.w;
drawarrow fargn.e--argiii.w;
drawarrow stackp.w -- 1.5[argiii.se,argiii.ne];
drawarrow fretpc.w{left}..{left}1.5[mnargs.ne,mnargs.se];
drawarrow mpsym.e{dir-40} .. {dir-40}empty.w;
drawarrow fsp.w{dir220} .. {dir220}empty.e;
drawarrow defn.w{left} .. {dir30}2[mnargs.nw,mnargs.sw];
endfig;

end

