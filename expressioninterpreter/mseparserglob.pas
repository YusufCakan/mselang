{ MSEide Copyright (c) 2013 by Martin Schreiber
   
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
unit mseparserglob;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 msestream,mseelements;

type
 uint8 = byte; 
 uint16 = word;
 uint32 = longword;
 sint8 = shortint; 
 sint16 = smallint;
 sint32 = integer;

 puint8 = ^uint8; 
 puint16 = ^uint16;
 puint32 = ^uint32;
 psint8 = ^sint8; 
 psint16 = ^sint16;
 psint32 = ^sint32;
 
 datakindty = (dk_none,dk_bool8,dk_int32,dk_flo64,dk_kind,dk_address,dk_record);

const
 defaultstackdepht = 256;

type 
 contextkindty = (ck_none,ck_error,
                  ck_end,ck_ident,ck_opmark,
                  ck_neg,ck_const,ck_fact);
 stackdatakindty = (sdk_bool8,sdk_int32,sdk_flo64,
                    sdk_bool8rev,sdk_int32rev,sdk_flo64rev);
 opaddressty = ptruint;
 dataaddressty = ptruint;
 
const
// constkinds = [ck_bool8const,ck_int32const,ck_flo64const];
 dummyaddress = 0;
 {
 contextdatakinds: array[contextkindty] of datakindty = (
                  //ck_none,ck_error,
                    dk_none,dk_none,
                  //ck_end,ck_ident,ck_opmark,
                    dk_none,dk_none,dk_none,
                  //ck_neg,
                    dk_none,
                  //ck_bool8const,ck_int32const,ck_flo64const,
                    dk_bool8,     dk_int32,     dk_flo64,
                  //ck_bool8fact,ck_int32fact,ck_flo64fact);
                    dk_bool8,    dk_int32,    dk_flo64
                    );   
}
type
 pparseinfoty = ^parseinfoty;
 contexthandlerty = procedure(const info: pparseinfoty);

 pcontextty = ^contextty;
 branchty = record
  t: string;
  x: boolean; //exit
  k: boolean; //keyword
  c: pcontextty;
  e: boolean; //eat flag
  p: boolean; //push flag
  s: boolean; //set ck_pc
  sb: boolean; //setparent before push flag
  sa: boolean; //setparent after push flag
 end;
 pbranchty = ^branchty;

 contextty = record
  branch: pbranchty; //array
  handle: contexthandlerty;
  continue: boolean;
  cut: boolean;
  restoresource: boolean;
  pop: boolean;
  popexe: boolean;
  nexteat: boolean;
  next: pcontextty;
//  setstackmark: boolean;
  caption: string;
 end;
 {
 bool8constty = record
  value: boolean;
 end;
 int32constty = record
  value: integer;
 end;
 flo64constty = record
  value: double;
 end;
 }
 datainfoty = record
  case kind: datakindty of //first, maps ck_fact: factkind
   dk_bool8: (
    vbool8: integer;
   );
   dk_int32: (
    vint32: integer;
   );
   dk_flo64: (
    vflo64: double;
   );
 end;
 opmarkty = record
  address: opaddressty;
 end;
 {
 constkindty = (cok_bool8,cok_int32,cok_flo64);
 constdataty = record
  case kind: constkindty of
   cok_bool8: (bool8: bool8constty);
   cok_int32: (int32: int32constty);
   cok_flo64: (flo64: flo64constty);
 end;
 }
 contextdataty = record
  case kind: contextkindty of 
   ck_ident:(
    ident: identty;
    identlen: integer
   );
   ck_const:(
    constval: datainfoty;
   );
   ck_fact:(
    factkind: datakindty; 
   );
   {
   ck_bool8const:(
    bool8const: bool8constty;
   );
   ck_int32const:(
    int32const: int32constty;
   );
   ck_flo64const:(
    flo64const: flo64constty;
   );
   }
   {
   ck_var:(
    varaddress: ptruint;
    varsize: ptruint;
   );
   }
   ck_opmark:(
    opmark: opmarkty;
   )
 end;

 sourceinfoty = record
  po: pchar;
  line: integer;
 end;
  
 pcontextdataty = ^contextdataty;
 contextitemty = record
  parent: integer;
  context: pcontextty;
  start: sourceinfoty;
  debugstart: pchar;
  d: contextdataty;
 end;

 opty = procedure;

 op1infoty = record
  index0: integer;
 end;

 opninfoty = record
  paramcount: integer;
 end;

 startupdataty = record
  globdatasize: ptruint;
//  startaddress: opaddressty;
 end;
 pstartupdataty = ^startupdataty;
 
 opkindty = (ok_none,ok_startup,ok_pushbool8,ok_pushint32,ok_pushflo64,
             ok_pushdatakind,
             ok_pop,ok_op,ok_op1,ok_opn,ok_var,ok_opaddress);
 
 opdataty = record
  case opkindty of 
   ok_pushbool8: (
    vbool8: boolean;
   );
   ok_pushint32: (
    vint32: integer;
   );
   ok_pushflo64: (
    vflo64: real;
   );
   ok_pushdatakind: (
    vdatakind: datakindty;
   );
   ok_pop: (
    count: integer;
   );
   ok_op1: (
    op1: op1infoty;
   );
   ok_opn: (
    opn: opninfoty;
   );
   ok_var: (
    dataaddress: dataaddressty;
    datasize: ptruint;
   );
   ok_opaddress: (
    opaddress: opaddressty;
   );
  end;

 opinfoty = record
//todo: variable item size, immediate data
  op: opty;
  d: opdataty;
 end;
 popinfoty = ^opinfoty;

 opinfoarty = array of opinfoty;
 errorlevelty = (erl_none,erl_fatal,erl_error);

 parseinfoty = record
  pb: pbranchty;
  pc: pcontextty;
  stophandle: boolean;
  filename: string;
  sourcestart: pchar; //todo: use file cache for inclued files
  source: sourceinfoty;
  debugsource: pchar;
  consumed: pchar;
  contextstack: array of contextitemty;
  stackdepht: integer;
  stackindex: integer; 
  stacktop: integer; 
  command: ttextstream;
  errors: array[errorlevelty] of integer;
  ops: opinfoarty;
  opcount: integer;
  start: integer;
  globdatapo: ptruint;
  locdatapo: ptruint;
 end;

const
 startupoffset = (sizeof(startupdataty)+sizeof(opinfoty)-1) div 
                                                         sizeof(opinfoty);
implementation

end.
