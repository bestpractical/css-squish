use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'CSS::Squish',
    VERSION_FROM      => 'lib/CSS/Squish.pm',
    PREREQ_PM         => {
        'File::Spec' => 0
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/CSS/Squish.pm',
       AUTHOR         => 'Thomas Sibley <trs@bestpractical.com>') : ()),
);

