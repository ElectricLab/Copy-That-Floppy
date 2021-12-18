#!/usr/local/bin/perl
#
# "copy that floppy!"
#
# ElectricLab March 2020
#
# Mtools version 3.9.6, dated 28 June 1999 does NOT do recursive copying.
#
# Todo:
# [ ] Create a useful recursive copy function.
# [ ] Detect local disk full!   
#     Message appears during copy:    plain_io: No space left on device

use strict;
use File::Basename;

my $config = {
              'floppy_drive'   => 'B:',
              'floppies_dir'   => '/home/corey/floppies',
              'floppy_dir'     => '',
              'dir_text_file'  => '',
              'start_disk_num' => '001',   # 3 digits
             };


while (1) {
    print "\n** READY to COPY THAT FLOPPY **\n";
    print "\nInsert Floppy Disk into $config->{'floppy_drive'} and Press Enter > ";

    my $tmp = <STDIN>;
    
    print "Doing a directory listing of disk...\n";
    
    my $mdir_results = qx(mdir $config->{'floppy_drive'} 2>&1);
    
    if ($mdir_results =~ /Permission denied/i) {
        print "\n**** ERROR: $mdir_results\n";
        
        print "Suggestion: run as root (or sudo)\n\n";
        
        exit;
    }
    elsif ($mdir_results =~/Cannot initialize/i) {
        print "\n**** ERROR: $mdir_results\n";
        
        print "Is there a disk in $config->{'floppy_drive'}?\n\n";
        
        exit;
    }
    
    my @files = split('\n', $mdir_results);
    
    @files = @files[3 .. $#files];  # Delete first 3 elements
    $#files -= 2;                   # Delete last 2 elements
    
    print "There are as many as: " . scalar(@files) . " files.\n";
    print "Directory listing:\n $mdir_results\n";
    print "Proceed with copy? ";
    
    my $yorn = <STDIN>;
    
    if ($yorn !~/y/i) {
        print "\n**** NOT reading in disk... ****\n";

        print "    _    ____   ___  ____ _____ _____ ____  \n";
        print "   / \\  | __ ) / _ \\|  _ \\_   _| ____|  _ \\ \n";
        print "  / _ \\ |  _ \\| | | | |_) || | |  _| | | | |\n";
        print " / ___ \\| |_) | |_| |  _ < | | | |___| |_| |\n";
        print "/_/   \\_\\____/ \\___/|_| \\_\\|_| |_____|____/ \n";     
        print "\n";
        
        next;
    }

    print "Proceeding with copy...\n";
    
    my $user_input = '';
    my $next_disk_num = '';
    my $next_dir = '';
    
    my $globule = $config->{'floppies_dir'} . '/???';
    
    my @file_list = glob ($globule);
    
    @file_list = sort(@file_list);
    
    if (scalar(@file_list)) {
        my $last_dir = basename($file_list[-1]);
        
        $next_disk_num = sprintf("%.3d", $last_dir + 1);
    }
    else {
        $next_disk_num = $config->{'start_disk_num'};
    }

    while (1) {
    
        print "Enter Disk Number (Enter for #" . $next_disk_num . "): ";
        $user_input = <STDIN>;
        chomp($user_input);
     
        if ($user_input =~ /y/i) {
            print "Not Valid!\n";
        }
        else {
            last;
        }
    }        
    
    $next_disk_num = (length($user_input)) ? $user_input : $next_disk_num;
    
    $next_dir = $config->{'floppies_dir'} . '/' . $next_disk_num;
    
    print "next_dir: --$next_dir--\n";
    
    if (-e $next_dir) {
        print "\nError Disk #" . $next_disk_num . " has already been copied, or at least its directory exists here: " . $config->{'floppies_dir'};
        print "Not overwriting. use -force to overwrite (not yet implemented)\n\n";
        
        exit;
    }
    

    print "Creating destination directory: $next_dir\n";
        
    mkdir($next_dir, 0755);
    mkdir($next_dir . '/' . 'contents', 0755);
        
    $config->{'dir_text_file'} = $next_dir . '/' . 'dir.txt';

    open (OUT,">$config->{'dir_text_file'}");
    print OUT "$mdir_results\n";
    close (OUT);

    print "Copying files...\n";
    
    my $cmd = "mcopy -nvms $config->{'floppy_drive'} $next_dir" . '/' . "contents 2>&1";
    my $copy_results = qx($cmd);
    
    print "$copy_results\n";

    # Deal with Subdirectories since this ancient version of mcopy can't do it:
    #
    for my $f (@files) {
        if ($f =~ /<DIR>/) {
            print "DIR!!! $f\n";
            
            my ($sub_dir, $nada) = split('<DIR>', $f);
            
            print "raw sub_dir: --$sub_dir--\n";
            
            $sub_dir =~ s/\s+/\./;
            
            # nasty hack:
            if (substr($sub_dir, -1) eq '.') {
            
                print "chomp!!!!!!!!\n";
                chop($sub_dir);
            }
            
            print "need to make dir: --$sub_dir--\n";
            
            &copy_sub_dir($next_dir . '/contents', $sub_dir);
            
        }
    }
    
    if ($copy_results =~ /Input\/output error/i) {
        print "************************************************\n";
        print "************************************************\n";
        print "**** DONE, but READ Errors were Encountered ****\n";
        print "************************************************\n";
        print "************************************************\n";
    }
    else {
        print "  ____ ___  ______   __  ____  _   _  ____ ____ _____ ____ ____  \n";
        print " / ___/ _ \\|  _ \\ \\ / / / ___|| | | |/ ___/ ___| ____/ ___/ ___| \n";
        print "| |  | | | | |_) \\ V /  \\___ \\| | | | |  | |   |  _| \\___ \\___ \\ \n";
        print "| |__| |_| |  __/ | |    ___) | |_| | |__| |___| |___ ___) |__) |\n";
        print " \\____\\___/|_|    |_|   |____/ \\___/ \\____\\____|_____|____/____/ \n";
    }
    
    print "\nDone with Floppy #" . $next_disk_num . " Don't forget to label it with a sharpie.\n";
    
    print "\n\n\n\n\n";
}



sub copy_sub_dir {
    my ($contents_dir, $sub_dir) = @_;
    
    my $new_local_dir = $contents_dir . '/' . $sub_dir;
    
    print "In copy_sub_dir()\n";
    print "contents_dir: --$contents_dir--\n";
    print "     sub_dir: --$sub_dir--\n";
    
    mkdir($new_local_dir, 0755);
    
    print "Copying files...\n";
    
    my $cmd = "mcopy -nvms $config->{'floppy_drive'}" . '/' . $sub_dir . ' ' . "$contents_dir 2>&1";
    
    my $copy_results = qx($cmd);
    
    print "$copy_results\n";

    print "Checking for more subdirs...\n";
    
    my $mdir_results = qx(mdir $config->{'floppy_drive'}/$sub_dir 2>&1);

    my @files = split('\n', $mdir_results);
    
    @files = @files[5 .. $#files];  # Delete first 3 elements
    $#files -= 2;                   # Delete last 2 elements
    
    print "There are as many as: " . scalar(@files) . " files. in $sub_dir\n";
       
    for my $f (@files) {
        if ($f =~ /\.            <DIR>/ or $f =~ /\.\.           <DIR>/) {
            print "Skipping: $f\n";
            next;
        }
    
        if ($f =~ /<DIR>/) {
            print "Found another SUBDIR!!! $f\n";
            
            my ($sub_dir, $nada) = split(' ', $f);
            
            print "\n\n\nOH NOES, we have another subdir.\n";
            print "IT looks like we need to make this function handle recursion after all.\n";
            exit;
        }
    }    

}    





__END__
