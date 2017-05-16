#!/usr/bin/perl
#
# htmldiff - present a diff marked version of two html documents
#
# Copyright (c) 1998-2006 MACS, Inc.
#
# Copyright (c) 2007 SiSco, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# usage: htmldiff oldversion newversion

# markit - diff-mark the streams
#
# markit(file1, file2)
#
# markit relies upon GNUdiff to mark up the text.
#
# The markup is encoded using special control sequences:
#
#   a block wrapped in control-a is deleted text
#   a block wrapped in control-b is old text
#   a block wrapped in control-c is new text
#
# The main processing loop attempts to wrap the text blocks in appropriate
# SPANs based upon the type of text that it is.
#
# When the loop encounters a < in the text, it stops the span. Then it outputs
# the element that is defined, then it restarts the span.

sub markit {
	my $retval = "";
	my($file1) = shift;
	my($file2) = shift;
	my $old="%c'\012'%c'\001'%c'\012'%<%c'\012'%c'\001'%c'\012'";
	my $new="%c'\012'%c'\003'%c'\012'%>%c'\012'%c'\003'%c'\012'";
	my $unchanged="%=";
	my $changed="%c'\012'%c'\001'%c'\012'%<%c'\012'%c'\001'%c'\012'%c'\004'%c'\012'%>%c'\012'%c'\004'%c'\012'";

	my @span;
	$span[0]="</span>";
	$span[1]="<del>";
	$span[2]="<del>";
	$span[3]="<ins>";
	$span[4]="<ins>";

	my @diffEnd ;
	$diffEnd[1] = '</del>';
	$diffEnd[2] = '</del>';
	$diffEnd[3] = '</ins>';
	$diffEnd[4] = '</ins>';

	my $diffcounter = 0;

	open(FILE, qq(diff -d --old-group-format="$old" --new-group-format="$new" --changed-group-format="$changed" --unchanged-group-format="$unchanged" $file1 $file2 |)) || die("Diff failed: $!");

	my $state = 0;
	my $inblock = 0;
	my $temp = "";
	my $lineCount = 0;

# strategy:
#
# process the output of diff...
#
# a link with control A-D means the start/end of the corresponding ordinal
# state (1-4). Resting state is state 0.
#
# While in a state, accumulate the contents for that state. When exiting the
# state, determine if it is appropriate to emit the contents with markup or
# not (basically, if the accumulated buffer contains only empty lines or lines
# with markup, then we don't want to emit the wrappers.  We don't need them.
#
# Note that if there is markup in the "old" block, that markup is silently
# removed.  It isn't really that interesting, and it messes up the output
# something fierce.

	while (<FILE>) {
		my $anchor = "";
		my $anchorEnd = "";
		$lineCount ++;
		if ($state == 0) {	# if we are resting and we find a marker,
							# then we must be entering a block
			if (m/^([\001-\004])/) {
				$state = ord($1);
				$_ = "";
			}
		} else {
			# if we are in "old" state, remove markup
			if (($state == 1) || ($state == 2)) {
				s/\<.*\>//;	# get rid of any old markup
				s/\</&lt;/g; # escape any remaining STAG or ETAGs
				s/\>/&gt;/g;
			}
			# if we found another marker, we must be exiting the state
			if (m/^([\001-\004])/) {
				if ($temp ne "") {
					$_ = $span[$state] . $anchor . $temp . $anchorEnd . $diffEnd[$state] . "\n";
					$temp = "";
				} else {
					$_ = "" ;
				}
				$state = 0;
			} elsif (m/^\s*\</) { # otherwise, is this line markup?
				# if it is markup AND we haven't seen anything else yet,
				# then we will emit the markup
				if ($temp eq "") {
					$retval .= $_;
					$_ = "";
				} else {	# we wrap it with the state switches and hold it
					s/^/$anchorEnd$diffEnd[$state]/;
					s/$/$span[$state]$anchor/;
					$temp .= $_;
					$_ = "";
				}
			} else {
				if (m/.+/) {
					$temp .= $_;
					$_ = "";
				}
			}
		}

		s/\001//g;
		s/\002//g;
		s/\003//g;
		s/\004//g;
		if ($_ !~ m/^$/) {
			$retval .= $_;
		}
		$diffcounter++;
	}
	close FILE;
	$retval =~ s/$span[1]\n+$diffEnd[1]//g;
	$retval =~ s/$span[2]\n+$diffEnd[2]//g;
	$retval =~ s/$span[3]\n+$diffEnd[3]//g;
	$retval =~ s/$span[4]\n+$diffEnd[4]//g;
	$retval =~ s/$span[1]\n*$//g;
	$retval =~ s/$span[2]\n*$//g;
	$retval =~ s/$span[3]\n*$//g;
	$retval =~ s/$span[4]\n*$//g;
	return $retval;
}

sub splitit {
	my $filename = shift;
	my $inheader=0;
	my $preformatted=0;
	my $inelement=0;
	my $retval = "";

	my $incomment = 0;
	open(FILE, $filename) || die("File $filename cannot be opened: $!");
	while (<FILE>) {
		if ($incomment) {
			if (m;-->;) {
				$incomment = 0;
				s/.*-->//;
			} else {
				next;
			}
		}
		if (m;<!--;) {
			while (m;<!--.*-->;) {
				s/<!--.*?-->//;
			}
			if (m;<!--; ) {
				$incomment = 1;
				s/<!--.*//;
			}
		}
		if (m/\<pre/i) {
			$preformatted = 1;
		}
		if (m/\<\/pre\>/i) {
			$preformatted = 0;
		}
		if ($preformatted) {
			$retval .= $_;
		} elsif (/^;;;/) {
			$retval .= $_;
		} else {
			my @list = split(' ');
			foreach $element (@list) {
				if ($element =~ m/\<H[1-6]/i) {
					# $inheader = 1;
				}
				if ($inheader == 0) {
					$element =~ s/</\n</g;
					$element =~ s/^\n//;
					$element =~ s/>/>\n/g;
					$element =~ s/\n$//;
					$element =~ s/>\n([.,:!]+)/>$1/g;
				}
				if ($element =~ m/\<\/H[1-6]\>/i) {
					$inheader = 0;
				}
				$retval .= "$element";
				$inelement += ($element =~ s/</&lt;/g);
				$inelement -= ($element =~ s/>/&gt;/g);
				if ($inelement < 0) {
					$inelement = 0;
				}
				if (($inelement == 0) && ($inheader == 0)) {
					$retval .= "\n";
				} else {
					$retval .= " ";
				}
			}
			undef @list;
		}
	}
	$retval .= "\n";
	close FILE;
	return $retval;
}

$tmp1 = "/tmp/htdtmp1.$$";
$tmp2 = "/tmp/htdtmp2.$$";

if (@ARGV < 2) {
	print STDERR "htmldiff oldversion newversion\n";
	exit;
}

$file1 = $ARGV[0];
$file2 = $ARGV[1];

$tmp = splitit($file1);
open(FILE, ">$tmp1");
print FILE $tmp;
close FILE;

$tmp = splitit($file2);
open(FILE, ">$tmp2");
print FILE $tmp;
close FILE;

$output = markit($tmp1, $tmp2);
print $output;

unlink $tmp1;
unlink $tmp2;
