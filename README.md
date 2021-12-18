# Copy-That-Floppy
A Perl script I wrote to help me read through my large floppy collection, and copy all the files onto a NAS for safekeeping. 
The disks' contents also are inventoried into text files.

Edit the $config hashref to reflect the drive you're reading from 'floppy_drive', and what directory on your local disk to write files to in 'floppies_dir'.
It starts from disk 001 and increments as you read floppies. I normally would write this number on the floppy with a Sharpie after a successful read.

Let me know if you find this useful, or if you have any problems running it.

-Corey J. Anderson
ElectricLab
