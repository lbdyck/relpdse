RELPDSE is a ISPF command that may be used from ISPF 3.4 or ISPF 6
to release space within a PDSE.

Requirements:
    1. ADRDSSU must be defined in the IKJTSOxx member of SYS1.PARMLIB
       in the AUTHPGM section.
    2. The dataset being processed must not be allocated.
    3. The dataset must be a PDSE.
    4. Must be used under ISPF.

Syntax:  %RELPDSE 'fully-qualified-pdse-dsname'

 This tool was created after I found a web disussion at
 https://ibmmainframes.com/about61886.html with sample code provided by
 Pedro back in November 2013.
