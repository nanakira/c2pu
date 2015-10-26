use strict;

my $inputfile = $ARGV[0];
open(IN,$inputfile) || die "$!";

my $outputfile = $inputfile;
$outputfile =~ s/(.*)\.(.+)$/$1.pu/;
open( OUT, ">", $outputfile )
  or die "Cannot open $outputfile with write permission: $!";

print OUT "\@startuml $1.png\n\n";

while(<IN>) {
  if (/START_(BASIC_)?HSM_STATE_TABLE/){
    parseStateTable();
  }
  elsif (/START_(BASIC_)?TRANSITION_TABLE/){
    parseTransitionTable();
  }
  elsif (/START_(BASIC_)?INTERNAL_TRANSITION_TABLE/){
    parseIntTransitionTable();
  }
  elsif (/START_(BASIC_)?ACTION_TABLE/){
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
  print OUT "' ### State structure definition ###\n";
  while(<IN>) {
    if (/END_(BASIC_)?HSM_STATE_TABLE/) {
        popStackCloseBracket();
        print OUT "\n\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      $parent = $2; $state = $3;
      if ($cur_state eq '' && $cur_parent eq ''){
        print OUT "STATE $parent \{\n";
        $depth++;
        printStateIndented($depth, $state);
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
        popStackCloseBracket();
      }
    }
  }

  sub printStateIndented {
    my ($depth, $state) = @_;
    print OUT ("  " x $depth, "STATE ", $state);
  }

  sub popStackCloseBracket {
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

sub parseTransitionTable {
  print OUT "' ### External state transition ###\n";
  while(<IN>) {
    if (/END_(BASIC_)?TRANSITION_TABLE/) {
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
  print OUT "' ### Internal event ###\n";
  while(<IN>) {
    if (/END_(BASIC_)?INTERNAL_TRANSITION_TABLE/) {
      print OUT "\n";
      return;
    }
    elsif (/^\s*\/\//) {next}
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      print OUT "$2: $3 \/ $4\n";
    }
  }
}

sub parseActionTable {
  print OUT "' ### entry / exit action ###\n";
  while(<IN>) {
    if (/END_(BASIC_)?ACTION_TABLE/) {
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
