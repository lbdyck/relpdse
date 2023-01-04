/* --------------------  rexx procedure  -------------------- *
 | Name:      RELPDSE                                         |
 |                                                            |
 | Function:  Release space from a PDSE using ADRDSSU.        |
 |                                                            |
 | Syntax:    %relpdse fully-qualified-pdse-dsname  quiet     |
 |                                                            |
 |            dataset-name   - self explanatory               |
 |            quiet          - disable report                 |
 |                             any non-blank character(s)     |
 |                                                            |
 | Dependencies: The dataset must *not* be in use.            |
 |                                                            |
 |               The dataset must be a PDSE.                  |
 |                                                            |
 |               ADRDSSU must be defined in IKJTSOxx in the   |
 |               AUTHPGM section.                             |
 |                                                            |
 |               ISPF is required to view the results.        |
 |                                                            |
 | Author:    Lionel B. Dyck                                  |
 |                                                            |
 | History:  (most recent on top)                             |
 |            2023/01/04 LBD - Enable Batch use               |
 |            2021/11/22 LBD - Add quiet option               |
 |            2021/05/31 LBD - Remove STEMEDIT and add more   |
 |                             informative messages.          |
 |            2021/05/31 LBD - Creation from discussion       |
 |            https://ibmmainframes.com/about61886.html       |
 |            with sample code provided by Pedro Vera         |
 |                                                            |
 * ---------------------------------------------------------- */

  parse arg dataset quiet

  if sysdsn(dataset) /= 'OK' then do
    say 'Requested dataset' dataset
    say sysdsn(dataset)
    exit 8
  end

  x = listdsi(dataset 'DIR')
  if sysadirblk /= 'NO_LIM' then do
    say dataset 'is not a PDSE'
    say 'This application is terminating.'
    exit 8
  end

  if left(dataset,1) = "'"
  then parse value dataset with "'"dsn"'"
  else dsn = dataset

  /* ------------------------------------------------------ *
   | Allocate the SYSIN and SYSPRINT DD's to temp datasets. |
   * ------------------------------------------------------ */
  Address TSO
  'alloc f(sysin) spa(1) recfm(f b) lrecl(80) blksize(3120)' ,
    'unit(3390) new reuse'
  'alloc f(sysprint) spa(15,15) recfm(v b a) lrecl(121)' ,
    'unit(3390) new reuse blksize(2428)'

  /*   create DFDSS control card */
  reldd = 'REL'random(9999)
  out.1 =" RELEASE INCLUDE("translate(dsn)") DDNAME("reldd")   "
  out.0 = 1
  "EXECIO 1 DISKW SYSIN (STEM OUT. FINIS "

  /* CALL DFDSS to release the space */
  "ALLOC F("reldd") DA("dataset") SHR"
  "CALL 'SYS1.LINKLIB(ADRDSSU)'"

  /* ------------------------------------------------------------ *
   | Read in the SYSPRINT report and then free all allocated DD's |
   | used by this exec.                                           |
   * ------------------------------------------------------------ */
  'execio * diskr sysprint (finis stem sysp.'
  "FREE F("reldd" SYSIN SYSPRINT)"

  /* -------------------------------------------------- *
   | If Quiet is any non-blank then exit without report |
   * -------------------------------------------------- */
  if quiet /= '' then exit 0

  /* ------------------------------------ *
   | Capture for reporting original state |
   * ------------------------------------ */
  m1 = 'Processing dataset:' dataset
  m2 = 'Using' ((sysallocpages * 1024)/50000)%1 +1 'Tracks'
  m3 = 'With' sysusedpercent'% in use'

  /* ------------------------------------------------------ *
   | Now generate the ISPF long message (short is null) and |
   | then view the generated ADRDSSU report.                |
   * ------------------------------------------------------ */
  x = listdsi(dataset 'DIR')
  r1 = 'Now using:'
  r2 = 'Using' ((sysallocpages * 1024)/50000)%1 +1 'Tracks'
  r3 = 'With' sysusedpercent'% in use'

  if sysvar('sysenv') = 'FORE'
  then if sysvar('sysispf') = 'ACTIVE' then do
    ispf = 1
    zedsmsg = ''
    zedlmsg = left(m1,74) left(m2,74) left(m3,74) left('-',74,'-') ,
      left(r1,74) left(r2,74) r3
    Address ISPExec 'Setmsg msg(isrz001)'
  end
  else do
    ispf = 0
    say ' '
    say m1
    say m2
    say m3
    say copies('-',74)
    say r1
    say r2
    say r3
  end

  "allocate file("reldd") reuse unit(3390) space(1 1)" ,
    "track dsorg(ps) recfm(v b a) lrecl(121) blksize(2420)"
  "execio * diskw" reldd "(stem sysp. finis)"

  if ispf = 1 then do
    Address ISPEXEC
    "LMINIT DATAID(DATAID) DDNAME("reldd")"
    "VIEW DATAID("dataid")"
    "LMFREE DATAID("dataid")"
  end
  else do i = 1 to sysp.0
    say sysp.i
  end

  Address TSO ,
    "FREE FILE("reldd")"
