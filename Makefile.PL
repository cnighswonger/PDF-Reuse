use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          =>  'PDF::Reuse',
    'DISTNAME'      =>  'PDF-Reuse',
    'VERSION_FROM'  =>  'lib/PDF/Reuse.pm',
    'ABSTRACT_FROM' =>  'lib/PDF/Reuse.pm',
    'PMLIBDIRS'     =>  [ qw( lib/ ) ],
    'AUTHOR'        =>  [
                            'Lars Lundberg <larslund@cpan.org>',
                            'Chris Nighswonger <cnighs@cpan.org>',
                        ],
    'PREREQ_PM'     =>  {   Digest::MD5         => 0,
                            Compress::Zlib      => 0,
                            Carp                => 0,
                            Exporter            => 0,
                            AutoLoader          => 0,
                            Data::Dumper        => 0,
                            Text::PDF::TTFont0  => 0,
                            Font::TTF           => 0,
                        },
    dist            =>  {
                            COMPRESS    =>  'gzip -9f',
                            SUFFIX      =>  'gz',
                        },
    depend          =>  {
                            Makefile    =>  '$(VERSION_FROM)'
                        },
    clean           =>  {
                            FILES   =>  'PDF-Reuse-*'
                        }
);
