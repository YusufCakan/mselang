unit mainmodule_mfm;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface

implementation
uses
 mseclasses,mainmodule;

const
 objdata: record size: integer; data: array[0..197] of byte end =
      (size: 198; data: (
  84,80,70,48,7,116,109,97,105,110,109,111,6,109,97,105,110,109,111,9,
  98,111,117,110,100,115,95,99,120,3,145,1,9,98,111,117,110,100,115,95,
  99,121,3,72,1,4,108,101,102,116,2,47,3,116,111,112,3,216,0,15,
  109,111,100,117,108,101,99,108,97,115,115,110,97,109,101,6,14,116,109,115,
  101,100,97,116,97,109,111,100,117,108,101,0,14,116,115,121,115,101,110,118,
  109,97,110,97,103,101,114,6,115,121,115,101,110,118,4,100,101,102,115,6,
  39,97,107,95,110,111,110,101,10,97,107,95,110,111,110,101,10,97,107,95,
  110,111,110,101,10,97,107,95,110,111,110,101,10,97,107,95,110,111,110,101,
  6,111,110,105,110,105,116,7,13,105,110,105,116,115,121,115,101,110,118,101,
  120,101,4,108,101,102,116,2,16,3,116,111,112,2,8,0,0,0)
 );

initialization
 registerobjectdata(@objdata,tmainmo,'');
end.
