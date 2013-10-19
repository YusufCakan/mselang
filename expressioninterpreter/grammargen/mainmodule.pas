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
unit mainmodule;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}
interface
uses
 mseglob,mseapplication,mseclasses,msedatamodules,msestrings,msesysenv;

(*
#<comment>

{<macroname>} "<macrotext>" 
 macrotext can be multiline, "" -> "

${macroname}
@<tokendef>
 <pascalstring>{,<pascalstring>}
<handler_usesdef>

<context>,[<next>][-],[<handler>][^|!][+][*][>]
    <handler> called by context termination,
    transition to <next> or termination if no branch matches
    or after return from branch
    <handler> also called for transition contexts without branches
 - -> eat text
 ^ -> pop parent
 ! -> pop parent and execute parent handler
 + -> restore source pointer
 * -> stackindex -> stacktop
 > -> continue with calling context
 <stringdef>|@<tokendef>{,<stringdef>|@<tokendef>},
              [[<context>][-] [[^][*] | [*][^]] [!] ] [,<pushed context>]
 - -> eat token
 <context>^ -> set parent
 <context>* -> push context
 <context>! -> set ck_opmark
 * -> terminate context
<stringdef> -> <pascalstring>[.]
 . -> keyword
*)

type
 tmainmo = class(tmsedatamodule)
   sysenv: tsysenvmanager;
   procedure eventloopexe(const sender: TObject);
   procedure afterinitexe(sender: tsysenvmanager);
 end;
var
 mainmo: tmainmo;
implementation
uses
 mainmodule_mfm,msefileutils,msestream,msesys,msetypes,msesysutils,sysutils,
 mseformatstr,msearrayutils,msemacros,mseparserglob,typinfo;
 
type
 paramty = (pa_grammarfile,pa_pasfile);

const
 b: array[0..0] of branchty = (
   (flags: []; dest: nil; push: nil; keys: (
    (kind: bkk_none; chars: []),
    (kind: bkk_none; chars: []),
    (kind: bkk_none; chars: []),
    (kind: bkk_none; chars: [])
    )
   )
  );

type
 branchrecty = record
  tokens: stringarty;
  keyword: keywordty;
  dest: string;
  push: string;
  emptytoken: boolean;
 end;
 
 brancharty = array of branchrecty;

//procedure test(uses: integer);

function checklastchar(var astr: string; const achar: char): boolean;
begin
 result:= (astr <> '') and (astr[length(astr)] = achar);
 if result then begin
  setlength(astr,length(astr)-1);
 end;
end;
 
function comparebranch(const l,r): integer;
begin
 result:= 0;
 with branchrecty(l) do begin
  if emptytoken then begin
   inc(result);
  end;
  if branchrecty(r).emptytoken then begin
   dec(result);
  end;
  if (result = 0) and not emptytoken then begin
   result:= keyword - branchrecty(r).keyword;
   if (result = 0) and (keyword = 0) then begin
    if length(tokens) = 0 then begin
     inc(result);
    end;
    if length(branchrecty(r).tokens) = 0 then begin
     dec(result);
    end;
    if (result = 0) and (length(tokens) <> 0) then begin
     result:= length(branchrecty(r).tokens[0]) - length(tokens[0]);
    end;
   end;
  end;
 end;
end;

function charsettostring(const aset: charsetty): string;
 function getcharstr(const achar: char): string;
 begin
  if (achar > #$1f) and (achar < #$7f) then begin
   if achar = '''' then begin
    result:= '''''''''';
   end
   else begin
    result:= ''''+achar+'''';
   end;
  end
  else begin
   result:= '#'+inttostr(ord(achar));
  end;
 end; //getcharstr
 
var
 ch1: char;
 last: integer;
begin
 result:= '[';
 last:= -1;
 for ch1:= #1 to #255 do begin
  if ch1 in aset then begin
   if last < 0 then begin
    result:= result+getcharstr(ch1);
    last:= ord(ch1);
   end
   else begin
    if ch1 = #255 then begin
     result:= result+'..#255';
    end;
   end;
  end
  else begin
   if last >= 0 then begin
    if (last <> ord(ch1)-1) then begin
     result:= result+'..'+getcharstr(char(byte(ch1)-1));
    end;
    result:= result+',';
    last:= -1;
   end;
  end;
 end;
 if result[length(result)] = ',' then begin
  setlength(result,length(result)-1);
 end;
 result:= result + ']';
end;

procedure creategrammar(const grammar,outfile: filenamety);
type
 contextinfoty = record
  cont: stringarty;
  bran: brancharty;
 end;
 contextinfoarty = array of contextinfoty;
 tokendefty = record
  name: string;
  tokens: stringarty;
 end;
 tokendefarty = array of tokendefty;
 
var
 grammarstream: ttextstream = nil;
 passtream: ttextstream = nil;
 str1: string;
 firstrow: boolean = true;
 usesdef: string;
 context: string;
 contextline: stringarty;
 branches: brancharty;
 line: integer;
// branchcount: integer;
 contexts: contextinfoarty;
 tokendefs: tokendefarty;
 intokendef: boolean;
 keywords: array of string;

 procedure error(const text: string);
 begin
  exitcode:= 1;
//  application.terminated:= true;
  writestderr('***ERROR*** '+text+ ' line '+inttostr(line)+lineend+str1,true);
 end;

 function getkeyword(const atext: string; out keyword: keywordty): boolean;
 const
  keywordoffset = 1;
 var
  int1: integer;
  mstr1: msestring;
  str1: string;
 begin
  result:= true;
  if not trypascalstringtostring(atext,mstr1) then begin
   error('Invalid keyword "'+atext+'".');
   result:= false;
   exit;
  end;
  str1:= mstr1;
  for int1:= 1 to length(str1) do begin
   if not (str1[int1] in ['a'..'z','A'..'Z']) then begin
    error('Invalid keyword "'+str1+'".');
    result:= false;
    exit;
   end;
  end;
  for int1:= 0 to high(keywords) do begin
   if keywords[int1] = str1 then begin
    keyword:= int1+keywordoffset;
//    atext:= stringtopascalstring(msechar(int1+keywordoffset));
    exit;
   end;
  end;
  setlength(keywords,high(keywords)+2);
  keywords[high(keywords)]:= str1;
  if high(keywords) + keywordoffset > 255 then begin
   error('Too many keywords.');
   result:= false;
   exit;
  end;
  keyword:= high(keywords)+keywordoffset;
//  atext:= stringtopascalstring(msechar(high(keywords)+keywordoffset))+
//   '{'+atext+'}';
 end;
 
 function gettokendef(const aname: string; const acontext: string): boolean;
 var
  int1,int2,int3: integer;
  ar1: stringarty;
 begin
  result:= true;
  int2:= -1;
  for int1:= 0 to high(tokendefs) do begin
   if tokendefs[int1].name = aname then begin
    int2:= int1;
    break;
   end;
  end;
  if int2 < 0 then begin
   error('Tokendef not found.');
   result:= false;
   exit;
  end;
  if intokendef then begin
   with tokendefs[int2] do begin
    int3:= high(tokendefs[high(tokendefs)].tokens);
    setlength(tokendefs[high(tokendefs)].tokens,int3+length(tokens)+1);
    for int1:= 0 to high(tokens) do begin
     inc(int3);
     tokendefs[high(tokendefs)].tokens[int3]:= tokens[int1];
    end;
   end;
  end
  else begin
   with tokendefs[int2] do begin
    for int1:= 0 to high(tokens) do begin
     additem(branches[high(branches)].tokens,tokens[int1]);
//     setlength(ar1,2);
//     ar1[1]:= acontext;
//     ar1[0]:= tokens[int1];
//     additem(branches,ar1,branchcount);
    end;
   end;
  end;
 end;

 procedure handlecontext;
 begin
//  setlength(branches,branchcount);
  setlength(contexts,high(contexts)+2);
  with contexts[high(contexts)] do begin
   cont:= contextline;
   bran:= branches;
  end;
 end;

const
 branchformat = 'Format of branch is'+lineend+
'"''string''[.],{''string''[.],}context[-][[^][*] | [*][^]][,<pushed context>]"';
 defaultflags = ' e:false; p:false; s: false; sb:false; sa: false';
var
 ar1: stringarty;
// mstr1: msestring;
 str2,str3,str4,str5: string;
 int1,int2,int3: integer;
 po1,po2,po3: pchar;
 setbefore,setafter: boolean;
// identchars: array[char] of boolean;
 keywordsstart: integer;
 ar2: stringarty;
 macroname,macrotext: string;
 bo1: boolean;
 macrolist1: tmacrolist = nil;
 expandedtext: stringarty;
 lnr: integer;
 mstr1: msestring;
 branflags1: branchflagsty;
 chars1: charsetty;
 
begin
 application.terminated:= true;
 try
  grammarstream:= ttextstream.create(grammar,fm_read);
  macrolist1:= tmacrolist.create([mao_curlybraceonly]);
  line:= 0;
  context:= '';
  intokendef:= false;
  tokendefs:= nil;
  repeat
   grammarstream.readln(str1);
   inc(line);
   if (str1 <> '') then begin
    if str1[1] = '{' then begin //macrodef
     int1:= findchar(str1,'}');
     if int1 = 0 then begin
      error('Invalid macrodef');
      exit;
     end;
     macroname:= copy(str1,2,int1-2);
     int2:= findchar(str1,'"');
     if (int2 > 0) and (int2 < int1) then begin
      error('Ivalid macro name.');
      exit;
     end;
     if int2 = 0 then begin
      if grammarstream.eof then begin
       str2:= '';
      end
      else begin
       grammarstream.readln(str2);
       inc(line);
       int2:= findchar(str2,'"');
       if int2 = 0 then begin
        error('Invalid macrodef');
        exit;
       end;
      end;
     end
     else begin
      str2:= str1;
     end;
     str2:= copy(str2,int2+1,bigint);
     macrotext:= '';
     bo1:= false;
     while true do begin
      int1:= 0;
      while true do begin
       int1:= findchar(str2,int1+1,'"');
       if int1 > 0 then begin
        if str2[int1+1] = '"' then begin
         move(str2[int1+1],str2[int1],length(str2)-int1);
         setlength(str2,length(str2)-1);
        end
        else begin
         setlength(str2,int1-1);
         bo1:= true;
         break;
        end;
       end
       else begin
        break;
       end;
      end;
      macrotext:= macrotext+str2;
      if bo1 or grammarstream.eof then begin
       break;
      end;
      macrotext:= macrotext+lineend;
      grammarstream.readln(str2);
     end;
     macrolist1.add([utf8tostring(macroname)],[utf8tostring(macrotext)]);
    end
    else begin
     mstr1:= utf8tostring(str1);
     macrolist1.expandmacros(mstr1);
     expandedtext:= breaklines(stringtoutf8(mstr1));
     for lnr:= 0 to high(expandedtext) do begin
      str1:= expandedtext[lnr];
     
      if str1[1] = '@' then begin
       setlength(tokendefs,high(tokendefs)+2);
       with tokendefs[high(tokendefs)] do begin
        name:= trim(copy(str1,2,bigint));
       end;
       intokendef:= true;
      end
      else begin
       if (str1[1] <> '#') then begin
        if str1[1] <> ' ' then begin
         intokendef:= false;
        end;
        if intokendef then begin
         po1:= @str1[2];
         with tokendefs[high(tokendefs)] do begin
          while true do begin
           po3:= po1;
           if po1^= '@' then begin
            inc(po3);
            while not (po1^ in [',',#0]) do begin
             inc(po1)
            end;
            if not gettokendef(psubstr(po3,po1),'') then begin
             exit;
            end;
           end
           else begin
            getpascalstring(po1);
            if po1 = po3 then begin
             error('Invalid string');
             exit;
            end;
            setlength(tokens,high(tokens)+2);
            setstring(tokens[high(tokens)],po3,po1-po3);
           end;
           if po1^ = #0 then begin
            break;
           end;
           if po1^ <> ',' then begin
            error('Format of tokendef is "''string''{,''string''}"');
            exit;
           end;
           inc(po1);
          end;
         end;
        end
        else begin
         if firstrow then begin
          usesdef:= str1;
          firstrow:= false;
         end
         else begin
          if str1[1] <> ' ' then begin
           if context <> '' then begin
            handlecontext;
           end;
           context:= str1;
           contextline:= splitstring(context,',',true);
           if length(contextline) <> 3 then begin
            error('Format of contextline is "context,next[-],handler[^|!][>]"');
            exit;
           end;
           branches:= nil;
          end
          else begin
           int1:= findlastchar(str1,',');
           if int1 = 0 then begin
            error(branchformat);
            exit;
           end;
           setlength(branches,high(branches)+2);
           str2:= trim(copy(str1,int1+1,bigint));
           branches[high(branches)].dest:= str2;
           po1:= pchar(str1)+1;
           po2:= po1+int1-3;
           while po2 > po1 do begin
            if po2^ = ',' then begin
             with branches[high(branches)] do begin
              push:= dest;
              setstring(dest,po2+1,int1-(po2-po1)-3);
              dest:= trim(dest);
              int1:= (po2-po1)+2;
             end;
             break;
            end;
            if po2^ in ['''','@'] then begin
             break;
            end;
            dec(po2);
           end;
           
           po2:= po1+int1-2;
           while true do begin
            po3:= po1;
            if po1^ = '@' then begin
             inc(po3);
             while po1^ <> ',' do begin
              inc(po1);
             end;
             if not gettokendef(psubstr(po3,po1),str2) then begin
              exit;
             end;
            end
            else begin
             getpascalstring(po1);
             if po1 = po3 then begin
              error('Invalid string');
              exit;
             end;
             if po1^ = '.' then begin
              inc(po1);
             end;
             setstring(str3,po3,po1-po3);
             additem(branches[high(branches)].tokens,str3);
            end;
            if po1 = po2 then begin
             break;
            end;
            if po1^ <> ',' then begin
             error(branchformat);
             exit;
            end;
            inc(po1);
           end;
           with branches[high(branches)] do begin
            for int1:= 0 to high(tokens) do begin
             if (tokens[int1] = '''''') then begin
              if (length(tokens) > 1) then begin
               error(branchformat);
               exit;
              end;
              emptytoken:= true;
              tokens[int1]:= '';
             end
             else begin
              if tokens[int1][length(tokens[int1])] = '.' then begin
               if keyword > 0 then begin
                error(branchformat);
                exit;
               end;
               setlength(tokens[int1],length(tokens[int1])-1);
               if not getkeyword(tokens[int1],keyword) then begin
                exit;
               end;
              end
              else begin
               po1:= pchar(tokens[int1]);
               tokens[int1]:= getpascalstring(po1);
               if length(tokens[int1]) > 1 then begin
                if high(tokens) > 0 then begin
                 error(branchformat);
                 exit;
                end;
               end;
               if length(tokens[int1]) > branchkeymaxcount then begin
                error(branchformat);
                exit;
               end;
              end;
             end;
            end;
           end;
          end;
         end;
        end;
       end;
      end;
     end;
    end;
   end;
  until grammarstream.eof;
  if context = '' then begin
   error('Context definition expected');
   exit;
  end;
  handlecontext;
  passtream:= ttextstream.create(outfile,fm_create);
 str1:= 
'{ MSEide Copyright (c) 2013 by Martin Schreiber'+lineend+
'   '+lineend+
'    This program is free software; you can redistribute it and/or modify'+lineend+
'    it under the terms of the GNU General Public License as published by'+lineend+
'    the Free Software Foundation; either version 2 of the License, or'+lineend+
'    (at your option) any later version.'+lineend+
''+lineend+
'    This program is distributed in the hope that it will be useful,'+lineend+
'    but WITHOUT ANY WARRANTY; without even the implied warranty of'+lineend+
'    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the'+lineend+
'    GNU General Public License for more details.'+lineend+
''+lineend+
'    You should have received a copy of the GNU General Public License'+lineend+
'    along with this program; if not, write to the Free Software'+lineend+
'    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.'+lineend+
'}'+lineend+
'unit '+filenamebase(outfile)+';'+lineend+
'{$ifdef FPC}{$mode objfpc}{$h+}{$endif}'+lineend+
'interface'+lineend+
'uses'+lineend+
' mseparserglob;'+lineend+
' '+lineend+
'function startcontext: pcontextty;'+lineend+
''+lineend;
//  str1:= str1+
//'const'+lineend;
  keywordsstart:= length(str1);
 str1:= str1+
'var'+lineend;
  for int1:= 0 to high(contexts) do begin
   str2:= '';
   with contexts[int1] do begin
    if (cont[2] <> '') and (cont[2][length(cont[2])] = '>') then begin
     setlength(cont[2],length(cont[2])-1);
     str2:= str2+'continue: true; ';
    end
    else begin
     str2:= str2+'continue: false; ';
    end;
    if (cont[2] <> '') and (cont[2][length(cont[2])] = '*') then begin
     setlength(cont[2],length(cont[2])-1);
     str2:= str2+'cut: true; ';
    end
    else begin
     str2:= str2+'cut: false; ';
    end;
    if (cont[2] <> '') and (cont[2][length(cont[2])] = '+') then begin
     setlength(cont[2],length(cont[2])-1);
     str2:= str2+'restoresource: true; ';
    end
    else begin
     str2:= str2+'restoresource: false; ';
    end;
    if (cont[2] <> '') and (cont[2][length(cont[2])] = '^') then begin
     setlength(cont[2],length(cont[2])-1);
     str2:= str2+'pop: true; popexe: false; ';
    end
    else begin
     if (cont[2] <> '') and (cont[2][length(cont[2])] = '!') then begin
      setlength(cont[2],length(cont[2])-1);
      str2:= str2+'pop: true; popexe: true; ';
     end
     else begin
      str2:= str2+'pop: false; popexe: false; ';
     end;
    end;
    if (cont[1] <> '') and (cont[1][length(cont[1])] = '-') then begin
     setlength(cont[1],length(cont[1])-1);
     str2:= str2+'nexteat: true; ';
    end
    else begin
     str2:= str2+'nexteat: false; ';
    end;
    str1:= str1+
' '+cont[0]+'co: contextty = (branch: nil; handle: nil; '+lineend+
'               '+str2+'next: nil;'+lineend+
'               caption: '''+cont[0]+''');'+lineend;
   end;
  end;
  str1:= str1+
lineend+
'implementation'+lineend+
''+lineend+
'uses'+lineend+
' '+usesdef+';'+lineend+
' '+lineend+
'const'+lineend;
  for int1:= 0 to high(contexts) do begin
   with contexts[int1] do begin
    if bran <> nil then begin
     sortarray(bran,sizeof(bran[0]),@comparebranch);
     str1:= str1+
' b'+cont[0]+': array[0..'+inttostr(high(bran)+1)+'] of branchty = ('+lineend;
     for int2:= 0 to high(bran) do begin
      with bran[int2] do begin
       branflags1:= [bf_nt];
       if emptytoken then begin
        include(branflags1,bf_emptytoken);
       end;
       if keyword <> 0 then begin
        include(branflags1,bf_keyword);
       end;
       if checklastchar(dest,'!') then begin
        include(branflags1,bf_setpc);
       end;
       if checklastchar(dest,'*') then begin
        include(branflags1,bf_push);
       end;
       if checklastchar(dest,'^') then begin
        if bf_push in branflags1 then begin
         include(branflags1,bf_setparentbeforepush);
        end
        else begin
         include(branflags1,bf_setparentafterpush);
        end;
       end;
       if checklastchar(dest,'*') then begin
        include(branflags1,bf_push);
       end;
       if checklastchar(dest,'-') then begin
        include(branflags1,bf_eat);
       end;
       str1:= str1+
'   (flags: '+settostring(ptypeinfo(typeinfo(branflags1)),
                                 integer(branflags1),true)+'; dest: ';
       if dest = '' then begin
        str1:= str1+'nil';
       end
       else begin
        str1:= str1+'@'+dest+'co';
       end;
       str1:= str1+'; push: ';
       if push = '' then begin
        str1:= str1+'nil';
       end
       else begin
        str1:= str1+'@'+push+'co';
       end;
       str1:= str1+'; ';
       if keyword <> 0 then begin
        include(branflags1,bf_keyword);
        str1:= str1+lineend+
'     keyword: '+inttostr(keyword)+'{'+tokens[0]+'}),'+lineend;
       end
       else begin
        if (tokens <> nil) and (length(tokens[0]) > 1) then begin
         str1:= str1+'keys: ('+lineend;
         for int3:= 1 to length(tokens[0])-1 do begin
          str1:= str1+
'    (kind: bkk_charcontinued; chars: '+
            charsettostring([tokens[0][int3]])+')';
          if int3 <> branchkeymaxcount then begin
           str1:= str1 + ',';
          end;
          str1:= str1+lineend;
         end;
         str1:= str1+
'    (kind: bkk_char; chars: '+
            charsettostring([tokens[0][length(tokens[0])]])+'),'+lineend;
         for int3:= length(tokens[0])+1 to branchkeymaxcount do begin
          str1:= str1 +
'    (kind: bkk_none; chars: [])';
          if int3 <> branchkeymaxcount then begin
           str1:= str1+ ',';
          end;
          str1:= str1+lineend;
         end;
         str1:= str1+
'    )),'+lineend;
        end
        else begin
         chars1:= [];
         for int3:= 0 to high(tokens) do begin
          if tokens[int3] <> '' then begin
           include(chars1,tokens[int3][1]);
          end
          else begin
           chars1:= [#1..#255];
           break;
          end;
         end;
         str1:= str1+'keys: ('+lineend+
'    (kind: bkk_char; chars: '+charsettostring(chars1)+'),'+lineend+
'    (kind: bkk_none; chars: []),'+lineend+
'    (kind: bkk_none; chars: []),'+lineend+
'    (kind: bkk_none; chars: [])'+lineend+
'    )),'+lineend;
        end;
       end;
      end;
     end;
     str1:= str1+
'   (flags: []; dest: nil; push: nil; keyword: 0)'+lineend+
'   );'+lineend;
    end;
   end;
  end;
  str5:= 
'type'+lineend+
' keywordty = (kw_none,'+lineend;
  str2:=
'  ';
  for int2:= 0 to high(keywords) do begin
   str3:= 'kw_'+keywords[int2]+',';
   if length(str2) + length(str3) > 80 then begin
    str5:= str5+str2+lineend;
    str2:= '  ';
   end;
   str2:= str2+str3;
  end;
  setlength(str2,length(str2)-1); //remove last comma
  str5:= str5+str2+lineend+
' );'+lineend+lineend;
  str5:= str5+
'const'+lineend+
' keywords: array[keywordty] of string = ('''','+lineend;
  str2:= 
'  ';
  for int2:= 0 to high(keywords) do begin
   str3:= stringtopascalstring(keywords[int2])+',';
   if length(str2)+length(str3) > 80 then begin
    str5:= str5+str2+lineend;
    str2:= 
'  ';
   end;
   str2:= str2+str3;
  end;
  setlength(str2,length(str2)-1);
  str5:= str5 + str2+');'+lineend+lineend;
  str1:= copy(str1,1,keywordsstart)+str5+copy(str1,keywordsstart+1,bigint);

  str1:= str1+
'procedure init;'+lineend+
'begin'+lineend;
  for int1:= 0 to high(contexts) do begin
   with contexts[int1] do begin
    str1:= str1+
' '+cont[0]+'co.branch:= ';
    if bran = nil then begin
     str1:= str1+'nil;'+lineend;
    end
    else begin
     str1:= str1+'@b'+cont[0]+';'+lineend;
    end;
    if cont[1] <> '' then begin
     str1:= str1+
' '+cont[0]+'co.next:= @'+cont[1]+'co;'+lineend;
    end;
    if cont[2] <> '' then begin
     str1:= str1+
' '+cont[0]+'co.handle:= @'+cont[2]+';'+lineend;
    end;
   end;
  end;
  str1:= str1 +
'end;'+lineend;
  str1:= str1+lineend+
'function startcontext: pcontextty;'+lineend+
'begin'+lineend+
' result:= @'+contexts[0].cont[0]+'co;'+lineend+
'end;'+lineend+
''+lineend+
'initialization'+lineend+
' init;'+lineend+
'end.'+lineend+
lineend;

  passtream.write(str1);
 finally
  grammarstream.free;
  passtream.free;
  macrolist1.free;
 end;
end;

procedure tmainmo.eventloopexe(const sender: TObject);
begin
 with sysenv do begin
  creategrammar(value[ord(pa_grammarfile)],value[ord(pa_pasfile)]);
 end;
end;

procedure tmainmo.afterinitexe(sender: tsysenvmanager);
begin
{
 with sender do begin
  if not defined[ord(pa_pasfile)] then begin
   value[ord(pa_pasfile)]:= replacefileext(value[ord(pa_grammarfile)],'pas');
  end;
 end;
}
end;

end.
