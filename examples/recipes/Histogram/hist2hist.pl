#!/usr/bin/perl

use Demeter qw(:ui=screen :plotwith=gnuplot);
use Demeter::ScatteringPath::Histogram::DL_POLY;

use DateTime;

my $prj = Demeter::Data::Prj->new(file=>"/home/bruce/PtData.prj");
my $data = $prj->record(1);
$data->bft_rmin(1.6);


      my $start = DateTime->now( time_zone => 'floating' );
my $dlp = Demeter::ScatteringPath::Histogram::DL_POLY->new( rmin=>1.5, rmax=>7, ss=>1, file=>'HISTORY',);
#my $dlp = Demeter::ScatteringPath::Histogram::DL_POLY->new( r1=>1.5, r2=>3.5, r3=>5.2, r4=>5.6, ncl=>1, skip=>20, file=>'HISTORY',);
      my $lap = DateTime->now( time_zone => 'floating' );
      my $dur = $lap->subtract_datetime($start);
      printf("%d minutes, %d seconds\n", $dur->minutes, $dur->seconds);

# open(my $twod, '>', 'twod');
# foreach my $p (@{$dlp->nearcl}) {
#   printf $twod "  %.9f  %.9f  %.9f  %.15f\n", @$p;
# };
# close $twod;
# print $#{$dlp->nearcl}, $/;

# exit;

#print $dlp->npairs, $/;

$dlp->rebin;
$dlp->plot;
$dlp->pause;

exit;

open(my $bin2d, '>', 'bin2d');
foreach my $p (@{$dlp->populations}) {
  printf $bin2d "  %.9f  %.9f  %.d\n", @$p;
};
close $bin2d;

exit;

# $dlp->bin(0.02);
# $dlp->rebin;
# $dlp->plot;
# $dlp->pause;

my $atoms = Demeter::Atoms->new();
$atoms -> set(a=>3.92);
$atoms -> space('f m 3 m');
$atoms -> push_sites( join("|", 'Pt',  0.0, 0.0, 0.0,   'Pt'  ) );
$atoms -> core('Pt');
$atoms -> set(rpath=>5.2, rmax => 8);
my $feff = Demeter::Feff->new(workspace=>"feff/", screen=>0, atoms=>$atoms);
$feff->run;
$dlp->sp($feff->pathlist->[0]);

my $composite = $dlp->fpath;
$composite->plot('r');
$composite->pause;

exit;

my @gds = (Demeter::GDS->new(gds=>'guess', name=>'amp',  mathexp=>1),
	   Demeter::GDS->new(gds=>'guess', name=>'enot', mathexp=>0),
	   Demeter::GDS->new(gds=>'guess', name=>'ss',   mathexp=>0.001),
	   Demeter::GDS->new(gds=>'set',   name=>'delr', mathexp=>0),
	  );

$composite->set(data   => $data,
		s02    => 'amp',
		e0     => 'enot',
		delr   => 'delr',
		sigma2 => 'ss',
	       );
my $fit = Demeter::Fit->new(gds=>\@gds,
			    data=>[$data],
			    paths=>[$composite],
			   );
$fit->fit;
$fit->logfile('dlpoly.log');
$data->po->start_plot;
$data->po->set(plot_fit=>1);
$data->plot('r');
$data->pause;

