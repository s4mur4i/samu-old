#!/usr/bin/perl -w
#
# Copyright 2008 VMware, Inc.  All rights reserved.
#######################################################################################
# DISCLAIMER. THIS SCRIPT IS PROVIDED TO YOU "AS IS" WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, WHETHER ORAL OR WRITTEN, EXPRESS OR IMPLIED. THE AUTHOR SPECIFICALLY
# DISCLAIMS ANY IMPLIED WARRANTIES OR CONDITIONS OF MERCHANTABILITY, SATISFACTORY
# QUALITY, NON-INFRINGEMENT AND FITNESS FOR A PARTICULAR PURPOSE.
#######################################################################################
use strict;
use warnings;
use lib '/usr/lib/vmware-vcli/apps';
use VMware::VIM2Runtime;
use VMware::VILib;
use AppUtil::HostUtil;
use AppUtil::VMUtil;
sub browse_datastore;
sub print_browse;
sub find_datastores;
sub display_summary;
sub display_folder_structure;
sub print_log;
sub isNumber;
sub validate;
#######################################################################################
#
# exdsfilesize.pl
#	Example script to add a network card virtual machine
#	Parameters:
#		-- name 		Datastore name
#		-- filetype 	credentials
#		-- capacity 	Datastore capacity
#		-- freespace  	Available space in datastore
#		-- out 			Output file name
# This script works with VMware VirtualCenter 2.0 or later.
# This script works with VMware ESX Server 3.0 or later.
#######################################################################################

my %opts = (
   name => {
      type => "=s",
      help => "Name of the Datastore",
	  variable => "name",
      required => 0,
   },
   filetype => {
      type => "=s",
      help => "Type of file system volume",
	  variable => "filetype",
      required => 0,
   },
   capacity => {
      type => "=i",
      help => "Maximum capacity of the datastore, in GB",
	  variable => "capacity",
      required => 0,
   },
   freespace => {
      type => "=i",
      help => "Available space of the datastore, in GB",
	  variable => "freespace",
      required => 0,
   },
   out => {
      type => "=s",
      help => "The file name for storing the script's output",
	  variable => "name",
      required => 0,
   },
);

# validate options, and connect to the server
Opts::add_options(%opts);
Opts::parse();
Opts::validate(\&validate);

my @valid_properties;
use constant STORAGE_MULTIPLIER => 1073741824;  # 1024*1024*1024 (to convert to GB)

Util::connect();

####################################################################################
#	Find the all datastores in datacenter
####################################################################################
my $datastores = find_datastores();

####################################################################################
#	Browse the datastores to get the information
####################################################################################
if (@$datastores) {
   browse_datastore($datastores);
}
else {
   Util::trace(0, "\nNo Datastores Found\n");
}

# logout
Util::disconnect();


sub browse_datastore {
   my ($datastores) = @_;

   # Loop through each datastore
   foreach my $datastore (@$datastores) {

      display_summary($datastore);
      display_folder_structure($datastore);
   }
   Util::trace(0, "\n\n");
}

# Print the filesize belogs to datastore
#=======================================
sub print_browse {
   my %args = @_;
   my $datastore_mor = $args{mor};
   my $path = $args{filePath};
   my $level = $args{level};
   my $browse_task;

   # Create HostDatastoreBrowserSearchSpec spec
   my $files = FileQueryFlags->new(fileSize => 1,
                                   fileType => 1,
                                   modification => 1
                                  );
    my $hostdb_search_spec = HostDatastoreBrowserSearchSpec->new(
                                             details => $files);

	# Searches the folder specified by the datastore path and all subfolders based on the searchSpec
   eval {
      $browse_task = $datastore_mor->SearchDatastoreSubFolders(datastorePath=>$path,
					searchSpec=>$hostdb_search_spec);
	print $path;
   };
   if ($@) {
      Util::trace(0, "\nError occured : ");
      if (ref($@) eq 'SoapFault') {
         if (ref($@->detail) eq 'FileNotFound') {
            Util::trace(0, "The file or folder specified by "
                         . "datastorePath is not found");
         }
         elsif (ref($@->detail) eq 'InvalidDatastore') {
            Util::trace(0, "Operation cannot be performed on the target datastores");
         }
         else {
            Util::trace(0, "\n" . $@ . "\n");
         }
      }
      else {
         Util::trace(0, "\n" . $@ . "\n");
      }
   }
   #Display the filesize and path available in the datastore
   foreach(@$browse_task) {
      print_log("\n Folder Path: '" . $_->folderPath . "'");
      if(defined $_->file) {
         print_log("\n Files present \n");
         foreach my $x (@{$_->file}) {
            print_log("  " . $x->path . "\n");
			print_log("  " . $x->fileSize . "\n");
         }
      }
   }
}
#Gets the list of the datastores in the datacenter on the basis of the parameter provided
#========================================================================================
sub find_datastores {
   my $datastore_name = Opts::get_option('name');
   my $filetype = Opts::get_option('filetype');
   my $capacity = Opts::get_option('capacity');
   my $freespace = Opts::get_option('freespace');
   my $dc = Vim::find_entity_views(view_type => 'Datacenter');
   my @ds_array = ();
   foreach(@$dc) {
      if(defined $_->datastore) {
         @ds_array = (@ds_array, @{$_->datastore});
      }
   }
   my $datastores = Vim::get_views(mo_ref_array => \@ds_array);
   @ds_array = ();
   foreach(@$datastores) {
   my $match_flag = 1;
      if($_->summary->accessible) {
# Checking datastore name
         if($match_flag && $datastore_name) {
            if($_->summary->name eq $datastore_name) {
               # Do Nothing
            }
            else {
               $match_flag = 0;
            }
         }
		 # Checking datastore filetype
         if($match_flag && $filetype) {
            if($_->summary->type eq $filetype) {
               # Do Nothing
            }
            else {
               $match_flag = 0;
            }
         }
		 # Checking datastore capacity
         if($match_flag && $capacity) {
            if( (($_->summary->capacity)/STORAGE_MULTIPLIER) >= $capacity) {
               # Do Nothing
            }
            else {
               $match_flag = 0;
            }
         }
		 # Checking datastore freespace
         if($match_flag && $freespace) {
            if((($_->summary->freeSpace)/STORAGE_MULTIPLIER) >= $freespace) {
               # Do Nothing
            }
            else {
               $match_flag = 0;
            }
         }
		 # Add datastore into the array if matching criteria satisfied
         if($match_flag) {
            @ds_array = (@ds_array, $_);
         }
      }
   }
   return \@ds_array;
}
# Display the datastore filter information
#=========================================
sub display_summary {
   my ($datastore) = @_;
   if($datastore->summary->accessible) {
      print_log("\n\nInformation about datastore : '"
              . $datastore->summary->name . "'");
      print_log("\n---------------------------");
      print_log("\nSummary");
      foreach (@valid_properties) {
         if ($_ eq 'name') {
            print_log("\n Name             : " . $datastore->summary->name);
         }
         if ($_ eq 'location') {
            print_log("\n Location         : " . $datastore->info->url);
         }
         if ($_ eq 'filetype') {
            print_log("\n File system      : " . $datastore->summary->type);
         }
         if ($_ eq 'capacity') {
            print_log("\n Maximum Capacity : "
                   . (($datastore->summary->capacity)/STORAGE_MULTIPLIER) . " GB");
         }
         if ($_ eq 'freespace') {
            print_log("\n Available space  : "
                   . (($datastore->summary->freeSpace)/STORAGE_MULTIPLIER) . " GB");
         }
      }
   }
   else {
      Util::trace(0, "\nDatastore summary not accessible\n");
   }
}
# Display the datastore information
#==================================
sub display_folder_structure {
   my ($datastore) = @_;
   print_log("\n\nDatastore Folder Structure.");
   my $host_data_browser = Vim::get_view(mo_ref => $datastore->browser);
   print_browse(mor => $host_data_browser,
                filePath => '[' . $datastore->summary->name . ']',
                level => 0);
}
# Display/write the information
#==============================
sub print_log {
   my ($data) = @_;
   if (defined (Opts::get_option('out'))) {
      print OUTFILE  "$data";
   }
   else {
      Util::trace(0, "$data");
   }
}
#Sub routine to check wheather value is Numeric
#==============================================
sub isNumber {
   my ($val) = @_;
   my $result = ($val =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/);
   return $result;
}
# validate the host's fields to be displayed
# ===========================================
sub validate {
   my $valid = 1;
   my $length =0;
   @valid_properties = ("name",
                        "location",
                        "filetype",
                        "capacity",
                        "freespace");
   if (Opts::option_is_set('capacity')) {
      if(isNumber (Opts::get_option('capacity'))) {
         if(Opts::get_option('capacity') <= 0) {
            Util::trace(0, "\nCapacity must be a poistive non zero number \n");
            $valid = 0;
         }
      }
   }
   if (Opts::option_is_set('freespace')) {
      if(isNumber (Opts::get_option('freespace'))) {
         if(Opts::get_option('freespace') <= 0) {
            Util::trace(0, "\nFreespace must be a poistive non zero number \n");
            $valid = 0;
         }
      }
   }
   if (Opts::option_is_set('out')) {
      my $filename = Opts::get_option('out');
      if ((length($filename) == 0)) {
         Util::trace(0, "\n'$filename' Not Valid:\n$@\n");
         $valid = 0;
      }
      else {
         open(OUTFILE, ">$filename");
         Util::trace(0, "\nStoring output into file . . . \n");
         if ((length($filename) == 0) ||
            !(-e $filename && -r $filename && -T $filename)) {
            Util::trace(0, "\n'$filename' Not Valid:\n$@\n");
            $valid = 0;
         }
      }
   }
   return $valid;
}
