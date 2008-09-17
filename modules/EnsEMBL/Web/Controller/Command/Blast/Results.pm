package EnsEMBL::Web::Controller::Command::Blast::Results;

use strict;
use warnings;

use Class::Std;

use EnsEMBL::Web::RegObj;
use base 'EnsEMBL::Web::Controller::Command::Blast';

use EnsEMBL::Web::Magic qw(stuff);
{

sub BUILD {
  my ($self, $ident, $args) = @_; 
}

sub process {
  my $self = shift;
  stuff 'Blast', 'Results', $self;
}

}

1;
