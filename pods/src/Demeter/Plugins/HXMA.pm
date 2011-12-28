package Demeter::Plugins::HXMA;  # -*- cperl -*-

use Moose;
extends 'Demeter::Plugins::FileType';

has '+is_binary'   => (default => 0);
has '+description' => (default => "the HXMA beamline at the CLS");
has '+version'     => (default => 0.1);

sub is {
  my ($self) = @_;
  open D, $self->file or die "could not open " . $self->file . " as data (HXMA)\n";
  my $first = <D>;
  close D, return 1 if ($first =~ m{CLS Data Acquisition});
  close D;
  return 0;
};

sub fix {
  my ($self) = @_;

  my $file = $self->file;
  my $new = File::Spec->catfile($self->stash_folder, $self->filename);
  ($new = File::Spec->catfile($self->stash_folder, "toss")) if (length($new) > 127);
  open D, $file or $self->Croak("could not open $file as data (fix in HXMA)\n");
  open N, ">".$new or die "could not write to $new (fix in HXMA)\n";

  print N "# $file demystified:", $/;
  print N "# ", "-" x 60, $/;
  print N "# Energy        I0        It        Ir        Lytle$/";

  my $found_headers = 0;
  my ($energy, $lytle, $i0, $it, $ir) = (0,0,0,0,0);
  while (<D>) {
    if ((not $found_headers) and ($_ =~ m{Event-ID})) {
      $found_headers = 1;
      my @headers = split(/\s+/, $_);
      foreach my $i (1 .. $#headers) {
	($energy = $i-1) if ($headers[$i] =~ m{Energy:sp});
	($lytle  = $i-1) if ($headers[$i] =~ m{mcs03:fbk});
	($i0     = $i-1) if ($headers[$i] =~ m{mcs04:fbk});
	($it     = $i-1) if ($headers[$i] =~ m{mcs05:fbk});
	($ir     = $i-1) if ($headers[$i] =~ m{mcs06:fbk});
      };
    };

    if ($_ !~ m{^\#}) {
      my @data = split(/,?\s+/, $_);
      printf N "  %s  %s  %s  %s  %s$/",
	$data[$energy], $data[$i0], $data[$it], $data[$ir], $data[$lytle];
    };
  };

  close N;
  close D;
  $self->fixed($new);
  return $new;
};

sub suggest {
  my ($self, $which) = @_;
  $which ||= 'transmission';
  if ($which eq 'transmission') {
    return (energy      => '$1',
	    numerator   => '$2',
	    denominator => '$3',
	    ln          =>  1,);
  } else {
    return (energy      => '$1',
	    numerator   => '$5',
	    denominator => '$2',
	    ln          =>  0,);
  };
};



__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Demeter::Plugin::HXMA - Demystify files from the HXMA beamline at the CLS

=head1 SYNOPSIS

This plugin strips the many columns not normally needed from a file
from the CLS HXMA beamline.  Most significantly, this strips the
leading 1 from every line of data, a feature which confuses Athena's
column selection dialog.  It also chooses the Energy:sp column as the
energy axis.

=head1 Methods

=over 4

=item C<is>

Recognize the HXMA file by the first line, which contains the phrase
"CLS Data Acquisition".

=item C<fix>

Strip out all columns except for energy, I0, I1, I2, and the Lytle
detector.  Also write sensible column labels to the output data file.

=back

=head1 AUTHOR

  Bruce Ravel <bravel@bnl.gov>
  http://xafs.org/BruceRavel/

