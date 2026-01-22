use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'          => 'PDF::Reuse',
    'VERSION_FROM'  => 'Reuse.pm', 
    'PREREQ_PM'     => { Digest::MD5    => 0,
                          Compress::Zlib => 0,
                          Carp           => 0,
                          Exporter       => 0,
                          AutoLoader     => 0,
                          Data::Dumper   => 0,
                          Text::PDF::TTFont0 => 0,
                          Font::TTF   => 0},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Reuse.pm', 
       AUTHOR     => [  'Lars Lundberg LARSLUND@CPAN.ORG',
                        'Chris Nighswonger CNIGHS@CPAN.ORG',
                     ]) : ()),
);
