use strict;

my $inputfile = $ARGV[0];
open(IN,$inputfile) || die "$!";

my $outputfile = $inputfile;
$outputfile =~ s/(.*)\.(.+)$/$1.pu/;
open( OUT, ">", $outputfile )
  or die "Cannot open $outputfile with write permission: $!";

print (OUT "\@startuml hsm.png\n\n");

while(<IN>) {
  if (/START_BASIC_HSM_STATE_TABLE/){
    &parseStateTable();
  }
}

print (OUT "\n\@enduml\n");

close(OUT);
close(IN);


sub parseStateTable {
  while(<IN>) {
    if (/END_BASIC_HSM_STATE_TABLE/) {
      return;
    }
    elsif (/\((.*),\s*(.*),\s*(.*)\)/) {
      print (OUT "$1\n");
      print (OUT "$2\n");
      print (OUT "$3\n");
      print (OUT "$4\n\n");
    }
#    print (OUT $_)
  }
}
