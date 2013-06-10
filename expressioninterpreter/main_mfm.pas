unit main_mfm;
{$ifdef FPC}{$mode objfpc}{$h+}{$endif}

interface

implementation
uses
 mseclasses,main;

const
 objdata: record size: integer; data: array[0..5720] of byte end =
      (size: 5721; data: (
  84,80,70,48,7,116,109,97,105,110,102,111,6,109,97,105,110,102,111,8,
  98,111,117,110,100,115,95,120,3,35,1,8,98,111,117,110,100,115,95,121,
  3,247,0,9,98,111,117,110,100,115,95,99,120,3,115,1,9,98,111,117,
  110,100,115,95,99,121,3,194,1,7,97,110,99,104,111,114,115,11,6,97,
  110,95,116,111,112,8,97,110,95,114,105,103,104,116,0,16,99,111,110,116,
  97,105,110,101,114,46,98,111,117,110,100,115,1,2,0,2,0,3,115,1,
  3,194,1,0,8,115,116,97,116,102,105,108,101,7,5,115,116,97,116,102,
  15,109,111,100,117,108,101,99,108,97,115,115,110,97,109,101,6,9,116,109,
  97,105,110,102,111,114,109,0,7,116,98,117,116,116,111,110,8,116,98,117,
  116,116,111,110,49,8,98,111,117,110,100,115,95,120,3,8,1,8,98,111,
  117,110,100,115,95,121,2,8,9,98,111,117,110,100,115,95,99,120,2,50,
  9,98,111,117,110,100,115,95,99,121,2,20,7,97,110,99,104,111,114,115,
  11,6,97,110,95,116,111,112,8,97,110,95,114,105,103,104,116,0,5,115,
  116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,112,116,105,111,
  110,17,97,115,95,108,111,99,97,108,111,110,101,120,101,99,117,116,101,0,
  7,99,97,112,116,105,111,110,6,5,112,97,114,115,101,9,111,110,101,120,
  101,99,117,116,101,7,8,112,97,114,115,101,101,120,101,0,0,11,116,115,
  116,114,105,110,103,103,114,105,100,4,103,114,105,100,8,116,97,98,111,114,
  100,101,114,2,1,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,
  110,100,115,95,121,2,119,9,98,111,117,110,100,115,95,99,120,3,82,1,
  9,98,111,117,110,100,115,95,99,121,2,115,7,97,110,99,104,111,114,115,
  11,7,97,110,95,108,101,102,116,6,97,110,95,116,111,112,8,97,110,95,
  114,105,103,104,116,9,97,110,95,98,111,116,116,111,109,0,9,102,111,110,
  116,46,110,97,109,101,6,9,115,116,102,95,102,105,120,101,100,11,102,111,
  110,116,46,120,115,99,97,108,101,2,1,10,102,111,110,116,46,100,117,109,
  109,121,2,0,14,100,97,116,97,99,111,108,115,46,99,111,117,110,116,2,
  1,14,100,97,116,97,99,111,108,115,46,105,116,101,109,115,14,1,5,119,
  105,100,116,104,3,26,1,7,111,112,116,105,111,110,115,11,7,99,111,95,
  102,105,108,108,12,99,111,95,115,97,118,101,118,97,108,117,101,12,99,111,
  95,115,97,118,101,115,116,97,116,101,17,99,111,95,109,111,117,115,101,115,
  99,114,111,108,108,114,111,119,0,10,118,97,108,117,101,102,97,108,115,101,
  6,1,48,9,118,97,108,117,101,116,114,117,101,6,1,49,0,0,13,102,
  105,120,99,111,108,115,46,99,111,117,110,116,2,1,13,102,105,120,99,111,
  108,115,46,105,116,101,109,115,14,1,8,110,117,109,115,116,97,114,116,2,
  255,7,110,117,109,115,116,101,112,2,1,0,0,13,100,97,116,97,114,111,
  119,104,101,105,103,104,116,2,16,13,114,101,102,102,111,110,116,104,101,105,
  103,104,116,2,14,0,0,9,116,114,101,97,108,100,105,115,112,2,100,105,
  11,102,114,97,109,101,46,100,117,109,109,121,2,0,8,116,97,98,111,114,
  100,101,114,2,2,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,
  110,100,115,95,121,2,8,9,98,111,117,110,100,115,95,99,120,3,180,0,
  9,98,111,117,110,100,115,95,99,121,2,18,10,118,97,108,117,101,114,97,
  110,103,101,2,1,10,118,97,108,117,101,115,116,97,114,116,2,0,5,118,
  97,108,117,101,5,0,0,0,0,0,0,0,128,255,255,13,114,101,102,102,
  111,110,116,104,101,105,103,104,116,2,14,0,0,11,116,115,116,114,105,110,
  103,101,100,105,116,10,103,101,116,105,100,101,110,116,101,100,13,102,114,97,
  109,101,46,99,97,112,116,105,111,110,6,8,103,101,116,105,100,101,110,116,
  11,102,114,97,109,101,46,100,117,109,109,121,2,0,16,102,114,97,109,101,
  46,111,117,116,101,114,102,114,97,109,101,1,2,0,2,17,2,0,2,0,
  0,8,116,97,98,111,114,100,101,114,2,3,8,98,111,117,110,100,115,95,
  120,2,16,8,98,111,117,110,100,115,95,121,3,241,0,9,98,111,117,110,
  100,115,95,99,120,3,212,0,9,98,111,117,110,100,115,95,99,121,2,37,
  7,97,110,99,104,111,114,115,11,7,97,110,95,108,101,102,116,9,97,110,
  95,98,111,116,116,111,109,0,11,111,112,116,105,111,110,115,101,100,105,116,
  11,12,111,101,95,117,110,100,111,111,110,101,115,99,13,111,101,95,99,108,
  111,115,101,113,117,101,114,121,16,111,101,95,99,104,101,99,107,109,114,99,
  97,110,99,101,108,14,111,101,95,115,104,105,102,116,114,101,116,117,114,110,
  24,111,101,95,102,111,114,99,101,114,101,116,117,114,110,99,104,101,99,107,
  118,97,108,117,101,12,111,101,95,101,97,116,114,101,116,117,114,110,20,111,
  101,95,114,101,115,101,116,115,101,108,101,99,116,111,110,101,120,105,116,15,
  111,101,95,101,120,105,116,111,110,99,117,114,115,111,114,13,111,101,95,101,
  110,100,111,110,101,110,116,101,114,13,111,101,95,97,117,116,111,115,101,108,
  101,99,116,25,111,101,95,97,117,116,111,115,101,108,101,99,116,111,110,102,
  105,114,115,116,99,108,105,99,107,22,111,101,95,102,111,99,117,115,114,101,
  99,116,111,110,114,101,97,100,111,110,108,121,12,111,101,95,115,97,118,101,
  118,97,108,117,101,12,111,101,95,115,97,118,101,115,116,97,116,101,25,111,
  101,95,99,104,101,99,107,118,97,108,117,101,112,97,115,116,115,116,97,116,
  114,101,97,100,0,10,111,110,115,101,116,118,97,108,117,101,7,10,102,105,
  110,100,115,101,116,101,120,101,13,114,101,102,102,111,110,116,104,101,105,103,
  104,116,2,14,0,0,12,116,105,110,116,101,103,101,114,100,105,115,112,5,
  105,110,116,100,105,11,102,114,97,109,101,46,100,117,109,109,121,2,0,8,
  116,97,98,111,114,100,101,114,2,4,8,98,111,117,110,100,115,95,120,3,
  240,0,8,98,111,117,110,100,115,95,121,3,2,1,9,98,111,117,110,100,
  115,95,99,121,2,18,7,97,110,99,104,111,114,115,11,7,97,110,95,108,
  101,102,116,9,97,110,95,98,111,116,116,111,109,0,13,114,101,102,102,111,
  110,116,104,101,105,103,104,116,2,14,0,0,11,116,115,116,114,105,110,103,
  101,100,105,116,6,112,117,115,104,101,100,13,102,114,97,109,101,46,99,97,
  112,116,105,111,110,6,11,112,117,115,104,101,108,101,109,101,110,116,11,102,
  114,97,109,101,46,100,117,109,109,121,2,0,16,102,114,97,109,101,46,111,
  117,116,101,114,102,114,97,109,101,1,2,0,2,17,2,0,2,0,0,8,
  116,97,98,111,114,100,101,114,2,5,8,98,111,117,110,100,115,95,120,2,
  16,8,98,111,117,110,100,115,95,121,3,25,1,9,98,111,117,110,100,115,
  95,99,120,3,212,0,9,98,111,117,110,100,115,95,99,121,2,37,7,97,
  110,99,104,111,114,115,11,7,97,110,95,108,101,102,116,9,97,110,95,98,
  111,116,116,111,109,0,11,111,112,116,105,111,110,115,101,100,105,116,11,12,
  111,101,95,117,110,100,111,111,110,101,115,99,13,111,101,95,99,108,111,115,
  101,113,117,101,114,121,16,111,101,95,99,104,101,99,107,109,114,99,97,110,
  99,101,108,14,111,101,95,115,104,105,102,116,114,101,116,117,114,110,24,111,
  101,95,102,111,114,99,101,114,101,116,117,114,110,99,104,101,99,107,118,97,
  108,117,101,12,111,101,95,101,97,116,114,101,116,117,114,110,20,111,101,95,
  114,101,115,101,116,115,101,108,101,99,116,111,110,101,120,105,116,15,111,101,
  95,101,120,105,116,111,110,99,117,114,115,111,114,13,111,101,95,101,110,100,
  111,110,101,110,116,101,114,13,111,101,95,97,117,116,111,115,101,108,101,99,
  116,25,111,101,95,97,117,116,111,115,101,108,101,99,116,111,110,102,105,114,
  115,116,99,108,105,99,107,22,111,101,95,102,111,99,117,115,114,101,99,116,
  111,110,114,101,97,100,111,110,108,121,12,111,101,95,115,97,118,101,118,97,
  108,117,101,12,111,101,95,115,97,118,101,115,116,97,116,101,25,111,101,95,
  99,104,101,99,107,118,97,108,117,101,112,97,115,116,115,116,97,116,114,101,
  97,100,0,10,111,110,115,101,116,118,97,108,117,101,7,14,112,117,115,104,
  101,108,101,109,101,110,116,101,120,101,13,114,101,102,102,111,110,116,104,101,
  105,103,104,116,2,14,0,0,11,116,115,116,114,105,110,103,101,100,105,116,
  5,97,100,100,101,100,13,102,114,97,109,101,46,99,97,112,116,105,111,110,
  6,10,97,100,100,101,108,101,109,101,110,116,11,102,114,97,109,101,46,100,
  117,109,109,121,2,0,16,102,114,97,109,101,46,111,117,116,101,114,102,114,
  97,109,101,1,2,0,2,17,2,0,2,0,0,8,116,97,98,111,114,100,
  101,114,2,6,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,110,
  100,115,95,121,3,65,1,9,98,111,117,110,100,115,95,99,120,3,212,0,
  9,98,111,117,110,100,115,95,99,121,2,37,7,97,110,99,104,111,114,115,
  11,7,97,110,95,108,101,102,116,9,97,110,95,98,111,116,116,111,109,0,
  11,111,112,116,105,111,110,115,101,100,105,116,11,12,111,101,95,117,110,100,
  111,111,110,101,115,99,13,111,101,95,99,108,111,115,101,113,117,101,114,121,
  16,111,101,95,99,104,101,99,107,109,114,99,97,110,99,101,108,14,111,101,
  95,115,104,105,102,116,114,101,116,117,114,110,24,111,101,95,102,111,114,99,
  101,114,101,116,117,114,110,99,104,101,99,107,118,97,108,117,101,12,111,101,
  95,101,97,116,114,101,116,117,114,110,20,111,101,95,114,101,115,101,116,115,
  101,108,101,99,116,111,110,101,120,105,116,15,111,101,95,101,120,105,116,111,
  110,99,117,114,115,111,114,13,111,101,95,101,110,100,111,110,101,110,116,101,
  114,13,111,101,95,97,117,116,111,115,101,108,101,99,116,25,111,101,95,97,
  117,116,111,115,101,108,101,99,116,111,110,102,105,114,115,116,99,108,105,99,
  107,22,111,101,95,102,111,99,117,115,114,101,99,116,111,110,114,101,97,100,
  111,110,108,121,12,111,101,95,115,97,118,101,118,97,108,117,101,12,111,101,
  95,115,97,118,101,115,116,97,116,101,25,111,101,95,99,104,101,99,107,118,
  97,108,117,101,112,97,115,116,115,116,97,116,114,101,97,100,0,10,111,110,
  115,101,116,118,97,108,117,101,7,13,97,100,100,101,108,101,109,101,110,116,
  101,120,101,13,114,101,102,102,111,110,116,104,101,105,103,104,116,2,14,0,
  0,12,116,98,111,111,108,101,97,110,100,105,115,112,4,97,100,100,105,11,
  102,114,97,109,101,46,100,117,109,109,121,2,0,8,116,97,98,111,114,100,
  101,114,2,7,8,98,111,117,110,100,115,95,120,3,248,0,8,98,111,117,
  110,100,115,95,121,3,82,1,9,98,111,117,110,100,115,95,99,120,2,28,
  9,98,111,117,110,100,115,95,99,121,2,18,7,97,110,99,104,111,114,115,
  11,7,97,110,95,108,101,102,116,9,97,110,95,98,111,116,116,111,109,0,
  9,116,101,120,116,102,108,97,103,115,11,12,116,102,95,121,99,101,110,116,
  101,114,101,100,0,10,116,101,120,116,95,102,97,108,115,101,6,1,70,9,
  116,101,120,116,95,116,114,117,101,6,1,84,13,114,101,102,102,111,110,116,
  104,101,105,103,104,116,2,14,0,0,7,116,98,117,116,116,111,110,8,116,
  98,117,116,116,111,110,50,8,116,97,98,111,114,100,101,114,2,8,8,98,
  111,117,110,100,115,95,120,3,240,0,8,98,111,117,110,100,115,95,121,3,
  40,1,9,98,111,117,110,100,115,95,99,120,2,50,9,98,111,117,110,100,
  115,95,99,121,2,20,7,97,110,99,104,111,114,115,11,7,97,110,95,108,
  101,102,116,9,97,110,95,98,111,116,116,111,109,0,5,115,116,97,116,101,
  11,15,97,115,95,108,111,99,97,108,99,97,112,116,105,111,110,17,97,115,
  95,108,111,99,97,108,111,110,101,120,101,99,117,116,101,0,7,99,97,112,
  116,105,111,110,6,5,99,108,101,97,114,9,111,110,101,120,101,99,117,116,
  101,7,8,99,108,101,97,114,101,120,101,0,0,7,116,98,117,116,116,111,
  110,8,116,98,117,116,116,111,110,51,8,116,97,98,111,114,100,101,114,2,
  9,8,98,111,117,110,100,115,95,120,3,40,1,8,98,111,117,110,100,115,
  95,121,3,40,1,9,98,111,117,110,100,115,95,99,120,2,50,9,98,111,
  117,110,100,115,95,99,121,2,20,7,97,110,99,104,111,114,115,11,7,97,
  110,95,108,101,102,116,9,97,110,95,98,111,116,116,111,109,0,5,115,116,
  97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,112,116,105,111,110,
  17,97,115,95,108,111,99,97,108,111,110,101,120,101,99,117,116,101,0,7,
  99,97,112,116,105,111,110,6,3,112,111,112,9,111,110,101,120,101,99,117,
  116,101,7,6,112,111,112,101,120,101,0,0,11,116,115,116,114,105,110,103,
  101,100,105,116,6,102,105,110,100,101,100,13,102,114,97,109,101,46,99,97,
  112,116,105,111,110,6,4,102,105,110,100,11,102,114,97,109,101,46,100,117,
  109,109,121,2,0,16,102,114,97,109,101,46,111,117,116,101,114,102,114,97,
  109,101,1,2,0,2,17,2,0,2,0,0,8,116,97,98,111,114,100,101,
  114,2,10,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,110,100,
  115,95,121,3,105,1,9,98,111,117,110,100,115,95,99,120,3,212,0,9,
  98,111,117,110,100,115,95,99,121,2,37,7,97,110,99,104,111,114,115,11,
  7,97,110,95,108,101,102,116,9,97,110,95,98,111,116,116,111,109,0,11,
  111,112,116,105,111,110,115,101,100,105,116,11,12,111,101,95,117,110,100,111,
  111,110,101,115,99,13,111,101,95,99,108,111,115,101,113,117,101,114,121,16,
  111,101,95,99,104,101,99,107,109,114,99,97,110,99,101,108,14,111,101,95,
  115,104,105,102,116,114,101,116,117,114,110,24,111,101,95,102,111,114,99,101,
  114,101,116,117,114,110,99,104,101,99,107,118,97,108,117,101,12,111,101,95,
  101,97,116,114,101,116,117,114,110,20,111,101,95,114,101,115,101,116,115,101,
  108,101,99,116,111,110,101,120,105,116,15,111,101,95,101,120,105,116,111,110,
  99,117,114,115,111,114,13,111,101,95,101,110,100,111,110,101,110,116,101,114,
  13,111,101,95,97,117,116,111,115,101,108,101,99,116,25,111,101,95,97,117,
  116,111,115,101,108,101,99,116,111,110,102,105,114,115,116,99,108,105,99,107,
  22,111,101,95,102,111,99,117,115,114,101,99,116,111,110,114,101,97,100,111,
  110,108,121,12,111,101,95,115,97,118,101,118,97,108,117,101,12,111,101,95,
  115,97,118,101,115,116,97,116,101,25,111,101,95,99,104,101,99,107,118,97,
  108,117,101,112,97,115,116,115,116,97,116,114,101,97,100,0,10,111,110,115,
  101,116,118,97,108,117,101,7,14,102,105,110,100,101,108,101,109,101,110,116,
  101,120,101,13,114,101,102,102,111,110,116,104,101,105,103,104,116,2,14,0,
  0,11,116,115,116,114,105,110,103,100,105,115,112,6,102,105,110,100,100,105,
  11,102,114,97,109,101,46,100,117,109,109,121,2,0,8,116,97,98,111,114,
  100,101,114,2,11,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,
  110,100,115,95,121,3,144,1,9,98,111,117,110,100,115,95,99,120,3,212,
  0,9,98,111,117,110,100,115,95,99,121,2,18,7,97,110,99,104,111,114,
  115,11,7,97,110,95,108,101,102,116,9,97,110,95,98,111,116,116,111,109,
  0,13,114,101,102,102,111,110,116,104,101,105,103,104,116,2,14,0,0,7,
  116,98,117,116,116,111,110,8,116,98,117,116,116,111,110,52,8,116,97,98,
  111,114,100,101,114,2,12,8,98,111,117,110,100,115,95,120,3,240,0,8,
  98,111,117,110,100,115,95,121,3,236,0,9,98,111,117,110,100,115,95,99,
  120,2,50,9,98,111,117,110,100,115,95,99,121,2,20,7,97,110,99,104,
  111,114,115,11,7,97,110,95,108,101,102,116,9,97,110,95,98,111,116,116,
  111,109,0,5,115,116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,
  97,112,116,105,111,110,17,97,115,95,108,111,99,97,108,111,110,101,120,101,
  99,117,116,101,0,7,99,97,112,116,105,111,110,6,5,115,101,116,112,97,
  9,111,110,101,120,101,99,117,116,101,7,8,115,101,116,112,97,101,120,101,
  0,0,12,116,98,111,111,108,101,97,110,101,100,105,116,13,116,98,111,111,
  108,101,97,110,101,100,105,116,49,20,102,114,97,109,101,46,102,114,97,109,
  101,102,97,99,101,95,108,105,115,116,7,10,116,102,97,99,101,108,105,115,
  116,49,22,102,114,97,109,101,46,102,114,97,109,101,102,97,99,101,95,111,
  102,102,115,101,116,2,255,28,102,114,97,109,101,46,102,114,97,109,101,102,
  97,99,101,95,111,102,102,115,101,116,97,99,116,105,118,101,2,1,33,102,
  114,97,109,101,46,102,114,97,109,101,102,97,99,101,95,111,102,102,115,101,
  116,97,99,116,105,118,101,109,111,117,115,101,2,1,35,102,114,97,109,101,
  46,102,114,97,109,101,102,97,99,101,95,111,102,102,115,101,116,97,99,116,
  105,118,101,99,108,105,99,107,101,100,2,1,17,102,114,97,109,101,46,108,
  111,99,97,108,112,114,111,112,115,49,11,18,102,114,108,49,95,102,114,97,
  109,101,102,97,99,101,108,105,115,116,20,102,114,108,49,95,102,114,97,109,
  101,102,97,99,101,111,102,102,115,101,116,21,102,114,108,49,95,102,114,97,
  109,101,102,97,99,101,111,102,102,115,101,116,49,28,102,114,108,49,95,102,
  114,97,109,101,102,97,99,101,111,102,102,115,101,116,100,105,115,97,98,108,
  101,100,25,102,114,108,49,95,102,114,97,109,101,102,97,99,101,111,102,102,
  115,101,116,109,111,117,115,101,27,102,114,108,49,95,102,114,97,109,101,102,
  97,99,101,111,102,102,115,101,116,99,108,105,99,107,101,100,26,102,114,108,
  49,95,102,114,97,109,101,102,97,99,101,111,102,102,115,101,116,97,99,116,
  105,118,101,31,102,114,108,49,95,102,114,97,109,101,102,97,99,101,111,102,
  102,115,101,116,97,99,116,105,118,101,109,111,117,115,101,33,102,114,108,49,
  95,102,114,97,109,101,102,97,99,101,111,102,102,115,101,116,97,99,116,105,
  118,101,99,108,105,99,107,101,100,0,11,102,114,97,109,101,46,100,117,109,
  109,121,2,0,8,116,97,98,111,114,100,101,114,2,13,8,98,111,117,110,
  100,115,95,120,3,240,0,8,98,111,117,110,100,115,95,121,3,120,1,0,
  0,9,116,115,112,108,105,116,116,101,114,10,116,115,112,108,105,116,116,101,
  114,49,5,99,111,108,111,114,4,3,0,0,144,8,116,97,98,111,114,100,
  101,114,2,14,8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,110,
  100,115,95,121,2,116,9,98,111,117,110,100,115,95,99,120,3,82,1,9,
  98,111,117,110,100,115,95,99,121,2,3,7,97,110,99,104,111,114,115,11,
  7,97,110,95,108,101,102,116,6,97,110,95,116,111,112,8,97,110,95,114,
  105,103,104,116,0,7,111,112,116,105,111,110,115,11,9,115,112,111,95,118,
  109,111,118,101,12,115,112,111,95,100,111,99,107,108,101,102,116,11,115,112,
  111,95,100,111,99,107,116,111,112,13,115,112,111,95,100,111,99,107,114,105,
  103,104,116,14,115,112,111,95,100,111,99,107,98,111,116,116,111,109,0,7,
  108,105,110,107,116,111,112,7,6,101,100,103,114,105,100,10,108,105,110,107,
  98,111,116,116,111,109,7,4,103,114,105,100,8,115,116,97,116,102,105,108,
  101,7,5,115,116,97,116,102,0,0,11,116,119,105,100,103,101,116,103,114,
  105,100,6,101,100,103,114,105,100,8,116,97,98,111,114,100,101,114,2,15,
  8,98,111,117,110,100,115,95,120,2,16,8,98,111,117,110,100,115,95,121,
  2,32,9,98,111,117,110,100,115,95,99,120,3,82,1,9,98,111,117,110,
  100,115,95,99,121,2,84,11,111,112,116,105,111,110,115,103,114,105,100,11,
  19,111,103,95,102,111,99,117,115,99,101,108,108,111,110,101,110,116,101,114,
  15,111,103,95,97,117,116,111,102,105,114,115,116,114,111,119,20,111,103,95,
  99,111,108,99,104,97,110,103,101,111,110,116,97,98,107,101,121,10,111,103,
  95,119,114,97,112,99,111,108,12,111,103,95,97,117,116,111,112,111,112,117,
  112,17,111,103,95,109,111,117,115,101,115,99,114,111,108,108,99,111,108,0,
  13,102,105,120,99,111,108,115,46,99,111,117,110,116,2,1,13,102,105,120,
  99,111,108,115,46,119,105,100,116,104,2,30,13,102,105,120,99,111,108,115,
  46,105,116,101,109,115,14,1,5,119,105,100,116,104,2,30,8,110,117,109,
  115,116,97,114,116,2,1,7,110,117,109,115,116,101,112,2,1,0,0,14,
  100,97,116,97,99,111,108,115,46,99,111,117,110,116,2,1,14,100,97,116,
  97,99,111,108,115,46,105,116,101,109,115,14,7,2,101,100,1,5,119,105,
  100,116,104,3,224,7,10,119,105,100,103,101,116,110,97,109,101,6,2,101,
  100,9,100,97,116,97,99,108,97,115,115,7,23,116,103,114,105,100,114,105,
  99,104,115,116,114,105,110,103,100,97,116,97,108,105,115,116,0,0,16,100,
  97,116,97,114,111,119,108,105,110,101,119,105,100,116,104,2,0,13,100,97,
  116,97,114,111,119,104,101,105,103,104,116,2,16,8,115,116,97,116,102,105,
  108,101,7,5,115,116,97,116,102,13,114,101,102,102,111,110,116,104,101,105,
  103,104,116,2,14,0,11,116,115,121,110,116,97,120,101,100,105,116,2,101,
  100,11,111,112,116,105,111,110,115,115,107,105,110,11,19,111,115,107,95,102,
  114,97,109,101,98,117,116,116,111,110,111,110,108,121,0,8,116,97,98,111,
  114,100,101,114,2,1,7,118,105,115,105,98,108,101,8,8,98,111,117,110,
  100,115,95,120,2,0,8,98,111,117,110,100,115,95,121,2,0,9,98,111,
  117,110,100,115,95,99,120,3,224,7,9,98,111,117,110,100,115,95,99,121,
  2,16,11,102,111,110,116,46,104,101,105,103,104,116,2,14,9,102,111,110,
  116,46,110,97,109,101,6,9,115,116,102,95,102,105,120,101,100,11,102,111,
  110,116,46,120,115,99,97,108,101,2,1,10,102,111,110,116,46,100,117,109,
  109,121,2,0,17,111,110,101,100,105,116,110,111,116,105,102,99,97,116,105,
  111,110,7,11,101,100,105,116,110,111,116,105,101,120,101,13,114,101,102,102,
  111,110,116,104,101,105,103,104,116,2,16,0,0,0,12,116,105,110,116,101,
  103,101,114,100,105,115,112,5,99,111,108,100,105,11,102,114,97,109,101,46,
  100,117,109,109,121,2,0,8,116,97,98,111,114,100,101,114,2,16,8,98,
  111,117,110,100,115,95,120,3,208,0,8,98,111,117,110,100,115,95,121,2,
  8,9,98,111,117,110,100,115,95,99,120,2,52,9,98,111,117,110,100,115,
  95,99,121,2,18,13,114,101,102,102,111,110,116,104,101,105,103,104,116,2,
  14,0,0,7,116,98,117,116,116,111,110,8,116,98,117,116,116,111,110,53,
  8,116,97,98,111,114,100,101,114,2,17,8,98,111,117,110,100,115,95,120,
  3,64,1,8,98,111,117,110,100,115,95,121,2,8,9,98,111,117,110,100,
  115,95,99,120,2,42,9,98,111,117,110,100,115,95,99,121,2,20,5,115,
  116,97,116,101,11,15,97,115,95,108,111,99,97,108,99,97,112,116,105,111,
  110,17,97,115,95,108,111,99,97,108,111,110,101,120,101,99,117,116,101,0,
  7,99,97,112,116,105,111,110,6,4,115,97,118,101,9,111,110,101,120,101,
  99,117,116,101,7,6,115,97,118,101,101,120,0,0,9,116,115,116,97,116,
  102,105,108,101,5,115,116,97,116,102,8,102,105,108,101,110,97,109,101,6,
  10,115,116,97,116,117,115,46,115,116,97,4,108,101,102,116,3,232,0,3,
  116,111,112,2,32,0,0,9,116,102,97,99,101,108,105,115,116,10,116,102,
  97,99,101,108,105,115,116,49,10,108,105,115,116,46,99,111,117,110,116,2,
  1,10,108,105,115,116,46,105,116,101,109,115,14,1,14,102,97,100,101,95,
  112,111,115,46,99,111,117,110,116,2,1,14,102,97,100,101,95,112,111,115,
  46,105,116,101,109,115,1,2,0,0,16,102,97,100,101,95,99,111,108,111,
  114,46,99,111,117,110,116,2,1,16,102,97,100,101,95,99,111,108,111,114,
  46,105,116,101,109,115,1,4,255,190,181,0,0,5,100,117,109,109,121,2,
  0,0,0,4,108,101,102,116,3,248,0,3,116,111,112,3,144,1,0,0,
  0)
 );

initialization
 registerobjectdata(@objdata,tmainfo,'');
end.
