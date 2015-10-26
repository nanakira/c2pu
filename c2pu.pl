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
      $parent =~ s/HSM_STATE_//;
      $state =~ s/HSM_STATE_//;
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
      my $from = $2; my $to = $3; my $by = $4;
      $from =~ s/HSM_STATE_//;
      $to =~ s/HSM_STATE_//;
      $by =~ s/HSM_EVENT_//;
      print OUT "$from --> $to: $by\n";
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
      my $in = $2; my $by = $3; my $callback = $4;
      $in =~ s/HSM_STATE_//;
      $by =~ s/HSM_EVENT_//;
      print OUT "$in: $by \/ $callback\n";
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
      my $in = $2; my $entryaction = $3; my $exitaction = $4;
      $in =~ s/HSM_STATE_//;
      print OUT "$in: entry / $entryaction\n" if ($entryaction ne "NULL");
      print OUT "$in: exit / $exitaction\n" if ($exitaction ne "NULL");
    }
  }
}
