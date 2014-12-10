#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;

BEGIN {
        use_ok('PDF::Reuse') or BAIL_OUT "Can't load PDF::Reuse";
}

prFile('./test.pdf');

my $f_flag = 1 if -e './test.pdf';
is ($f_flag, 1, "PDF file creation");

# Test findFont
$PDF::Reuse::font = 'H';
my ($foINTNAME, $foEXTNAME, $foREFOBJ) = PDF::Reuse::findFont();
subtest 'PDF::Reuse::findFont'    => sub{
    plan tests  => 3;
    is ($foINTNAME, 'Ft1', "Internal font name");
    is ($foEXTNAME, 'Helvetica', "External font name");
    is ($foREFOBJ, '4', "PDF reference object for this font");
};

# Test prText
prText(250, 650, 'Hello World !');
is ($PDF::Reuse::stream, '0 0 0 rg
 0 g
f

BT /Ft1 12 Tf 250 650 Td (Hello World !) Tj ET
', "PDF Stream");

prEnd();

# Test newly created PDF file
open (my $pdf, "<", "test.pdf") or BAIL_OUT "Can't open test.pdf: $!";
binmode $pdf;
my @pdf_got = <$pdf>;
close $pdf;

binmode main::DATA, ':encoding(UTF-8)';
my @pdf_expected = <main::DATA>;
# Line 29 contains two MD% hashes which are time-based and change with every new
# PDF file created, so we will ignore it while testing the resulting file.
$pdf_expected[29] = ignore();
close main::DATA;

cmp_deeply(\@pdf_got, \@pdf_expected, "Finished PDF file");

__DATA__
%PDF-1.4
%âãÏÓ
4 0 obj<</Type/Font/Subtype/Type1/BaseFont/Helvetica/Encoding/WinAnsiEncoding>>endobj
5 0 obj<</ProcSet[/PDF/Text]/Font << /Ft1 4 0 R >>>>endobj
6 0 obj<</Length 64>>stream
0 0 0 rg
 0 g
f

BT /Ft1 12 Tf 250 650 Td (Hello World !) Tj ET

endstream
endobj
3 0 obj<</Type/Page/Parent 2 0 R/Contents 6 0 R/MediaBox [0 0 595 842]/Resources 5 0 R>>endobj
2 0 obj<</Type/Pages/Kids [3 0 R ]/Count 1 >>endobj
1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
xref
0 7
0000000000 65535 f 
0000000417 00000 n 
0000000365 00000 n 
0000000270 00000 n 
0000000015 00000 n 
0000000101 00000 n 
0000000160 00000 n 
trailer
<<
/Size 7
/Root 1 0 R
/ID [<350aa45c19681b7ceab857c0e6c131dc><350aa45c19681b7ceab857c0e6c131dc>]
>>
startxref
460
%%EOF
