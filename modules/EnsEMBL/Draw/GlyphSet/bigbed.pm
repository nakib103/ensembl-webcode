=head1 LICENSE

Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package EnsEMBL::Draw::GlyphSet::bigbed;

### Module for drawing data in BigBED format (either user-attached, or
### internally configured via an ini file or database record

use strict;
use warnings;
no warnings 'uninitialized';

use EnsEMBL::Web::IOWrapper::Indexed;

use parent qw(EnsEMBL::Draw::GlyphSet::Generic);

sub can_json { return 1; }

# Overridden in some regulation tracks, as it's not always this simple
sub my_url { return $_[0]->my_config('url'); }

sub get_data {
  my ($self, $url)    = @_;
  my $hub             = $self->{'config'}->hub;
  $url              ||= $self->my_url;
  my $container       = $self->{'container'};
  my $default_strand  = $self->{'my_config'}->get('strand') eq 'r' ? -1 : 1;
  my $args            = { 'options' => {
                                  'hub'         => $hub,
                                  'config_type' => $self->{'config'}{'type'},
                                  'track'       => $self->{'my_config'}{'id'},
                                  }, 
                        'default_strand' => $default_strand,
                        'drawn_strand' => $self->strand};
                        

  my $iow = EnsEMBL::Web::IOWrapper::Indexed::open($url, 'BigBed', $args);
  my $data;

  if ($iow) {
    ## We need to pass 'faux' metadata to the ensembl-io wrapper, because
    ## most files won't have explicit colour settings
    my $colour = $self->my_config('colour');
    my $metadata = {
                    'colour'          => $colour,
                    'join_colour'     => $colour,
                    'label_colour'    => $colour,
                    'display'         => $self->{'display'},
                    'default_strand'  => $default_strand,
                    'pix_per_bp'      => $self->scalex,
                    'spectrum'        => $self->{'my_config'}->get('spectrum'),
                    };

    ## Also set a default gradient in case we need it
    my @gradient = $iow->create_gradient([qw(yellow green blue)]);
    $metadata->{'default_gradient'} = \@gradient;

    ## No colour defined in ImageConfig, so fall back to defaults
    unless ($colour) {
      my $colourset_key           = $self->{'my_config'}->get('colourset') || 'userdata';
      my $colourset               = $hub->species_defs->colour($colourset_key);
      my $colours                 = $colourset->{'url'} || $colourset->{'default'};
      $metadata->{'colour'}       = $colours->{'default'};
      $metadata->{'join_colour'}  = $colours->{'join'} || $colours->{'default'};
      $metadata->{'label_colour'} = $colours->{'text'} || $colours->{'default'};
    }

    ## Omit individual feature links if this glyphset has a clickable background
    $metadata->{'omit_feature_links'} = 1 if $self->can('bg_link');

    ## Parse the file, filtering on the current slice
    $data = $iow->create_tracks($container, $metadata);
    #use Data::Dumper; warn Dumper($data);
  } else {
    #return $self->errorTrack(sprintf 'Could not read file %s', $self->my_config('caption'));
    warn "!!! ERROR CREATING PARSER FOR BIGBED FORMAT";
  }
  #$self->{'config'}->add_to_legend($legend);

  return $data;
}
  
sub render_as_alignment_nolabel {
  my $self = shift;
  $self->{'my_config'}->set('depth', 20);
  $self->draw_features;
}
 
sub render_as_alignment_label {
  my $self = shift;
  $self->{'my_config'}->set('depth', 20);
  $self->{'my_config'}->set('show_labels', 1);
  $self->draw_features;
}

sub render_compact {
  my $self = shift;
  $self->{'my_config'}->set('depth', 0);
  $self->{'my_config'}->set('no_join', 1);
  $self->draw_features;
}

sub render_as_transcript_nolabel {
  my $self = shift;
  $self->{'my_config'}->set('drawing_style', ['Feature::Transcript']);
  $self->{'my_config'}->set('depth', 20);
  $self->draw_features;
}

sub render_as_transcript_label {
  my $self = shift;
  $self->{'my_config'}->set('drawing_style', ['Feature::Transcript']);
  $self->{'my_config'}->set('depth', 20);
  $self->{'my_config'}->set('show_labels', 1);
  $self->draw_features;
}

sub render_text { warn "No text renderer for bigbed\n"; return ''; }

1;

