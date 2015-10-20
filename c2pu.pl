use strict;

my $inputfile = $ARGV[0];
open(IN,$inputfile) || die "$!";

my $outputfile = $inputfile;
$outputfile =~ s/(.*)\.(.+)$/$1.pu/;
open( OUT, ">", $outputfile )
  or die "Cannot open $outputfile with write permission: $!";

print "\@startuml hsm.png\n\n";

while(<IN>) {
  if (/START_BASIC_HSM_STATE_TABLE/){
    &parseStateTable();
  }
}

print "\n\@enduml\n";

close(OUT);
close(IN);


sub parseStateTable {
  my $cur_state = '';
  my $cur_parent = '';
  my $domain, my $parent, my $state;
  while(<IN>) {
    if (/END_BASIC_HSM_STATE_TABLE/) {
      return;
    }
    elsif (/\(\s*(\S+)\s*,\s*(\S+)\s*,\s*(\S+)\s*\)/) {
      $parent = $2; $state = $3;
#      print "parent: $2, state: $3, cur_parent: $cur_parent, cur_state: $cur_state\n";
      if ($cur_state eq '' && $cur_parent eq ''){
        print "STATE $state \{";
        $cur_state = $state;
        $cur_parent = $parent;
      }
      elsif ($parent eq $cur_parent){
        print "\nSTATE $state";
        $cur_state = $state;
      }
      elsif ($parent eq $cur_state){
        print "\{\nSTATE $state"};
        $cur_parent = $parent;
        $cur_state = $state;
#      print ("$1, $2, $3\n");
    }
#    print (OUT $_)
  }
}
