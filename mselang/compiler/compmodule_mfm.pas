unit compmodule_mfm;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface

implementation
uses
 mseclasses,compmodule;

const
 objdata: record size: integer; data: array[0..872] of byte end =
      (size: 873; data: (
  84,80,70,48,7,116,99,111,109,112,109,111,6,99,111,109,112,109,111,9,
  98,111,117,110,100,115,95,99,120,3,75,1,9,98,111,117,110,100,115,95,
  99,121,3,255,0,8,111,110,99,114,101,97,116,101,7,9,99,114,101,97,
  116,101,101,120,101,16,111,110,101,118,101,110,116,108,111,111,112,115,116,97,
  114,116,7,12,101,118,101,110,116,108,111,111,112,101,120,101,12,111,110,116,
  101,114,109,105,110,97,116,101,100,7,13,116,101,114,109,105,110,97,116,101,
  100,101,120,101,4,108,101,102,116,3,153,0,3,116,111,112,3,113,1,15,
  109,111,100,117,108,101,99,108,97,115,115,110,97,109,101,6,14,116,109,115,
  101,100,97,116,97,109,111,100,117,108,101,0,14,116,115,121,115,101,110,118,
  109,97,110,97,103,101,114,6,115,121,115,101,110,118,7,111,112,116,105,111,
  110,115,11,27,115,101,111,95,97,112,112,116,101,114,109,105,110,97,116,101,
  111,110,101,120,99,101,112,116,105,111,110,20,115,101,111,95,116,101,114,109,
  105,110,97,116,101,111,110,101,114,114,111,114,12,115,101,111,95,116,111,111,
  117,116,112,117,116,11,115,101,111,95,116,111,101,114,114,111,114,0,11,111,
  110,118,97,108,117,101,114,101,97,100,7,11,118,97,108,117,101,114,101,97,
  100,101,118,4,108,101,102,116,2,16,3,116,111,112,2,16,4,100,101,102,
  115,1,1,7,6,97,107,95,97,114,103,6,0,1,0,11,0,6,0,6,
  0,6,0,6,0,6,0,0,1,7,6,97,107,95,112,97,114,6,5,45,
  108,108,118,109,1,0,11,0,6,0,6,0,6,0,6,0,6,0,0,1,
  7,6,97,107,95,112,97,114,6,15,45,110,111,99,111,109,112,105,108,101,
  114,117,110,105,116,1,0,11,0,6,0,6,0,6,0,6,0,6,0,0,
  1,7,6,97,107,95,112,97,114,6,11,45,110,111,114,116,108,117,110,105,
  116,115,1,0,11,0,6,0,6,0,6,0,6,0,6,0,0,1,7,6,
  97,107,95,112,97,114,6,1,103,1,0,11,0,6,0,6,0,6,0,6,
  0,6,0,0,1,7,6,97,107,95,112,97,114,6,1,108,1,0,11,0,
  6,0,6,0,6,0,6,0,6,0,0,1,7,9,97,107,95,112,97,114,
  97,114,103,6,2,70,117,1,0,11,0,6,0,6,0,6,0,6,0,6,
  0,0,1,7,9,97,107,95,112,97,114,97,114,103,6,1,100,1,0,11,
  0,6,0,6,0,6,0,6,0,6,0,0,1,7,9,97,107,95,112,97,
  114,97,114,103,6,1,117,1,0,11,0,6,0,6,0,6,0,6,0,6,
  0,0,1,7,6,97,107,95,112,97,114,6,1,66,1,0,11,0,6,0,
  6,0,6,0,6,0,6,0,0,1,7,6,97,107,95,112,97,114,6,2,
  88,111,1,0,11,0,6,0,6,0,6,0,6,0,6,0,0,1,7,6,
  97,107,95,112,97,114,6,2,88,98,1,0,11,0,6,0,6,0,6,0,
  6,0,6,0,0,1,7,6,97,107,95,112,97,114,6,2,86,99,1,0,
  11,0,6,0,6,0,6,0,6,0,6,0,0,1,7,9,97,107,95,112,
  97,114,97,114,103,6,1,79,1,0,11,0,6,0,6,0,6,0,6,0,
  6,0,0,1,7,6,97,107,95,112,97,114,6,2,88,116,1,0,11,0,
  6,0,6,0,6,0,6,0,6,0,0,1,7,9,97,107,95,112,97,114,
  97,114,103,6,3,45,97,115,1,0,11,0,6,0,6,0,6,0,6,0,
  6,0,0,1,7,9,97,107,95,112,97,114,97,114,103,6,4,45,103,99,
  99,1,0,11,0,6,0,6,0,6,0,6,0,6,0,0,1,7,9,97,
  107,95,112,97,114,97,114,103,6,4,45,108,108,99,1,0,11,0,6,0,
  6,0,6,0,6,0,6,0,0,0,0,0,0)
 );

initialization
 registerobjectdata(@objdata,tcompmo,'');
end.
