=head1 LICENSE

Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

package EnsEMBL::Web::Component::Info::GeneGallery;

## 

use strict;

use base qw(EnsEMBL::Web::Component::Info::Gallery);

sub _init {
  my $self = shift;
  $self->cacheable(0);
  $self->ajaxable(0);
}

sub content {
  my $self = shift;
  my $hub  = $self->hub;

  my $layout = [
                {
                    'title' => 'Sequence &amp; Structure',
                    'pages' => ['Scrolling Browser', 'Region in Detail', 'Immediate Neighbourhood', 'Summary Information', 'Splice Variants', 'Gene Sequence', 'Secondary Structure', 'Supporting Evidence', 'Gene History', 'Gene Identifiers', 'Gene Alleles'],
                    'icon'  => 'dna.png',
                  },
                {
                  'title' => 'Function &amp; Regulation',
                  'pages' => ['Table of Ontology Terms', 'Gene Regulation Image', 'Gene Regulation Table', 'Gene Expression'],
                  'icon'  => 'regulation.png',
                },
                  {
                    'title' => 'Transcripts & Proteins',
                    'pages' => ['Transcript Table', 'Transcript Summary', 'Transcript Comparison', 'Transcript Image', 'Exon Sequence', 'Protein Summary', 'Transcript cDNA', 'Transcript History', 'Protein Sequence', 'Domains and Features', 'Protein Family Alignments', 'Transcript Identifiers', 'Oligo Probes', 'Protein Variants', 'Protein History'],
                    'icon'  => 'protein.png',
                  },
                {
                    'title' => 'Comparative Genomics',
                    'pages' => ['Gene Tree', 'Gene Tree Alignments', 'Gene Gain/Loss Tree', 'Summary of Orthologues', 'Table of Orthologues', 'Summary of Paralogues', 'Table of Paralogues', 'Protein Family Alignments', 'Gene Family', 'Aligned Sequence', 'Region Comparison'],
                    'icon'  => 'compara.png',
                },
                  {
                    'title' => 'Variants',
                    'pages' => ['Variant Image', 'Variant Table', 'Structural Variant Image', 'Structural Variant Table', 'Transcript Variant Image', 'Transcript Variant Table', 'Transcript Haplotypes', 'Protein Variants', 'Population Comparison Table', 'Population Comparison Image'],
                    'icon'  => 'variation.png',
                  },
                ];

  return $self->format_gallery('Gene', $layout, $self->_get_pages);
}

sub _get_pages {
  ## Define these in a separate method to make content method cleaner
  my $self = shift;
  my $hub = $self->hub;
  my $g = $hub->param('g');

  my $builder   = EnsEMBL::Web::Builder->new($hub);
  my $factory   = $builder->create_factory('Gene');
  my $object    = $factory->object;

  if (!$object) {
    return $self->warning_panel('Invalid identifier', 'Sorry, that identifier could not be found. Please try again.');
  }
  else {

    my $r = $hub->param('r');
    unless ($r) {
      $r = sprintf '%s:%s-%s', $object->slice->seq_region_name, $object->start, $object->end;
    }

    my $avail = $hub->get_query('Availability::Gene')->go($object,{
                          species => $hub->species,
                          type    => $object->get_db,
                          gene    => $object->Obj,
                        })->[0];
    my $no_transcripts  = !$avail->{'has_transcripts'};
    my $has_gxa         = $object->gxa_check;
    my $has_rna         = ($avail->{'has_2ndary'} && $avail->{'can_r2r'}); 
    my $has_tree        = ($avail->{'has_species_tree'} && !$hub->species_defs->IS_STRAIN_OF);

    my ($sole_trans, $multi_trans, $multi_prot);
    my $prot_count      = 0;
    if ($avail->{'multiple_transcripts'}) {
      $multi_trans = {
                      'type'    => 'Transcript',
                      'param'   => 't',
                      'values'  => [{'value' => '', 'caption' => '-- Select transcript --'}],
                      };
      $multi_prot = {
                      'type'    => 'Protein',
                      'param'   => 'p',
                      'values'  => [{'value' => '', 'caption' => '-- Select protein --'}],
                      };
    }
    foreach my $t (map { $_->[2] } sort { $a->[0] cmp $b->[0] || $a->[1] cmp $b->[1] } map { [ $_->external_name, $_->stable_id, $_ ] } @{$object->Obj->get_all_Transcripts}) {
      if ($avail->{'multiple_transcripts'}) {
        my $name = $t->external_name || $t->{'stable_id'};
        $name .= sprintf ' (%s)', $t->biotype;
        push @{$multi_trans->{'values'}}, {'value' => $t->stable_id, 'caption' => $name};
      }
      else {
        $sole_trans = $t->stable_id;
      }
      if ($t->translation) {
        $prot_count++;
        my $id = $t->translation->stable_id;
        push @{$multi_prot->{'values'}}, {'value' => $id, 'caption' => $id};
      }
    }
    $multi_prot = {} unless $prot_count > 1;

    return {
            'Scrolling Browser' => {
                                  'link_to'   => {'type'    => 'Location',
                                                  'action'  => 'View',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_genoverse',
                                  'caption'   => 'View the position of this gene in our fully scrollable genome browser',
                                },
            'Region in Detail' => {
                                  'link_to'   => {'type'    => 'Location',
                                                  'action'  => 'View',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_view',
                                  'caption'   => 'Zoom in on your gene of interest',
                                },

            'Immediate Neighbourhood' => {
                                  'link_to'   => {'type'    => 'Gene',
                                                  'action'  => 'Summary',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_summary_image',
                                  'caption'   => 'View this gene in its genomic location',
                                },
            'Aligned Sequence' => {
                                  'link_to'   => {'type'      => 'Location',
                                                  'action'    => 'Compara_Alignments',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_align',
                                  'caption'   => 'View the region underlying your gene aligned to that of one or more other species',
                                  'disabled'  => !$avail->{'has_alignments'},
                                },
            'Region Comparison' => {
                                  'link_to'   => {'type'      => 'Location',
                                                  'action'    => 'Multi',
                                                  'r'      => $r,
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'location_compare',
                                  'caption'   => 'View your gene compared to its homologue in another species',
                                },
            'Summary Information' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Summary',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_summary',
                                  'caption'   => 'General information about this gene, e.g. identifiers and synonyms',
                                },
            'Splice Variants' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Splice',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_splice',
                                  'caption'   => '',
                                },
            'Gene Alleles' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Alleles',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_alleles',
                                  'caption'   => 'Table of genes that have been annotated on haplotypes and patches as well as on the reference assembly',
                                  'disabled'  => !$avail->{'has_alt_alleles'},
                                },
            'Gene Sequence' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Sequence',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_sequence',
                                  'caption'   => 'DNA sequence of this gene, optionally with variants marked',
                                },
            'Secondary Structure' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'SecondaryStructure',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_secondary',
                                  'caption'   => 'Secondary structure of this gene',
                                  'disabled'  => !$has_rna,
                                  'message'   => 'Only available for RNA genes'
                                },
            'Gene Tree' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Tree',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_tree',
                                  'caption'   => 'Tree showing homologues of this gene across many species',
                                  'disabled'  => !$has_tree,
                                },
            'Gene Tree Alignments' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Tree',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_tree_align',
                                  'caption'   => "Alignments of this gene's homologues across many species",
                                  'disabled'  => !$has_tree,
                                },
            'Gene Gain/Loss Tree' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => '',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_cafe_tree',
                                  'caption'   => 'Interactive tree of loss and gain events in a family of genes',
                                  'disabled'  => !$has_tree,
                                },
            'Summary of Orthologues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Ortholog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ortho_summary',
                                  'caption'   => 'Table showing numbers of different types of orthologue (1-to-1, 1-to-many, etc) in various taxonomic groups',
                                },
            'Table of Orthologues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Ortholog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ortho_table',
                                  'caption'   => 'Table of orthologues in other species, with links to gene tree, alignments, etc.',
                                },
            'Table of Paralogues' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Compara_Paralog',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_para_table',
                                  'caption'   => 'Table of within-species paralogues, with links to alignments of cDNAs and proteins',
                                },
            'Protein Family Alignments' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Family',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'protein_family',
                                  'caption'   => "Alignments of protein sequence within a protein family (go to the Protein Family page and click on the 'Wasabi viewer' link)",
                                  'disabled'  => !$prot_count,
                                },
            'Gene Family' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Family',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_family',
                                  'caption'   => 'Locations of all genes in a protein family',
                                },
            'Table of Ontology Terms' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Ontologies',
                                                  'function'  => 'biological_process',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_ontology',
                                  'caption'   => 'Table of ontology terms linked to this gene',
                                },
            'Supporting Evidence' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Evidence',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_support',
                                  'caption'   => "Table of evidence for this gene's transcripts, from protein, EST and cDNA sources",
                                },
            'Gene History' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Idhistory',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_history',
                                  'caption'   => "History of a gene's stable ID",
                                  'disabled'  => !$avail->{'history'},
                                },
            'Gene Expression' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'ExpressionAtlas',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_gxa',
                                  'caption'   => 'Interactive gene expression heatmap',
                                  'disabled'  => !$has_gxa,
                                },
            'Gene Regulation Image' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Regulation',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_reg_image',
                                  'caption'   => 'Gene shown in context of regulatory features',
                                },
            'Gene Regulation Table' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Regulation',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_reg_table',
                                  'caption'   => 'Table of regulatory features associated with this gene',
                                },
            'Transcript Comparison' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'TranscriptComparison',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_transcomp',
                                  'caption'   => 'Compare the sequence of two or more transcripts of a gene',
                                  'disabled'  => !$multi_trans,
                                },
            'Gene Identifiers' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Matches',
                                                  'g'      => $g,
                                                 },
                                  'img'       => 'gene_xref',
                                  'caption'   => 'Links to external database identifiers that match this gene',
                                },
            'Transcript Summary' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Summary',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_summary',
                                  'caption'   => 'General information about a particular transcript of this gene',
                                  'multi'     => $multi_trans,
                                },
            'Transcript Table' => {
                                  'link_to'   => {'type'      => 'Gene',
                                                  'action'    => 'Summary',
                                                  'g'         => $g,
                                                 },
                                  'img'       => 'trans_table',
                                  'caption'   => "Table of information about all transcripts of this gene (click on the 'Show transcript table' button on any gene or transcript page)",
                                },
            'Exon Sequence' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Exons',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_exons',
                                  'caption'   => 'Sequences of individual exons within a transcript',
                                  'multi'     => $multi_trans,
                                },
            'Transcript cDNA' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Sequence_cDNA',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_cdna',
                                  'caption'   => 'cDNA sequence of an individual transcript',
                                  'multi'     => $multi_trans,
                                },
            'Protein Sequence' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Sequence_Protein',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_protein_seq',
                                  'caption'   => 'Protein sequence of an individual transcript',
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Protein Summary' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'ProteinSummary',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_protein',
                                  'caption'   => 'Image showing protein domains and variants',
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Domains and Features' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Domains',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'prot_domains',
                                  'caption'   => 'Table of protein domains and other structural features',
                                  'multi'     => $multi_prot,
                                },
            'Protein Variants' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'ProtVariation',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'prot_variants',
                                  'caption'   => "Table of variants found within a transcript's protein",
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Transcript Identifiers' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Similarity',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_xref',
                                  'caption'   => 'Links to external database identifiers that match a transcript of this gene',
                                  'multi'     => $multi_trans,
                                },
            'Oligo Probes' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Oligos',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_oligo',
                                  'caption'   => 'List of oligo probes that map to a transcript of this gene',
                                  'multi'     => $multi_trans,
                                },
            'Transcript History' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Idhistory',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_history',
                                  'caption'   => "History of the stable ID for one of this gene's transcripts",
                                  'multi'     => $multi_trans,
                                },
            'Protein History' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Idhistory/Protein',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'prot_history',
                                  'caption'   => "History of the stable ID for one of this gene's protein products",
                                  'disabled'  => !$prot_count,
                                  'multi'     => $multi_prot,
                                },
            'Transcript Haplotypes' => {
                                  'link_to'   => {'type'      => 'Transcript',
                                                  'action'    => 'Haplotypes',
                                                  't'         => $sole_trans,
                                                 },
                                  'img'       => 'trans_haplotypes',
                                  'caption'   => 'Frequency of protein or CDS haplotypes across major population groups',
                                  'multi'     => $multi_trans,
                                },
          'Transcript Variant Image' => {
                                  'link_to'       => {'type'    => 'Transcript',
                                                      'action'  => 'Variation_Transcript/Image',
                                                      },
                                  'img'       => 'variation_gene_image',
                                  'caption'   => 'Image showing all variants in an individual transcript',
                          },
          'Transcript Variant Table' => {
                                  'link_to'       => {'type'    => 'Transcript',
                                                      'action'  => 'Variation_Transcript/Table',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'variation_gene_table',
                                  'caption'   => 'Table of all variants in an individual transcript',
                          },
          'Variant Image' => {
                                  'link_to'       => {'type'    => 'Gene',
                                                      'action'  => 'Variation_Gene/Image',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'variation_gene_image',
                                  'caption'   => 'Image showing all variants in this gene',
                          },
          'Variant Table' => {
                                  'link_to'       => {'type'    => 'Gene',
                                                      'action'  => 'Variation_Gene/Table',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'variation_gene_table',
                                  'caption'   => 'Table of all variants in this gene',
                          },
          'Structural Variant Image' => {
                                  'link_to'       => {'type'    => 'Gene',
                                                      'action'  => 'StructuralVariation_Gene',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'gene_sv_image',
                                  'caption'   => 'Image showing structural variants in this gene',
                          },
          'Structural Variant Table' => {
                                  'link_to'       => {'type'    => 'Gene',
                                                      'action'  => 'StructuralVariation_Gene',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'gene_sv_table',
                                  'caption'   => 'Table of all structural variants in this gene',
                          },
          'Population Comparison Image' => {
                                  'link_to'       => {'type'    => 'Transcript',
                                                      'action'  => 'Population/Image',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'population_image',
                                  'caption'   => 'Image showing variants across different populations',
                          },
          'Population Comparison Table' => {
                                  'link_to'       => {'type'    => 'Transcript',
                                                      'action'  => 'Population',
                                                      'g'       => $g,
                                                      },
                                  'img'       => 'population_table',
                                  'caption'   => 'Tables of variants within different populations',
                          },

            };
  }

}

1;
