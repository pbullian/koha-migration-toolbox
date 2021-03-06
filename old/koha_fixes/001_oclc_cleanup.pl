#!/usr/bin/perl
#---------------------------------
# Copyright 2011 ByWater Solutions
#
#---------------------------------
#
# -D Ruth Bavousett
#
#---------------------------------

use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Text::CSV;
use MARC::Charset;
use MARC::Record;
use MARC::Field;
use C4::Context;
use C4::Biblio;
use C4::Items;
$|=1;
my $debug=0;
my $doo_eet=0;

GetOptions(
    'debug'         => \$debug,
    'update'        => \$doo_eet,
);

#if (($branch eq '')){
#  print "Something's missing.\n";
#  exit;
#}

my $dbh=C4::Context->dbh();
my $i=0;
my $modified=0;
my $iggy = MARC::Charset::ignore_errors(1);
my $setting = MARC::Charset::assume_encoding('utf8');

my $sth=$dbh->prepare("SELECT biblioitems.biblionumber AS biblionumber,frameworkcode from biblioitems
                    JOIN biblio USING (biblionumber)");
$sth->execute();
my $marc_sth = $dbh->prepare("SELECT marc FROM biblioitems WHERE biblionumber=?");
while (my $thisrec=$sth->fetchrow_hashref()){
   $i++;
   print ".";
   print "\r$i" unless ($i % 100);
   $marc_sth->execute($thisrec->{'biblionumber'});
   my $marcrec = $marc_sth->fetchrow_hashref();
   my $rec;
   eval{ $rec = MARC::Record::new_from_usmarc($marcrec->{'marc'});};
   if ($@){
      print "\n Error in biblio $thisrec->{'biblionumber'}\n";
      next;
   }
   my $curval = $rec->field("001") || "";
   my $newval = $curval;
   $newval =~ s/ocm//;
   $newval =~ s/ocn//;
   if ($newval ne $curval){
      $debug and print "Biblio: $thisrec->{'biblionumber'}  Old: $curval New: $newval\n";
      foreach my $dump ($rec->field("001")){
         $rec->delete_field($dump);
      }
      my $field=MARC::Field->new('001', $newval);
      $rec->insert_fields_ordered($field);
      if ($doo_eet){
         C4::Biblio::ModBiblioMarc($rec,$thisrec->{'biblionumber'}, $thisrec->{'frameworkcode'});
         $modified++;
      }
   }
}
print "\n\n$i records examined.\n$modified records modified.\n";

