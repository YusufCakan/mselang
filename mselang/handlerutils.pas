{ MSElang Copyright (c) 2013-2014 by Martin Schreiber
   
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
unit handlerutils;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 handlerglob,parserglob,opglob,elements,msestrings,msetypes;

type
 systypety = (st_none,st_bool8,st_int32,st_float64,st_string8);
 systypeinfoty = record
  name: string;
  data: typedataty;
 end;
 sysconstinfoty = record
  name: string;
  ctyp: systypety;
  cval: dataty;
 end;
  
 opsinfoty = record
  ops: array[stackdatakindty] of opcodety;
  opname: string;
 end;

var
 unitsele: elementoffsetty;
 sysdatatypes: array[systypety] of typeinfoty;

const
 stackdatakinds: array[datakindty] of stackdatakindty = 
   //dk_none,dk_boolean,dk_cardinal,dk_integer,dk_float,dk_kind,
   (sdk_none,sdk_bool8,sdk_int32,   sdk_int32, sdk_flo64,sdk_none,
  //dk_address,dk_record,dk_string,dk_array,dk_class,dk_interface
    sdk_none,  sdk_none, sdk_none, sdk_none,sdk_none,sdk_none,
  //dk_enum,dk_enumitem, dk_set
    sdk_none,   sdk_none, sdk_none);
                
 resultdatakinds: array[stackdatakindty] of datakindty =
            //sdk_bool8,sdk_int32,sdk_flo64
           (dk_none,dk_boolean,dk_integer,dk_float);
 resultdatatypes: array[stackdatakindty] of systypety =
            //sdk_bool8,sdk_int32,sdk_flo64
           (st_none,st_bool8,st_int32,st_float64);

type
 comperrorty = (ce_invalidfloat,ce_expressionexpected,ce_startbracketexpected,
               ce_endbracketexpected);
const
 errormessages: array[comperrorty] of msestring = (
  'Invalid Float',
  'Expression expected',
  '''('' expected',
  ''')'' expected'
 );

//procedure error(const error: comperrorty;
//                   const pos: pchar=nil);
//procedure parsererror(const info: pparseinfoty; const text: string);
//procedure identnotfounderror(const info: contextitemty; const text: string);
//procedure wrongidentkinderror(const info: contextitemty; 
//       wantedtype: elementkindty; const text: string);
//procedure outcommand(const items: array of integer;
//                     const text: string);

function getidents(const astackoffset: integer;
                     out idents: identvecty): boolean; overload;
function getidents(const astackoffset: integer): identvecty; overload;
 
function findkindelementdata(const aident: contextdataty;
              const akinds: elementkindsty; const visibility: visikindsty;
                                    out ainfo: pointer): boolean;
function findkindelements(
           const astackoffset: integer; const akinds: elementkindsty; 
           const visibility: visikindsty; out aelement: pelementinfoty;
           out firstnotfound: integer; out idents: identvecty): boolean;
function findkindelements(
           const astackoffset: integer; const akinds: elementkindsty; 
           const visibility: visikindsty; out aelement: pelementinfoty): boolean;
function findkindelementsdata(
              const astackoffset: integer; const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer;
              out firstnotfound: integer; out idents: identvecty): boolean;
function findkindelementsdata(
              const astackoffset: integer; const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;

function findvar(const astackoffset: integer; 
        const visibility: visikindsty; out varinfo: vardestinfoty): boolean;
function addvar(const aname: identty; const avislevel: visikindsty;
          var chain: elementoffsetty; out aelementdata: pvardataty): boolean;

procedure updateop(const opsinfo: opsinfoty);
function convertconsts(): stackdatakindty;
function getvalue(const stackoffset: integer;
                               const retainconst: boolean = false): boolean;
function getaddress(const stackoffset: integer;
                                  const endaddress: boolean): boolean;

procedure push(const avalue: boolean); overload;
procedure push(const avalue: integer); overload;
procedure push(const avalue: real); overload;
procedure push(const avalue: addressvaluety; const offset: dataoffsty;
                                          const indirect: boolean); overload;
procedure push(const avalue: datakindty); overload;
procedure pushconst(const avalue: contextdataty);
procedure pushdata(const address: addressvaluety; const offset: dataoffsty;
                            const size: datasizety{; const ssaindex: integer});

procedure pushinsert(const stackoffset: integer; const before: boolean;
                  const avalue: datakindty); overload;
procedure pushinsert(const stackoffset: integer; const before: boolean;
            const avalue: addressvaluety; const offset: dataoffsty;
                                            const indirect: boolean); overload;
            //class field address
function pushinsertvar(const stackoffset: integer; const before: boolean;
                                     const atype: ptypedataty): integer;
procedure pushinsertsegaddress(const stackoffset: integer;
                            const before: boolean; const address: segaddressty);
procedure pushinsertdata(const stackoffset: integer; const before: boolean;
                  const address: addressvaluety; const offset: dataoffsty;
                              const size: datasizety{; const ssaindex: integer});
procedure pushinsertaddress(const stackoffset: integer; const before: boolean);
procedure pushinsertconst(const stackoffset: integer; const before: boolean);
procedure offsetad(const stackoffset: integer; const aoffset: dataoffsty);

procedure setcurrentloc(const indexoffset: integer);
procedure setcurrentlocbefore(const indexoffset: integer);
procedure setlocbefore(const destindexoffset,sourceindexoffset: integer);
procedure setloc(const destindexoffset,sourceindexoffset: integer);

procedure getordrange(const typedata: ptypedataty; out range: ordrangety);
function getordcount(const typedata: ptypedataty): int64;
function getordconst(const avalue: dataty): int64;
function getdatabitsize(const avalue: int64): databitsizety;

procedure initfactcontext(const stackoffset: integer);
//procedure trackalloc(const asize: integer; var address: addressvaluety);
procedure trackalloc(const asize: integer; var address: segaddressty);
procedure trackalloc(const asize: integer; var address: addressvaluety);
//procedure allocsubvars(const asub: psubdataty; out allocs: suballocinfoty);

procedure resetssa();

procedure init();
procedure deinit();

{$ifdef mse_debugparser}
procedure outhandle(const text: string);
procedure outinfo(const text: string; const indent: boolean);
{$endif}
                           
implementation
uses
 errorhandler,typinfo,opcode,stackops,parser,sysutils,mseformatstr,
 syssubhandler,managedtypes,grammar,segmentutils;
   
const
 mindouble = -1.7e308;
 maxdouble = 1.7e308; //todo: use exact values
 
  //will be replaced by systypes.mla
 systypeinfos: array[systypety] of systypeinfoty = (
   (name: 'none'; data: (ancestor: 0; rtti: 0; flags: []; indirectlevel: 0;
       bitsize: 0; bytesize: 0; datasize: das_none; kind: dk_none;
       dummy: 0)),
   (name: 'bool8'; data: (ancestor: 0; rtti: 0; flags: []; indirectlevel: 0;
       bitsize: 8; bytesize: 1; datasize: das_8; kind: dk_boolean;
       dummy: 0)),
   (name: 'int32'; data: (ancestor: 0; rtti: 0; flags: []; indirectlevel: 0;
       bitsize: 32; bytesize: 4; datasize: das_32;
                 kind: dk_integer; infoint32:(min: minint; max: maxint))),
   (name: 'flo64'; data: (ancestor: 0; rtti: 0; flags: []; indirectlevel: 0;
       bitsize: 64; bytesize: 8; datasize: das_64;
                 kind: dk_float; infofloat64:(min: mindouble; max: maxdouble))),
   (name: 'string8'; data: (ancestor: 0; rtti: 0; 
       flags: [tf_hasmanaged,tf_managed]; indirectlevel: 0;
       bitsize: pointerbitsize; bytesize: pointersize; datasize: das_pointer;
                 kind: dk_string8; manageproc: @managestring8;
                 ))
  );
 sysconstinfos: array[0..1] of sysconstinfoty = (
   (name: 'false'; ctyp: st_bool8; cval:(kind: dk_boolean; vboolean: false)),
   (name: 'true'; ctyp: st_bool8; cval:(kind: dk_boolean; vboolean: true))
  );
    
{ 
procedure error(const error: comperrorty;
                   const pos: pchar=nil);
begin
 outcommand([],'*ERROR* '+errormessages[error]);
end;
}
function findkindelementdata(const aident: contextdataty;
              const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;
var
 po1: pelementinfoty;
 ele1: elementoffsetty;
begin
 result:= false;
 if aident.kind = ck_ident then begin
  if ele.findcurrent(aident.ident.ident,akinds,visibility,ele1) then begin
   po1:= ele.eleinfoabs(ele1);
   ainfo:= @po1^.data;
   result:= true;
  end;
 end;
end;

function findkindelementdata(
              const astackoffset: integer;
              const akinds: elementkindsty;
              const visibility: visikindsty; out ainfo: pointer): boolean;
begin
 with info do begin
  result:= findkindelementdata(contextstack[stackindex+astackoffset].d,
                                                      akinds,visibility,ainfo);
 end;
end;

function getidents(const astackoffset: integer;
                     out idents: identvecty): boolean;
var
 po1: pcontextitemty;
 int1: integer;
 identcount: integer;
begin
 with info do begin
  po1:= @contextstack[stackindex+astackoffset];
  identcount:= -1;
  for int1:= 0 to high(idents.d) do begin
   idents.d[int1]:= po1^.d.ident.ident;
   if not po1^.d.ident.continued then begin
    identcount:= int1;
    break;
   end;
   inc(po1);
  end;
  idents.high:= identcount;
  inc(identcount);
  result:= true;
  if identcount = 0 then begin
   result:= false;
  end;
  if identcount > high(idents.d) then begin
   errormessage(err_toomanyidentifierlevels,[],astackoffset+identcount);
  end;
 end;
end;

function getidents(const astackoffset: integer): identvecty;
begin
 getidents(astackoffset,result); 
end;

function findkindelements(const astackoffset: integer;
            const akinds: elementkindsty; 
            const visibility: visikindsty;
            out aelement: pelementinfoty;
            out firstnotfound: integer; out idents: identvecty): boolean;
var
 eleres,ele1,ele2: elementoffsetty;
 int1: integer;
begin
 result:= false;
 aelement:= nil;
 if getidents(astackoffset,idents) then begin
  with info do begin
   if ele.findparentscope(idents.d[0],akinds,visibility,eleres) then begin
    result:= true;
    firstnotfound:= 0;
   end
   else begin
    result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
    if not result then begin //todo: use cache
     ele2:= ele.elementparent;
     for int1:= 0 to high(info.unitinfo^.implementationuses) do begin
      ele.elementparent:=
        info.unitinfo^.implementationuses[int1]^.interfaceelement;
      result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
      if result then begin
       break;
      end;
     end;
     if not result then begin
      for int1:= 0 to high(info.unitinfo^.interfaceuses) do begin
       ele.elementparent:=
         info.unitinfo^.interfaceuses[int1]^.interfaceelement;
       result:= ele.findupward(idents,akinds,visibility,eleres,firstnotfound);
       if result then begin
        break;
       end;
      end;
     end;
     ele.elementparent:= ele2;
    end;
   end;
  end;
 end;
 if result then begin
  aelement:= ele.eleinfoabs(eleres);
 end;
end;

function findkindelements(const astackoffset: integer;
           const akinds: elementkindsty; 
           const visibility: visikindsty; out aelement: pelementinfoty): boolean;
var
 idents: identvecty;
 firstnotfound: integer;
begin
 result:= findkindelements(astackoffset,akinds,visibility,
                              aelement,firstnotfound,idents) and 
                              (firstnotfound > idents.high);
 if not result then begin
  identerror(astackoffset+firstnotfound,err_identifiernotfound);
 end;
end;

(*
function findkindelements(const astackoffset: integer;
           const akinds: elementkindsty; 
           const visibility: vislevelty; out aelement: pelementinfoty): boolean;
var
 eleres,ele1,ele2: elementoffsetty;
 int1: integer;
 idents: identvecty;
 lastident: integer;
begin
 result:= false;
 aelement:= nil;
 if getidents(astackoffset,idents) then begin
  with info do begin
   result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
   if not result then begin //todo: use cache
    ele2:= ele.elementparent;
    for int1:= 0 to high(info.unitinfo^.implementationuses) do begin
     ele.elementparent:=
       info.unitinfo^.implementationuses[int1]^.interfaceelement;
     result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
     if result then begin
      break;
     end;
    end;
    if not result then begin
     for int1:= 0 to high(info.unitinfo^.interfaceuses) do begin
      ele.elementparent:=
        info.unitinfo^.interfaceuses[int1]^.interfaceelement;
      result:= ele.findupward(idents,[],visibility,eleres,lastident); //exact
      if result then begin
       break;
      end;
     end;
    end;
    ele.elementparent:= ele2;
   end;
  end;
 end;
 if result then begin
  aelement:= ele.eleinfoabs(eleres);
  result:= (akinds = []) or (aelement^.header.kind in akinds);
 end;
end;
*)

function findkindelementsdata(
             const astackoffset: integer;
             const akinds: elementkindsty; const visibility: visikindsty; 
             out ainfo: pointer; out firstnotfound: integer;
             out idents: identvecty): boolean;
begin
 result:= findkindelements(astackoffset,akinds,visibility,ainfo,
                                firstnotfound,idents);
 if result then begin
  ainfo:= @pelementinfoty(ainfo)^.data;
 end;
end;

function findkindelementsdata(
             const astackoffset: integer;
             const akinds: elementkindsty; const visibility: visikindsty; 
             out ainfo: pointer): boolean;
begin
 result:= findkindelements(astackoffset,akinds,visibility,ainfo);
 if result then begin
  ainfo:= @pelementinfoty(ainfo)^.data;
 end;
end;

function findvar(const astackoffset: integer; 
                   const visibility: visikindsty;
                           out varinfo: vardestinfoty): boolean;
var
 idents,types: identvecty;	
 po1: pvardataty;
 po2: ptypedataty;
 po3: pfielddataty;
 ele1,ele2: elementoffsetty;
 int1: integer;
begin
 result:= false;
 if getidents(astackoffset,idents) then begin
  result:= ele.findupward(idents,[ek_var],visibility,ele1,int1);
  if result then begin
   po1:= ele.eledataabs(ele1);
   varinfo.address:= po1^.address;
   ele2:= po1^.vf.typ;
   if int1 < idents.high then begin
    for int1:= int1+1 to idents.high do begin //fields
     result:= ele.findchild(ele2,idents.d[int1],[ek_field],visibility,ele2);
     if not result then begin
      identerror(astackoffset+int1,err_identifiernotfound);
      exit;
     end;
     po3:= ele.eledataabs(ele2);
     varinfo.address.poaddress:= varinfo.address.poaddress + po3^.offset;
    end;
    varinfo.typ:= ele.eledataabs(po3^.vf.typ);
   end
   else begin
    po2:= ele.eledataabs(ele2);
    varinfo.typ:= po2;
   end;
  end
  else begin
   identerror(astackoffset,err_identifiernotfound);
  end;
 end;
end;                           

function addvar(const aname: identty; const avislevel: visikindsty;
          var chain: elementoffsetty; out aelementdata: pvardataty): boolean;
var
 po1: pelementinfoty;
begin
 result:= false;
 po1:= ele.addelement(aname,ek_var,avislevel);
 if po1 <> nil then begin
  aelementdata:= @po1^.data;
  aelementdata^.vf.next:= chain;
  aelementdata^.vf.flags:= [];
  chain:= ele.eleinforel(po1);
  result:= true;
 end;
end;

(*
procedure parsererror(const info: pparseinfoty; const text: string);
begin
 with info^ do begin
  contextstack[stackindex].d.kind:= ck_error;
  writeln(' ***ERROR*** '+text);
 end; 
end;

procedure identnotfounderror(const info: contextitemty; const text: string);
begin
 writeln(' ***ERROR*** ident '+lstringtostring(info.start.po,info.d.ident.len)+
                   ' not found. '+text);
end;

procedure wrongidentkinderror(const info: contextitemty; 
       wantedtype: elementkindty; const text: string);
begin
 writeln(' ***ERROR*** wrong ident kind '+
               lstringtostring(info.start.po,info.d.ident.len)+
                   ', expected '+
         getenumname(typeinfo(elementkindty),ord(wantedtype))+'. '+text);
end;
*)
(*
procedure outcommand(const items: array of integer;
                     const text: string);
var
 int1: integer;
begin
 with info do begin
  for int1:= 0 to high(items) do begin
   with contextstack[stacktop+items[int1]].d do begin
    command.write([getenumname(typeinfo(kind),ord(kind)),': ']);
    case kind of
     ck_const: begin
      with constval do begin
       case kind of
        dk_boolean: begin
         command.write(vboolean);
        end;
        dk_integer: begin
         command.write(vinteger);
        end;
        dk_float: begin
         command.write(vfloat);
        end;
       end;
      end;
     end;
    end;
    command.write(',');
   end;
  end;
  command.writeln([' ',text]);
 end;
end;
*)
function pushinsertvar(const stackoffset: integer; const before: boolean;
                                       const atype: ptypedataty): integer;
begin
 with insertitem(oc_push,stackoffset,before)^ do begin
  result:= atype^.bytesize; //todo: alignment
  par.imm.vsize:= result;
 end;
end;

procedure pushinsertsegaddress(const stackoffset: integer;
                             const before: boolean;
                             const address: segaddressty);
begin
 if address.segment = seg_nil then begin
  insertitem(oc_pushnil,stackoffset,before);
 end
 else begin
  with insertitem(oc_pushsegaddress,stackoffset,before)^ do begin
   par.vsegaddress.a:= address;
   par.vsegaddress.offset:= 0;
  end;
 end;
end;

procedure pushinsertaddress(const stackoffset: integer; const before: boolean);
begin
 with info,contextstack[stackindex+stackoffset].d.dat.ref do begin
  if af_segment in c.address.flags then begin
   with insertitem(oc_pushsegaddr,stackoffset,before)^ do begin
    par.vsegaddress.a:= c.address.segaddress;
    par.vsegaddress.offset:= offset;
   end;
  end
  else begin
   with insertitem(oc_pushlocaddr,stackoffset,before)^ do begin
    par.vlocaddress.a:= c.address.locaddress;
    par.vlocaddress.a.framelevel:= info.sublevel-
                          c.address.locaddress.framelevel-1;
    par.vlocaddress.offset:= offset;
   end;
  end;
 end;
end;

procedure pushinsertconst(const stackoffset: integer; const before: boolean);
var
 po1: pcontextitemty;
 isimm: boolean;
 segad1: segaddressty;
begin
 with info do begin
  po1:= @contextstack[stackindex+stackoffset];
  isimm:= true;
  case po1^.d.dat.constval.kind of
   dk_boolean: begin
    with insertitem(oc_pushimm8,stackoffset,before)^ do begin
     par.imm.vboolean:= po1^.d.dat.constval.vboolean;
    end;
   end;
   dk_integer,dk_enum: begin
    with insertitem(oc_pushimm32,stackoffset,before)^ do begin
     par.imm.vint32:= po1^.d.dat.constval.vinteger;
    end;
   end;
   dk_float: begin
    with insertitem(oc_pushimm64,stackoffset,before)^ do begin
     par.imm.vfloat64:= po1^.d.dat.constval.vfloat;
    end;
   end;
   dk_string8: begin
    isimm:= false;
    segad1:= stringconst(po1^.d.dat.constval.vstring);
    if segad1.segment = seg_nil then begin
     insertitem(oc_pushnil,stackoffset,before);
    end
    else begin
     with insertitem(oc_pushsegaddress,stackoffset,before)^ do begin
      par.vsegaddress.a:= segad1;
      par.vsegaddress.offset:= 0;
     end;
    end;
   end;
  {$ifdef mse_checkinternalerror}                             
   else begin
    internalerror(ie_handler,'20131121A');
   end;
  {$endif}
  end;
 {
  if isimm then begin
   par.ssad:= ssaindex;
  end;
 }
  initfactcontext(stackoffset);
 end;
end;

procedure offsetad(const stackoffset: integer; const aoffset: dataoffsty);
begin
 if aoffset <> 0 then begin
  with insertitem(oc_addimmint32,stackoffset,false)^ do begin
   par.imm.vint32:= aoffset;
  end;
 end;
end;

function addpushimm(const aop: opcodety): popinfoty; 
                                 {$ifndef mse_debugparser} inline; {$endif}
begin
 result:= additem(aop);
// result^.par.ssad:= info.ssaindex;
end;

procedure push(const avalue: boolean); overload;
begin
 with addpushimm(oc_pushimm8)^ do begin
  par.imm.vboolean:= avalue;
 end;
end;

procedure push(const avalue: integer); overload;
begin
 with addpushimm(oc_pushimm32)^ do begin
  par.imm.vint32:= avalue;
 end;
end;

procedure push(const avalue: real); overload;
begin
 with addpushimm(oc_pushimm64)^ do begin
  par.imm.vfloat64:= avalue;
 end;
end;

procedure pushins(const ains: boolean; const stackoffset: integer;
          const before: boolean;
          const avalue: addressvaluety; const offset: dataoffsty;
                                           const indirect: boolean);
//todo: optimize

 function getop(const aop: opcodety): popinfoty;
 begin
  if ains then begin
   result:= insertitem(aop,stackoffset,before);
  end
  else begin
   result:= additem(aop);
  end;
 end;

var
 po1: popinfoty;
  
begin
 if af_nil in avalue.flags then begin
  with getop(oc_pushaddr)^ do begin
   par.imm.vpointer:= 0;
  end;
 end
 else begin
  if af_segment in avalue.flags then begin
   if indirect then begin
    po1:= getop(oc_pushsegaddrindi);
   end
   else begin
    po1:= getop(oc_pushsegaddr);
   end;
   with po1^ do begin
    par.vsegaddress.a:= avalue.segaddress;
    par.vsegaddress.offset:= offset;
   end;
  end
  else begin
   if indirect then begin
    po1:= getop(oc_pushlocaddrindi);
   end
   else begin
    po1:= getop(oc_pushlocaddr);
   end;
   with po1^ do begin
    par.vlocaddress.a:= avalue.locaddress;
    par.vlocaddress.a.framelevel:= 
                               info.sublevel-avalue.locaddress.framelevel-1;
    par.vlocaddress.offset:= offset;
   end;
  end;
 end;
end;

procedure push(const avalue: addressvaluety; const offset: dataoffsty;
            const indirect: boolean); overload;
begin
 pushins(false,0,false,avalue,offset,indirect);
end;

procedure pushinsert(const stackoffset: integer; const before: boolean;
            const avalue: addressvaluety; const offset: dataoffsty;
            const indirect: boolean); overload;
begin
 pushins(true,stackoffset,before,avalue,offset,indirect);
end;

procedure push(const avalue: datakindty); overload;
      //no alignsize
begin
 with addpushimm(oc_pushimmdatakind)^ do begin
  par.imm.vdatakind:= avalue;
 end;
end;

function insertpushimm(const aop: opcodety; const stackoffset: integer;
                       const before: boolean): popinfoty; 
                                 {$ifndef mse_debugparser} inline; {$endif}
begin
 result:= insertitem(aop,stackoffset,before);
// result^.par.ssad:= info.ssaindex;
end;

procedure pushinsert(const stackoffset: integer; const before: boolean;
                                    const avalue: datakindty); overload;
      //no alignsize
begin
 with insertpushimm(oc_pushimmdatakind,stackoffset,before)^ do begin
  par.imm.vdatakind:= avalue;
 end;
end;

procedure pushconst(const avalue: contextdataty);
//todo: optimize
begin
 with avalue do begin
  case dat.constval.kind of
   dk_boolean: begin
    push(dat.constval.vboolean);
   end;
   dk_integer: begin
    push(dat.constval.vinteger);
   end;
   dk_float: begin
    push(dat.constval.vfloat);
   end;
   dk_address: begin
    push(dat.constval.vaddress,0,false);
   end;
  end;
 end;
end;

procedure int32toflo64({; const index: integer});
begin
 additem(oc_int32toflo64);
end;

procedure setcurrentloc(const indexoffset: integer);
begin 
 with info do begin
  getoppo(
   contextstack[stackindex+indexoffset].opmark.address)^.par.opaddress:=
                                                                     opcount-1;
 end; 
end;

procedure setcurrentlocbefore(const indexoffset: integer);
begin 
 with info do begin
  getoppo(
   contextstack[stackindex+indexoffset].opmark.address-1)^.par.opaddress:=
                                                                     opcount-1;
 end; 
end;

procedure setlocbefore(const destindexoffset,sourceindexoffset: integer);
begin
 with info do begin
  getoppo(
   contextstack[stackindex+destindexoffset].opmark.address-1)^.par.opaddress:=
         contextstack[stackindex+sourceindexoffset].opmark.address-1;
 end; 
end;

procedure setloc(const destindexoffset,sourceindexoffset: integer);
begin
 with info do begin
  getoppo(
    contextstack[stackindex+destindexoffset].opmark.address)^.par.opaddress:=
         contextstack[stackindex+sourceindexoffset].opmark.address-1;
 end; 
end;

function convertconsts(): stackdatakindty;
                //convert stacktop, stacktop-2
begin
 with info,contextstack[stacktop-2] do begin
  result:= stackdatakinds[d.dat.constval.kind];  
  if contextstack[stacktop].d.dat.constval.kind <> d.dat.constval.kind then begin
   case contextstack[stacktop].d.dat.constval.kind of
    dk_float: begin
     result:= sdk_flo64;
     with d,dat.constval do begin
      case kind of
       dk_float: begin
        vfloat:= vfloat + contextstack[stacktop].d.dat.constval.vfloat;
       end;
       dk_integer: begin
        vfloat:= vinteger + contextstack[stacktop].d.dat.constval.vfloat;
        kind:= dk_float;
        dat.datatyp:= contextstack[stacktop].d.dat.datatyp;
       end;
       else begin
        result:= sdk_none;
       end;
      end;
     end;
    end;
    dk_integer: begin
     with d,dat.constval do begin
      case kind of
       dk_integer: begin
        vinteger:= vinteger + contextstack[stacktop].d.dat.constval.vinteger;
       end;
       dk_float: begin
        result:= sdk_flo64;
        vfloat:= vfloat + contextstack[stacktop].d.dat.constval.vfloat;
        kind:= dk_float;
        dat.datatyp:= contextstack[stacktop].d.dat.datatyp;
       end;
       else begin
        result:= sdk_none;
       end;
      end;
     end;
    end;
    else begin
     result:= sdk_none;
    end;
   end;
  end;
  if result = sdk_none then begin
   incompatibletypeserror(contextstack[stacktop-2].d,
                                           contextstack[stacktop].d);
  end;
 end;
end;

procedure pushd(const ains: boolean; const stackoffset: integer;
          const before: boolean; const address: addressvaluety;
                     const offset: dataoffsty; const size: datasizety{;
                     const ssaindex: integer});
//todo: optimize

 function getop(const aop: opcodety): popinfoty;
 begin
  if ains then begin
   result:= insertitem(aop,stackoffset,before);
  end
  else begin
   result:= additem(aop);
  end;
 end;

var
 po1: popinfoty;
 
begin
 with address do begin //todo: use table
  if af_segment in flags then begin
   case size of
    1: begin 
     po1:= getop(oc_pushseg8);
    end;
    2: begin
     po1:= getop(oc_pushseg16);
    end;
    4: begin
     po1:= getop(oc_pushseg32);
    end;
    else begin
     po1:= getop(oc_pushseg);
    end;
   end;
   with po1^ do begin
    par.memop.segdataaddress.a:= segaddress;
    par.memop.segdataaddress.offset:= offset;
   end;
  end
  else begin
   if af_param in flags then begin
    case size of
     1: begin 
      po1:= getop(oc_pushpar8);
     end;
     2: begin
      po1:= getop(oc_pushpar16);
     end;
     4: begin
      po1:= getop(oc_pushpar32);
     end;
     else begin
      po1:= getop(oc_pushpar);
     end;
    end;
   end
   else begin   
    if af_paramindirect in flags then begin
     case size of
      1: begin 
       po1:= getop(oc_pushlocindi8);
      end;
      2: begin
       po1:= getop(oc_pushlocindi16);
      end;
      4: begin
       po1:= getop(oc_pushlocindi32);
      end;
      else begin
       po1:= getop(oc_pushlocindi);
      end;
     end;
    end
    else begin
     case size of
      1: begin 
       po1:= getop(oc_pushloc8);
      end;
      2: begin
       po1:= getop(oc_pushloc16);
      end;
      4: begin
       po1:= getop(oc_pushloc32);
      end;
      else begin
       po1:= getop(oc_pushloc);
      end;
     end;
    end;
   end;
   with po1^ do begin
    par.memop.locdataaddress.a:= locaddress;
    par.memop.locdataaddress.a.framelevel:= 
                                        info.sublevel-locaddress.framelevel-1;
    par.memop.locdataaddress.offset:= offset;
   end;
  end;
  po1^.par.memop.datasize:= size;
//  par.ssad:= ssaindex;
 end;
end;

//todo: optimize call
procedure pushdata(const address: addressvaluety; const offset: dataoffsty;
                         const size: datasizety{; const ssaindex: integer});
begin
 pushd(false,0,false,address,offset,size{,ssaindex});
end;

procedure pushinsertdata(const stackoffset: integer; const before: boolean;
                  const address: addressvaluety; const offset: dataoffsty;
                  const size: datasizety{; const ssaindex: integer});
begin
 pushd(true,stackoffset,before,address,offset,size{,ssaindex});
end;

procedure initfactcontext(const stackoffset: integer);
{
var
 int1: integer;
 po1: pcontextitemty;
 pend: pointer;
 ssa1: integer;
}
var
 int1,ssa1: integer;
 op1: opaddressty;
begin
 with info do begin
  int1:= stackindex+stackoffset;
  with info.contextstack[int1] do begin
   if int1 >= stacktop then begin
    ssa1:= ssa.index;
//    inc(ssaindex);
   end
   else begin
    op1:= contextstack[int1+1].opmark.address;
    if op1 > opmark.address then begin
     ssa1:= getoppo(op1-1)^.par.ssad; //use last op of context
    end
    else begin
     if op1 = opcount-1 then begin
      ssa1:= ssa.index;
//      inc(ssaindex);
     end
     else begin
      ssa1:= getoppo(op1)^.par.ssad; //use current op
     end;
    end;
   end;
   d.kind:= ck_fact;
   d.dat.fact.ssaindex:= ssa1;
//   inc(info.ssaindex);
   d.dat.indirection:= 0;
  end;
 end;
end;

function pushindirection(const stackoffset: integer): boolean;
var
 int1: integer;
begin
 result:= true;
 with info,contextstack[stackindex+stackoffset] do begin;
  if d.dat.indirection <= 0 then begin
   if d.dat.indirection = 0 then begin
    pushinsert(stackoffset,false,d.dat.ref.c.address,d.dat.ref.offset,true);
   end
   else begin
    pushinsert(stackoffset,false,d.dat.ref.c.address,0,true);
    for int1:= d.dat.indirection to -2 do begin
     insertitem(oc_indirectpo,stackoffset,false);
    end;
    with insertitem(oc_indirectpooffs,stackoffset,false)^ do begin
     par.voffset:= d.dat.ref.offset;
    end;
   end;
   initfactcontext(stackoffset);
  end
  else begin
   errormessage(err_cannotassigntoaddr,[],stackoffset);
   result:= false;
  end;
 end;
end;

function getvalue(const stackoffset: integer;
                            const retainconst: boolean = false): boolean;

 procedure doindirect();
 var
  po1: ptypedataty;
  si1: datasizety;
  op1: opcodety;
 begin
  with info,contextstack[stackindex+stackoffset],d do begin
   if dat.datatyp.indirectlevel > 0 then begin
    si1:= pointersize;
   end
   else begin
    si1:= ptypedataty(ele.eledataabs(dat.datatyp.typedata))^.bytesize;
   end;
   case si1 of       //todo: use table
    1: begin
     op1:= oc_indirect8;
    end;
    2: begin
     op1:= oc_indirect16;
    end;
    4: begin
     op1:= oc_indirect32;
    end;
    else begin
     op1:= oc_indirect;
    end;
   end;
   with insertitem(op1,stackoffset,false)^ do begin
    par.memop.datasize:= si1;
   end;
  end;
 end;

var
 po1: ptypedataty;
 si1: datasizety;
 op1: popinfoty;
 int1: integer;
 
begin                    //todo: optimize
 result:= false;
 with info,contextstack[stackindex+stackoffset] do begin
  case d.kind of
   ck_ref: begin
    if d.dat.datatyp.indirectlevel < 0 then begin
     errormessage(err_invalidderef,[],stackoffset);
     exit;
    end;
    if d.dat.indirection > 0 then begin //@ operator
     if d.dat.indirection = 1 then begin
      pushinsertaddress(stackoffset,false);
     end
     else begin
      errormessage(err_cannotassigntoaddr,[],stackoffset);
      exit;
     end;
    end
    else begin
     if d.dat.indirection < 0 then begin //dereference
      inc(d.dat.indirection); //correct addr handling
      if not pushindirection(stackoffset) then begin
       exit;
      end;
      doindirect;
     end
     else begin
      if d.dat.datatyp.indirectlevel <= 0 then begin //??? <0 = error?
       po1:= ele.eledataabs(d.dat.datatyp.typedata);
       si1:= po1^.bytesize;
      end
      else begin
       si1:= pointersize;
      end;
      pushinsertdata(stackoffset,false,d.dat.ref.c.address,d.dat.ref.offset,
                                                                 si1{,ssaindex});
     end;
    end;
   end;
   ck_reffact: begin
    doindirect();
   end;
   ck_const: begin
    if retainconst then begin
     result:= true;
     exit;
    end;
    pushinsertconst(stackoffset,false);
   end;
   ck_subres,ck_fact: begin
    if d.dat.indirection < 0 then begin
     for int1:= d.dat.indirection+2 to 0 do begin
      insertitem(oc_indirectpo,stackoffset,false);
     end;
     d.dat.indirection:= 0;
     doindirect();
    end
    else begin
     if d.dat.indirection > 0 then begin
      errormessage(err_cannotaddressexp,[],stackoffset);
      exit;
     end;
    end;
   end;
  {$ifdef mse_checkinternalerror}                             
   else begin
    internalerror(ie_notimplemented,'20140401B');
   end;
  {$endif}
  end;
  if d.kind <> ck_fact then begin
   initfactcontext(stackoffset);
  end;
 end;
 result:= true;
end;

function getaddress(const stackoffset: integer;
                                const endaddress: boolean): boolean;
var
// ref1: refvaluety;
 int1: integer;
begin
 result:= false;
 with info,contextstack[stackindex+stackoffset] do begin
 {$ifdef mse_checkinternalerror}                             
  if not (d.kind in datacontexts) then begin
   internalerror(ie_handler,'20140405A');
  end;
 {$endif}
  inc(d.dat.indirection);
  inc(d.dat.datatyp.indirectlevel);
  if d.dat.datatyp.indirectlevel <= 0 then begin
   errormessage(err_cannotassigntoaddr,[]);
   exit;
  end;
  case d.kind of
   ck_ref: begin
    if d.dat.indirection = 1 then begin
     if endaddress then begin
      pushinsert(stackoffset,false,d.dat.ref.c.address,d.dat.ref.offset,false);
                  //address pointer on stack
      initfactcontext(stackoffset);
     end
     else begin
      d.kind:= ck_refconst;
      d.dat.indirection:= 0;
//      ref1:= d.dat.ref; //todo: optimize
      d.dat.ref.c.address.poaddress:=
                       d.dat.ref.c.address.poaddress + d.dat.ref.offset;
      d.dat.ref.offset:= 0;
//      d.dat.ref.c.address:= ref1
      {
      d.dat.constval.kind:= dk_address;
      d.dat.constval.vaddress:= ref1.c.address;
      d.dat.constval.vaddress.poaddress:= 
                       d.dat.constval.vaddress.poaddress + ref1.offset;
      }
     end;
    end
    else begin
     if not pushindirection(stackoffset) then begin
      exit;
     end;
    end;
   end;
   ck_reffact: begin //
    internalerror1(ie_notimplemented,'20140404B'); //todo
    exit;
   end;
   ck_fact,ck_subres: begin
    if d.dat.indirection <> 0 then begin
     result:= getvalue(stackoffset);
    end;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20140401A');
   end;
  {$endif}
  end;
 end;
 result:= true;
end;

procedure init;
var
 ty1: systypety;
 po1: pelementinfoty;
 po2: ptypedataty;
 int1: integer;
begin
 ele.addelement(tks_units,ek_none,globalvisi,unitsele);
 for ty1:= low(systypety) to high(systypety) do begin
  with systypeinfos[ty1] do begin
   po1:= ele.addelement(getident(name),ek_type,globalvisi);
   po2:= @po1^.data;
   po2^:= data;
  end;
  sysdatatypes[ty1].typedata:= ele.eleinforel(po1);
//  sysdatatypes[ty1].flags:= [];
 end;
 for int1:= low(sysconstinfos) to high(sysconstinfos) do begin
  with sysconstinfos[int1] do begin
   po1:= ele.addelement(getident(name),ek_const,globalvisi);
   with pconstdataty(@po1^.data)^ do begin
    val.d:= cval;
    val.typ:= sysdatatypes[ctyp];
   end;
  end;
 end;
 syssubhandler.init();
end;

procedure deinit;
begin
 syssubhandler.deinit();
end;

procedure resetssa();
begin
 with info do begin
  ssa.index:= 0;
  ssa.nextindex:= 0;
 end;
end;

procedure updateop(const opsinfo: opsinfoty);
//todo: don't convert inplace, stack items will be of variable size
var
 kinda,kindb: datakindty;
 po1: pelementinfoty;
 sd1: stackdatakindty;
 op1: opcodety;
begin
 with info do begin
                  //todo: work botom up because of less op insertions
  if contextstack[stacktop].d.kind <> ck_const then begin
   getvalue(stacktop-stackindex{,false});
  end;
  sd1:= sdk_none;
  po1:= ele.eleinfoabs(contextstack[stacktop].d.dat.datatyp.typedata);
  kinda:= ptypedataty(@po1^.data)^.kind;
  po1:= ele.eleinfoabs(contextstack[stacktop-2].d.dat.datatyp.typedata);
  kindb:= ptypedataty(@po1^.data)^.kind;
  with contextstack[stacktop-2] do begin
   if d.kind <> ck_const then begin
    getvalue(stacktop-2-stackindex);
   end;
   if (kinda = dk_float) or (kindb = dk_float) then begin
    sd1:= sdk_flo64;
    if d.kind = ck_const then begin
     case d.dat.constval.kind of
      dk_integer: begin
       with insertitem(oc_pushimm64,stacktop-2-stackindex,false)^ do begin
        par.imm.vfloat64:= real(d.dat.constval.vinteger);
       end;
      end;
      dk_float: begin
       with insertitem(oc_pushimm64,stacktop-2-stackindex,false)^ do begin
        par.imm.vfloat64:= d.dat.constval.vfloat;
       end;
      end;
      else begin
       sd1:= sdk_none;
      end;
     end;
    end
    else begin //ck_fact
     case kinda of
      dk_integer: begin
       insertitem(oc_int32toflo64,stacktop-2-stackindex,false);
      end;
      dk_float: begin
      end;
      else begin
       sd1:= sdk_none;
      end;
     end;
    end;
    with contextstack[stacktop].d do begin
     if kind = ck_const then begin
      case kinda of
       dk_integer: begin
        push(real(dat.constval.vinteger));
       end;
       dk_float: begin
        push(real(dat.constval.vfloat));
       end;
       else begin
        sd1:= sdk_none;
       end;
      end;
     end
     else begin
      case kinda of
       dk_integer: begin
         int32toflo64({info});
       end;
       dk_float: begin
       end;
       else begin
        sd1:= sdk_none;
       end;
      end;
     end;
    end;
   end
   else begin
    if kinda = dk_boolean then begin
     if kindb = dk_boolean then begin
      sd1:= sdk_bool8;
      if d.kind = ck_const then begin
       with insertitem(oc_pushimm8,stacktop-2-stackindex,false)^ do begin
        par.imm.vboolean:= d.dat.constval.vboolean;
       end;
      end;
      with contextstack[stacktop].d do begin
       if kind = ck_const then begin
        push(dat.constval.vboolean);
       end;
      end;
     end;
    end
    else begin
     if (kinda = dk_integer) and (kindb = dk_integer) then begin
      sd1:= sdk_int32;
      if d.kind = ck_const then begin
       with insertitem(oc_pushimm32,stacktop-2-stackindex,false)^ do begin
        par.imm.vint32:= d.dat.constval.vinteger;
       end;
      end;
      with contextstack[stacktop],d do begin
       if kind = ck_const then begin
        push(dat.constval.vinteger);
        initfactcontext(stacktop-stackindex);
       end;
      end;
     end;
    end;
   end;
   if sd1 = sdk_none then begin
    incompatibletypeserror(contextstack[stacktop-2].d,
                                            contextstack[stacktop].d);
   end
   else begin
    op1:= opsinfo.ops[sd1];
    if op1 = oc_none then begin
     operationnotsupportederror(d,contextstack[stacktop].d,opsinfo.opname);
     dec(stacktop,2);
    end
    else begin
     with additem(op1)^ do begin      
//      par.ssad:= ssa.index;
      par.ssas1:= d.dat.fact.ssaindex;
      par.ssas2:= contextstack[stacktop].d.dat.fact.ssaindex;
     end;
     dec(stacktop,2);
//     opmark.address:= opcount-1;
     initfactcontext(-1{stacktop-stackindex});
     d.dat.datatyp:= sysdatatypes[resultdatatypes[sd1]];
     context:= nil;
    end;
   end;
  end;
//  if contextstack[stacktop].d.kind <> ck_const then begin
//   getvalue(stacktop-stackindex{,false});
//  end;
  stackindex:= stacktop-1; 
 end;
end;

procedure getordrange(const typedata: ptypedataty; out range: ordrangety);
begin
 with typedata^ do begin
  case kind of
   dk_cardinal: begin
    if datasize <= das_8 then begin
     range.min:= infocard8.min;
     range.max:= infocard8.max;
    end
    else begin
     if datasize <= das_16 then begin
      range.min:= infocard16.min;
      range.max:= infocard16.max;
     end
     else begin
      range.min:= infocard32.min;
      range.max:= infocard32.max;
     end;
    end;
   end;
   dk_integer: begin
    if datasize <= das_8 then begin
     range.min:= infoint8.min;
     range.max:= infoint8.max;
    end
    else begin
     if datasize <= das_16 then begin
      range.min:= infoint16.min;
      range.max:= infoint16.max;
     end
     else begin
      range.min:= infoint32.min;
      range.max:= infoint32.max;
     end;
    end;
   end;
   dk_boolean: begin
    range.min:= 0;
    range.max:= 1;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20120327B');
   end;
  {$endif}
  end;
 end;
end;

function getordcount(const typedata: ptypedataty): int64;
var
 ra1: ordrangety;
begin
 getordrange(typedata,ra1);
 result:= ra1.max - ra1.min + 1;
end;

function getordconst(const avalue: dataty): int64;
begin
 with avalue do begin
  case kind of
   dk_integer: begin
    result:= vinteger;
   end;
   dk_boolean: begin
    if vboolean then begin
     result:= 1;
    end
    else begin
     result:= 0;
    end;
   end;
  {$ifdef mse_checkinternalerror}
   else begin
    internalerror(ie_handler,'20140329A');
   end;
  {$endif}
  end;
 end;
end;

function getdatabitsize(const avalue: int64): databitsizety;
begin
 result:= das_8;
 if avalue < 0 then begin
  if avalue < -$80 then begin
   if avalue < -$8000 then begin
    if avalue < -$80000000 then begin
     result:= das_64;
    end
    else begin
     result:= das_32;
    end;
   end
   else begin
    result:= das_16;
   end;
  end;   
 end
 else begin
  if avalue > $7f then begin
   if avalue > $7fff then begin
    if avalue > $7fffffff then begin
     result:= das_64;
    end
    else begin
     result:= das_32;
    end;
   end
   else begin
    result:= das_16;
   end;
  end;   
 end;
end;

procedure trackalloc(const asize: integer; var address: segaddressty);
begin
 if info.backend = bke_llvm then begin
  if address.segment = seg_globvar then begin
   address.address:= info.globallocid;
   inc(info.globallocid);
   {
   with pgloballocinfoty(
              allocsegmentpo(seg_globalloc,sizeof(globallocinfoty)))^ do begin
    a:= address;
    size:= asize;
   end;
   }
  end;
 end;
end;

procedure trackalloc(const asize: integer; var address: addressvaluety);
begin
 if info.backend = bke_llvm then begin
  if af_segment in address.flags then begin
   trackalloc(asize,address.segaddress);
  end
  else begin
   address.locaddress.address:= info.locallocid;
   inc(info.locallocid);
   with plocallocinfoty(
               allocsegmentpo(seg_localloc,sizeof(locallocinfoty)))^ do begin
    a:= address;
    size:= asize;
   end;
  end;
 end;
end;

{
procedure trackalloc(const asize: integer; var address: locaddressty);
begin
 if info.backend = bke_llvm then begin
  address.address:= info.locallocid;
  inc(info.locallocid);
  with plocallocinfoty(
              allocsegmentpo(seg_localloc,sizeof(locallocinfoty)))^ do begin
   a:= address;
   size:= asize;
  end;
 end;
end;
}
{
procedure allocsubvars(const asub: psubdataty; out allocs: suballocinfoty);
var
 po1: pvardataty;
 ele1: elementoffsetty;
 size1: integer;
begin
 ele1:= asub^.varchain;
 with allocs do begin
  parallocs:= getsegmenttopoffs(seg_localloc);
  paralloccount:= 0;
  while ele1 <> 0 do begin
   po1:= ele.eledataabs(ele1);
   if not (af_param in po1^.address.flags) then begin
    break;
   end;
   if po1^.address.indirectlevel > 0 then begin
    size1:= pointersize;
   end
   else begin
    size1:= ptypedataty(ele.eledataabs(po1^.vf.typ))^.bytesize;
   end;
   trackalloc(size1,po1^.address);
   inc(paralloccount);
   ele1:= po1^.vf.next;
  end;
  varallocs:= getsegmenttopoffs(seg_localloc);
  varalloccount:= 0;
  while ele1 <> 0 do begin
   po1:= ele.eledataabs(ele1);
   if po1^.address.indirectlevel > 0 then begin
    size1:= pointersize;
   end
   else begin
    size1:= ptypedataty(ele.eledataabs(po1^.vf.typ))^.bytesize;
   end;
   trackalloc(size1,po1^.address);
   inc(varalloccount);
   ele1:= po1^.vf.next;
  end;
 end;
end;
}
{$ifdef mse_debugparser}
procedure outhandle(const text: string);
begin
 outinfo('*'+text+'*',false);
end;

procedure outinfo(const text: string; const indent: boolean = true);

 procedure writetype(const ainfo: contextdataty);
 var
  po1: ptypedataty;
 begin
  with ainfo.dat.datatyp do begin
   po1:= ele.eledataabs(typedata);
   write('T:',typedata,' ',
          getenumname(typeinfo(datakindty),ord(po1^.kind)));
   if po1^.kind <> dk_none then begin
    write(' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                  integer(po1^.flags),false),
          ' I:',indirectlevel,':',ainfo.dat.indirection,
          ' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                                            integer(flags),false),' ');
   end;
  end;
 end;//writetype

 procedure writetyp(const atyp: typeinfoty);
 var
  po1: ptypedataty;
 begin
  with atyp do begin
   if typedata = 0 then begin
    write('NIL');
   end
   else begin
    po1:= ele.eledataabs(typedata);
    write('T:',typedata,' ',
           getenumname(typeinfo(datakindty),ord(po1^.kind)));
    if po1^.kind <> dk_none then begin
     write(' F:',settostring(ptypeinfo(typeinfo(typeflagsty)),
                  integer(po1^.flags),false),
           ' I:',indirectlevel);
    end;
   end;
  end;
 end;//writetyp

 procedure writetypedata(const adata: ptypedataty);
 begin
   write(getidentname(pelementinfoty(pointer(adata)-eledatashift)^.header.name),
          ':',getenumname(typeinfo(datakindty),ord(adata^.kind)))
  end;
 
 procedure writeaddress(const aaddress: addressvaluety);
 begin
  with aaddress do begin
   write('I:',inttostr(indirectlevel),' A:',inttostr(integer(poaddress)),' ');
   write(settostring(ptypeinfo(typeinfo(addressflagsty)),
                                                     integer(flags),true),' ');
   if af_stack in flags then begin
    write(' F:',inttostr(locaddress.framelevel),' ');
   end;
   if af_segment in flags then begin
    write(' S:',getenumname(typeinfo(segmentty),ord(segaddress.segment)),' ');
   end;
  end;
 end;//writeaddress
 
 procedure writeref(const ainfo: contextdataty);
 begin
  with ainfo.dat.ref do begin
   writeaddress(c.address);
   write('O:',offset,' ');
  end;
 end;//writeref
 
var
 int1: integer;
begin
 with info do begin
  if indent then begin
   write('  ');
  end;
  write(text,' T:',stacktop,' I:',stackindex,' O:',opcount,
  ' S:',ssa.index,' N:',ssa.nextindex,
  ' cont:',currentcontainer);
  if currentcontainer <> 0 then begin
   write(' ',getidentname(ele.eleinfoabs(currentcontainer)^.header.name));
  end;
  write(' ',settostring(ptypeinfo(typeinfo(statementflagsty)),
                         integer(currentstatementflags),true));
  write(' L:'+inttostr(source.line+1)+':''',psubstr(debugsource,source.po)+''','''+
                         singleline(source.po),'''');
  writeln;
  for int1:= 0 to stacktop do begin
   write(fitstring(inttostr(int1),3,sp_right));
   if int1 = stackindex then begin
    write('*');
   end
   else begin
    write(' ');
   end;
   if (int1 < stacktop) and (int1 = contextstack[int1+1].parent) then begin
    write('-');
   end
   else begin
    write(' ');
   end;
   with contextstack[int1],d do begin
    write(fitstring(inttostr(parent),3,sp_right),' ');
    if bf_continue in transitionflags then begin
     write('>');
    end
    else begin
     write(' ');
    end;
    if context <> nil then begin
     with context^ do begin
      if cutbefore then begin
       write('-');
      end
      else begin
       write(' ');
      end;
      if pop then begin
       write('^');
      end
      else begin
       write(' ');
      end;
      if popexe then begin
       write('!');
      end
      else begin
       write(' ');
      end;
      if cutafter then begin
       write('-');
      end
      else begin
       write(' ');
      end;
     end;
     write(fitstring(inttostr(opmark.address),3,sp_right));
     write('<',context^.caption,'> ');
    end
    else begin
     write(fitstring(inttostr(opmark.address),3,sp_right));
     write('<NIL> ');
    end;
    write(getenumname(typeinfo(kind),ord(kind)),' ');
    case kind of
     ck_ident: begin
      write('$',hextostr(ident.ident,8),':',ident.len);
      if ident.continued then begin
       write('c ');
      end
      else begin
       write('  ');
      end;
      write(getidentname(ident.ident));
     end;
     ck_getfact: begin
      with getfact do begin
       write('flags:',settostring(ptypeinfo(typeinfo(factflagsty)),
                                           integer(getfact.flags),true));
      end;
     end;
     ck_fact,ck_subres: begin
      write('ssa:',d.dat.fact.ssaindex,' ');
      writetype(d);
     end;
     ck_ref: begin
      writeref(d);
      writetype(d);
     end;
     ck_reffact: begin
      writetype(d);
     end;
     ck_const: begin
      writetype(d);
      write('V:');
      case dat.constval.kind of
       dk_boolean: begin
        write(dat.constval.vboolean,' ');
       end;
       dk_integer: begin
        write(dat.constval.vinteger,' ');
       end;
       dk_float: begin
        write(dat.constval.vfloat,' ');
       end;
       dk_address: begin
        writeaddress(dat.constval.vaddress);
       end;
      end;
     end;
     ck_subdef: begin
      write('fl:',settostring(ptypeinfo(typeinfo(subflagsty)),
                                           integer(subdef.flags),true),
            ' ma:',subdef.match,
                            ' ps:',subdef.paramsize,' vs:',subdef.varsize);
     end;
     ck_paramsdef: begin
      with paramsdef do begin
       write('kind:',getenumname(typeinfo(kind),ord(kind)))
      end;
     end;
     ck_recorddef: begin
      write('foffs:',d.rec.fieldoffset);
     end;
     ck_classdef: begin
      write('foffs:',d.cla.fieldoffset,' virt:',d.cla.virtualindex);
     end;
     ck_index: begin
      write('opshiftmark:'+inttostr(opshiftmark));
     end;
     ck_typedata: begin
      writetypedata(d.typedata);
     end;
     ck_typeref: begin
      writetypedata(ele.eledataabs(d.typeref));
     end;
     ck_typetype,ck_fieldtype: begin
      writetyp(typ);
     end;
    end;
    writeln(' '+inttostr(start.line+1)+':''',
             psubstr(debugstart,start.po),''',''',singleline(start.po),'''');
   end;
  end;
 end;
end;

{$endif}

end.