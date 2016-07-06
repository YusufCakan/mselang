{ MSElang Copyright (c) 2014-2016 by Martin Schreiber
   
    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
}
unit llvmops;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface
uses
 opglob,parserglob,msestream,llvmbcwriter,llvmbitcodes;

//todo: handle shiftcount overflow
 
function getoptable: poptablety;
//function getssatable: pssatablety;
//procedure allocproc(const asize: integer; var address: segaddressty);

procedure run(const atarget: tllvmbcwriter; const amain: boolean);
 
implementation
uses
 globtypes,sysutils,msesys,segmentutils,handlerglob,elements,msestrings,
 compilerunit,bcunitglob,identutils,
 handlerutils,llvmlists,errorhandler,__mla__internaltypes,opcode,msearrayutils,
 interfacehandler;

type
 icomparekindty = (ick_eq,ick_ne,
                  ick_ugt,ick_uge,ick_ult,ick_ule,
                  ick_sgt,ick_sge,ick_slt,ick_sle);
 idsarty = array[0..maxparamcount-1] of int32;
var
 pc: popinfoty;
 i32consts: array[0..32] of int32;
 trampolinealloc: suballocinfoty;
 
 
type
 internalfuncinfoty = record
  name: string;
  flags: subflagsty;
  params: pparamsty;
 end;
 internalfuncty = (if_printf,
                   if_malloc,if_free,if_calloc,if_realloc,if_memset,if_memcpy,
                   if__exit,
                   if_sin64);
const
 printfpar: array[0..0] of paramitemty = (
              (typelistindex: pointertype; flags: [])
 );
 printfparams: paramsty = (count: 1; items: @printfpar);
 mallocpar: array[0..1] of paramitemty = (
              (typelistindex: pointertype; flags: []), //result
              (typelistindex: sizetype; flags: [])     //size
 );
 mallocparams: paramsty = (count: 2; items: @mallocpar);
 freepar: array[0..0] of paramitemty = (
              (typelistindex: pointertype; flags: [])  //ptr
 );
 freeparams: paramsty = (count: 1; items: @freepar);
 callocpar: array[0..2] of paramitemty = (
              (typelistindex: pointertype; flags: []), //result
              (typelistindex: sizetype; flags: []),    //nelm
              (typelistindex: sizetype; flags: [])     //elsize
 );
 callocparams: paramsty = (count: 3; items: @callocpar);
 reallocpar: array[0..2] of paramitemty = (
              (typelistindex: pointertype; flags: []), //result
              (typelistindex: pointertype; flags: []), //source
              (typelistindex: sizetype; flags: [])     //size
 );
 reallocparams: paramsty = (count: 3; items: @reallocpar);
 memsetpar: array[0..3] of paramitemty = (
              (typelistindex: pointertype; flags: []), //result
              (typelistindex: pointertype; flags: []), //s data
              (typelistindex: inttype; flags: []),     //c fill value
              (typelistindex: sizetype; flags: [])     //n count
 );
 memsetparams: paramsty = (count: 4; items: @memsetpar);
 memcpypar: array[0..3] of paramitemty = (
              (typelistindex: pointertype; flags: []), //result
              (typelistindex: pointertype; flags: []), //dest
              (typelistindex: pointertype; flags: []), //source
              (typelistindex: sizetype; flags: [])     //count
 );
 memcpyparams: paramsty = (count: 4; items: @memcpypar);

 _exitpar: array[0..0] of paramitemty = (
              (typelistindex: inttype; flags: [])      //status
 );
 _exitparams: paramsty = (count: 1; items: @_exitpar);

 _Unwind_RaiseExceptionpar: array[0..0] of paramitemty = (
              (typelistindex: pointertype; flags: [])  //ptr
 );
 _Unwind_RaiseExceptionparams: paramsty = 
                      (count: 1; items: @_Unwind_RaiseExceptionpar);

 ffunc64par: array[0..1] of paramitemty = (
              (typelistindex: floattype; flags: []),   //result
              (typelistindex: floattype; flags: [])
 );
 ffunc64params: paramsty = (count: 2; items: @ffunc64par);

//todo: use llvm intinsics where possible 
 internalfuncconsts: array[internalfuncty] of internalfuncinfoty = (
  (name: 'printf'; flags: [sf_proto,sf_vararg]; params: @printfparams),
  (name: 'malloc'; flags: [sf_proto,sf_function]; params: @mallocparams),
  (name: 'free'; flags: [sf_proto]; params: @freeparams),
  (name: 'calloc'; flags: [sf_proto,sf_function]; params: @callocparams),
  (name: 'realloc'; flags: [sf_proto,sf_function]; params: @reallocparams),
  (name: 'memset'; flags: [sf_proto,sf_function]; params: @memsetparams),
  (name: 'memcpy'; flags: [sf_proto,sf_function]; params: @memcpyparams),
  (name: '_exit'; flags: [sf_proto]; params: @_exitparams),
  (name: 'llvm.sin.f64'; flags: [sf_proto,sf_function]; params: @ffunc64params)
 );

type
 internalstringinfoty = record
  text: string;
 end;
 internalstringty = (is_ret,is_card32,is_int8,is_int16,is_int32,is_int64,
                     is_char8,is_string8,is_pointer,is_flo64);
const
 internalstringconsts: array[internalstringty] of internalstringinfoty = (
  (text: #$a#0),        //is_ret,
  (text: '%u'#0),       //is_card32,
  (text: '%hhd'#0),     //is_int8,
  (text: '%hd'#0),      //is_int16,
  (text: '%d'#0),       //is_int32,
  (text: '%lld'#0),     //is_int64,
  (text: '%c'#0),       //is_char8,
  (text: '%s'#0),       //is_string8,
  (text: '%p'#0),       //is_pointer
  (text: '%e'#0)        //is_flo64
 );  

var
 bcstream: tllvmbcwriter;
 globconst: string;
 internalfuncs: array[internalfuncty] of int32;
 internalstrings: array[internalstringty] of int32;
 
procedure outbinop(const aop: BinaryOpcodes);
begin
 with pc^.par do begin
  bcstream.emitbinop(aop,bcstream.ssaval(ssas1),bcstream.ssaval(ssas2));
 end;
end;

procedure notimplemented();
begin
 raise exception.create('LLVM OP not implemented');
end;

procedure storeseg(const source: int32);
begin
 with pc^.par do begin
  if af_aggregate in memop.t.flags then begin
   bcstream.emitsegdataaddresspo(memop);
//   bcstream.emitgetelementptr(bcstream.globval(a.address),
//                                         bcstream.constval(offset));
//   bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(t.listindex));
   bcstream.emitstoreop(source,bcstream.relval(0));
  end
  else begin
   bcstream.emitstoreop(source,
                  bcstream.globval(memop.segdataaddress.a.address));
  end;
 end;
end;

procedure storeseg();
begin
 storeseg(bcstream.ssaval(pc^.par.ssas1));
end;

procedure storelastseg(); //store last ssa value
begin
 storeseg(bcstream.relval(0));
end;

procedure loadseg();
begin
 with pc^.par do begin
  if af_aggregate in memop.t.flags then begin
   bcstream.emitsegdataaddresspo(memop);
   bcstream.emitloadop(bcstream.relval(0));
  end
  else begin
   bcstream.emitloadop(bcstream.globval(memop.segdataaddress.a.address));
  end;
 end;
end;

procedure storeloc(const source: int32);
begin
 with pc^.par do begin
  with memop,locdataaddress do begin
   if a.framelevel >= 0 then begin  //nested variable
    bcstream.emitgetelementptr(bcstream.subval(0),
            //pointer to array of pointer to local alloc
                                           bcstream.constval(a.address));
            //byte offset in array
    bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
    bcstream.emitloadop(bcstream.relval(0));
            //pointer to variable
    if af_aggregate in t.flags then begin
     bcstream.emitnopssaop();          //agregatessa = 3
     bcstream.emitgetelementptr(bcstream.relval(1),bcstream.constval(offset));
    end;
    bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(t.listindex));
    bcstream.emitstoreop(source,bcstream.relval(0));
   end
   else begin
    if af_aggregate in t.flags then begin
     bcstream.emitlocdataaddresspo(memop);
     bcstream.emitstoreop(source,bcstream.relval(0));
    end
    else begin
     bcstream.emitstoreop(source,bcstream.allocval(a.address));
    end;
   end;
  end;
 end;
end;

procedure storelocindi(const source: int32);
var
 str1,str2,dest1,dest2: shortstring;
begin
 with pc^.par do begin           
  with memop,locdataaddress do begin
  {$ifdef mse_checkinternalerror}
   if a.framelevel >= 0 then begin  //nested variable not possible, called from
                                    //popparindi*() only.
    internalerror(ie_llvm,'20150313A');
   end;
  {$endif}
   bcstream.emitloadop(bcstream.allocval(a.address)); //^variable
   if af_aggregate in t.flags then begin
    bcstream.emitnopssaop(); //aggregatessa = 3
    bcstream.emitgetelementptr(bcstream.relval(1),
                          bcstream.constval(offset));
   end;
   bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(t.listindex));
   bcstream.emitstoreop(source,bcstream.relval(0));
  end;
 end;
end;

procedure storeloc();
begin
 storeloc(bcstream.ssaval(pc^.par.ssas1));
end;

procedure storelastloc(); //store last ssa value
begin
 storeloc(bcstream.relval(0));
end;

procedure loadindirect();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),
                    bcstream.ptypeval(memop.t.listindex));
  bcstream.emitloadop(bcstream.relval(0));
 end;
end;

procedure loadloc(const indirect: boolean);
var
 i1: int32;
begin
 with pc^.par do begin
  with memop do begin
   if indirect then begin
    i1:= bcstream.ptypeval(t.listindex);
   end
   else begin
    i1:= bcstream.typeval(t.listindex);
   end;
   if af_temp in t.flags then begin
    bcstream.emitbitcast(bcstream.ssaval(tempdataaddress.a.ssaindex),i1);
   end
   else begin
    if locdataaddress.a.framelevel >= 0 then begin
     bcstream.emitgetelementptr(bcstream.subval(0),
             //pointer to array of pointer to local alloc
                             bcstream.constval(locdataaddress.a.address));
             //byte offset in array
     bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
     bcstream.emitloadop(bcstream.relval(0));
             //pointer to variable
     if af_aggregate in t.flags then begin
      bcstream.emitnopssaop();          //agregatessa = 3
      bcstream.emitgetelementptr(bcstream.relval(1),
                        bcstream.constval(locdataaddress.offset));
     end;
     bcstream.emitbitcast(bcstream.relval(0),i1+1); //pointer
     bcstream.emitloadop(bcstream.relval(0));
    end
    else begin
     if af_aggregate in t.flags then begin
      bcstream.emitlocdataaddresspo(memop);
      bcstream.emitloadop(bcstream.relval(0));
     end
     else begin
      bcstream.emitloadop(bcstream.allocval(locdataaddress.a.address));
                  //indirect?
     end;
    end;
   end;
  end;
 end;
end;

procedure loadlocindi();
begin
 with pc^.par.memop do begin
  loadloc(true);
  bcstream.emitloadop(bcstream.relval(0));
 end;   
end;

procedure comparessa(const apredicate: predicate);
begin
 with pc^.par do begin
  bcstream.emitcmpop(apredicate,bcstream.ssaval(ssas1),bcstream.ssaval(ssas2));
 end;
end;

procedure callcompilersub(const asub: compilersubty;
          const afunc: boolean; const aparams: array of int32);
begin
 bcstream.emitcallop(afunc,bcstream.globval(compilersubids[asub]),aparams);
end;

procedure nopop();
begin
 with pc^.par do begin
  bcstream.emitnopssaop();
 end;
end;

procedure labelop();
begin
 with pc^.par do begin
  bcstream.emitbrop(opaddress.bbindex);
 end;
end;

var
// exitcodeaddress: segaddressty;
 finihandler: int32; //globid
 codestarted: boolean;
 ismain: boolean;

procedure startllvmcode();
const
 constlinkage = li_internal;
var
 ele1,ele2: elementoffsetty;
 po1: punitdataty;
 po2: pvardataty;
 po3: ptypedataty;
 po4: popinfoty;
 int1: integer;
 str1,str2: shortstring;
 funcs1: internalfuncty;
 strings1: internalstringty;
 compilersub1: compilersubty;
 poclassdef,peclassdef: ^classdefinfoty;
 povirtual,pevirtual: popaddressty;
 i1,i2,i3: int32;
 virtualcapacity: int32;
 virtualsubs,virtualsubconsts: pint32;
 countpo,counte: pint32;
 intfpo: pintfdefinfoty;
 unitheader1: bcunitinfoty;
begin
 codestarted:= true;
 for int1:= low(i32consts) to high(i32consts) do begin
  i32consts[int1]:= info.s.unitinfo^.llvmlists.constlist.addi32(int1).listid;
 end;
 fillchar(trampolinealloc,sizeof(trampolinealloc),0); //used in subbeginop

 int1:= getsegmentsize(seg_globconst);
 if int1 > 0 then begin                               //global consts
  bcstream.constseg:= info.s.unitinfo^.llvmlists.globlist.addinitvalue(gak_var,
             info.s.unitinfo^.llvmlists.constlist.
             addvalue(getsegmentpo(seg_globconst,0)^,int1).listid,constlinkage);
 end;

 for funcs1:= low(internalfuncs) to high(internalfuncs) do begin
                                             //llvm utility functions
  with internalfuncconsts[funcs1] do begin
   internalfuncs[funcs1]:= info.s.unitinfo^.llvmlists.globlist.
                      addexternalsubvalue(flags,params^,getidentname(name));
  end;
 end;
 for strings1:= low(internalstringconsts) to high(internalstringconsts) do begin
                                       //string consts
  with internalstringconsts[strings1] do begin
   internalstrings[strings1]:= info.s.unitinfo^.llvmlists.globlist.
            addinitvalue(gak_const,
                     info.s.unitinfo^.llvmlists.constlist.
                 addvalue(pointer(text)^,length(text)).listid,constlinkage);
  end;
 end;

 countpo:= getsegmentbase(seg_intfitemcount); //interfaces
 counte:= getsegmenttop(seg_intfitemcount);
 intfpo:= getsegmentbase(seg_intf);
 while countpo < counte do begin
  if countpo^ > 0 then begin
   pint32(intfpo)^:= info.s.unitinfo^.llvmlists.globlist.
          addinitvalue(gak_const,
              info.s.unitinfo^.llvmlists.constlist.
                               addintfdef(intfpo,countpo^).listid,constlinkage);
  end;
  inc(pointer(intfpo),sizeof(intfpo^)+countpo^*opaddresssize);
  inc(countpo);
 end;

 poclassdef:= getsegmentbase(seg_classdef);
 peclassdef:= getsegmenttop(seg_classdef);
 virtualcapacity:= 0;
 virtualsubs:= nil; 
 virtualsubconsts:= nil;
 countpo:= getsegmentbase(seg_classintfcount);
// try
  while poclassdef < peclassdef do begin   //classes
   pint32(poclassdef)^:= info.s.unitinfo^.llvmlists.globlist.
            addinitvalue(gak_const,info.s.unitinfo^.llvmlists.constlist.
                         addclassdef(poclassdef,countpo^).listid,constlinkage);
   poclassdef:= pointer(poclassdef) +
                        poclassdef^.header.allocs.classdefinterfacestart +
                                                         countpo^*pointersize;
   inc(countpo);
  end;
// finally
  if virtualsubs <> nil then begin
   freemem(virtualsubs);
   freemem(virtualsubconsts);
  end;
// end;
 with info.s.unitinfo^ do begin
  unitheader1.guid:= filematch.guid;
  with llvmlists do begin
   bcstream.start(constlist,globlist,metadatalist,unitheader1,
                     'e-m:e-p:32:32-f64:32:64-f80:32-n8:16:32-S128',
                     'i386-unknown-linux-gnu'); //todo: real values
  end;
 end;
end;

procedure beginparseop();
begin
 startllvmcode(); 
 with pc^.par.beginparse do begin
//  llvmops.exitcodeaddress:= exitcodeaddress;
  if finisub = 0 then begin
   llvmops.finihandler:= 0;
  end
  else begin
   llvmops.finihandler:= getoppo(finisub)^.par.subbegin.globid;
  end;
 end;
end;

procedure endparseop();
begin
 bcstream.stop();
end;

procedure beginunitcodeop();
begin
 if not codestarted then begin
  startllvmcode();
 end;
end;

procedure endunitop();
begin
 if info.modularllvm and not ismain then begin
  bcstream.stop();
 end;
end;

procedure mainop();
begin
 with pc^.par do begin
  bcstream.beginsub([]{false},nullallocs,main.blockcount);
 end;
end;

procedure progendop();
var
 i1: int32;
begin
 with pc^.par do begin
  bcstream.emitloadop(bcstream.valindex(progend.exitcodeaddress));
 end;
 bcstream.emitretop(bcstream.ssaindex-1);
 bcstream.endsub();
end;

procedure haltop();
begin
 if finihandler <> 0 then begin
  bcstream.emitcallop(false,bcstream.globval(finihandler),[]);
 end;  
 with pc^.par do begin
  bcstream.emitloadop(bcstream.valindex(progend.exitcodeaddress));
 end;
 bcstream.emitcallop(false,bcstream.globval(internalfuncs[if__exit]),
                                                        [bcstream.relval(0)]);
end;

procedure movesegreg0op();
begin
 notimplemented();
end;
procedure moveframereg0op();
begin
 notimplemented();
end;
procedure popreg0op();
begin
 notimplemented();
end;
procedure increg0op();
begin
 notimplemented();
end;

procedure phiop();
begin
 with pc^.par do begin
  bcstream.emitphiop(bcstream.typeval(phi.t.listindex),
                                getsegmentpo(seg_localloc,phi.philist));
 end;
end;

procedure gotoop();
begin
 with pc^.par do begin
  bcstream.emitbrop(getoppo(opaddress.opaddress+1)^.par.opaddress.bbindex);
 end;
end;

procedure gotofalseop();
begin
 with pc^.par do begin
  bcstream.emitbrop(bcstream.ssaval(ssas1),opaddress.bbindex,
             getoppo(opaddress.opaddress+1)^.par.opaddress.bbindex);
 end;
end;

procedure gototrueop();
begin
 with pc^.par do begin
  bcstream.emitbrop(bcstream.ssaval(ssas1),
             getoppo(opaddress.opaddress+1)^.par.opaddress.bbindex,
                                                         opaddress.bbindex);
 end;
end;

procedure compjmpimm(const apredicate: predicate);
begin
 with pc^.par do begin
  bcstream.emitcmpop(apredicate,bcstream.ssaval(ssas1),
                        bcstream.constval(cmpjmpimm.imm.llvm.listid));
  bcstream.emitbrop(bcstream.relval(0),
             getoppo(cmpjmpimm.destad.opaddress)^.par.opaddress.bbindex,
                                                    cmpjmpimm.destad.bbindex);
                           //label
 end;
end;

procedure cmpjmpneimm4op();
begin
 compjmpimm(icmp_ne);
end;

procedure cmpjmpeqimm4op();
begin
 compjmpimm(icmp_eq);
end;

procedure cmpjmploimm4op();
begin
 compjmpimm(icmp_slt);
end;

procedure cmpjmpgtimm4op();
begin
 compjmpimm(icmp_sgt);
end;

procedure cmpjmploeqimm4op();
begin
 compjmpimm(icmp_sle);
end;

procedure ifop();
begin
 with pc^.par do begin
  bcstream.emitbrop(bcstream.ssaval(ssas1),opaddress.bbindex,
                         getoppo(opaddress.opaddress)^.par.opaddress.bbindex);
 end;
end;

procedure whileop();
begin
 with pc^.par do begin
  bcstream.emitbrop(bcstream.ssaval(ssas1),opaddress.bbindex,
                         getoppo(opaddress.opaddress)^.par.opaddress.bbindex);
 end;
end;

procedure untilop();
begin
 with pc^.par do begin
  bcstream.emitbrop(bcstream.ssaval(ssas1),opaddress.bbindex,
                         getoppo(opaddress.opaddress+1)^.par.opaddress.bbindex);
 end;
end;

procedure writelnop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[is_ret]),
                                             bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                                                      [bcstream.relval(0)]);
 end;
end;

procedure writebooleanop();
begin
 notimplemented();
end;
 
procedure writecardinalop(const typestring: internalstringty);
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[typestring]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writecardinal8op();
begin
 writecardinalop(is_int8);
end;

procedure writecardinal16op();
begin
 writecardinalop(is_int16);
end;

procedure writecardinal32op();
begin
 writecardinalop(is_int32);
end;

procedure writecardinal64op();
begin
 writecardinalop(is_int64);
end;

procedure writeintegerop(const typestring: internalstringty);
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[typestring]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writeinteger8op();
begin
 writeintegerop(is_int8);
end;

procedure writeinteger16op();
begin
 writeintegerop(is_int16);
end;

procedure writeinteger32op();
begin
 writeintegerop(is_int32);
end;

procedure writeinteger64op();
begin
 writeintegerop(is_int64);
end;

procedure writefloat64op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[is_flo64]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writestring8op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[is_string8]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writechar8op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[is_char8]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writepointerop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(internalstrings[is_pointer]),
                                           bcstream.typeval(pointertype));
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_printf]),
                               [bcstream.relval(0),bcstream.ssaval(ssas1)]);
 end;
end;

procedure writeclassop();
begin
 writepointerop();
end;

procedure writeenumop();
begin
 notimplemented();
end;

procedure pushop();
begin
 //dummy
end;

procedure popop();
begin
 //dummy
end;

procedure swapstackop();
begin
 //dummy
end;

procedure pushimm1op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimm8op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimm16op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimm32op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimm64op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimmf64op();
begin
 with pc^.par do begin
  bcstream.emitpushconst(imm.llvm);
 end;
end;

procedure pushimmdatakindop();
begin
 notimplemented();
end;

procedure ordtoflo64();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),bcstream.typeval(das_f64),
                                                               CAST_SITOFP);
 end;
end;

procedure card8toflo64op();
begin
 ordtoflo64();
end;
procedure card16toflo64op();
begin
 ordtoflo64();
end;
procedure card32toflo64op();
begin
 ordtoflo64();
end;
procedure card64toflo64op();
begin
 ordtoflo64();
end;

procedure int8toflo64op();
begin
 ordtoflo64();
end;
procedure int16toflo64op();
begin
 ordtoflo64();
end;
procedure int32toflo64op();
begin
 ordtoflo64();
end;
procedure int64toflo64op();
begin
 ordtoflo64();
end;

procedure potoint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),bcstream.typeval(das_32),
                                                               CAST_PTRTOINT);
 end;
end;

procedure inttopoop();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),bcstream.typeval(pointertype),
                                                               CAST_INTTOPTR);
 end;
end;

procedure and1op();
begin
 outbinop(BINOP_AND);
end;

procedure and32op();
begin
 outbinop(BINOP_AND);
end;

procedure or1op();
begin
 outbinop(BINOP_OR);
end;

procedure or32op();
begin
 outbinop(BINOP_OR);
end;

procedure xor1op();
begin
 outbinop(BINOP_XOR);
end;

procedure xor32op();
begin
 outbinop(BINOP_XOR);
end;

procedure shl32op();
begin
 outbinop(BINOP_SHL);
end;

procedure shr32op();
begin
 outbinop(BINOP_LSHR);
end;
{
procedure shrint32op();
begin
 outbinop(BINOP_ASHR);
end;
}
procedure mulcard32op();
begin
 outbinop(BINOP_MUL);
end;

procedure mulint32op();
begin
 outbinop(BINOP_MUL);
end;

procedure divcard32op();
begin
 outbinop(BINOP_UDIV);
end;

procedure divint32op();
begin
 outbinop(BINOP_SDIV);
end;

procedure mulimmint32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_MUL,bcstream.ssaval(ssas1),
                                    bcstream.constval(imm.llvm.listid));
 end;
end;

procedure mulflo64op();
begin
 outbinop(BINOP_MUL);
end;

procedure divflo64op();
begin
 outbinop(BINOP_SDIV);
end;

procedure addint32op();
begin
 outbinop(BINOP_ADD);
end;

procedure subint32op();
begin
 outbinop(BINOP_SUB);
end;

procedure addpoint32op();
begin
 with pc^.par do begin
  bcstream.emitgetelementptr(bcstream.ssaval(ssas1),bcstream.ssaval(ssas2));
 end;
end;

procedure subpoint32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_SUB,bcstream.constval(ord(nc_i32)),
                                              bcstream.ssaval(ssas2));
  bcstream.emitgetelementptr(bcstream.ssaval(ssas1),bcstream.relval(0));
 end;
end;

procedure subpoop();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(sizetype),CAST_PTRTOINT);
  bcstream.emitcastop(bcstream.ssaval(ssas2),
                               bcstream.typeval(sizetype),CAST_PTRTOINT);
  bcstream.emitbinop(BINOP_SUB,bcstream.relval(1),bcstream.relval(0));
 end;
end;

procedure addimmint32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(binop_add,bcstream.ssaval(ssas1),
                                           bcstream.constval(imm.llvm.listid));
 end;
end;

procedure addflo64op();
begin
 outbinop(BINOP_ADD);
end;

procedure subflo64op();
begin
 outbinop(BINOP_SUB);
end;

procedure diffsetop(); //todo: arbitrary size
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_XOR,bcstream.constval(ord(mc_i32)),
                                         bcstream.ssaval(ssas2)); //not
  bcstream.emitbinop(BINOP_AND,bcstream.ssaval(ssas1),bcstream.relval(0));
 end;
end;

procedure xorsetop(); //todo: arbitrary size
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_XOR,bcstream.ssaval(ssas1),bcstream.ssaval(ssas2));
 end;
end;

procedure setbitop(); //todo: arbitrary size
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_SHL,bcstream.constval(ord(oc_i32)),
                                             bcstream.ssaval(ssas2));
  bcstream.emitbinop(BINOP_OR,bcstream.ssaval(ssas1),bcstream.relval(0));
 end;
end;

procedure card8tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_16)),CAST_ZEXT);
 end;
end;

procedure card8tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                            bcstream.typeval(ord(das_32)),CAST_ZEXT);
 end;
end;

procedure card8tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                            bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card16tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card16tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_32)),CAST_ZEXT);
 end;
end;

procedure card16tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card32tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card32tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure card32tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card64tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card64tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure card64tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_32)),CAST_TRUNC);
 end;
end;

procedure int8toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                             bcstream.typeval(ord(das_16)),CAST_SEXT);
 end;
end;

procedure int8toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                              bcstream.typeval(ord(das_32)),CAST_SEXT);
 end;
end;

procedure int8toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int16toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int16toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(ord(das_32)),CAST_SEXT);
 end;
end;

procedure int16toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int32toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                               bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int32toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure int32toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int64toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int64toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure int64toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_TRUNC);
 end;
end;

procedure card8toint8op();
begin
 //dummy
end;

procedure card8toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_ZEXT);
 end;
end;

procedure card8toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_ZEXT);
 end;
end;

procedure card8toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card16toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card16toint16op();
begin
 //dummy
end;

procedure card16toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_ZEXT);
 end;
end;

procedure card16toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card32toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card32toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card32toint32op();
begin
 //dummy
end;

procedure card32toint64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_ZEXT);
 end;
end;

procedure card64toint8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure card64toint16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure card64toint32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_TRUNC);
 end;
end;

procedure card64toint64op();
begin
 //dummy
end;

procedure int8tocard8op();
begin
 //dummy
end;

procedure int8tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_SEXT);
 end;
end;

procedure int8tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_SEXT);
 end;
end;

procedure int8tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int16tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int16tocard16op();
begin
 //dummy
end;

procedure int16tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_SEXT);
 end;
end;

procedure int16tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int32tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int32tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure int32tocard32op();
begin
 //dummy
end;

procedure int32tocard64op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_64)),CAST_SEXT);
 end;
end;

procedure int64tocard8op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_8)),CAST_TRUNC);
 end;
end;

procedure int64tocard16op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_16)),CAST_TRUNC);
 end;
end;

procedure int64tocard32op();
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                                bcstream.typeval(ord(das_32)),CAST_TRUNC);
 end;
end;

procedure int64tocard64op();
begin
 //dummy
end;

procedure chartostring8op();
begin
 with pc^.par do begin
  callcompilersub(cs_chartostring8,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure arraytoopenarop();
begin
 with pc^.par do begin
  callcompilersub(cs_arraytoopenar,true,[bcstream.constval(imm.llvm.listid),
                                                    bcstream.ssaval(ssas1)]);
 end;
end;

procedure dynarraytoopenarop();
begin
 with pc^.par do begin
  callcompilersub(cs_dynarraytoopenar,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure listtoopenarop();
var
 po1,poe: plistitemallocinfoty;
 i1: int32;
begin
 with pc^.par do begin
  bcstream.emitalloca(bcstream.ptypeval(listtoopenar.arraytype)); //1 ssa
  bcstream.emitbitcast(bcstream.relval(0),bcstream.typeval(das_pointer));
                                                                  //1 ssa
  i1:= bcstream.relval(0);
  po1:= getsegmentpo(seg_localloc,listinfo.allocs);
  poe:= po1 + listinfo.alloccount;
  while po1 < poe do begin
   bcstream.emitbitcast(bcstream.relval(0),
                   bcstream.ptypeval(listtoopenar.itemtype));     //1 ssa
   bcstream.emitstoreop(bcstream.ssaval(po1^.ssaindex),bcstream.relval(0));
   bcstream.emitgetelementptr(bcstream.relval(0),
                         bcstream.constval(listinfo.itemsize));   //2 ssa
   inc(po1);
  end;
  callcompilersub(cs_arraytoopenar,true,
                [bcstream.constval(listtoopenar.allochigh),i1]);  //1 ssa
 end;
end;

procedure not1op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_XOR,bcstream.constval(ord(mc_i1)),
                                                    bcstream.ssaval(ssas1));
 end;
end;

procedure not32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_XOR,bcstream.constval(ord(mc_i32)),
                                                    bcstream.ssaval(ssas1));
 end;
end;

procedure negcard32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_SUB,bcstream.constval(ord(nc_i32)),
                                                    bcstream.ssaval(ssas1));
 end;
end;

procedure negint32op();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_SUB,bcstream.constval(ord(nc_i32)),
                                                    bcstream.ssaval(ssas1));
 end;
end;

procedure negflo64op();
begin
 notimplemented();
end;

procedure offsetpoimm32op();
begin
 with pc^.par do begin
  bcstream.emitgetelementptr(bcstream.ssaval(ssas1),
                                    bcstream.constval(imm.llvm.listid));
 end;
end;

procedure incdecsegimmint32op();
begin
 with pc^.par,memimm do begin
  loadseg();
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.constval(llvm.listid));
  storelastseg();
 end;
end;

procedure incdecsegimmpo32op();
begin
 with pc^.par,memimm do begin
  loadseg();
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.constval(llvm.listid));
  storelastseg();
 end;
end;

procedure incdeclocimmint32op();
begin
 with pc^.par,memimm do begin
  loadloc(false);
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.constval(llvm.listid));
  storelastloc();
 end;
end;

procedure incdeclocimmpo32op();
begin
 with pc^.par,memimm do begin
  loadloc(false);
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.constval(llvm.listid));
  storelastloc();
 end;
end;

procedure incdecparimmint32op();
begin
 notimplemented();
end;

procedure incdecparimmpo32op();
begin
 incdeclocimmpo32op();
end;

procedure incdecparindiimmint32op();
begin
 notimplemented();
end;

procedure incdecparindiimmpo32op();
begin
 notimplemented();
end;

procedure incdecindiimmint32op();
begin
 with pc^.par,memimm do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(das_32));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                  bcstream.constval(llvm.listid));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure incdecindiimmpo32op();
begin
 with pc^.par,memimm do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitptroffset(bcstream.relval(0),bcstream.constval(llvm.listid));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure incsegint32op();
begin
 with pc^.par do begin
  loadseg();
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.ssaval(ssas2));
  storelastseg();
 end;
end;

procedure incsegpo32op();
begin
 with pc^.par do begin
  loadseg();
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.ssaval(ssas2));
  storelastseg();
 end;
end;

procedure inclocint32op();
begin
 with pc^.par do begin
  loadloc(false);
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.ssaval(ssas2));
  storelastloc();
 end;
end;

procedure inclocpo32op();
begin
 with pc^.par do begin
  loadloc(false);
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.ssaval(ssas2));
  storelastloc();
 end;
end;

procedure incparint32op();
begin
 notimplemented();
end;

procedure incparpo32op();
begin
 inclocpo32op();
end;

procedure incparindiint32op();
begin
 notimplemented();
end;

procedure incparindipo32op();
begin
 notimplemented();
end;

procedure incindiint32op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(das_32));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                  bcstream.ssaval(ssas2));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure incindipo32op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitptroffset(bcstream.relval(0),bcstream.ssaval(ssas2));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure decsegint32op();
begin
 with pc^.par do begin
  loadseg();
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.ssaval(ssas2));
  storelastseg();
 end;
end;

procedure decsegpo32op();
begin
 with pc^.par do begin
  loadseg();
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.ssaval(ssas2));
  storelastseg();
 end;
end;

procedure declocint32op();
begin
 with pc^.par do begin
  loadloc(false);
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                bcstream.ssaval(ssas2));
  storelastloc();
 end;
end;

procedure declocpo32op();
begin
 with pc^.par do begin
  loadloc(false);
  bcstream.emitgetelementptr(bcstream.relval(0),bcstream.ssaval(ssas1));
  storelastloc();
 end;
end;

procedure decparint32op();
begin
 notimplemented();
end;

procedure decparpo32op();
begin
 declocpo32op();
end;

procedure decparindiint32op();
begin
 notimplemented();
end;

procedure decparindipo32op();
begin
 notimplemented();
end;

procedure decindiint32op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(das_32));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitbinop(BINOP_ADD,bcstream.relval(0),
                                  bcstream.ssaval(ssas2));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure decindipo32op();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitptroffset(bcstream.relval(0),bcstream.ssaval(ssas2));
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure comparepo(const apredicate: predicate);
begin
 with pc^.par do begin
  bcstream.emitcastop(bcstream.ssaval(ssas1),
                              bcstream.typeval(sizetype),CAST_PTRTOINT);
  bcstream.emitcastop(bcstream.ssaval(ssas2),
                              bcstream.typeval(sizetype),CAST_PTRTOINT);
  bcstream.emitcmpop(apredicate,bcstream.relval(1),bcstream.relval(0));
 end;
end;

const
 scomps: array[compopkindty] of predicate = (
//     cok_eq, cmp_ne, cok_gt, cok_lt, cok_ge, cok_le
      icmp_eq,icmp_ne,icmp_sgt,icmp_slt,icmp_sge,icmp_sle);
 ucomps: array[compopkindty] of predicate = (
//     cok_eq, cmp_ne, cok_gt, cok_lt, cok_ge, cok_le
      icmp_eq,icmp_ne,icmp_ugt,icmp_ult,icmp_uge,icmp_ule);
 fcomps: array[compopkindty] of predicate = (
//     cok_eq,   cmp_ne,  cok_gt,  cok_lt,  cok_ge,  cok_le
      fcmp_oeq,fcmp_one,fcmp_ogt,fcmp_olt,fcmp_oge,fcmp_ole);

procedure cmppoop();
begin
 with pc^.par do begin
  comparessa(ucomps[stackop.compkind]);
 end;
end;

procedure cmpboolop();
begin
 with pc^.par do begin
  comparessa(ucomps[stackop.compkind]);
 end;
end;

procedure cmpcard32op();
begin
 with pc^.par do begin
  comparessa(ucomps[stackop.compkind]);
 end;
end;

procedure cmpint32op();
begin
 with pc^.par do begin
  comparessa(scomps[stackop.compkind]);
 end;
end;

procedure cmpflo64op();
begin
 with pc^.par do begin
  comparessa(fcomps[stackop.compkind]);
 end;
end;

procedure cmpstring8op();
begin
 notimplemented();
end;

procedure setcontainsop();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_XOR,bcstream.ssaval(ssas1),bcstream.ssaval(ssas2));
  bcstream.emitbinop(BINOP_AND,bcstream.ssaval(ssas1),bcstream.relval(0));
  bcstream.emitcmpop(ICMP_EQ,bcstream.relval(0),bcstream.constval(ord(nc_i32)));
 end;
end;

procedure setinop();
begin
 with pc^.par do begin
  bcstream.emitbinop(BINOP_SHL,bcstream.constval(ord(oc_i32)),
                                                      bcstream.ssaval(ssas1));
  bcstream.emitbinop(BINOP_AND,bcstream.ssaval(ssas2),bcstream.relval(0));
  bcstream.emitcmpop(ICMP_NE,bcstream.relval(0),bcstream.constval(ord(nc_i32)));
 end;
end;

procedure storesegnilop();
var
 str1: shortstring;
begin
 with pc^.par do begin
  bcstream.emitstoreop(bcstream.constval(nullpointer),
                     bcstream.globval(memop.segdataaddress.a.address));
 end;
end;

procedure storereg0nilop();
begin
 notimplemented();
end;

procedure storelocnilop();
begin
 storeloc(bcstream.constval(nullpointer));
{
 with pc^.par do begin
  bcstream.emitstoreop(bcstream.constval(nullpointer),
                                         bcstream.allocval(voffset));
 end;
}
end;

procedure storestacknilop(); 
begin
 with pc^.par do begin
 {//??? probably wrong indirection
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(das_pointer));
  bcstream.emitstoreop(bcstream.constval(nullpointer),
                                         bcstream.relval(0));
 }
  bcstream.emitbitcast(bcstream.constval(nullpointer),
                                          bcstream.typeval(das_pointer));
 end;
end;

procedure storestackrefnilop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(das_pointer));
//  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitstoreop(bcstream.constval(nullpointer),bcstream.relval(0));
 end;
end;

procedure storesegnilarop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(memop.segdataaddress.a.address),
                                                bcstream.typeval(pointertype));
  callcompilersub(cs_zeropointerar,false,[bcstream.relval(0),
                                          bcstream.constval(memop.t.size)]);
 end;
end;

procedure storelocnilarop();
begin
 notimplemented();
end;
procedure storereg0nilarop();
begin
 notimplemented();
end;
procedure storestacknilarop();
begin
 notimplemented();
end;
procedure storestackrefnilarop();
begin
 notimplemented();
end;

procedure storesegnildynarop();
begin
 notimplemented();
end;
procedure storelocnildynarop();
begin
 notimplemented();
end;
procedure storereg0nildynarop();
begin
 notimplemented();
end;
procedure storestacknildynarop();
begin
 notimplemented();
end;
procedure storestackrefnildynarop();
begin
 notimplemented();
end;

procedure finirefsizesegop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(memop.segdataaddress.a.address),
                                                bcstream.typeval(pointertype));
  callcompilersub(cs_finifrefsize,false,[bcstream.relval(0)]);
 end;
end;

procedure finirefsizelocop();
begin
 with pc^.par do begin
  bcstream.emitlocdataaddress(memop);
//  bcstream.emitbitcast(bcstream.allocval(voffset),
//                                                bcstream.typeval(pointertype));
  callcompilersub(cs_finifrefsize,false,[bcstream.relval(0)]);
 end;
end;

procedure finirefsizereg0op();
begin
 notimplemented();
end;
procedure finirefsizestackop();
begin
 notimplemented();
end;

procedure finirefsizestackrefop();
begin
 with pc^.par do begin
  callcompilersub(cs_finifrefsize,false,[bcstream.ssaval(ssas1)]);
{ 
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  callcompilersub(cs_finifrefsize,false,[bcstream.relval(0)]);
}
 end;
end;

procedure finirefsizesegarop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.globval(memop.segdataaddress.a.address),
                                                bcstream.typeval(pointertype));
  callcompilersub(cs_finirefsizear,false,[bcstream.relval(0),
                                             bcstream.constval(memop.t.size)]);
 end;
end;

procedure finirefsizelocarop();
begin
 notimplemented();
end;
procedure finirefsizereg0arop();
begin
 notimplemented();
end;
procedure finirefsizestackarop();
begin
 notimplemented();
end;
procedure finirefsizestackrefarop();
begin
 notimplemented();
end;

procedure finirefsizesegdynarop();
begin
 notimplemented();
end;
procedure finirefsizelocdynarop();
begin
 notimplemented();
end;
procedure finirefsizereg0dynarop();
begin
 notimplemented();
end;
procedure finirefsizestackdynarop();
begin
 notimplemented();
end;
procedure finirefsizestackrefdynarop();
begin
 notimplemented();
end;

procedure increfsizesegop();
begin
// with pc^.par do begin
//  bcstream.emitbitcast(bcstream.globval(memop.segdataaddress.a.address),
//                                                bcstream.typeval(pointertype));
 loadseg();
 callcompilersub(cs_increfsize,false,[bcstream.relval(0)]);
// end;
end;

procedure increfsizelocop();
begin
 loadloc(false);
 callcompilersub(cs_increfsize,false,[bcstream.relval(0)]);
end;

procedure increfsizereg0op();
begin
 notimplemented();
end;

procedure increfsizestackop();
begin
 with pc^.par do begin
  callcompilersub(cs_increfsize,false,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure increfsizestackrefop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  callcompilersub(cs_increfsize,false,[bcstream.relval(0)]);
 end;
end;

procedure increfsizesegarop();
begin
 notimplemented();
end;
procedure increfsizelocarop();
begin
 notimplemented();
end;
procedure increfsizereg0arop();
begin
 notimplemented();
end;
procedure increfsizestackarop();
begin
 notimplemented();
end;
procedure increfsizestackrefarop();
begin
 notimplemented();
end;

procedure increfsizesegdynarop();
begin
 notimplemented();
end;
procedure increfsizelocdynarop();
begin
 notimplemented();
end;
procedure increfsizereg0dynarop();
begin
 notimplemented();
end;
procedure increfsizestackdynarop();
begin
 notimplemented();
end;
procedure increfsizestackrefdynarop();
begin
 notimplemented();
end;

procedure decrefsizesegop();
begin
// with pc^.par do begin
 loadseg();
//  bcstream.emitloadop(bcstream.globval(memop.segdataaddress.a.address));
 callcompilersub(cs_decrefsize,false,[bcstream.relval(0)]);
// end;
end;

procedure decrefsizelocop();
begin
 with pc^.par do begin
  loadloc(false);
//  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.typeval(pointertype));
  callcompilersub(cs_decrefsize,false,[bcstream.relval(0)]);
 end;
end;

procedure decrefsizereg0op();
begin
 notimplemented();
end;

procedure decrefsizestackop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.typeval(pointertype));
  callcompilersub(cs_decrefsize,false,[bcstream.relval(0)]);
 end;
end;

procedure decrefsizestackrefop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  callcompilersub(cs_decrefsize,false,[bcstream.relval(0)]);
 end;
end;

procedure decrefsizesegarop();
begin
 notimplemented();
end;
procedure decrefsizelocarop();
begin
 notimplemented();
end;
procedure decrefsizereg0arop();
begin
 notimplemented();
end;
procedure decrefsizestackarop();
begin
 notimplemented();
end;
procedure decrefsizestackrefarop();
begin
 notimplemented();
end;

procedure decrefsizesegdynarop();
begin
 notimplemented();
end;
procedure decrefsizelocdynarop();
begin
 notimplemented();
end;
procedure decrefsizereg0dynarop();
begin
 notimplemented();
end;
procedure decrefsizestackdynarop();
begin
 notimplemented();
end;
procedure decrefsizestackrefdynarop();
begin
 notimplemented();
end;

procedure highstringop();
begin
 with pc^.par do begin
  callcompilersub(cs_highstring,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure highdynarop();
begin
 with pc^.par do begin
  callcompilersub(cs_highdynarray,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure highopenarop();
begin
 with pc^.par do begin
  callcompilersub(cs_highopenarray,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure lengthstringop();
begin
 with pc^.par do begin
  callcompilersub(cs_lengthstring,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure lengthdynarop();
begin
 with pc^.par do begin
  callcompilersub(cs_lengthdynarray,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure lengthopenarop();
begin
 with pc^.par do begin
  callcompilersub(cs_lengthopenarray,true,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure popseg8op();
begin
 storeseg();
end;

procedure popseg16op();
begin
 storeseg();
end;

procedure popseg32op();
begin
 storeseg();
end;

procedure popseg64op();
begin
 storeseg();
end;

procedure popsegpoop();
var
 str1: shortstring;
begin
 storeseg();
{
 with pc^.par do begin
  bcstream.emitstoreop(bcstream.ssaval(ssas1),
                     bcstream.globval(memop.segdataaddress.a.address));
 end;
}
end;

procedure popsegf16op();
begin
 storeseg();
end;

procedure popsegf32op();
begin
 storeseg();
end;

procedure popsegf64op();
begin
 storeseg();
end;

procedure popsegop();
begin
 storeseg();
end;

procedure poploc8op();
begin
 storeloc();
end;

procedure poploc16op();
begin
 storeloc();
end;

procedure poploc32op();
begin
 storeloc();
end;

procedure poploc64op();
begin
 storeloc();
end;

procedure poplocpoop();
begin
 storeloc();
end;

procedure poplocf16op();
begin
 storeloc();
end;

procedure poplocf32op();
begin
 storeloc();
end;

procedure poplocf64op();
begin
 storeloc();
end;

procedure poplocop();
begin
 storeloc();
end;

procedure poplocindi8op();
begin
 storeloc();
end;

procedure poplocindi16op();
begin
 storeloc();
end;

procedure poplocindi32op();
begin
 storeloc();
end;

procedure poplocindi64op();
begin
 storeloc();
end;

procedure poplocindipoop();
begin
 notimplemented();
end;

procedure poplocindif16op();
begin
 storeloc();
end;

procedure poplocindif32op();
begin
 storeloc();
end;

procedure poplocindif64op();
begin
 storeloc();
end;

procedure poplocindiop();
begin
 notimplemented();
end;

procedure poppar8op();
begin
 storeloc();
end;

procedure poppar16op();
begin
 storeloc();
end;

procedure poppar32op();
begin
 storeloc();
end;

procedure poppar64op();
begin
 storeloc();
end;

procedure popparpoop();
begin
 storeloc();
end;

procedure popparf16op();
begin
 storeloc();
end;

procedure popparf32op();
begin
 storeloc();
end;

procedure popparf64op();
begin
 storeloc();
end;

procedure popparop();
begin
 notimplemented();
end;

procedure popparindi8op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindi16op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindi32op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindi64op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindipoop();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindif16op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindif32op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindif64op();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure popparindiop();
begin
 storelocindi(bcstream.ssaval(pc^.par.ssas1));
end;

procedure pushnilop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.constval(nullpointer),
                               bcstream.typeval(pointertype));
 end;
end;
{
procedure pushstack8op();
begin
 notimplemented();
end;

procedure pushstack16op();
begin
 notimplemented();
end;

procedure pushstack32op();
begin
 notimplemented();
end;

procedure pushstack64op();
begin
 notimplemented();
end;

procedure pushstackpoop();
begin
 notimplemented();
end;

procedure pushstackindi8op();
begin
 notimplemented();
end;

procedure pushstackindi16op();
begin
 notimplemented();
end;

procedure pushstackindi32op();
begin
 notimplemented();
end;

procedure pushstackindi64op();
begin
 notimplemented();
end;

procedure pushstackindipoop();
begin
 notimplemented();
end;
}
procedure pushsegaddressop();
begin
 notimplemented();
end;

procedure pushseg8op();
begin
 loadseg();
end;

procedure pushseg16op();
begin
 loadseg();
end;

procedure pushseg32op();
begin
 loadseg();
end;

procedure pushseg64op();
begin
 loadseg();
end;

procedure pushsegpoop();
begin
 loadseg();
end;

procedure pushsegf16op();
begin
 loadseg();
end;

procedure pushsegf32op();
begin
 loadseg();
end;

procedure pushsegf64op();
begin
 loadseg();
end;

procedure pushsegop();
begin
 loadseg();
end;
{
procedure pushsegopenarop();
begin
 notimplemented();
end;
}
procedure pushloc8op();
begin
 loadloc(false);
end;

procedure pushloc16op();
begin
 loadloc(false);
end;

procedure pushloc32op();
begin
 loadloc(false);
end;

procedure pushloc64op();
begin
 loadloc(false);
end;

procedure pushlocpoop();
begin
 loadloc(false);
end;

procedure pushlocf16op();
begin
 loadloc(false);
end;

procedure pushlocf32op();
begin
 loadloc(false);
end;

procedure pushlocf64op();
begin
 loadloc(false);
end;

procedure pushlocop();
begin
 loadloc(false);
end;

procedure pushpar8op();
begin
 loadloc(false);
end;

procedure pushpar16op();
begin
 loadloc(false);
end;

procedure pushpar32op();
begin
 loadloc(false);
end;

procedure pushpar64op();
begin
 loadloc(false);
end;

procedure pushparpoop();
begin
 loadloc(false);
end;

procedure pushparf16op();
begin
 loadloc(false);
end;

procedure pushparf32op();
begin
 loadloc(false);
end;

procedure pushparf64op();
begin
 loadloc(false);
end;

procedure pushparop();
begin
 loadloc(false);
end;

procedure pushlocindi8op();
begin
 loadlocindi();
end;

procedure pushlocindi16op();
begin
 loadlocindi();
end;

procedure pushlocindi32op();
begin
 loadlocindi();
end;

procedure pushlocindi64op();
begin
 loadlocindi();
end;

procedure pushlocindipoop();
begin
 loadlocindi();
end;

procedure pushlocindif16op();
begin
 loadlocindi();
end;

procedure pushlocindif32op();
begin
 loadlocindi();
end;

procedure pushlocindif64op();
begin
 loadlocindi();
end;

procedure pushlocindiop();
begin
 loadlocindi();
end;

procedure pushaddrop();
begin
 notimplemented();
end;

procedure pushlocaddrop();
begin
 with pc^.par do begin
  if memop.locdataaddress.a.framelevel >= 0 then begin
   bcstream.emitgetelementptr(bcstream.subval(0),
           //pointer to array of pointer to local alloc
                           bcstream.constval(memop.locdataaddress.a.address));
           //byte offset in array
   bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
   bcstream.emitloadop(bcstream.relval(0));
           //pointer to variable
   if af_aggregate in memop.t.flags then begin
    bcstream.emitnopssaop();          //agregatessa = 3
    bcstream.emitgetelementptr(bcstream.relval(1),
                      bcstream.constval(memop.locdataaddress.offset));
   end;
  end
  else begin
   bcstream.emitlocdataaddress(memop); //2 ssa
  end;
 end;
end;
{
procedure pushlocaddrindiop();          //todo: nested frames
begin
 with pc^.par do begin
  if memop.locdataaddress.a.framelevel >= 0 then begin
   notimplemented();
  end;
  bcstream.emitloadop(bcstream.allocval(memop.locdataaddress.a.address));
  bcstream.emitgetelementptr(bcstream.relval(0),
                bcstream.constval(memop.locdataaddress.offset));
 end;
end;
}
procedure pushsegaddrop();
var
 str1: shortstring;
begin
 with pc^.par do begin
  bcstream.emitsegdataaddress(memop);
 end;
end;
{
procedure pushsegaddrindiop(); //offset after load
begin
 with pc^.par do begin
  bcstream.emitloadop(bcstream.globval(memop.segdataaddress.a.address));
  bcstream.emitgetelementptr(bcstream.relval(0),
                bcstream.constval(memop.segdataaddress.offset));
 end;
end;
}
procedure pushstackaddrop();
begin
 with pc^.par.memop do begin
  bcstream.emitalloca(bcstream.ptypeval(t.listindex));
  bcstream.emitstoreop(bcstream.ssaval(tempdataaddress.a.ssaindex),
                                                        bcstream.relval(0));
  bcstream.emitgetelementptr(bcstream.relval(0),
                           bcstream.constval(tempdataaddress.offset))
 end;
// bcstream.emitsegdataaddress(memop);
end;
{
procedure pushstackaddrindiop();
begin
 notimplemented();
end;
}
procedure pushduppoop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.typeval(das_pointer));
 end;
end;

procedure indirect8op();
begin
 loadindirect();
end;

procedure indirect16op();
begin
 loadindirect();
end;

procedure indirect32op();
begin
 loadindirect();
end;

procedure indirect64op();
begin
 loadindirect();
end;

procedure indirectpoop();
var
 dest1,dest2: shortstring;
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
 end;
end;

procedure indirectf16op();
begin
 loadindirect();
end;

procedure indirectf32op();
begin
 loadindirect();
end;

procedure indirectf64op();
begin
 loadindirect();
end;

procedure indirectpooffsop();
begin //offset after indirect
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitptroffset(bcstream.relval(0),bcstream.constval(voffset));
 end;
end; 

procedure indirectoffspoop();
begin
 notimplemented();
end; //offset before indirect
procedure indirectop();
begin
 notimplemented();
end;

procedure popindirect();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas2),
                              bcstream.ptypeval(memop.t.listindex));
  bcstream.emitstoreop(bcstream.ssaval(ssas1),bcstream.relval(0));
 end;
end;

procedure popindirect8op();
begin
 popindirect();
end;

procedure popindirect16op();
begin
 popindirect();
end;

procedure popindirect32op();
begin
 popindirect();
end;

procedure popindirect64op();
begin
 popindirect();
end;

procedure popindirectpoop();
begin
 popindirect();
end;

procedure popindirectf16op();
begin
 popindirect();
end;

procedure popindirectf32op();
begin
 popindirect();
end;

procedure popindirectf64op();
begin
 popindirect();
end;

procedure popindirectop();
begin
 popindirect();
end;

procedure dooutlink(const outlinkcount: integer);
var
 i1: int32;
begin
 with pc^.par do begin
  if (outlinkcount > 0) and (sf_hasnestedaccess in callinfo.flags) then begin
   bcstream.emitgetelementptr(bcstream.subval(0),
                     bcstream.constval(nullpointeroffset)); //nested vars
   for i1:= outlinkcount-2 downto 0 do begin;
    bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
    bcstream.emitloadop(bcstream.relval(0));
   end;
  end;
 end;
end;

procedure docallparam(const outlinkcount: int32; var ids: idarty);
var
 parpo,endpo: pparallocinfoty;
 po1: pint32;
begin
 with pc^.par do begin
  ids.count:= callinfo.paramcount;
  po1:= ids.ids;
  if sf_hasnestedaccess in callinfo.flags then begin
   if outlinkcount > 0 then begin
    po1^:= bcstream.relval(0);
   end
   else begin
    po1^:= bcstream.ssaval(-1); //last alloc is nested var ref table
   end;
   inc(po1);
   inc(ids.count);
  end;
 {$ifdef mse_checkinternalerror}
  if ids.count >= high(idsarty) then begin
   internalerror(ie_llvm,'20150122');
  end;
 {$endif}
  parpo:= getsegmentpo(seg_localloc,callinfo.params);
  endpo:= parpo + callinfo.paramcount;  
  if sf_function in callinfo.flags then begin
   inc(parpo);            //skip result param
   dec(ids.count);
  end;
  while parpo < endpo do begin
   po1^:= bcstream.ssaval(parpo^.ssaindex);
   inc(po1);
   inc(parpo);
  end;
 end;
end;

procedure docall(const outlinkcount: integer; const aindirect: boolean);
var
 ids: idsarty;
 idar: idarty;
 i1: int32;
begin
 with pc^.par do begin               //todo: calling convention
  idar.ids:= @ids;
  if aindirect then begin
   bcstream.emitbitcast(bcstream.ssaval(ssas1),                     //1ssa
                         bcstream.ptypeval(callinfo.indi.typeid));
   i1:= bcstream.relval(0);
  end
  else begin
   i1:= bcstream.globval(callinfo.ad.globid);
//   i1:= bcstream.globval(getoppo(callinfo.ad+1)^.par.subbegin.globid);
  end;
  docallparam(outlinkcount,idar);
  bcstream.emitcallop(sf_function in callinfo.flags,i1,idar);
 end;
end;

procedure callop();
begin
 docall(0,false);
end;

procedure callfuncop();
begin
 docall(0,false);
end;

procedure callindiop();
begin
 docall(0,true);
end;

procedure callfuncindiop();
begin
 docall(0,true);
end;

procedure calloutop();
var
 int1: integer;
begin
 with pc^.par do begin
  int1:= callinfo.linkcount+2;
  dooutlink(int1);
  docall(int1,false);
 end;
end;

procedure callfuncoutop();
var
 int1: integer;
begin
 with pc^.par do begin
  int1:= callinfo.linkcount+2;
  dooutlink(int1);
  docall(int1,false);
 end;
end;

procedure callvirtop();
var
 ids: idsarty;
 idar: idarty;
 i1: int32;
begin
 with pc^.par do begin               //todo: calling convention
  idar.ids:= @ids;
  docallparam(0,idar);
  bcstream.emitbitcast(ids[0],bcstream.ptypeval(pointertype)); //1ssa **i8
  bcstream.emitloadop(bcstream.relval(0));                     //1ssa *i8
               //class def
  bcstream.emitgetelementptr(bcstream.relval(0),               
                     bcstream.constval(callinfo.virt.virtoffset));//2ssa *i8
               //virtual table item address
  bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(pointertype));
                                                                  //1ssa **i8
  bcstream.emitloadop(bcstream.relval(0));                        //1ssa *i8
               //sub address
  bcstream.emitbitcast(bcstream.relval(0),                     //1ssa
                         bcstream.ptypeval(callinfo.virt.typeid));
  bcstream.emitcallop(sf_function in callinfo.flags,bcstream.relval(0),idar);
 end;
end;

procedure callvirtfuncop();
begin
 callvirtop();
end;

procedure callintfop();
var
 ids: idsarty;
 idar: idarty;
 i1: int32;
begin
 with pc^.par do begin               //todo: calling convention
  idar.ids:= @ids;
  docallparam(0,idar);
  bcstream.emitbitcast(ids[0],bcstream.ptypeval(pointertype)); //1ssa **i8
  bcstream.emitloadop(bcstream.relval(0));                     //1ssa *i8
              //interface base
  bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(inttype));
                                                               //1ssa *i32
  bcstream.emitloadop(bcstream.relval(0));                     //1ssa i32
              //instanceoffset
  bcstream.emitgetelementptr(ids[0],bcstream.relval(0));       //2ssa *i8
              //shift instance po
  ids[0]:= bcstream.relval(0); //class instance
  bcstream.emitgetelementptr(bcstream.relval(3),                   //2ssa *i8
       bcstream.constval(callinfo.virt.virtoffset));
              //interface table item address
  bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(pointertype));
                                                               //1ssa **i8
  bcstream.emitloadop(bcstream.relval(0));                     //1ssa *i8
               //sub address
  bcstream.emitbitcast(bcstream.relval(0),                     //1ssa
                         bcstream.ptypeval(callinfo.virt.typeid));
  bcstream.emitcallop(sf_function in callinfo.flags,bcstream.relval(0),idar);
 end;
end;

procedure callintffuncop();
begin
 callintfop();
end;

procedure virttrampolineop();
begin
 bcstream.marktrampoline(pc);
end;

procedure locvarpushop();
begin
 //dummy
end;

procedure locvarpopop();
begin
 //dummy
end;

procedure subbeginop();
var
 po1,ps,pe: plocallocinfoty;
 po2: pnestedallocinfoty;
 i1,i2,i3: int32;
 poend: pointer;
 trampop: popinfoty;
 idar: idarty;
 ids: idsarty;
 isfunction: boolean;
 dummyexp,derefexp,openarrayexp: int32;
begin
///////////// bcstream.nodebugloc:= true; 
            //debugloc necessary because of param debuginfo
 isfunction:= sf_function in pc^.par.subbegin.sub.flags;
 bcstream.releasetrampoline(trampop);
 if trampop <> nil then begin //todo: force tailcall
  with trampop^.par.subbegin do begin
   i1:= 0; //first param, class instance
   if isfunction then begin
    i1:= 1;//second param, class instance
   end;
   idar.count:= pc^.par.subbegin.sub.allocs.paramcount - i1;
   trampolinealloc.paramcount:= idar.count;

   bcstream.beginsub([],trampolinealloc,1);
   bcstream.emitbitcast(bcstream.subval(0), //first param, class instance
                                 bcstream.ptypeval(pointertype)); //1ssa **i8
   bcstream.emitloadop(bcstream.relval(0));                     //1ssa *i8
                //class def
   bcstream.emitgetelementptr(bcstream.relval(0),               
                     bcstream.constval(trampoline.virtoffset));//2ssa *i8
               //virtual table item address
   bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(pointertype));
                                                                  //1ssa **i8
   bcstream.emitloadop(bcstream.relval(0));                       //1ssa *i8
               //sub address
   bcstream.emitbitcast(bcstream.relval(0),
                          bcstream.ptypeval(pc^.par.subbegin.typeid)); //1ssa
   for i2:= 0 to idar.count-1 do begin
    ids[i2]:= bcstream.subval(i2);
   end;
   idar.ids:= @ids;
   bcstream.emitcallop(isfunction,bcstream.relval(0),idar);
   if isfunction then begin
    bcstream.emitretop(bcstream.relval(0));
   end
   else begin
    bcstream.emitretop();
   end;
   bcstream.endsub();
  end;
 end;
 with pc^.par.subbegin do begin
  bcstream.beginsub(sub.flags,sub.allocs,sub.blockcount);
  if sf_nolineinfo in sub.flags then begin
   bcstream.nodebugloc:= true;
  end;
  ps:= getsegmentpo(seg_localloc,sub.allocs.allocs);
  pe:= ps + sub.allocs.alloccount;
  po1:= ps;
  if do_proginfo in info.o.debugoptions then begin
   bcstream.beginblock(METADATA_BLOCK_ID,3);
   i1:= bcstream.allocval(0);
   while po1 < pe do begin
    bcstream.emitmetavalue(bcstream.ptypeval(po1^.size.listindex),i1);
    inc(po1);
    inc(i1);
   end;
   bcstream.endblock();
   po1:= ps;
  end;
  while po1 < pe do begin
   bcstream.emitalloca(bcstream.ptypeval(po1^.size));
   inc(po1);
  end;
  i2:= 0;
  if isfunction then begin
   i2:= 1; //skip result param
  end;
  for i1:= i2 to sub.allocs.paramcount-1 do begin
   bcstream.emitstoreop(bcstream.paramval(i1),bcstream.allocval(i1));
  end;
  if sub.allocs.nestedalloccount > 0 then begin
  {$ifdef mse_checkinternalerror}
   if sub.allocs.nestedallocstypeindex < 0 then begin
    internalerror(ie_llvm,'20151022A');
   end;
  {$endif}
   bcstream.emitalloca(bcstream.ptypeval(sub.allocs.nestedallocstypeindex));
   if sf_hascallout in sub.flags then begin
    bcstream.emitgetelementptr(bcstream.subval(0),
                                      bcstream.constval(ord(nc_i8))); 
                                        //param parent nested var,source
    bcstream.emitgetelementptr(bcstream.ssaval(0),
                                      bcstream.constval(nullpointeroffset));
                                                  //nested var array,dest
    bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
    bcstream.emitstoreop(bcstream.relval(3),bcstream.relval(0));
   end;
   po2:= getsegmentpo(seg_localloc,sub.allocs.nestedallocs);
   poend:= po2+sub.allocs.nestedalloccount;
   i1:= 1;
   while po2 < poend do begin
    if po2^.address.nested then begin
     bcstream.emitgetelementptr(bcstream.subval(0),
                 bcstream.constval(po2^.address.arrayoffset));
                              //pointer to parent nestedvars, 2 ssa
     bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
     bcstream.emitloadop(bcstream.relval(0));                       //source
    end
    else begin
     bcstream.emitbitcast(bcstream.allocval(po2^.address.origin),
                                    bcstream.typeval(das_pointer)); //source
    end;
    bcstream.emitgetelementptr(bcstream.ssaval(0),
                  bcstream.constval(po2^.address.arrayoffset));
//               info.s.unitinfo^.llvmlists.constlist.pointeroffset(i1))); //dest
                        //pointer to nestedallocs
    bcstream.emitbitcast(bcstream.relval(0),bcstream.ptypeval(das_pointer));
    bcstream.emitstoreop(bcstream.relval(3),bcstream.relval(0));
    inc(po2);
    inc(i1);
   end;
   bcstream.emitbitcast(bcstream.allocval(sub.allocs.alloccount),
                                               bcstream.typeval(das_pointer));
                                 //pointer to nestedallocs
   bcstream.resetssa();
  end;
  if do_proginfo in info.o.debugoptions then begin
   idar.count:= 3;
   idar.ids:= @ids;
   with info.s.unitinfo^.llvmlists.metadatalist do begin
    i1:= count;
    i2:= bcstream.globval(dbgdeclare);
    dummyexp:= dummyaddrexp.id;
    derefexp:= derefaddrexp.id;
    openarrayexp:= openarrayaddrexp.id;
   end;
   po1:= ps;
   while po1 < pe do begin
//    bcstream.emitalloca(bcstream.ptypeval(po1^.size));
    ids[0]:= i1;
    ids[1]:= po1^.debuginfo.id;
    if af_paramindirect in po1^.flags then begin
     ids[2]:= derefexp;
    end
    else begin
     if af_openarray in po1^.flags then begin
      ids[2]:= openarrayexp;
     end
     else begin
      ids[2]:= dummyexp;
     end;
    end;
    bcstream.emitcallop(false,i2,idar); //dbgdeclare
    inc(i1);
    inc(po1);
   end;
  end;
 end;
//////////////// bcstream.nodebugloc:= false;
end;

procedure subendop();
var
 po1,pe: plocallocinfoty;
 metalist: tmetadatalist;
 i1: int32;
 po2: pdilocvariablety;
begin
 with pc^.par.subend do begin
  if info.o.debugoptions * [do_name,do_proginfo] = 
                                     [do_name,do_proginfo] then begin
   po1:= getsegmentpo(seg_localloc,allocs.allocs);
   pe:= po1 + allocs.alloccount;
   bcstream.beginblock(VALUE_SYMTAB_BLOCK_ID,3);
   i1:= bcstream.paramval(0);
   metalist:= info.s.unitinfo^.llvmlists.metadatalist;
   while po1 < pe do begin
    po2:= metalist.getdata(po1^.debuginfo);
   {$ifdef mse_checkinternalerror}
    if pmetadataty(pointer(po2)-sizeof(metadataheaderty))^.header.kind <> 
                                                    mdk_dilocvariable then begin
     internalerror(ie_llvmmeta,'20151108B');
    end;
   {$endif}
    bcstream.emitvstentry(i1,metalist.getstringvalue(po2^.name));    
    inc(po1);
    inc(i1);
   end;
   bcstream.endblock();
  end;
  bcstream.endsub();
 end;
 bcstream.nodebugloc:= false;
end;

procedure externalsubop();
begin
 //dummy
end;

procedure returnop();
begin
 bcstream.emitretop();
 //dummy
// bcstream.emitretop();
// outass('ret void');
end;

procedure returnfuncop();
begin
 with pc^.par do begin
  bcstream.emitloadop(bcstream.allocval(0));
  bcstream.emitretop(bcstream.relval(0));
 end;
end;

procedure initclassop();
begin
 with pc^.par.initclass do begin
//  bcstream.emitpushconstsegad(classdef); //2ssa
  bcstream.emitgetelementptr(bcstream.globval(
            pint32(getsegmentpo(seg_classdef,classdef))^),
                bcstream.constval(info.s.unitinfo^.llvmlists.constlist.i8(0))); 
                                                           //2ssa
  callcompilersub(cs_initclass,true,[bcstream.relval(0)]); //1ssa
 end;
end;

procedure destroyclassop();
begin
 with pc^.par do begin
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_free]),
                                                    [bcstream.ssaval(ssas1)]);
 end;
end;

procedure decloop32op();
begin
 notimplemented();
end;
procedure decloop64op();
begin
 notimplemented();
end;

procedure setlengthstr8op();
begin
 with pc^.par do begin
  callcompilersub(cs_setlengthstring8,false,[bcstream.ssaval(ssas1),
                                                         //dest
                                                     bcstream.ssaval(ssas2)]);
                                                            //count
 end;
end;

procedure setlengthdynarrayop();
begin                           
 with pc^.par do begin                            
  callcompilersub(cs_setlengthdynarray,false,[bcstream.ssaval(ssas1),
                                                     //dest
       bcstream.ssaval(ssas2),bcstream.constval(setlength.itemsize)]);
           //count                 //itemsize
 end;
end;

procedure uniquestr8op();
begin
 with pc^.par do begin
  callcompilersub(cs_uniquestring8,false,[bcstream.ssaval(ssas1)]);
                                                   //dest
 end;
end;

procedure uniquedynarrayop();
begin                                         
 with pc^.par do begin
  callcompilersub(cs_uniquedynarray,false,[bcstream.ssaval(ssas1),
                                                    //dest                                                      
                                       bcstream.constval(setlength.itemsize)]);
                                                    //itemsize
 end;
end;

procedure raiseop();
begin
 with pc^.par do begin
  callcompilersub(cs_raise,false,[bcstream.ssaval(ssas1)]);
 end;
end;

procedure pushcpucontextop();
begin
 with pc^.par do begin
  bcstream.landingpad:= opaddress.bbindex;
 end;
end;

procedure popcpucontextop();
begin
 with pc^.par do begin
  bcstream.landingpad:= opaddress.bbindex;
  bcstream.emitlandingpad(bcstream.typeval(
                         info.s.unitinfo^.llvmlists.typelist.landingpad),
                       bcstream.globval(compilersubids[cs_personality]));
 end;
end;

procedure finiexceptionop();
begin
// notimplemented();
end;

procedure continueexceptionop();
begin
// notimplemented();
end;

procedure getmemop();
begin
 with pc^.par do begin
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_malloc]),
                                                    [bcstream.ssaval(ssas2)]);
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitstoreop(bcstream.relval(1),bcstream.relval(0));
 end;
end;

procedure getzeromemop();
begin
 with pc^.par do begin
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_calloc]),
               [bcstream.ssaval(ssas2),bcstream.constval(i32consts[1])]);
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitstoreop(bcstream.relval(1),bcstream.relval(0));
 end;
end;

procedure freememop();
begin
 with pc^.par do begin
  bcstream.emitcallop(false,bcstream.globval(internalfuncs[if_free]),
                                                    [bcstream.ssaval(ssas1)]);
 end;
end;

procedure reallocmemop();
begin
 with pc^.par do begin
  bcstream.emitbitcast(bcstream.ssaval(ssas1),bcstream.ptypeval(pointertype));
  bcstream.emitloadop(bcstream.relval(0));
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_realloc]),
               [bcstream.relval(0),bcstream.ssaval(ssas2)]);
  bcstream.emitstoreop(bcstream.relval(0),bcstream.relval(2));
 end;
end;

procedure setmemop();
begin
 with pc^.par do begin
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_memset]),
            [bcstream.ssaval(ssas1),bcstream.ssaval(ssas3),
                                                    bcstream.ssaval(ssas2)]);
 end;
end;

procedure memcpyop();
begin
 with pc^.par do begin
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_memcpy]),
            [bcstream.ssaval(ssas1),bcstream.ssaval(ssas2),
                                                    bcstream.ssaval(ssas3)]);
 end;
end;

procedure sin64op();
begin
 with pc^.par do begin
  bcstream.emitcallop(true,bcstream.globval(internalfuncs[if_sin64]),
                                                  [bcstream.ssaval(ssas1)]);
 end;
end;

procedure lineinfoop();
begin
 with pc^.par.lineinfo do begin
  bcstream.debugloc:= loc;
 end;
end;

const
  nonessa = 0;
  nopssa = 1;
  labelssa = 0;
  ifssa = 0;
  whilessa = 0;
  untilssa = 0;
  decloop32ssa = 1;
  decloop64ssa = 1;

  beginparsessa = 0;
  endparsessa = 0;
  beginunitcodessa = 0;
  endunitssa = 0;
  mainssa = 0;//1;
  progendssa = 0;  
  haltssa = 1;

  movesegreg0ssa = 1;
  moveframereg0ssa = 1;
  popreg0ssa = 1;
  increg0ssa = 1;

  phissa = 1;

  gotossa = 0;
  gotofalsessa = 0;
  gototruessa = 0;
  cmpjmpneimm4ssa = 1;
  cmpjmpeqimm4ssa = 1;
  cmpjmploimm4ssa = 1;
  cmpjmpgtimm4ssa = 1;
  cmpjmploeqimm4ssa = 1;

  writelnssa = 1;
  writebooleanssa = 1;
  writecardinal8ssa = 1;
  writecardinal16ssa = 1;
  writecardinal32ssa = 1;
  writecardinal64ssa = 1;
  writeinteger8ssa = 1;
  writeinteger16ssa = 1;
  writeinteger32ssa = 1;
  writeinteger64ssa = 1;
  writefloat64ssa = 1;
  writechar8ssa = 1;
  writestring8ssa = 1;
  writepointerssa = 1;
  writeclassssa = 1;
  writeenumssa = 1;

  pushssa = 0; //dummy
  popssa = 0;  //dummy
  swapstackssa = 0;  //dummy

  pushimm1ssa = 1;
  pushimm8ssa = 1;
  pushimm16ssa = 1;
  pushimm32ssa = 1;
  pushimm64ssa = 1;
  pushimmf64ssa = 1;
  pushimmdatakindssa = 1;
  
  card8toflo64ssa = 1;
  card16toflo64ssa = 1;
  card32toflo64ssa = 1;
  card64toflo64ssa = 1;

  int8toflo64ssa = 1;
  int16toflo64ssa = 1;
  int32toflo64ssa = 1;
  int64toflo64ssa = 1;

  potoint32ssa = 1;
  inttopossa =1;

  and1ssa = 1;
  and32ssa = 1;
  or1ssa = 1;
  or32ssa = 1;
  xor1ssa = 1;
  xor32ssa = 1;
  
  shl32ssa = 1;
  shr32ssa = 1;
//  shrint32ssa = 1;
  
  card8tocard16ssa = 1;
  card8tocard32ssa = 1;
  card8tocard64ssa = 1;
  card16tocard8ssa = 1;
  card16tocard32ssa = 1;
  card16tocard64ssa = 1;
  card32tocard8ssa = 1;
  card32tocard16ssa = 1;
  card32tocard64ssa = 1;
  card64tocard8ssa = 1;
  card64tocard16ssa = 1;
  card64tocard32ssa = 1;

  int8toint16ssa = 1;
  int8toint32ssa = 1;
  int8toint64ssa = 1;
  int16toint8ssa = 1;
  int16toint32ssa = 1;
  int16toint64ssa = 1;
  int32toint8ssa = 1;
  int32toint16ssa = 1;
  int32toint64ssa = 1;
  int64toint8ssa = 1;
  int64toint16ssa = 1;
  int64toint32ssa = 1;

  card8toint8ssa = 0;
  card8toint16ssa = 1;
  card8toint32ssa = 1;
  card8toint64ssa = 1;
  card16toint8ssa = 1;
  card16toint16ssa = 0;
  card16toint32ssa = 1;
  card16toint64ssa = 1;
  card32toint8ssa = 1;
  card32toint16ssa = 1;
  card32toint32ssa = 0;
  card32toint64ssa = 1;
  card64toint8ssa = 1;
  card64toint16ssa = 1;
  card64toint32ssa = 1;
  card64toint64ssa = 0;

  int8tocard8ssa = 0;
  int8tocard16ssa = 1;
  int8tocard32ssa = 1;
  int8tocard64ssa = 1;
  int16tocard8ssa = 1;
  int16tocard16ssa = 0;
  int16tocard32ssa = 1;
  int16tocard64ssa = 1;
  int32tocard8ssa = 1;
  int32tocard16ssa = 1;
  int32tocard32ssa = 0;
  int32tocard64ssa = 1;
  int64tocard8ssa = 1;
  int64tocard16ssa = 1;
  int64tocard32ssa = 1;
  int64tocard64ssa = 0;
  
  chartostring8ssa = 1;
  arraytoopenarssa = 1;
  dynarraytoopenarssa = 1;
  listtoopenarssa = 3;

  not1ssa = 1;
  not32ssa = 1;
  
  negcard32ssa = 1;
  negint32ssa = 1;
  negflo64ssa = 1;

  mulcard32ssa = 1;
  mulint32ssa = 1;
  divcard32ssa = 1;
  divint32ssa = 1;
  mulflo64ssa = 1;
  divflo64ssa = 1;
  addint32ssa = 1;
  subint32ssa = 1;
  addpoint32ssa = 2;
  subpoint32ssa = 3;
  subpossa = 3;
  addflo64ssa = 1;
  subflo64ssa = 1;
  diffsetssa = 2;
  xorsetssa = 1;
  
  setbitssa = 2;

  addimmint32ssa = 1;
  mulimmint32ssa = 1;
  offsetpoimm32ssa = 2;

  incdecsegimmint32ssa = 2;
  incdecsegimmpo32ssa = 3;

  incdeclocimmint32ssa = 2;
  incdeclocimmpo32ssa = 3;

  incdecparimmint32ssa = 2;
  incdecparimmpo32ssa = 3;

  incdecparindiimmint32ssa = 3;
  incdecparindiimmpo32ssa = 4;

  incdecindiimmint32ssa = 3;
  incdecindiimmpo32ssa = 3;

  incsegint32ssa = 2;
  incsegpo32ssa = 3;

  inclocint32ssa = 2;
  inclocpo32ssa = 3;

  incparint32ssa = 2;
  incparpo32ssa = 3;

  incparindiint32ssa = 3;
  incparindipo32ssa = 4;

  incindiint32ssa = 3;
  incindipo32ssa = 3;

  decsegint32ssa = 2;
  decsegpo32ssa = 3;

  declocint32ssa = 2;
  declocpo32ssa = 3;

  decparint32ssa = 2;
  decparpo32ssa = 3;

  decparindiint32ssa = 3;
  decparindipo32ssa = 4;

  decindiint32ssa = 3;
  decindipo32ssa = 3;

  cmppossa = 1;
  cmpboolssa = 1;
  cmpcard32ssa = 1;
  cmpint32ssa = 1;
  cmpflo64ssa = 1;
  cmpstring8ssa = 1;

  setcontainsssa = 3;
  setinssa = 3;

  storesegnilssa = 0;
  storereg0nilssa = 1;
  storelocnilssa = 0;
  storestacknilssa = 1;
  storestackrefnilssa = 1;

  storesegnilarssa = 1;
  storelocnilarssa = 1;
  storereg0nilarssa = 1;
  storestacknilarssa = 1;
  storestackrefnilarssa = 2;

  storesegnildynarssa = 1;
  storelocnildynarssa = 1;
  storereg0nildynarssa = 1;
  storestacknildynarssa = 1;
  storestackrefnildynarssa = 2;

  finirefsizesegssa = 1;
  finirefsizelocssa = 1;
  finirefsizereg0ssa = 1;
  finirefsizestackssa = 1;
  finirefsizestackrefssa = 0;

  finirefsizesegarssa = 1;
  finirefsizelocarssa = 1;
  finirefsizereg0arssa = 1;
  finirefsizestackarssa = 1;
  finirefsizestackrefarssa = 2;

  finirefsizesegdynarssa = 1;
  finirefsizelocdynarssa = 1;
  finirefsizereg0dynarssa = 1;
  finirefsizestackdynarssa = 1;
  finirefsizestackrefdynarssa = 2;

  increfsizesegssa = 1;
  increfsizelocssa = 1;
  increfsizereg0ssa = 1;
  increfsizestackssa = 0;
  increfsizestackrefssa = 2;

  increfsizesegarssa = 1;
  increfsizelocarssa = 1;
  increfsizereg0arssa = 1;
  increfsizestackarssa = 1;
  increfsizestackrefarssa = 1;

  increfsizesegdynarssa = 1;
  increfsizelocdynarssa = 1;
  increfsizereg0dynarssa = 1;
  increfsizestackdynarssa = 1;
  increfsizestackrefdynarssa = 1;

  decrefsizesegssa = 1;
  decrefsizelocssa = 1;
  decrefsizereg0ssa = 1;
  decrefsizestackssa = 1;
  decrefsizestackrefssa = 2;

  decrefsizesegarssa = 1;
  decrefsizelocarssa = 1;
  decrefsizereg0arssa = 1;
  decrefsizestackarssa = 1;
  decrefsizestackrefarssa = 1;

  decrefsizesegdynarssa = 1;
  decrefsizelocdynarssa = 1;
  decrefsizereg0dynarssa = 1;
  decrefsizestackdynarssa = 1;
  decrefsizestackrefdynarssa = 1;

  highstringssa = 1;
  highdynarssa = 1;
  highopenarssa = 1;
  lengthstringssa = 1;
  lengthdynarssa = 1;
  lengthopenarssa = 1;
  
  popseg8ssa = 0;
  popseg16ssa = 0;
  popseg32ssa = 0;
  popseg64ssa = 0;
  popsegpossa = 0;
  popsegf16ssa = 0;
  popsegf32ssa = 0;
  popsegf64ssa = 0;
  popsegssa = 0;

  poploc8ssa = 0;
  poploc16ssa = 0;
  poploc32ssa = 0;
  poploc64ssa = 0;
  poplocpossa = 0;
  poplocf16ssa = 0;
  poplocf32ssa = 0;
  poplocf64ssa = 0;
  poplocssa = 0;

  poplocindi8ssa = 2;
  poplocindi16ssa = 2;
  poplocindi32ssa = 2;
  poplocindi64ssa = 2;
  poplocindipossa = 2;
  poplocindif16ssa = 2;
  poplocindif32ssa = 2;
  poplocindif64ssa = 2;
  poplocindissa = 2;

  poppar8ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  poppar16ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  poppar32ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  poppar64ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  popparpossa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  popparf16ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  popparf32ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  popparf64ssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};
  popparssa = {$ifdef mse_locvarssatracking}1{$else}0{$endif};

  popparindi8ssa = 2;
  popparindi16ssa = 2;
  popparindi32ssa = 2;
  popparindi64ssa = 2;
  popparindipossa = 2;
  popparindif16ssa = 2;
  popparindif32ssa = 2;
  popparindif64ssa = 2;
  popparindissa = 2;

  pushnilssa = 1;
{
  pushstack8ssa = 1;
  pushstack16ssa = 1;
  pushstack32ssa = 1;
  pushstack64ssa = 1;
  pushstackpossa = 1;
  pushstackindi8ssa = 1;
  pushstackindi16ssa = 1;
  pushstackindi32ssa = 1;
  pushstackindi64ssa = 1;
  pushstackindipossa = 1;
 }
  pushsegaddressssa = 1;

  pushseg8ssa = 1;
  pushseg16ssa = 1;
  pushseg32ssa = 1;
  pushseg64ssa = 1;
  pushsegpossa = 1;
  pushsegf16ssa = 1;
  pushsegf32ssa = 1;
  pushsegf64ssa = 1;
  pushsegssa = 1;
//  pushsegopenarssa = 0; //todo

  pushloc8ssa = 1;
  pushloc16ssa = 1;
  pushloc32ssa = 1;
  pushloc64ssa = 1;
  pushlocpossa = 1;
  pushlocf16ssa = 1;
  pushlocf32ssa = 1;
  pushlocf64ssa = 1;
  pushlocssa = 1;

  pushlocindi8ssa = 2;
  pushlocindi16ssa = 2;
  pushlocindi32ssa = 2;
  pushlocindi64ssa = 2;
  pushlocindipossa = 2;
  pushlocindif16ssa = 2;
  pushlocindif32ssa = 2;
  pushlocindif64ssa = 2;
  pushlocindissa = 2;

  pushpar8ssa = 1;
  pushpar16ssa = 1;
  pushpar32ssa = 1;
  pushpar64ssa = 1;
  pushparpossa = 1;
  pushparf16ssa = 1;
  pushparf32ssa = 1;
  pushparf64ssa = 1;
  pushparssa = 1;

  pushaddrssa = 1;
  pushlocaddrssa = 2;
//  pushlocaddrindissa = 3;
  pushsegaddrssa = 1;
//  pushsegaddrindissa = 3;
  pushstackaddrssa = 3;
//  pushstackaddrindissa = 1;
  
  pushduppossa = 1;

  indirect8ssa = 2;
  indirect16ssa = 2;
  indirect32ssa = 2;
  indirect64ssa = 2;
  indirectpossa = 2;
  indirectf16ssa = 2;
  indirectf32ssa = 2;
  indirectf64ssa = 2;
  indirectpooffsssa = 2;
  indirectoffspossa = 1;
  indirectssa = 1;

  popindirect8ssa = 1;
  popindirect16ssa = 1;
  popindirect32ssa = 1;
  popindirect64ssa = 1;
  popindirectpossa = 1;
  popindirectf16ssa = 1;
  popindirectf32ssa = 1;
  popindirectf64ssa = 1;
  popindirectssa = 1;

  callssa = 0;
  callfuncssa = 1;
  calloutssa = 0;
  callfuncoutssa = 1;
  callvirtssa = 7;
  callvirtfuncssa = 8;
  callintfssa = 11;
  callintffuncssa = 12;
  virttrampolinessa = 1;

  callindissa = 1;
  callfuncindissa = 2;

  locvarpushssa = 0; //dummy
  locvarpopssa = 0;  //dummy

  subbeginssa = 0; //1;
  subendssa = 0;
  externalsubssa = 0;
  returnssa = 0;
  returnfuncssa = 1;

  initclassssa = 3;
  destroyclassssa = 0;

  setlengthstr8ssa = 0;
  setlengthdynarrayssa = 0;

  uniquestr8ssa = 0;
  uniquedynarrayssa = 0;

  raisessa = 0;
  pushcpucontextssa = 0;
  popcpucontextssa = 1;
  finiexceptionssa = 0;
  continueexceptionssa = 0;
  getmemssa = 2;
  getzeromemssa = 2;
  freememssa = 0;
  reallocmemssa = 3;
  setmemssa = 1;
  memcpyssa = 1;
  
  sin64ssa = 1;
  
  lineinfossa = 0;

//ssa only
  nestedvarssa = 5;
  nestedvaradssa = 2;
  popnestedvarssa = 5;
//  popsegaggregatessa = 3;
  pushnestedvarssa = 5;
  aggregatessa = 3;
  allocssa = 1;
  nestedcalloutssa = 2;
  hascalloutssa = 1;

  pushsegaddrnilssa = 0;
  pushsegaddrglobvarssa = 1;
  pushsegaddrglobconstssa = 3;
  pushsegaddrclassdefssa = 3;
  listtoopenaritemssa = 3;
  
{$include optable.inc}

procedure run(const atarget: tllvmbcwriter; const amain: boolean);
var
 endpo: pointer;
 lab: shortstring;
begin
 bcstream:= atarget;
 codestarted:= false;
 ismain:= amain;
 pc:= getsegmentbase(seg_op);
 endpo:= pointer(pc)+getsegmentsize(seg_op);
 if amain then begin
  inc(pc,startupoffset);
 end;
 while pc < endpo do begin
  optable[pc^.op.op].proc();
  inc(pc);
 end;
end;

function getoptable: poptablety;
begin
 result:= @optable;
end;
{
function getssatable: pssatablety;
begin
 result:= @ssatable;
end;
}
finalization
// freeandnil(assstream);
end.
