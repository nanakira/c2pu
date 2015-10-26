use strict;

my $inputfile = $ARGV[0];
open(IN,$inputfile) || die "$!";

my $outputfile = $inputfile;
$outputfile =~ s/(.*)\.(.+)$/$1.pu/;
open( OUT, ">", $outputfile )
  or die "Cannot open $outputfile with write permission: $!";

print OUT "\@startuml hsm.png\n\n";

while(<IN>) {
  if (/START_BASIC_HSM_STATE_TABLE/){
    parseStateTable();
  }
  elsif (/START_TRANSITION_TABLE/){
    parseTransitionTable();
  }
  elsif (/START_INTERNAL_TRANSITION_TABLE/){
    parseIntTransitionTable();
  }
  elsif (/START_ACTION_TABLE/){
    parseActionTable();
  }
}

print OUT "\@enduml\n";

close(OUT);
close(IN);


sub parseStateTable {
  my $depth = 0;
  my @stack = ();
  my $cur_state = '';
  my $cur_parent = '';
  my $domain, my $parent, my $state;
  while(<IN>) {
    if (/END_BASIC_HSM_STATE_TABLE/) {
      print OUT "\n\}\n\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      $parent = $2; $state = $3;
      if ($cur_state eq '' && $cur_parent eq ''){
        print OUT "STATE $state \{";
        $depth++;
        $cur_state = $state;
        $cur_parent = $parent;
      }
      elsif ($parent eq $cur_parent){
        print OUT "\n";
        printStateIndented($depth, $state);
        $cur_state = $state;
      }
      elsif ($parent eq $cur_state){
        print OUT " \{\n";
        $depth++;
        push @stack, $cur_parent;
        printStateIndented($depth, $state);
        $cur_parent = $parent;
        $cur_state = $state;
      }
      else {
        while (1){
          # Pop stack until root or correct depth
          last if ($depth == 0);
          $cur_parent = pop(@stack);
          $depth--;
          print OUT "\n", "  " x $depth, "\}";
          if ($parent eq $cur_parent){
            print OUT "\n";
            printStateIndented($depth, $state);
            $cur_state = $state;
            last;
          }
          else {
          }
        }
      }
    }
  }
}

sub printStateIndented {
  my ($depth, $state) = @_;
  print OUT ("  " x $depth, "STATE ", $state);
}

sub parseTransitionTable {
  while(<IN>) {
    if (/END_TRANSITION_TABLE/) {
      print OUT "\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      print OUT "$2 --> $3: $4\n";
    }
  }
}

sub parseIntTransitionTable {
  while(<IN>) {
    if (/END_INTERNAL_TRANSITION_TABLE/) {
      print OUT "\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      print OUT "$2 --> $2: $3 \/ $4\n";
    }
  }
}

sub parseActionTable {
  while(<IN>) {
    if (/END_ACTION_TABLE/) {
      print OUT "\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      print OUT "$2: entry / $3\n" if ($3 ne "NULL");
      print OUT "$2: exit / $4\n" if ($4 ne "NULL");
    }
  }
}
